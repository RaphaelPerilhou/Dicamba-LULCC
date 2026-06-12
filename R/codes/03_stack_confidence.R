##############################################################################
# 03_stack_confidence.R
# Stack classified raster with GEE-exported confidence band for each county.
# Confidence is re-clipped using the same county polygon + touches=FALSE as
# in 00_setup_and_clip.R, guaranteeing pixel-perfect alignment.
#
# Run after 01_mask_and_classify.R and Export_CDL_Confidence.js
##############################################################################

#setwd("/users/rperilhou/RA_Dicamba/")
rm(list = ls())

library(terra)
library(dplyr)

# ── Parameters ────────────────────────────────────────────────────────────────

VALIDATION_GEOIDS <- c("17019", "19169")   # Champaign IL, Story IA
VALIDATION_YEAR   <- 2012
CONF_INPUT_DIR    <- "data/confidence_bands"
CONF_OUTPUT_DIR   <- "data/class_and_conf"

# ── Helpers ───────────────────────────────────────────────────────────────────

classified_path <- function(year, geoid, statefp) {
  file.path("data/classified", statefp, paste0("Classified_", year, "_", geoid, ".tif"))
}
conf_input_path <- function(year, geoid) {
  file.path(CONF_INPUT_DIR, paste0("CDL_conf_", year, "_", geoid, ".tif"))
}
conf_output_path <- function(year, geoid, statefp) {
  file.path(CONF_OUTPUT_DIR, statefp, paste0("Conf_stacked_", year, "_", geoid, ".tif"))
}

counties_sf   <- readRDS("data/SF/counties_2016.rds")
county_lookup <- read.csv("data/county_lookup.csv", colClasses = "character")

# ── Main loop ─────────────────────────────────────────────────────────────────

for (geoid in VALIDATION_GEOIDS) {
  
  statefp <- county_lookup %>% filter(GEOID == geoid) %>% pull(STATEFP)
  year    <- VALIDATION_YEAR
  
  cat("\nGEOID:", geoid, "| Year:", year, "\n")
  
  classified <- rast(classified_path(year, geoid, statefp))
  confidence <- rast(conf_input_path(year, geoid))
  cat("the extent of classified:", as.vector(ext(classified)), "\n")
  cat("the extent of confidence:", as.vector(ext(confidence)), "\n")
  
  # Re-clip confidence with same polygon + touches=FALSE as 00_setup_and_clip.R
  # This removes the 1-pixel border GEE adds during export, guaranteeing alignment
  county_vect <- counties_sf %>% filter(GEOID == geoid) %>% vect()
  county_proj <- project(county_vect, crs(confidence))
  confidence  <- crop(confidence, county_proj) %>% mask(county_proj, touches = FALSE)
  
  cat("  compareGeom:", compareGeom(classified, confidence, stopOnError = FALSE), "\n")
  
  stacked        <- c(classified, confidence)
  names(stacked) <- c("category", "confidence")
  
  dir.create(dirname(conf_output_path(year, geoid, statefp)), recursive = TRUE, showWarnings = FALSE)
  writeRaster(stacked, conf_output_path(year, geoid, statefp), overwrite = TRUE, datatype = "INT1U")
  cat("  Saved:", conf_output_path(year, geoid, statefp), "\n")
}


cat("\nDone.\n")

