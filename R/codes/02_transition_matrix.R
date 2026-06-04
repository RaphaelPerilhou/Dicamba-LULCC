################################################################################
# 02_transition_matrix.R
# Computes exact pixel-level transition matrices between consecutive years
# using terra::crosstab() on classified rasters.

# Inputs:  outputs/classified/<state>/Classified_<year>_<state>.tif
# Outputs: outputs/transitions/<state>/TM_<year_from><year_to>_<state>.csv

# For parallelisation on ANUBIS HPC: replace lapply with mclapply.
################################################################################

rm(list = ls())
setwd("/users/rperilhou/RA_Dicamba")

library(terra)
library(dplyr)
library(tidyr)
library(readr)
################################################################################
# CONFIGURATION
################################################################################
states_sf   <- readRDS("data/SF/states_2016.rds")
counties_sf <- readRDS("data/SF/counties_2016.rds")

# All 48 contiguous states
contiguous_states <- states_sf %>%
  sf::st_drop_geometry() %>%
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) %>%
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
  
  if (!file.exists(path_from)) stop("Missing classified raster: ", path_from)
  if (!file.exists(path_to))   stop("Missing classified raster: ", path_to)
  
  # Load both classified rasters
  r_from <- rast(path_from)
  r_to   <- rast(path_to)
  
  # Verify alignment (same extent, resolution and CRS)
  if (!compareGeom(r_from, r_to, stopOnError = FALSE)) {
    stop("Rasters are not aligned for ", state, " years ", year_from, "-", year_to)
  }
  
  # Stack and crosstab to get exact pixel-level transition matrix.
  # Crosstab counts every combination of (r_from value, r_to value).
  # NAs are automatically ignored (only pixels outside the union mask,
  # which we exclude entirely). Pixels inside the union mask but
  # unclassified were already converted to 99 (Unclassified) in 01.R.
  cat("  Running crosstab", year_from, "->", year_to, "...\n")
  stacked <- c(r_from, r_to)
  tm      <- crosstab(stacked)  # Our 5x5 matrix 
  
  # Apply category labels to rows and columns
  rownames(tm) <- category_labels[rownames(tm)]
  colnames(tm) <- category_labels[colnames(tm)]
  
  # Check that total pixels is equal to union mask size
  total <- sum(tm)
  cat("  Total transition pixels:", total)
  
  # TM: 
  cat("  Transition matrix:", year_from, "->", year_to)
  print(tm)
  
  # Save the 5x5 matrix as CSV
  write.csv(tm, out_path)
  cat("  Saved:", out_path, "\n")
  
  return(tm)
}

# Run 

cat("Starting transition matrix pipeline...\n")
cat("States:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Years: ", paste(TARGET_YEARS,  collapse = ", "), "\n\n")

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
                    "compute_transition", "classified_path", "transition_path",
                    "category_labels", "tasks"))

parLapply(cl, seq_len(nrow(tasks)), function(i) {
  library(terra)
  library(dplyr)
  state  <- tasks$state[i]
  county <- tasks$county[i]
  for (j in seq_len(length(TARGET_YEARS) - 1)) {
    compute_transition(TARGET_YEARS[j], TARGET_YEARS[j+1], state, county)
  }
})

stopCluster(cl)
cat("ALL DONE: Transition matrices saved in outputs/transitions/")





