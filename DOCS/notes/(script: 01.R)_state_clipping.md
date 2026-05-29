# State Clipping, Boundary Delimitation

To extract cropland data for a specific state, we clip the full US CDL raster to the state boundary in two steps. Below is a worked example for Alabama.

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

## Step-by-step explanation

**`states_sf`** is an `sf` object from `tigris` where each row is a US state and the geometry column holds its boundary polygon.

**`vect()`** converts the `sf` object into a `SpatVector`, which is terra's own vector format required for raster operations.

**`project(state_vect, crs(cdl))`** reprojects the state boundary polygon into the same Coordinate Reference System (CRS) as the CDL raster. This alignment is essential as without it, the polygon coordinates would not correspond to the correct pixel locations in the raster.

**`crop(cdl, state_proj)`** clips the raster to the smallest rectangle containing the entire state. This dramatically reduces the data size before the more precise masking operation.

**`mask(state_proj)`** sets to `NA` all pixels whose centres fall outside the actual state boundary polygon, giving the precise state shape.

## Data source for state boundaries

State boundaries are downloaded via the `tigris` package, which provides
direct access to TIGER shapefiles from the US Census Bureau. Calling
`states(year = 2016, cb = TRUE)` downloads the **cartographic boundary
shapefile** for the requested year. The `cb = TRUE` argument requests the
simplified cartographic boundary version rather than the full legal
TIGER/Line boundary. The former is generalised for mapping purposes
(e.g. smoothed coastlines), which is sufficient for our pixel-level
agricultural analysis.

Each state is represented as a **polygon**, and it is this polygon that `mask()`
uses to determine which CDL raster pixels fall inside or outside the state
boundary.

Note: tigris returns an `sf` object by default. We convert it to a terra
`SpatVector` with `vect()` and reproject it to the CDL's CRS with
`project()` before clipping.
