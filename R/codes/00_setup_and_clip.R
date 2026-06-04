##############################################################################
# 00_setup_and_clip.R
# Step 1: Create directory structure
# Step 2: Verify CDL files exist + Projection is correct.
# Step 3: Clip national CDL to each state
#
# Run this script first before anything else.
# Later on TSE server: change states and years arguments only.
##############################################################################
setwd("/users/rperilhou/RA_Dicamba/")
rm(list = ls())

library(terra)
library(dplyr)

# 1/ LOAD OFFICIAL STATE BOUNDARIES FROM CENSUS
# Independent cities are already handled in the RDS:
# LSAD == "25" entries have "_City" appended to their NAME.
# Source: https://www.census.gov/library/reference/code-lists/legal-status-codes.html

cat("Loading state boundaries (from Census TIGER)")
states_sf  <- readRDS("data/SF/states_2016.rds")
counties_sf <- readRDS("data/SF/counties_2016.rds")

# All contiguous states
contiguous_states <- states_sf %>%
  sf::st_drop_geometry() %>%
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) %>%
  pull(NAME) %>%
  sort()

cat("Contiguous states available:", length(contiguous_states), "\n")

TARGET_STATES <- contiguous_states
TARGET_YEARS  <- c(2009:2018)

cat("Running for:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Running for years:", paste(TARGET_YEARS, collapse = ", "), "\n")

# 2/ CREATE DIRECTORY STRUCTURE

cat("Creating directory structure")

created <- 0
for (state in TARGET_STATES) {
  state_fips   <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  county_names <- counties_sf %>% sf::st_drop_geometry() %>%
    filter(STATEFP == state_fips) %>% pull(NAME)
  state_s <- gsub(" ", "_", state)
  for (county in county_names) {
    county_s <- gsub(" ", "_", county)
    dirs <- c(
      file.path("data/clipped",        state_s, county_s),
      file.path("outputs/classified",  state_s, county_s),
      file.path("outputs/transitions", state_s, county_s)
    )
    for (d in dirs) {
      if (!dir.exists(d)) {
        dir.create(d, recursive = TRUE)
        created <- created + 1
      }
    }
  }
}

cat("Done:", created, "directories created.\n")

# 3/ VERIFY CDL FILES EXIST

cat("Checking CDL files:")

get_cdl_path <- function(year) {
  paste0("data/", year, "_30m_cdls/", year, "_30m_cdls.tif")
}

missing_files <- c()
for (year in TARGET_YEARS) {
  path <- get_cdl_path(year)
  if (file.exists(path)) {
    size_mb <- round(file.info(path)$size / 1e6, 1)
    cat(" CORRECT:", path, "(", size_mb, "MB)\n")
  } else {
    cat(" MISSING:", path, "\n")
    missing_files <- c(missing_files, path)
  }
}

if (length(missing_files) > 0) {
  stop("Missing CDL files. Please download the following before continuing:",
       paste(missing_files, collapse = "\n"))
} else {
  cat("All CDL files found.")
}

# 4/ VERIFY CRS

rasters <- lapply(TARGET_YEARS, function(y) rast(get_cdl_path(y)))

cat("CRS:       ", crs(rasters[[1]], describe = TRUE)$name, "\n")
cat("Resolution:", res(rasters[[1]]), "metres\n\n")

for (i in seq_along(rasters)[-1]) {
  cat("vs", TARGET_YEARS[i],
      "— CRS:", same.crs(rasters[[1]], rasters[[i]]),
      "| res:", all(res(rasters[[1]]) == res(rasters[[i]])),
      "| ext:", ext(rasters[[1]]) == ext(rasters[[i]]), "\n")
}

# 5/ CLIP FUNCTION

clip_county <- function(year, state_name, county_name, counties_sf) {

  state_s  <- gsub(" ", "_", state_name)
  county_s <- gsub(" ", "_", county_name)
  out_path <- file.path("data/clipped", state_s, county_s,
                        paste0("CDL_", year, "_", county_s, ".tif"))

  if (file.exists(out_path)) {
    cat("  Skipping (exists):", out_path, "\n")
    return(out_path)
  }

  cdl         <- rast(get_cdl_path(year))
  county_vect <- counties_sf %>% filter(NAME == county_name) %>% vect()
  county_proj <- project(county_vect, crs(cdl))
  clipped     <- crop(cdl, county_proj) %>% mask(county_proj, touches = FALSE)

  writeRaster(clipped, out_path, overwrite = TRUE, datatype = "INT1U")
  cat("  Saved:", out_path, "\n")
  return(out_path)
}

# 6/ RUN CLIPPING
library(parallel)

tasks <- do.call(rbind, lapply(TARGET_STATES, function(state) {
  state_fips   <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  county_names <- counties_sf %>% sf::st_drop_geometry() %>%
    filter(STATEFP == state_fips) %>% pull(NAME)
  expand.grid(state = state, county = county_names,
              stringsAsFactors = FALSE)
}))

source("/softs/R/createCluster.R")
cl <- createCluster()

clusterExport(cl, c("states_sf", "counties_sf", "TARGET_YEARS",
                    "clip_county", "get_cdl_path", "tasks"))

parLapply(cl, seq_len(nrow(tasks)), function(i) {
  library(terra)
  library(dplyr)
  state  <- tasks$state[i]
  county <- tasks$county[i]
  state_fips     <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  counties_state <- counties_sf %>% filter(STATEFP == state_fips)
  for (year in TARGET_YEARS) {
    clip_county(year, state, county, counties_state)
  }
})

stopCluster(cl)
cat("ALL DONE: Clipped files saved in data/clipped/")
