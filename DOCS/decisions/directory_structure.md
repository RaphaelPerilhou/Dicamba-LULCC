# Directory Structure — Decision Log

## Overview

This document specifies the folder structure, file naming conventions, and
path function signatures used throughout the pipeline. The pipeline
operates at **county level** nested within states. All code must follow
these conventions exactly to ensure consistency between the three pipeline
stages and future HPC adaptation.

---

## Input Data Structure

Raw CDL rasters are clipped to county boundaries in `00_setup_and_clip.R`.
The clipped inputs are stored as:

```
data/
└── clipped/
    └── <State_Name>/
        └── <County_Name>/
            ├── CDL_2009_<County_Name>.tif
            ├── CDL_2010_<County_Name>.tif
            ├── ...
            └── CDL_2018_<County_Name>.tif
```

### Naming conventions
- State folders: state name with spaces replaced by underscores
  (e.g. `New_York`, `Rhode_Island`)
- County folders: county name with spaces replaced by underscores
  (e.g. `Jefferson_County`, `St_Lawrence_County`)
- File names: `CDL_<year>_<County_Name>.tif`

### `clipped_path()` signature (defined in `00_setup_and_clip.R` and `01_mask_and_classify.R`)

```r
clipped_path <- function(year, state, county) {
  state_s  <- gsub(" ", "_", state)
  county_s <- gsub(" ", "_", county)
  file.path("data/clipped", state_s, county_s,
            paste0("CDL_", year, "_", county_s, ".tif"))
}
```

---

## Output Data Structure

### Classified rasters

Output of `01_mask_and_classify.R`:

```
outputs/
└── classified/
    └── <State_Name>/
        └── <County_Name>/
            ├── Classified_2009_<County_Name>.tif
            ├── Classified_2010_<County_Name>.tif
            ├── ...
            └── Classified_2018_<County_Name>.tif
```

### Transition matrices

Output of `02_transition_matrix.R`:

```
outputs/
└── transitions/
    └── <State_Name>/
        └── <County_Name>/
            ├── Transition_2009_2010_<County_Name>.csv
            ├── Transition_2010_2011_<County_Name>.csv
            ├── ...
            └── Transition_2017_2018_<County_Name>.csv
```

Each `.csv` is a **5×5 named matrix** (not a long/panel data.frame) with
rows = category in year t and columns = category in year t+1. The five
categories are: NonCrop (0), GM (1), Tolerant (2), Vulnerable (3),
Unclassified (99).

---

## Scale

- 48 contiguous states
- ~3,000 counties total
- 10 years → 10 classified rasters per county → ~30,000 classified rasters
- 9 year-pair transitions per county → ~27,000 transition matrices

---

## Path Functions

Each script defines its own path functions at the top. They all follow the same
`(year, state, county)` signature and the same `gsub(" ", "_", ...)` convention.

### `classified_path()` (defined in `01_mask_and_classify.R` and `02_transition_matrix.R`)

```r
classified_path <- function(year, state, county) {
  state_s  <- gsub(" ", "_", state)
  county_s <- gsub(" ", "_", county)
  file.path("outputs/classified", state_s, county_s,
            paste0("Classified_", year, "_", county_s, ".tif"))
}
```

### `transition_path()` (defined in `02_transition_matrix.R`)

```r
transition_path <- function(year_from, year_to, state, county) {
  state_s  <- gsub(" ", "_", state)
  county_s <- gsub(" ", "_", county)
  file.path("outputs/transitions", state_s, county_s,
            paste0("TM_", year_from, year_to, "_", county_s, ".csv"))
}
```

---

## Transition Matrix Format

Matrices are saved as `.csv` with `write.csv(..., row.names = TRUE)` so
that the row labels (from-category) are preserved alongside column labels
(to-category). Example structure for one county, one year pair:

```
         NonCrop   GM  Tolerant  Vulnerable  Unclassified
NonCrop      ...  ...       ...         ...           ...
GM           ...  ...       ...         ...           ...
Tolerant     ...  ...       ...         ...           ...
Vulnerable   ...  ...       ...         ...           ...
Unclassified ...  ...       ...         ...           ...
```

---

## What Has Changed vs. the Original State-Level Pipeline

| Aspect | Original (state) | New (county) |
|--------|-----------------|--------------|
| Path function args | `(year, state)` | `(year, state, county)` |
| Main loop | over states | over states → counties |
| Output nesting | `classified/<state>/` | `classified/<state>/<county>/` |
| File naming | `Classified_<year>_<state>.tif` | `Classified_<year>_<county>.tif` |
| Transition naming | `TM_<y1><y2>_<state>.csv` | `TM_<y1><y2>_<county>.csv` |
| Union mask scope | per state | per county |

---

## Notes

- County boundaries are sourced from `tigris::counties()` with
  `year = 2016` to match the CDL study period.
- The `gsub(" ", "_", ...)` convention is applied consistently to both
  state and county names everywhere — in folder creation, file naming,
  and result list naming.
- For now all code runs locally. ANUBIS parallelisation will be added
  later; the directory structure does not need to change for that.
