# GEE — Google Earth Engine Scripts

## Overview

This folder contains all Google Earth Engine (JavaScript) scripts used for
spatial data processing. Scripts are numbered in the order they should be run (but they should be able to run independtly).
Outputs are exported as CSV files to Google Drive and then stored in
`GEE/outputs/` in this repository.

---

## Scripts

### `01_Dicamba_ToFrom_SoyCot.js`

**Purpose**: Detects pixel-level land-use changes to and from soybean/cotton
across US counties, from 2009 to 2018.

**Method**:
1. **Agricultural mask** — filters out non-agricultural pixels using the CDL
   `cultivated` band (post-2012) or a manual crop code list (pre-2013, as the
   `cultivated` band did not exist before 2013)
2. **Annual CDL layers** — loads one masked cropland image per year (2009–2018)
3. **Change detection** — for each consecutive year pair, computes two binary
   pixel-level images:
   - `changeTo`: pixel was NOT soy/cotton in year N, IS soy/cotton in year N+1
   - `changeFrom`: pixel WAS soy/cotton in year N, is NOT soy/cotton in year N+1
4. **County aggregation** — sums changed pixels per county using
   `reduceRegions()` at 30m scale
5. **Export** — exports one CSV per year-pair and direction to Google Drive

**Inputs**:
- `USDA/NASS/CDL/{year}` — Cropland Data Layer, years 2009–2018
- `TIGER/2016/Counties` — US county boundaries

**Outputs** (in `GEE/outputs/`):

| Folder | Files | Description |
|---|---|---|
| `01_FromSoyCot/` | `changesByCounty{YYYYYYYY}_fromSoyCot.csv` | Pixels leaving soy/cotton |
| `01_ToSoyCot/` | `changesByCounty{YYYYYYYY}_toSoyCot.csv` | Pixels entering soy/cotton |

**Target crop CDL codes**:

| Code | Crop |
|---|---|
| 2 | Cotton |
| 5 | Soybean |
| 26 | Dbl Crop WinWht/Soybeans |
| 232 | Dbl Crop Lettuce/Cotton |
| 238 | Dbl Crop WinWht/Cotton |
| 239 | Dbl Crop Soybeans/Cotton |
| 240 | Dbl Crop Soybeans/Oats |
| 241 | Dbl Crop Corn/Soybeans |
| 254 | Dbl Crop Barley/Soybeans |

---

### `02_CropClassification.js` *(coming soon)*

**Purpose**: Classifies all agricultural pixels into three categories per year:
- **GM-enabled** — soybean and cotton (Dicamba-tolerant, commercially adopted)
- **Tolerant** — cereals (wheat, corn, barley, etc.)
- **Vulnerable** — other crops sensitive to Dicamba drift (e.g. tomatoes)

**Outputs** (in `GEE/outputs/`):
- `02_GMenabled/`
- `02_Tolerant/`
- `02_Vulnerable/`

---

### `03_Calibration.js` *(coming soon)*

**Purpose**: Applies calibration and bias adjustment to the change detection
outputs from script 01 and classification outputs from script 02.

**Outputs** (in `GEE/outputs/`):
- `03_Calibrated/`

---

## Notes

- Before 2013, the CDL `cultivated` band does not exist. Script 01 handles this
  by using a manually defined list of crop codes instead.
- All exports use a 30m scale matching the native CDL resolution.
- County-level aggregation uses `ee.Reducer.sum()` — each unit represents one
  30m pixel that changed land use.
