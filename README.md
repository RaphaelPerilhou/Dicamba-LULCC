# Dicamba Research — Crop Change Analysis

## Project Overview

This repository contains all scripts, outputs, and data for a research project
investigating crop land-use changes in the United States, with a focus on the
adoption of Dicamba-tolerant crops (soybean and cotton) and their potential
impact on vulnerable crops (e.g. tomatoes).

The analysis uses the **USDA NASS Cropland Data Layer (CDL)** from 2009 to 2018,
aggregated at the **US county level** (TIGER/2016), and is carried out in two
main tools: **Google Earth Engine (GEE)** for spatial processing and **R** for
statistical analysis and visualization.

---

## Repository Structure

```
your-repo/
│
├── README.md                        
│
├── GEE/                             Google Earth Engine
│   ├── codes/                       GEE JavaScript scripts
│   └── outputs/                     Raw CSV exports from GEE
│
├── R/                               R analysis
│   ├── codes/                       R scripts
│   └── outputs/
│       ├── figures/                 plots and maps
│       └── tables/                  summary tables
│
└── DATA/
    ├── raw/                         Input data fed into R (from GEE or other sources)
    └── processed/                   Cleaned and transformed data from R
```

---

## Numbering Convention

Scripts and folders are numbered consistently across GEE, R, and DATA so it is
always clear which data came from which script:

| # | Topic |
|---|---|
| 01 | Soybean / Cotton change detection (GM-enabled crops) |
| 02 | Three-way crop classification (GM-enabled / Tolerant / Vulnerable) |
| 03 | Calibration and bias adjustment |

Where two versions of a script exist (e.g. `01` and `01bis`), the `bis` version
is the methodologically improved one and should be preferred for analysis.
See the GEE README for details.

---

## Data Source

- **Dataset**: USDA NASS Cropland Data Layer (CDL)
- **Years**: 2009–2018
- **Resolution**: 30m pixel
- **Geography**: US Counties (TIGER/2016)
- **Access**: via Google Earth Engine (`USDA/NASS/CDL`)

---

## Crop Categories

| Category | Crops | CDL Codes |
|---|---|---|
| GM-enabled | Soybean, Cotton + double crops | 2, 5, 26, 232, 238, 239, 240, 241, 254 |
| Tolerant | Cereals (wheat, corn, barley...) | TBD in script 02 |
| Vulnerable | Tomatoes and other sensitive crops | TBD in script 02 |

---

## Status

- [x] GEE Script 01 : Agricultural mask + Soy/Cotton change detection at county level (2009–2018), yearly mask
- [x] GEE Script 01bis : Same as 01 with union mask (methodological improvement, preferred version)
- [ ] GEE Script 02 : Three-way crop classification
- [ ] GEE Script 03 : Calibration and bias adjustment
- [ ] R Script 01 : Data cleaning
- [ ] R Script 02 : Statistical analysis
- [ ] R Script 03 : Figures and tables

---

## Author

Raphaël Perilhou
