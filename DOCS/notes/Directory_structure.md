# Directory Structure — Decision Log

## Overview

This document specifies the folder structure, file naming conventions, and
`path_fn` signatures used throughout the `cdltools` pipeline. The pipeline
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

### `path_fn` signature (input)

```r
path_fn <- function(year, state, county) {
  file.path(
    "data", "clipped",
    gsub(" ", "_", state),
    gsub(" ", "_", county),
    paste0("CDL_", year, "_", gsub(" ", "_", county), ".tif")
  )
}
```

> **Note**: `path_fn` takes three arguments at county level: `year`, `state`,
> and `county`. This is a breaking change from the original state-level
> pipeline where `path_fn(year, state)` took only two arguments. All
> internal `cdltools` functions that accept `path_fn` must be updated
> accordingly.

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

## Internal Path Helpers (`R/utils.R`)

The internal helpers `.make_output_path()` and `.make_transition_path()`
must be updated to accept a `county` argument and nest county within state:

```r
.make_output_path <- function(output_dir, state, county, year) {
  county_dir <- file.path(
    output_dir, "classified",
    gsub(" ", "_", state),
    gsub(" ", "_", county)
  )
  if (!dir.exists(county_dir)) dir.create(county_dir, recursive = TRUE)
  file.path(county_dir,
            paste0("Classified_", year, "_",
                   gsub(" ", "_", county), ".tif"))
}

.make_transition_path <- function(output_dir, state, county,
                                  year_from, year_to) {
  county_dir <- file.path(
    output_dir, "transitions",
    gsub(" ", "_", state),
    gsub(" ", "_", county)
  )
  if (!dir.exists(county_dir)) dir.create(county_dir, recursive = TRUE)
  file.path(county_dir,
            paste0("Transition_", year_from, "_", year_to, "_",
                   gsub(" ", "_", county), ".csv"))
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
| `path_fn` args | `(year, state)` | `(year, state, county)` |
| Main loop | over states | over states → counties |
| Output nesting | `classified/<state>/` | `classified/<state>/<county>/` |
| File naming | `Classified_<year>_<state>.tif` | `Classified_<year>_<county>.tif` |
| Transition naming | `Transition_<y1>_<y2>_<state>.csv` | `Transition_<y1>_<y2>_<county>.csv` |
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
