##############################################################################
# 01_mask_and_classify.R
# Step 1: Build agricultural mask per year
# Step 2: Build union mask across all study years
# Step 3: Apply union mask to CDL layers
# Step 4: Classify pixels into {0=NonCrop, 1=GM, 2=Tolerant, 3=Vulnerable}
#
# Inputs:  data/clipped/<state>/CDL_<year>_<state>.tif
# Outputs: outputs/classified/<state>/Classified_<year>_<state>.tif
#
# Replicates GEE script 02 logic exactly.
# To scale up: change TARGET_STATES and TARGET_YEARS only.
##############################################################################

rm(list = ls())

library(terra)
library(tigris)
library(dplyr)

# CONFIGURATION

cat("Loading state boundaries (from Census TIGER 2016)")
states_sf <- states(year = 2016, cb = TRUE)

# All 48 contiguous states
contiguous_states <- states_sf %>%
  filter(!STATEFP %in% c("02", "15",  # Alaska, Hawaii
                         "60", "66", "69", "72", "78")) %>%  # territories
  pull(NAME) %>%
  sort()

cat("Contiguous states available:", length(contiguous_states), "\n")

# Here define states and period of interest.
#TARGET_STATES <- c("Rhode Island", "Alabama")
TARGET_STATES <- c("Alabama")# later: contiguous_states (all 48)
TARGET_YEARS  <- c(2009:2011)    # later: 2009:2018

# File paths

clipped_path <- function(year, state) {
  paste0("data/clipped/", state, "/CDL_", year, "_",
         gsub(" ", "_", state), ".tif")
}

classified_path <- function(year, state) {
  paste0("outputs/classified/", state, "/Classified_", year, "_",
         gsub(" ", "_", state), ".tif")
}

# 1/ AGRICULTURAL MASK CODES
# Agricultural codes 
# Matches our GEE makeMask function

ag_codes <- c(
  # CROPS 1-20
  1,2,3,4,5,6,10,11,12,13,14,
  # GRAINS, HAY, SEEDS 21-40
  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  # CROPS 41-60
  41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,
  # NON-CROP 61 (Fallow: retained as actively managed agricultural land)
  61,
  # CROPS 66-80
  66,67,68,69,70,71,72,74,75,76,77,
  # Aquaculture
  92,
  # CROPS 200-255
  204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,
  220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,
  236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,254
)

# 2/ CLASSIFICATION TABLE
# Priority rule: GM (1) > Tolerant (2) > Vulnerable (3) > NonCrop (0)
# Matches our GEE classifyPixel function
# Format: c(from_crop_code, to_category_code)
# ─────────────────────────────────────────────────────────────────────────────

