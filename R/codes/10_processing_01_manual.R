rm(list = ls())
library(tidyverse)
library(terra)
library(stargazer)

PIXEL_ACRES <- 0.222395
TARGET_YEAR <- 2012
#GEOIDS_FOCUS <- c("05093", "13277", "29155")
GEOIDS_FOCUS <- "13277"

#Load counties:
missing_geoid <- read_csv(
  "data/metadata/missing_geoid_census.csv",
  col_types = cols(GEOID = col_character())
) %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  pull(GEOID)

#For the moment we also exclude the cunties where census reports 0 acres
# across all 3 categories.
zero_acres_geoids <- read_csv("data/metadata/zero_census_acres_geoids.csv") %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  pull(GEOID)

counties_selected <- read.csv(
  "data/county_lookup.csv",
  colClasses = "character"
) %>%
  mutate(
    GEOID = sprintf("%05d", as.integer(GEOID)),
    STATEFP = sprintf("%02d", as.integer(STATEFP))
  ) %>%
  filter(
    GEOID %in% GEOIDS_FOCUS,
    !GEOID %in% missing_geoid,
    !GEOID %in% zero_acres_geoids
  ) %>%
  select(GEOID, STATEFP)

#Load baseline
baseline <- read_csv(
  "outputs/baseline_bias.csv",
  col_types = cols(GEOID = col_character())
) %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  filter(GEOID %in% counties_selected$GEOID) %>%
  rename(acres_cdl_baseline = acres_cdl, delta_acres_baseline = delta_acres)

cat("Counties to process:", nrow(counties_selected), "\n")
print(counties_selected)

#Helpers:
#To get classified and confidence raster for {County, Statefp}
conf_stacked_path <- function(geoid, statefp) {
  file.path(
    "data/class_and_conf",
    statefp,
    paste0("Conf_stacked_", TARGET_YEAR, "_", geoid, ".tif")
  )
}

out_path <- "outputs/models/"

# ── Model functions ───────────────────────────────────────────────────────────

# Model A: MMU full-class
# Small patches of each category (surrounded by other categories) are
# reclassified to the modal category of their immediate neighbours.
# Uses landscapemetrics::get_patches() so cross-category boundaries
# act as patch separators — a 3-pixel Vulnerable island inside GM
# is its own patch and gets reclassified if below mmu_acres.
apply_mmu_full <- function(cat_raster, mmu_acres, neighbors, window_size) {
  output <- terra::deepcopy(cat_raster)

  for (code in c(1L, 2L, 3L)) {
    patch_list <- landscapemetrics::get_patches(
      cat_raster,
      class = code,
      directions = neighbors
    )
    patch_raster <- patch_list[[1]][[1]]
    freq_tbl <- terra::freq(patch_raster)
    small_ids <- freq_tbl$value[freq_tbl$count * PIXEL_ACRES < mmu_acres]

    if (length(small_ids) == 0) {
      next
    }

    # Null out small patch pixels then fill from neighbours via focal modal
    # so small patch pixels don't vote for themselves
    temp <- ifel(patch_raster %in% small_ids, NA, cat_raster)
    fill <- terra::focal(
      temp,
      w = window_size,
      fun = "modal",
      na.rm = TRUE,
      na.policy = "only"
    )
    output <- ifel(patch_raster %in% small_ids, fill, output)
  }

  ifel(is.na(cat_raster), NA, output)
}

# Model B: spatial majority filter on full categorical raster
# Each pixel is replaced by the modal category in its w×w neighbourhood.
# Only cropland pixels {1,2,3} are updated; 0, 99, NA are preserved.
apply_spatfilter_full <- function(cat_raster, window_size, neighbors) {
  smoothed <- terra::focal(
    cat_raster,
    w = window_size,
    fun = "modal",
    na.rm = TRUE,
    na.policy = "omit"
  )

  update_mask <- (cat_raster %in% c(1L, 2L, 3L)) &
    (smoothed %in% c(0L, 1L, 2L, 3L, 99L))
  output <- ifel(update_mask, smoothed, cat_raster)
  ifel(is.na(cat_raster), NA, output)
}


#Function for measurement

