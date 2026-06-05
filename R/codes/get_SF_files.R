rm(list=ls())
library(tigris)
library(dplyr)

# Download state boundaries
states_sf <- states(year = 2016, cb = TRUE)

# Download all county boundaries at once
counties_sf <- counties(year = 2016, cb = TRUE)
# LSAD = "25" identifies independent cities (city suffix) in the counties shapefile.
# Source: https://www.census.gov/library/reference/code-lists/legal-status-codes.html

counties_sf <- counties_sf %>%
  mutate(NAME = ifelse(
    LSAD == "25",
    paste0(gsub(" ", "_", NAME), "_City"),
    gsub(" ", "_", NAME)
  ))

# Save both

saveRDS(states_sf, "data/SF/states_2016.rds")
saveRDS(counties_sf, "data/SF/counties_2016.rds")
