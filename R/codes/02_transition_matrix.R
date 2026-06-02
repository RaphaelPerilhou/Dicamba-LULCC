################################################################################
# 02_transition_matrix.R
# Computes exact pixel-level transition matrices between consecutive years
# using terra::crosstab() on classified rasters.

# Inputs:  outputs/classified/<state>/Classified_<year>_<state>.tif
# Outputs: outputs/transitions/<state>/TM_<year_from><year_to>_<state>.csv
#          outputs/transitions/<state>/TM_all_<state>.csv (all years combined)

# For parallelisation on ANUBIS HPC: replace lapply with mclapply.
################################################################################

rm(list = ls())

library(terra)
library(dplyr)
library(tidyr)
library(readr)
library(tigris)
################################################################################
# CONFIGURATION
################################################################################
states_sf <- states(year = 2016, cb = TRUE)

# All 48 contiguous states
contiguous_states <- states_sf %>%
  filter(!STATEFP %in% c("02", "15",  # Alaska, Hawaii
                         "60", "66", "69", "72", "78")) %>%  # territories
  pull(NAME) %>%
  sort()

cat("Contiguous states available:", length(contiguous_states), "\n")

# Here define states and period of interest.

TARGET_STATES <- contiguous_states   # later: contiguous_states (all 48)
TARGET_YEARS  <- c(2009: 2018)    # later: 2009:2018


# File paths

classified_path <- function(year, state, county) {
  state_s  <- gsub(" ", "_", state)
  county_s <- gsub(" ", "_", county)
  file.path("outputs/classified", state_s, county_s,
            paste0("Classified_", year, "_", county_s, ".tif"))
}

transition_path <- function(year_from, year_to, state, county) {
  state_s  <- gsub(" ", "_", state)
  county_s <- gsub(" ", "_", county)
  file.path("outputs/transitions", state_s, county_s,
            paste0("TM_", year_from, year_to, "_", county_s, ".csv"))
}
################################################################################
# CATEGORY LABELS
################################################################################
category_labels <- c("0"  = "NonCrop",
                     "1"  = "GM",
                     "2"  = "Tolerant",
                     "3"  = "Vulnerable",
                     "99" = "Unclassified")

################################################################################
# TRANSITION FUNCTION: Compute transition matrix for one year pair
################################################################################
compute_transition <- function(year_from, year_to, state, county, force = FALSE) {

  out_path <- transition_path(year_from, year_to, state, county)

  if (file.exists(out_path) && !force) {
    cat("  Already exists, skipping:", out_path, "\n")
    return(read.csv(out_path, row.names = 1, check.names = FALSE))
  }

  # Check inputs exist
  path_from <- classified_path(year_from, state, county)
  path_to   <- classified_path(year_to,   state, county)
  
  if (!file.exists(path_from)) {
    stop("Missing classified raster: ", path_from,
         "\nRun 01_mask_and_classify.R first.")
  }
  if (!file.exists(path_to)) {
    stop("Missing classified raster: ", path_to,
         "\nRun 01_mask_and_classify.R first.")
  }
  
  # Load both classified rasters
  r_from <- rast(path_from)
  r_to   <- rast(path_to)
  
  # Verify alignment (same extent, resolution and CRS)
  if (!compareGeom(r_from, r_to, stopOnError = FALSE)) {
    stop("Rasters are not aligned for ", state,
         " years ", year_from, "-", year_to)
  }
  
  # Stack and crosstab to get exact pixel-level transition matrix.
  # Crosstab counts every combination of (r_from value, r_to value).
  # NAs are automatically ignored (only pixels outside the union mask,
  # which we exclude entirely). Pixels inside the union mask but
  # unclassified were already converted to 0 (NonCrop) in 01.R.
  cat("  Running crosstab", year_from, "->", year_to, "...\n")
  stacked <- c(r_from, r_to)
  tm      <- crosstab(stacked)  # Our 4x4 matrix 
  
  # Apply category labels to rows and columns
  rownames(tm) <- category_labels[rownames(tm)]
  colnames(tm) <- category_labels[colnames(tm)]
  
  # Check that total pixels is equal to union mask size
  total <- sum(tm)
  cat("  Total transition pixels:", total)
  
  # TM: 
  cat("  Transition matrix:", year_from, "->", year_to)
  print(tm)
  
  # Save the 4x4 matrix as CSV
  write.csv(tm, out_path)
  cat("  Saved:", out_path, "\n")
  
  return(tm)
}

# RUN
# For parallelisation on TSE replace lapply with:
#   library(parallel)
#   mclapply(TARGET_STATES, function(state) {
#     lapply(seq_len(length(TARGET_YEARS) - 1), function(i)
#       compute_transition(TARGET_YEARS[i], TARGET_YEARS[i+1], state))
#   }, mc.cores = N)

cat("Starting transition matrix pipeline...\n")
cat("States:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Years: ", paste(TARGET_YEARS,  collapse = ", "), "\n\n")

for (state in TARGET_STATES) {
  counties_sf <- counties(state = state, year = 2016, cb = TRUE)
  county_names <- counties_sf %>% pull(NAME)
  for (county in county_names) {
    cat("##########################################\n")
    cat("State:", state, "| County:", county, "| Years:", min(TARGET_YEARS), "-", max(TARGET_YEARS),"\n")
    cat("##########################################\n")
    for (i in seq_len(length(TARGET_YEARS) - 1)) {
      cat("  - Year pair:", TARGET_YEARS[i], "->", TARGET_YEARS[i+1])
      compute_transition(TARGET_YEARS[i], TARGET_YEARS[i+1], state, county)
    }
    cat("County", county, "complete.")
  }
}

cat("ALL DONE: Transition matrices saved in outputs/transitions/")





