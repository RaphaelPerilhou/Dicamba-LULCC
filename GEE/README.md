# GEE — Google Earth Engine Scripts

## Overview

This folder contains all Google Earth Engine (JavaScript) scripts used for
spatial data processing. Scripts are designed to run independently.

All heavy computation (transition matrices at scale) moved to R. These scripts served to prototype the
methodology and validate R outputs.
Outputs are exported as CSV files to Google Drive and then stored in
`GEE/outputs/` in this repository.


## Scripts

### `01_Dicamba_ToFrom_SoyCot.js`

**Purpose**: Detects pixel-level land-use changes to and from soybean/cotton
across US counties, from 2009 to 2018.

**Method**:
1. **Agricultural mask** — filters out non-agricultural pixels using the CDL
   `cultivated` band (post-2012) or a manual crop code list (pre-2013, as the
   `cultivated` band did not exist before 2013). A **yearly mask** is applied:
   a pixel must be classified as cultivated in that specific year to be included.
2. **Annual CDL layers** — loads one masked cropland image per year (2009–2018)
3. **Change detection** — for each consecutive year pair, computes two binary
   pixel-level images:
   - `changeTo`: pixel was NOT soy/cotton in year N, IS soy/cotton in year N+1
   - `changeFrom`: pixel WAS soy/cotton in year N, is NOT soy/cotton in year N+1
4. **County aggregation** — sums changed pixels per county using
   `reduceRegions()` at 30m scale
5. **Export** — exports one CSV per year-pair and direction to Google Drive

**!!! Masking limitation**: See `01bis` below for the methodologically improved version.

**Inputs**:
- `USDA/NASS/CDL/{year}` — Cropland Data Layer, years 2009–2018
- `TIGER/2016/Counties` — US county boundaries

**Outputs** (in `GEE/outputs/01_FromSoyCot/` and `GEE/outputs/01_ToSoyCot/`):

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

### `01bis_Dicamba_ToFrom_SoyCot_UnionMask.js`

Same as `01` but uses a **union mask**: a pixel is retained if agricultural in
**any** year across 2009–2018. Preferred version for analysis.

**Masking change — Union Mask**:

The original script applies a yearly mask, meaning a pixel must be classified
as cultivated in that specific year to be included. This creates two problems
identified by Lark et al. (2017):

- **Hidden transitions**: a pixel switching from cropland to non-cropland (or
  vice versa) is one of the event we want to capture. A yearly mask filters
  it out instead.
- **Systematic bias**: the CDL underestimates cultivated area in early years,
  and this bias decreases over time. Yearly masks therefore exclude more pixels
  in early years simply because the CDL was less complete then and not because
  those pixels were not actually crops. This artificially inflates the
  appearance of cropland expansion, directly distorting change detection results.

Following Lark et al. (2017)'s recommendation to "utilize all available temporal
data" and consider "full trajectories of land cover over time", this script
builds a single **union mask**: a pixel is retained if it was classified as
agricultural in **any** year across the full 2009–2018 period. Only pixels that
were never agricultural in any year are excluded.

```javascript
var everCultivated = mask2009.or(mask2010).or(mask2011)...or(mask2018);
```

This preserves real crop-to-non-crop and non-crop-to-crop transitions while
still removing permanently non-agricultural pixels.

To determine agricultural status consistently across all years 2009–2018, we manually defined a list of crop codes sourced from USDA NASS metadata (codes 1–61, 66–80, 92, and 200–255; USDA NASS, 2014). We prefer this rather than using the "cultivated" band available post-2012, as it ensure methodological consistency before and after 2012. 

We include Fallow/Idle Cropland (code 61) in the mask because it represents an active agronomic decision within a crop rotation. Conversely, we exclude entirely permanent non-agricultural land covers such as pasture, forest, shrubland, and barren land (codes 62–65).

Then, we classify each pixel into one of four categories for each year. GM-enabled (1) captures soybean, cotton, and all double crops containing at least one GM component. Tolerant (2) captures true cereal crops with registered Dicamba tolerance, including wheat, corn, barley, rye, oats, millet, speltz, triticale, sorghum, and rice, as well as their double crop combinations. Vulnerable (3) captures all remaining agricultural codes in the mask such as other crops, fruits, vegetables, legumes, and managed land covers such as sod and switchgrass. Non-crop (0) captures pixels retained by the union mask that carry a non-agricultural CDL code in a given year (in practice almost exclusively Fallow/Idle Cropland (code 61), which is in the mask as actively managed land but not producing a crop that year. For ambiguous double crops containing components from different categories, a priority rule is applied: GM-enabled > Tolerant > Vulnerable. This ensures each pixel is always assigned to its most resistant component.

**Reference**: Lark, T.J., Mueller, R.M., Johnson, D.M., Gibbs, H.K. (2017).
Measuring land-use and land-cover change using the U.S. department of
agriculture's cropland data layer: Cautions and recommendations.
*Int J Appl Earth Obs Geoinformation*, 62, 224–235.


### `02_CropClassification_and_TransitionMatrix.js`

Combines classification, transition matrix exploration, and verification of results
against R outputs (Rhode Island, 2009) in one script.

**Part 1: Classification**:
Classifies each pixel into 4 categories per year using the union mask:

| Code | Category | Description |
|---|---|---|
| 0 | Non-crop | In union mask but not agricultural this year |
| 1 | GM-enabled | Soybean, cotton + some Dbl |
| 2 | Tolerant | True cereals (wheat, corn, barley, rye, oats...) + some Dbl |
| 3 | Vulnerable | All other agricultural codes |

Priority rule for double crops: GM (1) > Tolerant (2) > Vulnerable (3).
See `DOCS/notes/double_cropping.md` for full justification.

Also includes an exploratory pixel count of ambiguous double-crop codes (230, 232, 233)
to verify the priority rule is negligible in practice (~0.0025% of US agricultural land).

**Part 2: Transition matrix approaches** (all failed at scale, pipeline moved to R):

| # | Approach | Method | Outcome |
|---|---|---|---|
| 1 | National `frequencyHistogram` | `reduceRegion()` over full US geometry | timeout at national scale |
| 2 | County `frequencyHistogram` | `reduceRegions()` over all counties | timeout at national scale |
| 3 | County binary sum | One `reduceRegions()` per transition pair × 16 | timeout at national scale |
| 4 | Export pixel classifications and do the matrices in R | `sampleRegions()` per county, `crosstab()` in R | ~30,000 exports unmanageable |

The pipeline was ultimately moved to R using CDL `.tif` files downloaded directly
from the National Agricultural Statistics Service website: [link](https://www.nass.usda.gov/Research_and_Science/Cropland/Release/index.php).

**Important on projection**: all `reduceRegion()` calls must specify:
```javascript
crs: CDLIMAGE.projection()
```
Without this, GEE defaults to WGS84 and pixel counts are wrong.
See `DOCS/notes/use_of_projection.md`.

---

### `03_Calibration.js` *(coming soon)*

**Purpose**: Applies pixel-area calibration and bias adjustment to outputs from
scripts 01bis and 02.
