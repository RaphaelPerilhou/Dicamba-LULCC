rm(list=ls())
library(tigris)
library(dplyr)

# Download state boundaries
states_sf <- states(year = 2016, cb = TRUE)

# Download all county boundaries at once
counties_sf <- counties(year = 2016, cb = TRUE)
# LSAD = "25" identifies independent cities in the counties shapefile.
# Source: https://www.census.gov/library/reference/code-lists/legal-status-codes.html
# County NAME is kept as-is (raw Census NAME). GEOID is used as the unique
# identifier throughout the pipeline — no name manipulation needed.

# Save both

saveRDS(states_sf, "data/SF/states_2016.rds")
saveRDS(counties_sf, "data/SF/counties_2016.rds")
