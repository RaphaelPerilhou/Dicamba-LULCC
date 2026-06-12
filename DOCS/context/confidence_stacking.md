# Confidence Band Pipeline

This sub-pipeline adds the CDL **confidence band** to the classified rasters
produced by `01_mask_and_classify.R`. It is designed for validation counties
only and produces a two-band GeoTIFF (`category` + `confidence`) per
county-year pair.

---

## Overview

The CDL image in Google Earth Engine contains two bands: `cropland` (the crop
code) and `confidence` (0–100, percentage). The main R pipeline (`00`–`02`)
works from locally downloaded CDL GeoTIFFs that carry only the `cropland` band.
The confidence band must therefore be exported separately from GEE and then
stacked onto the already-classified raster in R.

```
GEE (05_Export_Confidence.js)
    └─► Google Drive: Raw_CDL_Confidence/CDL_conf_<year>_<GEOID>.tif
            │
            ▼
R (03_stack_confidence.R)
    reads classified raster  ──┐
    reads GEE confidence tif ──┤  re-clip + mask(touches=FALSE)
                               └─► Conf_stacked_<year>_<GEOID>.tif
                                     bands: [category, confidence]
```

---

## Files

| File | Role |
|---|---|
| `GEE/codes/05_Export_Confidence.js` | GEE script — exports the confidence band to Google Drive |
| `R/codes/03_stack_confidence.R` | R script — re-clips and stacks the confidence band onto the classified raster |

---

## Step 1 — GEE export (`05_Export_Confidence.js`)

Edit the two constants at the top of the script, then run it in the
[GEE Code Editor](https://code.earthengine.google.com/):

```javascript
var GEOIDS = ["17019", "19169"];  // FIPS codes of counties to export
var YEARS  = [2012];              // years to export
```

The script exports one GeoTIFF per county-year to the Google Drive folder
`Raw_CDL_Confidence/`. Key export parameters:

```javascript
crs:          "EPSG:5070",                          // CDL native CRS (Albers)
crsTransform: [30, 0, -2356095, 0, -30, 3172605],  // CDL native grid origin
```

Specifying `crsTransform` instead of `scale` forces the output pixels to snap
exactly to the CDL native grid, which is a prerequisite for pixel-perfect
alignment with the R-classified raster.

### Known issue: GEE exports a slightly larger extent

When stacking, `compareGeom()` throws an extent mismatch error between the
classified raster and the GEE-exported confidence band. Inspecting both extents
shows that the confidence raster is consistently 1 pixel wider and/or taller
than the classified raster.

We could not identify a documented reason for this in the GEE documentation.
Our best working hypothesis is that `Export.image.toDrive` includes any pixel
whose boundary merely *touches* the polygon, which would be equivalent to
`touches = TRUE` in `terra::mask()` — the opposite of what the R pipeline uses.

---

## Step 2 — R stacking (`03_stack_confidence.R`)

After downloading the exported GeoTIFFs from Google Drive to
`data/confidence_bands/`, run:

```bash
Rscript R/codes/03_stack_confidence.R
```

### What the script does

1. Loads the classified raster (`data/classified/<STATEFP>/Classified_<year>_<GEOID>.tif`).
2. Loads the GEE confidence raster (`data/confidence_bands/CDL_conf_<year>_<GEOID>.tif`).
3. **Re-clips the confidence raster** using the same county polygon and
   `touches = FALSE` as `00_setup_and_clip.R`. This trims the extra border
   pixel added by GEE and guarantees identical extents.
4. Verifies alignment with `compareGeom()`.
5. Stacks the two bands and writes
   `data/class_and_conf/<STATEFP>/Conf_stacked_<year>_<GEOID>.tif`
   (bands: `category`, `confidence`; dtype `INT1U`).

### Why `touches = FALSE` fixes the mismatch

Re-clipping the confidence raster with `touches = FALSE` excludes any pixel
whose centre falls outside the polygon, which trims the extra border row/column
back to the same footprint as the classified raster. `compareGeom()` then
passes and the two bands can be stacked cleanly.

---

## Output

```
data/class_and_conf/
└── <STATEFP>/
    └── Conf_stacked_<year>_<GEOID>.tif   # 2-band: category (INT1U) + confidence (INT1U)
```

---

## Validation counties (current)

| GEOID | County | State |
|---|---|---|
| 17019 | Champaign | IL |
| 19169 | Story | IA |
