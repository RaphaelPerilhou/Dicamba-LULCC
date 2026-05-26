# R — Analysis Pipeline

## Overview

Main pipeline for the Dicamba project. Scripts must be run in order.
To change scope, edit `TARGET_STATES` and `TARGET_YEARS` at the top of each script.

Parallelisation recommended for looking at multiple states and years. Replace `lapply` with `mclapply` when running the matrices. 

## Scripts

### `00_setup_and_clip.R`
- Creates directory structure for all 48 states
- Verifies CDL `.tif` files exist and checks CRS/resolution consistency across years
- Clips national CDL rasters to each state boundary (Census TIGER 2016)
- **Later: will also use Census Tiger to do the analysis at County level**. 

**Input**: `data/<year>_30m_cdls/<year>_30m_cdls.tif`
**Output**: `data/clipped/<state>/CDL_<year>_<state>.tif`

### `01_mask_and_classify.R`
- Builds an agricultural mask per year (FSA-defined crop codes)
- Combines into a union mask: pixel retained if agricultural in **any** year
- Classifies each pixel into 4 categories: NonCrop (0), GM (1), Tolerant (2), Vulnerable (3)

**Input**: `data/clipped/<state>/`
**Output**: `outputs/classified/<state>/Classified_<year>_<state>.tif`

### `02_transition_matrix.R`
- Computes pixel-level transition matrices between consecutive year pairs
- Uses `terra::crosstab()` on aligned classified rasters
- Exports one CSV per year pair + one combined CSV per state
- **Later: Will aggregate the matrices to national level**

**Input**: `outputs/classified/<state>/`
**Output**: `outputs/transitions/<state>/TM_<year_from><year_to>_<state>.csv`

## Data

CDL files must be downloaded manually from
[SARS](https://www.nass.usda.gov/Research_and_Science/Cropland/SARS1a.php)
and placed in the `data` folder before running the pipeline.