#Bias:
compute_bias <- function(model_category_raster, geoid, baseline) {
  # Count pixels per cropland category in the model output
  # freq() returns a table of (value, count)
  freq_tbl <- terra::freq(model_category_raster)
  freq_tbl <- freq_tbl[freq_tbl$value %in% c(1L, 2L, 3L), ]

  code_to_name <- c("1" = "GM", "2" = "Tolerant", "3" = "Vulnerable")

  model_acres <- data.frame(
    Category = code_to_name[as.character(freq_tbl$value)],
    acres_cdl_model = freq_tbl$count * PIXEL_ACRES,
    stringsAsFactors = FALSE
  )

  # Join model acres with baseline for this county
  baseline_county <- baseline %>%
    filter(GEOID == geoid)

  result <- baseline_county %>%
    select(
      GEOID,
      Category,
      acres_cdl_baseline,
      acres_census,
      delta_acres_baseline,
      delta_pct_CDL,
      delta_pct_total
    ) %>%
    left_join(model_acres, by = "Category") %>%
    mutate(
      acres_cdl_model = ifelse(is.na(acres_cdl_model), 0, acres_cdl_model), # 0 acres if category disappeared

      # Bias after model:
      delta_acres_model = acres_cdl_model - acres_census,

      # Absolute improvement (in acres)
      # How many acres of bias were removed by the model
      improvement_acres = abs(delta_acres_baseline) - abs(delta_acres_model),

      # Weighted relative improvement:
      # 1st relative improvement, then weighted.
      # Relative bias reduction scaled by category's share of total CDL acres
      # Ensures large categories drive the county-level score
      relative_improvement = ifelse(
        delta_acres_baseline != 0,
        (abs(delta_acres_baseline) - abs(delta_acres_model)) /
          abs(delta_acres_baseline),
        NA_real_
      )
    )

  # Add CDL share weight per category
  # Based on the original CDL, not the model output
  total_cdl_baseline <- sum(result$acres_cdl_baseline, na.rm = TRUE)

  result <- result %>%
    mutate(
      cdl_share = acres_cdl_baseline / total_cdl_baseline,

      # Weighted improvement = relative_improvement × CDL share
      # Summing this across categories gives the county-level weighted score
      improvement_weighted = improvement_acres * cdl_share,
      #and to avoid dividing
      relative_improvement_weighted = relative_improvement * cdl_share
    )

  result
}

#Quality:
compute_quality <- function(stacked_raster, model_category_raster, geoid) {
  orig_cat <- values(stacked_raster[[1]])
  conf <- values(stacked_raster[[2]])
  model_cat <- values(model_category_raster)

  #Get boolean for original pixel, and reclassified.
  is_orig_cropland <- !is.na(orig_cat) & orig_cat %in% c(1, 2, 3)
  is_reclassified <- !is.na(orig_cat) &
    !is.na(model_cat) &
    model_cat != orig_cat

  #Get mean confidence for pixel reclassified and across all original cropland pixels.
  mean_conf_reclassified <- if (any(is_reclassified, na.rm = TRUE)) {
    mean(conf[is_reclassified], na.rm = TRUE)
  } else {
    NA_real_
  }
  mean_conf_all_cropland <- mean(conf[is_orig_cropland], na.rm = TRUE)

  #Get the quality ratio
  quality_ratio <- if (
    !is.na(mean_conf_reclassified) &
      !is.na(mean_conf_all_cropland) &
      mean_conf_all_cropland != 0
  ) {
    mean_conf_reclassified / mean_conf_all_cropland
  } else {
    NA_real_
  }

  #output
  data.frame(
    GEOID = geoid,
    n_reclassified = sum(is_reclassified, na.rm = TRUE),
    mean_conf_reclassified = mean_conf_reclassified,
    mean_conf_all_cropland = mean_conf_all_cropland,
    quality_ratio = quality_ratio,
    stringsAsFactors = FALSE
  )
}

# Helper: run measurements for one model and append to results

record_model <- function(
  model_raster,
  model_label,
  geoid,
  stacked,
  baseline,
  results_bias,
  results_quality
) {
  cat("  Model:", model_label, "\n")

  bias_row <- compute_bias(model_raster, geoid, baseline)
  quality_row <- compute_quality(stacked, model_raster, geoid)
  bias_row$model <- model_label
  quality_row$model <- model_label

  results_bias[[paste0(geoid, "_", model_label)]] <- bias_row
  results_quality[[paste0(geoid, "_", model_label)]] <- quality_row

  list(bias = results_bias, quality = results_quality)
}

# Main loop

results_bias <- list()
results_quality <- list()

