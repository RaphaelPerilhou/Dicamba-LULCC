##############################################################################
# 00_setup_and_clip.R
# Step 1: Create directory structure
# Step 2: Verify CDL files exist + Projection is correct.
# Step 3: Clip national CDL to each state
#
# Run this script first before anything else.
# For now: Rhode Island only, 2009-2010.
# Later on TSE server: change states and years arguments only.
##############################################################################
setwd("/users/rperilhou/RA_Dicamba/")
rm(list = ls())

library(terra)
#library(tigris) not installed on ANUBIS so we download the shapefiles from
# tigris package on our computer as RDS and then we load them directly.
library(dplyr)

# 1/ LOAD OFFICIAL STATE BOUNDARIES FROM CENSUS
# We can adapt later for counties.


cat("Loading state boundaries (from Census TIGER)")
#states_sf <- states(year = 2016, cb = TRUE)
states_sf <- readRDS("data/SF/states_2016.rds")
counties_sf <- readRDS("data/SF/counties_2016.rds")
# All 48 contiguous states (for future reference)
contiguous_states <- states_sf %>%
  sf::st_drop_geometry() %>%
  filter(!STATEFP %in% c("02", "15",
                         "60", "66", "69", "72", "78")) %>%
  pull(NAME) %>%
  sort()

cat("Contiguous states available:", length(contiguous_states),"\n")

# Here define states and period of interest.
TARGET_STATES <- contiguous_states
TARGET_YEARS  <- c(2009: 2018)

cat("Running for:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Running for years:", paste(TARGET_YEARS, collapse = ", "), "\n")

# 2/ CREATE DIRECTORY STRUCTURE

cat("Creating directory structure")

created <- 0
for (state in TARGET_STATES) {
  state_fips   <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  counties_tbl <- counties_sf %>% sf::st_drop_geometry() %>%
    filter(STATEFP == state_fips) %>% select(NAME, COUNTYFP)
  state_s <- gsub(" ", "_", state)
  for (k in seq_len(nrow(counties_tbl))) {
    county   <- counties_tbl$NAME[k]
    countyfp <- counties_tbl$COUNTYFP[k]
    county_s <- make_county_s(county, countyfp)
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
# Does not overwrite so if there is any modification on the directory structure,
# need to deleted the folders and re-run.

# 3/ VERIFY CDL FILES EXIST
# Expected: data/<year>_30m_cdls/<year>_30m_cdls.tif

cat("Checking CDL files:")

get_cdl_path <- function(year) {
  paste0("data/", year, "_30m_cdls/", year, "_30m_cdls.tif")
}

# Independent cities (COUNTYFP >= 500) share NAME with a nearby county.
# Append _City to the folder/file token to keep paths distinct.
make_county_s <- function(county_name, countyfp) {
  s <- gsub(" ", "_", county_name)
  if (as.numeric(countyfp) >= 500) paste0(s, "_City") else s
}

missing_files <- c()
for (year in TARGET_YEARS) {
  path <- get_cdl_path(year)
  if (file.exists(path)) {
    size_mb <- round(file.info(path)$size / 1e6, 1)
    cat(" CORRECT:", path,"(",size_mb,"MB)\n")
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

# 4/ VERIFY the projection used matches the official CDL CRS
# Can be found here: https://www.nass.usda.gov/Research_and_Science/Cropland/sarsfaqs2.php#common.2

# load one raster object per year into a list (so we can still use when more than 2 years)
rasters <- lapply(TARGET_YEARS, function(y) rast(get_cdl_path(y))) 

# Check CRS and resolution of first year
cat("CRS:       ", crs(rasters[[1]], describe = TRUE)$name, "\n")
cat("Resolution:", res(rasters[[1]]), "metres\n\n")

# Cross-year consistency against first year as reference
for (i in seq_along(rasters)[-1]) {
  cat("vs", TARGET_YEARS[i],
      "— CRS:", same.crs(rasters[[1]], rasters[[i]]),
      "| res:", all(res(rasters[[1]]) == res(rasters[[i]])),
      "| ext:", ext(rasters[[1]]) == ext(rasters[[i]]), "\n")
}

# 5/ CLIP FUNCTION

clip_county <- function(year, state_name, county_name, countyfp, counties_sf) {

  state_s  <- gsub(" ", "_", state_name)
  county_s <- make_county_s(county_name, countyfp)
  out_path <- file.path("data/clipped", state_s, county_s,
                        paste0("CDL_", year, "_", county_s, ".tif"))

  if (file.exists(out_path)) {
    cat("  Skipping (exists):", out_path, "\n")
    return(out_path)
  }

  cdl          <- rast(get_cdl_path(year))
  county_vect  <- counties_sf %>% filter(NAME == county_name, COUNTYFP == countyfp) %>% vect()
  county_proj  <- project(county_vect, crs(cdl))
  clipped      <- crop(cdl, county_proj) %>% mask(county_proj, touches = FALSE)

  writeRaster(clipped, out_path, overwrite = TRUE, datatype = "INT1U")
  cat("  Saved:", out_path, "\n")
  return(out_path)
}

# 6/ RUN CLIPPING

#for (state in TARGET_STATES) {
#  state_fips     <- states_sf %>% sf::st_drop_geometry() %>%
#    filter(NAME == state) %>% pull(STATEFP)
#  counties_state <- counties_sf %>% filter(STATEFP == state_fips)
#  county_names   <- counties_state %>% sf::st_drop_geometry() %>% pull(NAME)
#  for (county in county_names) {
#    for (year in TARGET_YEARS) {
#      cat(state, county, year, "\n")
#      clip_county(year, state, county, counties_sf)
#    }
#  }
#}

# 6/ RUN CLIPPING
library(parallel)

# Build flat list of all state/county tasks
tasks <- do.call(rbind, lapply(TARGET_STATES, function(state) {
  state_fips   <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  counties_tbl <- counties_sf %>% sf::st_drop_geometry() %>%
    filter(STATEFP == state_fips) %>% select(NAME, COUNTYFP)
  data.frame(state    = state,
             county   = counties_tbl$NAME,
             countyfp = counties_tbl$COUNTYFP,
             stringsAsFactors = FALSE)
}))

# ANUBIS cluster setup
source("/softs/R/createCluster.R")
cl <- createCluster()

# Export necessary objects to all workers
clusterExport(cl, c("states_sf", "counties_sf", "TARGET_YEARS",
                    "clip_county", "get_cdl_path", "make_county_s", "tasks"))

# Run clipping in parallel across all state/county pairs
parLapply(cl, seq_len(nrow(tasks)), function(i) {
  library(terra)
  library(dplyr)
  state    <- tasks$state[i]
  county   <- tasks$county[i]
  countyfp <- tasks$countyfp[i]
  state_fips     <- states_sf %>% sf::st_drop_geometry() %>%
    filter(NAME == state) %>% pull(STATEFP)
  counties_state <- counties_sf %>% filter(STATEFP == state_fips)
  for (year in TARGET_YEARS) {
    clip_county(year, state, county, countyfp, counties_state)
  }
})

stopCluster(cl)
cat("ALL DONE: Clipped files saved in data/clipped/")

# At this stage each folder data/clipped/<state>/<county>/ should contain a .tif file per year,
# named like: CDL_<Year>_<County>.tif.

