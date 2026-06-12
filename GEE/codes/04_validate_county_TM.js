// ============================================================================
// Transition matrix validation — R vs GEE
// County: Autauga, AL (01001) | Union mask: 2009-2018
// ============================================================================

var GEOID     = "01001";
var YEARS     = [2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018];
var YEAR_FROM = 2009;
var YEAR_TO   = 2010;

// ============================================================================
// LOOKUP TABLES
// ============================================================================

var AG_CODES = [
  1,2,3,4,5,6,10,11,12,13,14,
  21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,61,
  66,67,68,69,70,71,72,74,75,76,77,
  204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,
  220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,
  236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,254
];

// [crop_code, category] pairs: equivalent of reclass_table in R
var RECLASS = [
  // GM (1)
  [2,1],[5,1],[26,1],[232,1],[238,1],[239,1],[240,1],[241,1],[254,1],
  // Tolerant (2)
  [1,2],[3,2],[4,2],[12,2],[13,2],[21,2],[22,2],[23,2],[24,2],[25,2],
  [27,2],[28,2],[29,2],[30,2],[45,2],[205,2],[225,2],[226,2],[228,2],
  [230,2],[233,2],[234,2],[235,2],[236,2],[237,2],
  // Vulnerable (3)
  [6,3],[10,3],[11,3],[14,3],[31,3],[32,3],[33,3],[34,3],[35,3],[36,3],
  [37,3],[38,3],[39,3],[41,3],[42,3],[43,3],[44,3],[46,3],[47,3],[48,3],
  [49,3],[50,3],[51,3],[52,3],[53,3],[54,3],[55,3],[56,3],[57,3],[58,3],
  [66,3],[67,3],[68,3],[69,3],[70,3],[71,3],[72,3],[74,3],[75,3],[76,3],
  [77,3],[204,3],[206,3],[207,3],[208,3],[209,3],[210,3],[211,3],[212,3],
  [213,3],[214,3],[215,3],[216,3],[217,3],[218,3],[219,3],[220,3],[221,3],
  [222,3],[223,3],[224,3],[227,3],[229,3],[231,3],[242,3],[243,3],[244,3],
  [245,3],[246,3],[247,3],[248,3],[249,3],[250,3],
  // NonCrop (0)
  [61,0]
];

var FROM = RECLASS.map(function(p) { return p[0]; });
var TO   = RECLASS.map(function(p) { return p[1]; });

var CATEGORIES = [
  {code: 0,  label: "NonCrop"},
  {code: 1,  label: "GM"},
  {code: 2,  label: "Tolerant"},
  {code: 3,  label: "Vulnerable"},
  {code: 99, label: "Unclassified"}
];

// ============================================================================
// STEP 1 — Load CDL images, clipped to county
// ============================================================================

var county = ee.FeatureCollection("TIGER/2016/Counties")
               .filter(ee.Filter.eq("GEOID", GEOID));

var cdlCollection = ee.ImageCollection("USDA/NASS/CDL")
                     .filter(ee.Filter.calendarRange(2009, 2018, "year"))
                     .select("cropland");

var images = YEARS.map(function(y) {
  return cdlCollection.filter(ee.Filter.calendarRange(y, y, "year")).first().clip(county);
});

var CDL_PROJECTION = images[0].projection();

// ============================================================================
// STEP 2 — Build union mask: pixel = 1 if ever agricultural across all years
// ============================================================================

function makeMask(img) {
  return img.remap(AG_CODES, AG_CODES.map(function() { return 1; }), 0).eq(1);
}

var unionMask = makeMask(images[0])
  .or(makeMask(images[1]))
  .or(makeMask(images[2]))
  .or(makeMask(images[3]))
  .or(makeMask(images[4]))
  .or(makeMask(images[5]))
  .or(makeMask(images[6]))
  .or(makeMask(images[7]))
  .or(makeMask(images[8]))
  .or(makeMask(images[9]))
  .selfMask();

// ============================================================================
// STEP 3 — Classify: known codes -> {0,1,2,3}, unknown -> null
// ============================================================================

var classified_raw = images.map(function(img) {
  return img.remap(FROM, TO, null);
});

// ============================================================================
// STEP 4 — Fill unknown-but-agricultural pixels with 99, drop rest
// ============================================================================

var classified = classified_raw.map(function(img) {
  return img.unmask(99).updateMask(unionMask);
});

// ============================================================================
// STEP 5 — Transition matrix for the selected year pair
// ============================================================================

var img_from = classified[YEARS.indexOf(YEAR_FROM)]; //image at index position of the year_from
var img_to   = classified[YEARS.indexOf(YEAR_TO)]; //image at index position of the year_to

print("--- " + YEAR_FROM + " -> " + YEAR_TO + " ---");

CATEGORIES.forEach(function(from_cat) {
  CATEGORIES.forEach(function(to_cat) { //loop accross all categories pairs. 

    var pixels = img_from.eq(from_cat.code).and(img_to.eq(to_cat.code)); //Binary code for the 
                                                                        // current transition.
    var result = pixels.reduceRegion({
      reducer:   ee.Reducer.sum(), //for the current transition, sum of pixel. 
      geometry:  county.geometry(),
      crs:       CDL_PROJECTION,
      scale:     CDL_PROJECTION.nominalScale(),
      maxPixels: 1e10
    });

    ee.Number(result.get(pixels.bandNames().get(0))).evaluate(function(n, err) {
      if (err) { print("Error:", err); return; }
      if (n > 0) print("  " + from_cat.label + " -> " + to_cat.label + ": " + n);
    });

  });
});
