# R — Analysis Pipeline

## Overview

Main pipeline for the Dicamba project. Scripts must be run in order.
To change scope, edit `TARGET_STATES`, `TARGET_YEARS`, or `TARGET_YEAR` at the top of each script.

Parallelisation recommended for looking at multiple states and years. Replace `lapply` with `mclapply` when running the matrices.

## Scripts

### `000_get_SF_files.R`
Downloads Census TIGER 2016 shapefiles (states and counties) via the `tigris` package and saves them as `.rds` files. Must be run once before any other script that relies on county/state polygons.

**Output**: `data/SF/states_2016.rds`, `data/SF/counties_2016.rds`

---

### `00_setup_and_clip.R`
- Creates directory structure for all 48 states
- Verifies CDL `.tif` files exist and checks CRS/resolution consistency across years
- Clips national CDL rasters to each county boundary (Census TIGER 2016, `touches=FALSE`)
- **Later: will also use Census Tiger to do the analysis at County level**

**Input**: `data/<year>_30m_cdls/<year>_30m_cdls.tif`
**Output**: `data/clipped/<statefp>/CDL_<year>_<geoid>.tif`

---

### `01_mask_and_classify.R`
- Builds an agricultural mask per year (FSA-defined crop codes)
- Combines into a union mask: pixel retained if agricultural in **any** year
- Classifies each pixel into 4 categories: NonCrop (0), GM (1), Tolerant (2), Vulnerable (3)

**Input**: `data/clipped/<statefp>/`
**Output**: `data/classified/<statefp>/Classified_<year>_<geoid>.tif`

---

### `02_transition_matrix.R`
- Computes pixel-level transition matrices between consecutive year pairs
- Uses `terra::crosstab()` on aligned classified rasters
- Exports one CSV per year pair + one combined CSV per state
- **Later: Will aggregate the matrices to national level**

**Input**: `data/classified/<statefp>/`
**Output**: `outputs/transitions/<statefp>/TM_<year_from><year_to>_<statefp>.csv`

---

### `03_confidence_NAT.R`
Merges GEE-exported confidence tiles (VRT) into a single national raster, then aligns it to the national CDL extent by cropping. Run once per year before `05_clip_confidence.R`.

**Input**: `data/confidence_NAT/*.tif`, `data/<year>_30m_cdls/<year>_30m_cdls.tif`
**Output**: `data/confidence_NAT/CDL_conf_<year>_national_merged.tif`, `data/confidence_NAT/CDL_conf_<year>_national_aligned.tif`

---

### `04_clip_confidence.R`
Clips the aligned national confidence raster to every county in `county_lookup.csv` and stacks it with the corresponding classified raster. Skips counties where output already exists or classified raster is missing.

**Input**: `data/confidence_NAT/CDL_conf_<year>_national_aligned.tif`, `data/classified/<statefp>/Classified_<year>_<geoid>.tif`, `data/SF/counties_2016.rds`, `data/county_lookup.csv`
**Output**: `data/class_and_conf/<statefp>/Conf_stacked_<year>_<geoid>.tif`

---

### `05_availability_census.R`
Checks that all CDL-mapped Census commodities are available at the county level in the 2012 Census of Agriculture (`qs.census2012.txt`). Resolves ambiguous `short_desc` fields (e.g. subcategories to sum such as CORN GRAIN + CORN SILAGE), and exports the final area dataset and `short_desc` mapping used downstream. Also documents counties missing from the Census (independent cities, DC) and logs them for exclusion.

**Input**: `data/qs.census2012.txt`, `data/metadata/CDL_CENSUS_MAP.xlsx`, `data/county_lookup.csv`, `data/SF/states_2016.rds`
**Output**: `outputs/county_census_check/census_stats_availability.csv`, `data/metadata/census_shortdesc_map.csv`, `data/CENSUS/census_area_2012.csv`, `data/metadata/missing_geoid_census.csv`

---

### `06_census_acres.R`
Aggregates Census of Agriculture area data to the CDL category level (GM / Tolerant / Vulnerable) per county. Handles suppressed values `(D)` / `(Z)` by setting them to zero (logged separately). Joins the CDL-to-Census commodity mapping and sums subcategory acres.

**Input**: `data/CENSUS/census_area_2012.csv`, `data/metadata/census_shortdesc_map.csv`, `data/metadata/CDL_CENSUS_MAP.xlsx`, `data/county_lookup.csv`
**Output**: `outputs/commodity_census_acres_2012.csv`, `outputs/category_census_acres_2012.csv`, `outputs/census_suppressed_log.csv`

---

### `07_bias_measure.R`
Computes baseline bias between CDL pixel-derived acres and Census of Agriculture acres, by category and county (2012). Produces `delta_acres`, `delta_pct_census`, and `delta_pct_CDL` metrics. Counties missing from the Census are excluded. This baseline is the denominator for measuring model improvement after reclassification.

**Input**: `outputs/category_census_acres_2012.csv`, `outputs/classification_summary.csv`, `data/metadata/missing_geoid_census.csv`
**Output**: `outputs/baseline_bias.csv`

---

### `08_confidence_baseline.R`
Computes baseline CDL confidence quality indices at the county and category level from the stacked rasters produced by `05_clip_confidence.R`. Outputs per-county, per-category mean confidence scores (`mean_conf_category`, `mean_conf_county`) that serve as denominators when evaluating reclassification models. Joins with bias metrics to produce a single baseline measures file.

**Input**: `data/class_and_conf/<statefp>/Conf_stacked_<year>_<geoid>.tif`, `data/county_lookup.csv`, `data/metadata/missing_geoid_census.csv`, `outputs/baseline_bias.csv`
**Output**: `outputs/baseline_measures.csv`

---

## Data

CDL files must be downloaded manually from
[SARS](https://www.nass.usda.gov/Research_and_Science/Cropland/SARS1a.php)
and placed in the `data` folder before running the pipeline.

The 2012 Census of Agriculture quick stats file (`qs.census2012.txt`) must be downloaded from USDA NASS and placed in `data/`.
