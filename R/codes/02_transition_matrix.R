################################################################################
# 02_transition_matrix.R
# Computes exact pixel-level transition matrices between consecutive years
# using terra::crosstab() on classified rasters.

# Inputs:  outputs/classified/<statefp>/Classified_<year>_<geoid>.tif
# Outputs: outputs/transitions/<statefp>/TM_<year_from><year_to>_<geoid>.csv

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

# All 48 contiguous states (STATEFP codes)
contiguous_statefps <- states_sf %>%
  sf::st_drop_geometry() %>%
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) %>%
  pull(STATEFP)

cat("Contiguous states available:", length(contiguous_statefps), "\n")

TARGET_STATEFPS <- contiguous_statefps
TARGET_YEARS    <- c(2009:2018)


# File paths

classified_path <- function(year, geoid, statefp) {
  file.path("outputs/classified", statefp,
            paste0("Classified_", year, "_", geoid, ".tif"))
}

transition_path <- function(year_from, year_to, geoid, statefp) {
  file.path("outputs/transitions", statefp,
            paste0("TM_", year_from, year_to, "_", geoid, ".csv"))
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
compute_transition <- function(year_from, year_to, geoid, statefp, force = FALSE) {

  out_path <- transition_path(year_from, year_to, geoid, statefp)

  if (file.exists(out_path) && !force) {
    cat("  Already exists, skipping:", out_path, "\n")
    return(read.csv(out_path, row.names = 1, check.names = FALSE))
  }

  # Check inputs exist
  path_from <- classified_path(year_from, geoid, statefp)
  path_to   <- classified_path(year_to,   geoid, statefp)

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
    stop("Rasters are not aligned for GEOID ", geoid,
         " years ", year_from, "-", year_to)
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

# RUN
cat("Starting transition matrix pipeline...\n")
cat("Years: ", paste(TARGET_YEARS, collapse = ", "), "\n\n")

library(parallel)

tasks <- counties_sf %>%
  sf::st_drop_geometry() %>%
  filter(STATEFP %in% TARGET_STATEFPS) %>%
  select(GEOID, STATEFP)

source("/softs/R/createCluster.R")
cl <- createCluster()

clusterExport(cl, c("counties_sf", "TARGET_YEARS",
                    "compute_transition", "classified_path", "transition_path",
                    "category_labels", "tasks"))

parLapply(cl, seq_len(nrow(tasks)), function(i) {
  library(terra)
  library(dplyr)
  geoid   <- tasks$GEOID[i]
  statefp <- tasks$STATEFP[i]
  for (j in seq_len(length(TARGET_YEARS) - 1)) {
    compute_transition(TARGET_YEARS[j], TARGET_YEARS[j+1], geoid, statefp)
  }
})

stopCluster(cl)
cat("ALL DONE: Transition matrices saved in outputs/transitions/\n")
