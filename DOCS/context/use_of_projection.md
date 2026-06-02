# Projection Verification: CDL, R, and GEE

## Context

When computing transition matrices from the USDA NASS Cropland Data Layer (CDL),
results must be computed in the **native CDL projection** to ensure pixel counts
are correct. This document explains the verification procedure and why it matters.

## 1. Native CDL Projection

According to the [CDL FAQ](https://www.nass.usda.gov/Research_and_Science/Cropland/sarsfaqs2.php#common.2),
CDL data use the **USA Contiguous Albers Equal Area Conic USGS Version** with:

- Spheroid: GRS 1980
- Datum: NAD83
- Standard parallel 1: 29.5°
- Standard parallel 2: 45.5°
- Latitude of center: 23°
- Longitude of center: -96°
- False easting/northing: 0
- Units: metres

Files downloaded directly from [SARS](https://www.nass.usda.gov/Research_and_Science/Cropland/SARS1a.php)
are in this native Albers projection.

## 2. Verification in R

After loading a CDL `.tif` file in R with `terra`, running `crs(r)` returns WKT2
format confirming the same projection parameters:

```r
library(terra)
r <- rast("data/2009_30m_cdls/2009_30m_cdls.tif")
crs(r)   # confirms NAD83 / Conus Albers, GRS 1980, params above
res(r)   # confirms 30 x 30 metres
```

Key parameters in the output match the CDL specification exactly:
- `Latitude of false origin`: 23
- `Longitude of false origin`: -96
- `Latitude of 1st standard parallel`: 29.5
- `Latitude of 2nd standard parallel`: 45.5
- Units: metres

Cross-year (only for 2009, 2010 here) consistency check (mandatory before computing transition matrices):

```r
r_2009 <- rast("data/2009_30m_cdls/2009_30m_cdls.tif")
r_2010 <- rast("data/2010_30m_cdls/2010_30m_cdls.tif")

crs(r_2009) == crs(r_2010)  # must be TRUE
res(r_2009) == res(r_2010)  # must be TRUE
ext(r_2009) == ext(r_2010)  # must be TRUE
```

All three return `TRUE` for SARS-downloaded files, confirming that the native
projection is consistent across years and that pixel-to-pixel comparison for
transition matrices is valid.

## 3. GEE Default Projection is Wrong

In Google Earth Engine, `reduceRegion()` uses **WGS84 (EPSG:4326)** as its default
projection when no `crs` parameter is specified. This is documented under
[The Default Projection](https://developers.google.com/earth-engine/guides/projections#the-default-projection).

This causes incorrect pixel counts and thus produces wrong
transition matrix counts.

Therefore, we always specify `crs` and `scale` explicitly in any `reduceRegion()`
or `reduceRegions()` call.

## 4. Verification in GEE

To confirm that `cdl.projection()` corresponds to the native CDL projection:

```javascript
var cdl2009 = ee.Image("USDA/NASS/CDL/2009");
print(cdl2009.projection());
```

Output:

```
Projection
  transform: [30, 0, -2356095, 0, -30, 3172605]
  wkt: PROJCS["Albers Conical Equal Area",
    GEOGCS["NAD83", ...],
    PROJECTION["Albers_Conic_Equal_Area"],
    PARAMETER["central_meridian", -96.0],
    PARAMETER["latitude_of_origin", 23.0],
    PARAMETER["standard_parallel_1", 29.5],
    PARAMETER["standard_parallel_2", 45.5],
    PARAMETER["false_easting", 0.0],
    PARAMETER["false_northing", 0.0],
    UNIT["m", 1.0]]
```

This matches the CDL specification.

## 5. Write the `crs` parameter

Example of a `reduceRegion()` call including the `crs` parameter:

```javascript
var cdl2009 = ee.Image("USDA/NASS/CDL/2009")

var counts = classifiedLayer.reduceRegion({
  reducer: ee.Reducer.frequencyHistogram(),
  geometry: regionGeometry,
  scale: 30,
  crs: cdl2009.projection(),  // native CDL grid
  maxPixels: 1e9
});
```

## 6. Summary

| Source | Projection | Correct ? |
|---|---|---|
| CDL SARS download | NAD83 / Albers Equal Area, GRS 1980 |  benchmark |
| R `terra` (`crs(r)`) | NAD83 / Conus Albers, GRS 1980 | yes, matches original CDL|
| GEE `cdl.projection()` | Albers Conical Equal Area, NAD83 | yes, matches original CDL |
| GEE default (no `crs`) | WGS84 / EPSG:4326 | wrong projection |

To conclude, the three, SARS, R, GEE with `crs` parameter (cdl.projection()) use the same
projection and produce consistent pixel counts. We should not use the GEE default `crs` parameter.
