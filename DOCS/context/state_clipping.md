# State Clipping, Boundary Delimitation

To extract cropland data for a specific state, we clip the full US CDL raster to the state boundary. Below you will find an example for Alabama as well as an explanation and how each pixel behave under different parameters.

**REMARK**: Everything apply to counties (replace `states()` with `counties()`).
```r
# Load US state boundaries (tigris)
states_sf <- states(year = 2016, cb = TRUE)

# Load the CDL raster for the target year
cdl <- rast("data/CDL/2017.tif")

# Extract Alabama's boundary as a terra SpatVector
state_vect <- states_sf %>%
  filter(NAME == "Alabama") %>%
  vect()

# Reproject the state boundary to match the CDL's CRS
state_proj <- project(state_vect, crs(cdl))

# Clip the CDL to Alabama
clipped <- crop(cdl, state_proj) %>%
  mask(state_proj)
```

## Explanation

**`states_sf`** is an `sf` object from `tigris` where each row is a US state and the geometry column holds its boundary polygon.

**`vect()`** converts the `sf` object into a `SpatVector` (`Terra`'s vector format) which is required for raster operations.

**`project(state_vect, crs(cdl))`** reprojects the state boundary polygon into the same Coordinate Reference System (CRS) as the CDL raster. We need to do this to guarantee that the the polygon coordinates correspond to the correct pixel locations in the raster.

To crop the States, we do it in two times:
1) **`crop(cdl, state_proj)`** clips the raster to the smallest rectangle containing the entire state. This reduces the data size before we use the more precise masking operation.

2) **`mask(state_proj)`** sets to `NA` all pixels that are both outside the polygon and not touching its boundary. See below for other rule for setting a pixe as `NA`.

## Precision of States Boundaries

By default, `mask()` uses `touches=TRUE` (default), meaning any pixel inside the polygon or touching the its boundary will be included. If set to `FALSE`, only pixels whose centre point falls inside the polygon are kept. In our code we use the false option to avoid double counting.

**Polygon creation**: There is also some subtlety in how the polygon itself is created. On R, we directly downloads shapefiles with `tigris` from the US Census Bureau TIGER database. The `cb` argument of the `states()` function controls the level of precision: if set to `TRUE`, it downloads a generalised cartographic boundary file (1:500,000 scale), which has fewer vertices and smoother edges. For the most detailed shapefile following legal boundaries precisely, `cb` should be set to `FALSE` (default).
In our code we use `cb = TRUE`, which means we accept the simplified boundary.

## References:
- https://www.census.gov/geographies/mapping-files/time-series/geo/carto-boundary-file.html
- https://www.rdocumentation.org/packages/tigris/versions/2.2.1/topics/states
- https://rspatial.github.io/terra/reference/mask.html
