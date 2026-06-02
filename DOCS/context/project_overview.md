# Project Overview — Dicamba Herbicide Exposure Study

## Research Context

This project is conducted at the **Toulouse School of Economics (TSE)** as part
of a research assistantship. The goal is to study land-use transitions in US
cropland in the context of Dicamba herbicide exposure, using the USDA Cropland
Data Layer (CDL) as the primary data source.

The core question is: how do agricultural fields transition between
Dicamba-relevant crop categories (GM-enabled, Tolerant, Vulnerable, NonCrop)
across years, and what does this imply for herbicide drift exposure?

---

## Study Parameters

- **Geography**: All 48 contiguous US states, all counties within each state
- **Period**: 2009–2018 (10 years, 9 consecutive year-pair transitions)
- **Spatial unit of analysis**: County
- **Data source**: USDA NASS Cropland Data Layer (CDL), 30m resolution

---

## Crop Classification

Four categories are used. Full details and rationale are in
`docs/decisions/classification.md`.

| Code | Label      |
|------|------------|
| 0    | NonCrop    |
| 1    | GM-enabled |
| 2    | Tolerant   |
| 3    | Vulnerable |
| 99   | Unclassified (in mask, CDL code not mapped) |
| NA   | Outside union mask |

---

## Pipeline Overview

The pipeline has three stages, implemented as an R package (`cdltools`):

### Stage 1 — Setup and Clip (`00_setup_and_clip.R`)
- Downloads or locates raw CDL rasters (national, 30m)
- Clips them to county boundaries using `tigris` shapefiles
- Outputs one `.tif` per county per year

### Stage 2 — Mask and Classify (`01_mask_and_classify.R`)
- Builds a **union agricultural mask** per county across all 10 years
  (a pixel is retained if it was agricultural in *any* year)
- Classifies each pixel into {0, 1, 2, 3, 99} per year using
  `default_cdl_categories()`
- Outputs one classified `.tif` per county per year

### Stage 3 — Transition Matrices (`02_transition_matrix.R`)
- For each county and each consecutive year pair (2009→2010, ..., 2017→2018),
  computes a **5×5 transition matrix** (rows = category in year t,
  columns = category in year t+1, including 99)
- Output is a **named matrix** (not a panel/long format) — one `.csv` file
  per county per year pair
- 9 transition matrices per county × ~3,000 counties = ~27,000 output files

---

## Output Directory Structure

See `docs/decisions/directory_structure.md` for the full specification.

```
outputs/
├── classified/
│   └── <state>/
│       └── <county>/
│           ├── Classified_2009_<county>.tif
│           ├── ...
│           └── Classified_2018_<county>.tif
└── transitions/
    └── <state>/
        └── <county>/
            ├── Transition_2009_2010_<county>.csv
            ├── ...
            └── Transition_2017_2018_<county>.csv
```

---

## Repository Structure

```
project-root/
├── R/                        # cdltools package source
├── GEE/                      # Google Earth Engine scripts
├── docs/
│   ├── context/
│   │   └── project_overview.md     ← this file
│   └── decisions/
│       ├── classification.md       ← CDL category decisions
│       └── directory_structure.md  ← folder/naming conventions
├── tests/                    # testthat unit tests
└── vignettes/                # getting started guide
```

---

## Tooling

| Tool | Role |
|------|------|
| R (`cdltools`) | Main pipeline — mask, classify, transition matrices |
| `terra` | Raster I/O and operations |
| `tigris` | County/state boundary shapefiles |
| Google Earth Engine (GEE) | Independent validation for selected states/years |
| ANUBIS (HPC cluster) | Future: scale to full 48-state run. Not yet configured — current code runs locally. |

---

## Current Status

The pipeline is currently written to run **locally** on a personal machine.
HPC adaptation for ANUBIS will be done in a later phase. When that time comes,
parallelisation will be implemented in Stage 3 (`R/codes/02_transition_matrix.R`,
not yet written); the planned approach is `parallelize_by = "state"`.

---

## Key Constraints for Code Development

- **Do not assume HPC/SLURM configuration** — write for local execution
- **County is the unit of analysis**, not state — all path functions,
  directory helpers, and output naming must use county + state
- **Transition matrices must be saved as named matrices** (5×5 `.csv`),
  not long/panel format
- **Classification must match `docs/decisions/classification.md` exactly**
  — especially codes 12, 13, 45 (Tolerant), and the 99 catch
- **`datatype = "INT1U"`** for all classified raster outputs (accommodates
  values 0–99)
- Before any code change, read `docs/decisions/` to understand why things
  are structured the way they are