reclass_table <- rbind(
  # 1) GM-ENABLED
  c(2,   1),  # Cotton
  c(5,   1),  # Soybeans
  c(26,  1),  # Dbl Crop WinWht/Soybeans    [GM > Tolerant]
  c(232, 1),  # Dbl Crop Lettuce/Cotton      [GM > Vulnerable]
  c(238, 1),  # Dbl Crop WinWht/Cotton       [GM > Tolerant]
  c(239, 1),  # Dbl Crop Soybeans/Cotton     [GM + GM]
  c(240, 1),  # Dbl Crop Soybeans/Oats       [GM > Tolerant]
  c(241, 1),  # Dbl Crop Corn/Soybeans       [GM > Tolerant]
  c(254, 1),  # Dbl Crop Barley/Soybeans     [GM > Tolerant]
  # 2) TOLERANT 
  c(1,   2),  # Corn
  c(3,   2),  # Rice
  c(4,   2),  # Sorghum
  c(21,  2),  # Barley
  c(22,  2),  # Durum Wheat
  c(23,  2),  # Spring Wheat
  c(24,  2),  # Winter Wheat
  c(25,  2),  # Other Small Grains
  c(27,  2),  # Rye
  c(28,  2),  # Oats
  c(29,  2),  # Millet
  c(30,  2),  # Speltz
  c(205, 2),  # Triticale
  c(225, 2),  # Dbl Crop WinWht/Corn
  c(226, 2),  # Dbl Crop Oats/Corn
  c(228, 2),  # Dbl Crop Triticale/Corn
  c(230, 2),  # Dbl Crop Lettuce/Durum Wht   [Tolerant > Vulnerable]
  c(233, 2),  # Dbl Crop Lettuce/Barley      [Tolerant > Vulnerable]
  c(234, 2),  # Dbl Crop Durum Wht/Sorghum
  c(235, 2),  # Dbl Crop Barley/Sorghum
  c(236, 2),  # Dbl Crop WinWht/Sorghum
  c(237, 2),  # Dbl Crop Barley/Corn
  # 3) VULNERABLE
  c(6,   3),  # Sunflower
  c(10,  3),  # Peanuts
  c(11,  3),  # Tobacco
  c(12,  3),  # Sweet Corn
  c(13,  3),  # Pop or Orn Corn
  c(14,  3),  # Mint
  c(31,  3),  # Canola
  c(32,  3),  # Flaxseed
  c(33,  3),  # Safflower
  c(34,  3),  # Rape Seed
  c(35,  3),  # Mustard
  c(36,  3),  # Alfalfa
  c(37,  3),  # Other Hay/Non Alfalfa
  c(38,  3),  # Camelina
  c(39,  3),  # Buckwheat
  c(41,  3),  # Sugarbeets
  c(42,  3),  # Dry Beans
  c(43,  3),  # Potatoes
  c(44,  3),  # Other Crops
  c(45,  3),  # Sugarcane
  c(46,  3),  # Sweet Potatoes
  c(47,  3),  # Misc Vegs & Fruits
  c(48,  3),  # Watermelons
  c(49,  3),  # Onions
  c(50,  3),  # Cucumbers
  c(51,  3),  # Chick Peas
  c(52,  3),  # Lentils
  c(53,  3),  # Peas
  c(54,  3),  # Tomatoes
  c(55,  3),  # Caneberries
  c(56,  3),  # Hops
  c(57,  3),  # Herbs
  c(58,  3),  # Clover/Wildflowers
  c(59,  3),  # Sod/Grass Seed
  c(60,  3),  # Switchgrass
  c(66,  3),  # Cherries
  c(67,  3),  # Peaches
  c(68,  3),  # Apples
  c(69,  3),  # Grapes
  c(70,  3),  # Christmas Trees
  c(71,  3),  # Other Tree Crops
  c(72,  3),  # Citrus
  c(74,  3),  # Pecans
  c(75,  3),  # Almonds
  c(76,  3),  # Walnuts
  c(77,  3),  # Pears
  c(92,  3),  # Aquaculture
  c(204, 3),  # Pistachios
  c(206, 3),  # Carrots
  c(207, 3),  # Asparagus
  c(208, 3),  # Garlic
  c(209, 3),  # Cantaloupes
  c(210, 3),  # Prunes
  c(211, 3),  # Olives
  c(212, 3),  # Oranges
  c(213, 3),  # Honeydew Melons
  c(214, 3),  # Broccoli
  c(215, 3),  # Avocados
  c(216, 3),  # Peppers
  c(217, 3),  # Pomegranates
  c(218, 3),  # Nectarines
  c(219, 3),  # Greens
  c(220, 3),  # Plums
  c(221, 3),  # Strawberries
  c(222, 3),  # Squash
  c(223, 3),  # Apricots
  c(224, 3),  # Vetch
  c(227, 3),  # Lettuce
  c(229, 3),  # Pumpkins
  c(231, 3),  # Dbl Crop Lettuce/Cantaloupe
  c(242, 3),  # Blueberries
  c(243, 3),  # Cabbage
  c(244, 3),  # Cauliflower
  c(245, 3),  # Celery
  c(246, 3),  # Radishes
  c(247, 3),  # Turnips
  c(248, 3),  # Eggplants
  c(249, 3),  # Gourds
  c(250, 3),  # Cranberries
  # 0) NON-CROP 
  # Fallow explicitly assigned 0
  # All other codes not in mask fall to 0 via `others = 0`
  c(61,  0)   # Fallow/Idle Cropland
)

