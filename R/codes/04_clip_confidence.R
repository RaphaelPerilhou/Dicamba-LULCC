########
# I) Clip confidence raster to county boundaries and stack with classified raster.

# Confidence is clipped from the national CDL confidence raster using the
# same county polygon + touches=FALSE as in 00_setup_and_clip.R,
# guaranteeing pixel-perfect alignment with the classified raster.

# Run after 01_mask_and_classify.R.
#########
getwd()
rm(list = ls())

library(terra)
library(dplyr)
library(sf)

#Parameters

TARGET_YEAR     <- 2012
CONF_NAT_PATH   <- "data/confidence_NAT/CDL_conf_2012_national_aligned.tif"
CONF_OUTPUT_DIR <- "data/class_and_conf"

#Helpers

classified_path <- function(year, geoid, statefp) {
  file.path("data/classified", statefp, paste0("Classified_", year, "_", geoid, ".tif"))
}

conf_output_path <- function(year, geoid, statefp) {
  file.path(CONF_OUTPUT_DIR, statefp, paste0("Conf_stacked_", year, "_", geoid, ".tif"))
}

#Load data

counties_sf   <- readRDS("data/SF/counties_2016.rds")
county_lookup <- read.csv("data/county_lookup.csv", colClasses = "character")

cat("Loading national confidence raster...\n")
conf_nat <- rast(CONF_NAT_PATH)
cat("  Extent:", as.vector(ext(conf_nat)), "\n")
cat("  CRS:   ", crs(conf_nat, describe = TRUE)$name, "\n")

#loop over each county

tasks <- county_lookup %>% select(GEOID, STATEFP)
cat("Counties:", nrow(tasks), "\n")

for (i in seq_len(nrow(tasks))) {
  
  geoid   <- tasks$GEOID[i]
  statefp <- tasks$STATEFP[i]
  year    <- TARGET_YEAR
  
  #skip if output already exists
  out_path <- conf_output_path(year, geoid, statefp)
  if (file.exists(out_path)) next
  
  #skip if classified raster is missing
  classified_file <- classified_path(year, geoid, statefp)
  if (!file.exists(classified_file)) next
  
  #create output directory if it doesn't exist
  dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
  
  #load classified raster and clip confidence raster to county boundary
  classified  <- rast(classified_file)
  county_vect <- vect(counties_sf[counties_sf$GEOID == geoid, ])
  county_proj <- project(county_vect, crs(conf_nat))
  confidence  <- crop(conf_nat, county_proj) %>% mask(county_proj, touches = FALSE)
  
  if (!compareGeom(classified, confidence, stopOnError = FALSE)) {
    warning("Extent mismatch GEOID ", geoid, " -- skipping.")
    next
  }
  
  stacked        <- c(classified, confidence)
  names(stacked) <- c("category", "confidence")
  writeRaster(stacked, out_path, overwrite = TRUE, datatype = "INT1U")
  cat("Saved:", out_path, "\n")
}

cat("Done.")