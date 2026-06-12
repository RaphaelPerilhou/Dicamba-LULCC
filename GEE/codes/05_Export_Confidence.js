// ============================================================================
// Export CDL confidence band clipped to county
// Output: single-band GeoTIFF (confidence only)
//         cropland band already exists in CDL_<year>_<GEOID>.tif from R pipeline
//
// crs + crsTransform force snap to exact CDL native grid.
// Remaining extent difference is corrected in 03_stack_confidence.R via
// crop() + mask(touches=FALSE) using the same county polygon as 00.R.
// ============================================================================

var GEOIDS     = ["17019", "19169"];  // Champaign IL, Story IA
var YEARS      = [2012];             // extend as needed
var EXPORT_DIR = "Raw_CDL_Confidence";   // Google Drive folder

var CDL_CRS       = "EPSG:5070";
var CDL_TRANSFORM = [30, 0, -2356095, 0, -30, 3172605];  // CDL native grid origin

// ============================================================================

var counties = ee.FeatureCollection("TIGER/2016/Counties");

GEOIDS.forEach(function(geoid) {

  var county = counties.filter(ee.Filter.eq("GEOID", geoid));

  YEARS.forEach(function(year) {

    var confidence = ee.Image("USDA/NASS/CDL/" + year)
                       .select("confidence")
                       .clip(county);

    Export.image.toDrive({
      image:          confidence,
      description:    "CDL_conf_" + year + "_" + geoid,
      folder:         EXPORT_DIR,
      fileNamePrefix: "CDL_conf_" + year + "_" + geoid,
      region:         county.geometry(),
      crs:            CDL_CRS,
      crsTransform:   CDL_TRANSFORM,
      maxPixels:      1e10,
      fileFormat:     "GeoTIFF"
    });

  });
});

print("Tasks submitted — check the Tasks tab.");