for (i in seq_len(nrow(counties_selected))) {
  geoid <- counties_selected$GEOID[i]
  statefp <- counties_selected$STATEFP[i]
  path <- conf_stacked_path(geoid, statefp)

  if (!file.exists(path)) {
    cat("WARNING: missing raster for GEOID", geoid, "— skipping.\n")
    next
  }

  cat("Processing GEOID", geoid, "...\n")
  stacked <- rast(path)
  original_category <- stacked[[1]]

  # Model 1: MMU = 5, window = 3, neighbors = 8
  model_1 <- apply_mmu_full(
    original_category,
    mmu_acres = 5,
    neighbors = 8,
    window_size = 3
  )
  r <- record_model(
    model_1,
    "MMU_5ac_nb8_w3",
    geoid,
    stacked,
    baseline,
    results_bias,
    results_quality
  )
  results_bias <- r$bias
  results_quality <- r$quality

  # Model 2: MMU = 15, window = 3, neighbors = 8
  model_2 <- apply_mmu_full(
    original_category,
    mmu_acres = 15,
    neighbors = 8,
    window_size = 3
  )
  r <- record_model(
    model_2,
    "MMU_15ac_nb8_w3",
    geoid,
    stacked,
    baseline,
    results_bias,
    results_quality
  )
  results_bias <- r$bias
  results_quality <- r$quality

  # Model 3: MMU = 5, window = 9, neighbors = 8
  model_3 <- apply_mmu_full(
    original_category,
    mmu_acres = 5,
    neighbors = 8,
    window_size = 9
  )
  r <- record_model(
    model_3,
    "MMU_5ac_nb8_w9",
    geoid,
    stacked,
    baseline,
    results_bias,
    results_quality
  )
  results_bias <- r$bias
  results_quality <- r$quality

  # Model 4: MMU = 15, window = 9, neighbors = 8
  model_4 <- apply_mmu_full(
    original_category,
    mmu_acres = 15,
    neighbors = 8,
    window_size = 9
  )
  r <- record_model(
    model_4,
    "MMU_15ac_nb8_w9",
    geoid,
    stacked,
    baseline,
    results_bias,
    results_quality
  )
  results_bias <- r$bias
  results_quality <- r$quality

  # Model 5: spatial filter
  model_5 <- apply_spatfilter_full(
    original_category,
    window_size = 9,
    neighbors = 8
  )
  r <- record_model(
    model_5,
    "SpatFilter_9x9",
    geoid,
    stacked,
    baseline,
    results_bias,
    results_quality
  )
  results_bias <- r$bias
  results_quality <- r$quality
}

# Collect results

bias_out <- bind_rows(results_bias)
quality_out <- bind_rows(results_quality)

cat("\n── Bias results ──\n")
geoid_13277_table <- bias_out %>%
  filter(GEOID == "13277") %>%
  select(
    model,
    Category,
    delta_acres_baseline,
    delta_acres_model,
    delta_pct_CDL,
    delta_pct_total,
    improvement_acres,
    cdl_share,
    improvement_weighted,
    relative_improvement_weighted
  ) %>%
  as.data.frame()
print(geoid_13277_table)

#save .tex
stargazer(
  geoid_13277_table,
  type = "latex",
  summary = FALSE,
  rownames = FALSE,
  digits = 3,
  title = "Bias and improvement by model, GEOID 13277",
  out = "outputs/tables/geoid_13277_models.tex"
)


print(
  bias_out %>%
    filter(GEOID == "29155") %>%
    select(
      GEOID,
      model,
      Category,
      delta_acres_baseline,
      delta_acres_model,
      delta_pct_total,
      improvement_acres,
      improvement_weighted
    )
)

print(
  bias_out %>%
    filter(GEOID == "05093") %>%
    select(
      GEOID,
      model,
      Category,
      delta_acres_baseline,
      delta_acres_model,
      delta_pct_total,
      improvement_acres,
      improvement_weighted
    )
)

cat("\n── Quality results ──\n")
print(
  quality_out %>%
    select(
      GEOID,
      model,
      n_reclassified,
      mean_conf_reclassified,
      mean_conf_all_cropland,
      quality_ratio
    )
)

cat("\n── County-level summary ──\n")
bias_out %>%
  group_by(GEOID, model) %>%
  summarise(
    total_weighted_improvement = sum(improvement_weighted, na.rm = TRUE),
    total_improvement_acres = sum(improvement_acres, na.rm = TRUE),
    delta_baseline = sum(abs(delta_acres_baseline), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(GEOID, desc(total_weighted_improvement)) %>%
  print()
