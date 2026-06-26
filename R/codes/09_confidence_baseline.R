rm(list = ls())
library(tidyverse)
library(terra)

#Configuration

TARGET_YEAR <- 2012
PIXEL_ACRES <- 0.222395

# Category codes for cropland (excludes 0=NonCrop, 99=Unclassified)
CROPLAND_CODES <- c(1L, 2L, 3L)
CODE_TO_NAME   <- c("1" = "GM", "2" = "Tolerant", "3" = "Vulnerable")

conf_stacked_path <- function(geoid, statefp) {
  file.path("data/class_and_conf", statefp,
            paste0("Conf_stacked_", TARGET_YEAR, "_", geoid, ".tif"))
}

#Counties to process

missing_geoid <- read_csv("data/metadata/missing_geoid_census.csv",
                          col_types = cols(GEOID = col_character())) %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  pull(GEOID) %>%
  unique()

counties <- read.csv("data/county_lookup.csv", colClasses = "character") %>%
  mutate(GEOID   = sprintf("%05d", as.integer(GEOID)),
         STATEFP = sprintf("%02d", as.integer(STATEFP))) %>%
  filter(!GEOID %in% missing_geoid) %>%
  select(GEOID, STATEFP)

#Main loop

results <- list()

for (i in seq_len(nrow(counties))) {
  
  geoid   <- counties$GEOID[i]
  statefp <- counties$STATEFP[i]
  path    <- conf_stacked_path(geoid, statefp)
  
  if (!file.exists(path)) {
    cat("WARNING: missing stacked raster for GEOID", geoid, "— skipping.\n")
    next
  }
  
  cat("Processing GEOID", geoid, "...\n")
  stacked  <- rast(path)
  cat_vals  <- values(stacked[[1]])   # category band
  conf_vals <- values(stacked[[2]])   # confidence band
  
  # Q_i: county-level quality index
  # Mean confidence of all cropland pixels in the county
  is_cropland <- !is.na(cat_vals) & cat_vals %in% CROPLAND_CODES
  mean_conf_county <- mean(conf_vals[is_cropland], na.rm = TRUE)
  
  # Q_i,c: per-category quality index 
  # Mean confidence of cropland pixels per category
  cat_results <- lapply(CROPLAND_CODES, function(code) {
    is_cat <- !is.na(cat_vals) & cat_vals == code
    data.frame(
      GEOID              = geoid,
      Category_Code      = code,
      Category           = CODE_TO_NAME[as.character(code)],
      n_pixels           = sum(is_cat),
      mean_conf_category = mean(conf_vals[is_cat], na.rm = TRUE)
    )
  })
  
  cat_df <- bind_rows(cat_results) %>%
    mutate(mean_conf_county = mean_conf_county)
  
  results[[geoid]] <- cat_df
}

# bind output 

quality_baseline <- bind_rows(results)

# Q_i,c = mean_conf_category / mean_conf_county  (per category per county)
# Q_i   = 1 by construction at baseline (all cropland / all cropland)
# These denominators are needed when we later compute quality for a model:
# Q_model_i,c = mean_conf(reclassified pixels in category c) / mean_conf_category
# Q_model_i   = mean_conf(all reclassified pixels) / mean_conf_county

cat("\nBaseline confidence by county and category:\n")
print(quality_baseline)

bias <- read_csv("outputs/baseline_bias.csv")
baseline <- bias %>%
  select(GEOID, Category,
         acres_cdl, acres_census, n_suppressed,
         delta_acres, delta_pct_census, delta_pct_CDL) %>%
  left_join(
    quality_baseline %>%
      select(GEOID, Category, mean_conf_category, mean_conf_county),
    by = c("GEOID", "Category")
  )

write_csv(baseline, "outputs/baseline_measures.csv")


