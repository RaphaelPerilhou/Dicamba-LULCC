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

rm(list = ls())

library(terra)
library(tigris)
library(dplyr)

# 1/ LOAD OFFICIAL STATE BOUNDARIES FROM CENSUS
# We can adapt later for counties.


cat("Loading state boundaries (from Census TIGER)")
states_sf <- states(year = 2016, cb = TRUE)

# All 48 contiguous states (for future reference)
contiguous_states <- states_sf %>%
  filter(!STATEFP %in% c("02", "15",  # Alaska, Hawaii
                         "60", "66", "69", "72", "78")) %>%  # territories
  pull(NAME) %>%
  sort()

cat("Contiguous states available:", length(contiguous_states))

# Here define states and period of interest.
TARGET_STATES <- c("Rhode Island", "Alabama")   # later: contiguous_states (all 48)
TARGET_YEARS  <- c(2009: 2011)    # later: 2009:2018

cat("Running for:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Running for years:", paste(TARGET_YEARS, collapse = ", "), "\n")

# 2/ CREATE DIRECTORY STRUCTURE

cat("Creating directory structure")

dirs <- c(
  paste0("data/clipped/",        contiguous_states),
  paste0("outputs/classified/",  contiguous_states),
  paste0("outputs/transitions/", contiguous_states)
)

created <- 0
for (d in dirs) {
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    created <- created + 1
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

clip_state <- function(year, state_name, states_sf) {
  
  out_path <- paste0("data/clipped/", state_name, "/CDL_", year, "_",
                     gsub(" ", "_", state_name), ".tif")
  
  if (file.exists(out_path)) {
    cat("  Skipping (exists):", out_path, "\n")
    return(out_path)
  }
  
  cdl         <- rast(get_cdl_path(year))
  state_vect  <- states_sf %>% filter(NAME == state_name) %>% vect()
  state_proj  <- project(state_vect, crs(cdl))
  clipped     <- crop(cdl, state_proj) %>% mask(state_proj)
  
  writeRaster(clipped, out_path, overwrite = TRUE, datatype = "INT1U")
  cat("  Saved:", out_path, "\n")
  return(out_path)
}

# 6/ RUN CLIPPING

for (state in TARGET_STATES) {
  for (year in TARGET_YEARS) {
    cat(state, year, "\n")
    clip_state(year, state, states_sf)
  }
}

# At this stage each folder data/clipped/<state>/ should contain a .tif file per year,
# named like: CDL_<Year>_<State>.tif. 