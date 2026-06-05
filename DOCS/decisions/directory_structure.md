# Directory Structure — Decision Log

## Overview

This document specifies the folder structure, file naming conventions, and
path function signatures used throughout the pipeline. The pipeline
operates at **county level** identified by GEOID (5-digit Census FIPS code).
All code must follow these conventions exactly to ensure consistency between
the three pipeline stages and future HPC adaptation.

Counties are identified by `GEOID` (e.g. `51059` for Fairfax County VA,
`51600` for Fairfax City VA). This avoids all name-based collisions and
eliminates string manipulation. A human-readable reference table is written
once at the start of `00_setup_and_clip.R` to `data/county_lookup.csv`
(columns: `GEOID`, `STATEFP`, `COUNTYFP`, `NAME`, `LSAD`).

---

## Input Data Structure

Raw CDL rasters are clipped to county boundaries in `00_setup_and_clip.R`.
The clipped inputs are stored as:

```
data/
└── clipped/
    └── <STATEFP>/
        ├── CDL_2009_<GEOID>.tif
        ├── CDL_2010_<GEOID>.tif
        ├── ...
        └── CDL_2018_<GEOID>.tif
```

### Naming conventions
- State folders: 2-digit STATEFP (e.g. `51`, `36`)
- File names: `CDL_<year>_<GEOID>.tif`

### `clipped_path()` signature (defined in `00_setup_and_clip.R` and `01_mask_and_classify.R`)

```r
clipped_path <- function(year, geoid, statefp) {
  file.path("data/clipped", statefp,
            paste0("CDL_", year, "_", geoid, ".tif"))
}
```

---

## Output Data Structure

### Classified rasters

Output of `01_mask_and_classify.R`:

```
outputs/
└── classified/
    └── <STATEFP>/
        ├── Classified_2009_<GEOID>.tif
        ├── Classified_2010_<GEOID>.tif
        ├── ...
        └── Classified_2018_<GEOID>.tif
```

### Transition matrices

Output of `02_transition_matrix.R`:

```
outputs/
└── transitions/
    └── <STATEFP>/
        ├── TM_20092010_<GEOID>.csv
        ├── TM_20102011_<GEOID>.csv
        ├── ...
        └── TM_20172018_<GEOID>.csv
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

Each script defines its own path functions at the top. They all follow the
`(year, geoid, statefp)` signature (or `(year_from, year_to, geoid, statefp)`
for transitions). No string manipulation of names is performed anywhere.

### `classified_path()` (defined in `01_mask_and_classify.R` and `02_transition_matrix.R`)

```r
classified_path <- function(year, geoid, statefp) {
  file.path("outputs/classified", statefp,
            paste0("Classified_", year, "_", geoid, ".tif"))
}
```

### `transition_path()` (defined in `02_transition_matrix.R`)

```r
transition_path <- function(year_from, year_to, geoid, statefp) {
  file.path("outputs/transitions", statefp,
            paste0("TM_", year_from, year_to, "_", geoid, ".csv"))
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

## What Has Changed

| Aspect | State-level | County (name-based) | County (GEOID-based, current) |
|--------|-------------|---------------------|-------------------------------|
| Path function args | `(year, state)` | `(year, state, county)` | `(year, geoid, statefp)` |
| Folder nesting | `classified/<state>/` | `classified/<state>/<county>/` | `classified/<statefp>/` |
| File identifier | state name | county name | GEOID |
| String manipulation | `gsub(" ", "_", state)` | `gsub(" ", "_", county)` | none |
| Name collision risk | none | yes (e.g. Fairfax County vs Fairfax City) | none (GEOIDs are unique) |
| Union mask scope | per state | per county | per county |
| Human-readable reference | n/a | n/a | `data/county_lookup.csv` |

---

## Notes

- County boundaries are sourced from `tigris::counties()` with
  `year = 2016` to match the CDL study period, pre-saved as
  `data/SF/counties_2016.rds`.
- `GEOID` is the 5-digit Census FIPS code: `STATEFP` (2 digits) +
  `COUNTYFP` (3 digits). It uniquely identifies every county and
  independent city in the US.
- `data/county_lookup.csv` is written by `00_setup_and_clip.R` and is
  the authoritative reference for mapping GEOIDs back to human-readable
  names. It is never used in path construction.