# 3/ CORE FUNCTIONS

# 3.1) Build agricultural mask for one year
make_mask <- function(year, state) {
  cdl <- rast(clipped_path(year, state))
  ifel(cdl %in% ag_codes, 1, NA)
}

# 3.2) Build union mask across all years for one state
# Pixel = 1 if EVER agricultural in any year
make_union_mask <- function(years, state) {
  cat("  Building union mask across", length(years), "years\n")
  masks <- lapply(years, function(y) make_mask(y, state))
  
  # Start with first year mask, OR with each subsequent year
  union <- masks[[1]]
  for (i in seq_along(masks)[-1]) {
    union <- ifel(!is.na(union) | !is.na(masks[[i]]), 1, NA)
  }
  
  n_ag_pixels <- sum(values(union) == 1, na.rm = TRUE)
  cat("  Union mask: ", n_ag_pixels, "agricultural pixels retained\n")
  return(union)
}

# Classify one year using union mask
classify_year <- function(year, state, union_mask) {
  
  out_path <- classified_path(year, state)
  
  if (file.exists(out_path)) {
    cat("  Already exists, skipping:", out_path, "\n")
    return(out_path)
  }
  
  # Load clipped CDL and apply union mask
  cdl    <- rast(clipped_path(year, state))
  masked <- mask(cdl, union_mask)
  
  # Classify: others = NA means unrecognized codes get NA first
  classified <- classify(masked, reclass_table, others = NA)
  
  # Pixels inside union mask but not assigned 1/2/3 → NonCrop (0)
  # Pixels outside union mask → stay NA (excluded entirely)
  classified <- ifel(
    !is.na(union_mask) & is.na(classified), 0,  # in mask, unclassified => 0
    classified                                    # everything else unchanged
  )
  
  classified <- as.int(classified)
  values_classified <- values(classified) #avoiding reading it multiple times. 
  
  # Count pixels per category (only within union mask)
  cat("  Category counts (union mask pixels only):\n")
  for (cat_val in 0:3) {
    label <- c("NonCrop", "GM", "Tolerant", "Vulnerable")[cat_val + 1]
    n <- sum(values_classified == cat_val, na.rm = TRUE)
    cat("   ", label, "(", cat_val, "):", n, "pixels\n")
  }
  
  # Total should equal union mask size
  total <- sum(!is.na(values_classified))
  cat("  Total classified pixels:", total,
      "(union mask has", sum(values(union_mask) == 1, na.rm = TRUE), ")\n")
  
  writeRaster(classified, out_path, overwrite = TRUE, datatype = "INT1U")
  cat("  Saved:", out_path, "\n")
  
  return(out_path)
}

# Full pipeline for one state
run_state <- function(state, years) {
  cat("####################################\n")
  cat("State:", state, "| Years:", min(years), "-", max(years), "\n")
  cat("####################################\n")
  
  # Check all clipped files exist
  missing <- years[!file.exists(sapply(years, clipped_path, state = state))]
  if (length(missing) > 0) {
    stop("Missing clipped files for ", state, " years: ",
         paste(missing, collapse = ", "),
         "\nRun 00_setup_and_clip.R first.")
  }
  
  # Build union mask once for all years
  union_mask <- make_union_mask(years, state)
  
  # Classify each year
  paths <- lapply(years, function(y) {
    cat("    - Year:", y, "\n")
    classify_year(y, state, union_mask)
  })
  
  cat("State", state, "complete.\n")
  return(paths)
}

# 4. RUN
# For parallelisation on TSE, replace lapply with mclapply:
#   library(parallel)
#   mclapply(TARGET_STATES, run_state, years = TARGET_YEARS, mc.cores = N)

cat("States:", paste(TARGET_STATES, collapse = ", "), "\n")
cat("Years: ", paste(TARGET_YEARS,  collapse = ", "), "\n")

results <- lapply(TARGET_STATES, run_state, years = TARGET_YEARS)

cat("ALL DONE: Classified files saved in outputs/classified/")

