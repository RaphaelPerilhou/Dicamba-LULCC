/////////////////////////////////
// VALIDATION SCRIPT
// Replicates 01_mask_and_classify.R output for any state/year/mask period.
// Goal: Be able to compare output CSVs with R classified raster pixel counts.
/////////////////////////////////

var cdls = ee.ImageCollection("USDA/NASS/CDL");

// 1) AG MASK
var makeMask = function(year) {
  return ee.Image("USDA/NASS/CDL/" + year)
    .select('cropland')
    .expression(
      "(b('cropland') == 1) ? 1"  +  // Corn
      ": (b('cropland') == 2) ? 1" + // Cotton
      ": (b('cropland') == 3) ? 1" + // Rice
      ": (b('cropland') == 4) ? 1" + // Sorghum
      ": (b('cropland') == 5) ? 1" + // Soybeans
      ": (b('cropland') == 6) ? 1" + // Sunflower
      ": (b('cropland') == 10) ? 1" + // Peanuts
      ": (b('cropland') == 11) ? 1" + // Tobacco
      ": (b('cropland') == 12) ? 1" + // Sweet Corn
      ": (b('cropland') == 13) ? 1" + // Pop or Orn Corn
      ": (b('cropland') == 14) ? 1" + // Mint
      ": (b('cropland') == 21) ? 1" + // Barley
      ": (b('cropland') == 22) ? 1" + // Durum Wheat
      ": (b('cropland') == 23) ? 1" + // Spring Wheat
      ": (b('cropland') == 24) ? 1" + // Winter Wheat
      ": (b('cropland') == 25) ? 1" + // Other Small Grains
      ": (b('cropland') == 26) ? 1" + // Dbl Crop WinWht/Soybeans
      ": (b('cropland') == 27) ? 1" + // Rye
      ": (b('cropland') == 28) ? 1" + // Oats
      ": (b('cropland') == 29) ? 1" + // Millet
      ": (b('cropland') == 30) ? 1" + // Speltz
      ": (b('cropland') == 31) ? 1" + // Canola
      ": (b('cropland') == 32) ? 1" + // Flaxseed
      ": (b('cropland') == 33) ? 1" + // Safflower
      ": (b('cropland') == 34) ? 1" + // Rape Seed
      ": (b('cropland') == 35) ? 1" + // Mustard
      ": (b('cropland') == 36) ? 1" + // Alfalfa
      ": (b('cropland') == 37) ? 1" + // Other Hay/Non Alfalfa
      ": (b('cropland') == 38) ? 1" + // Camelina
      ": (b('cropland') == 39) ? 1" + // Buckwheat
      ": (b('cropland') == 41) ? 1" + // Sugarbeets
      ": (b('cropland') == 42) ? 1" + // Dry Beans
      ": (b('cropland') == 43) ? 1" + // Potatoes
      ": (b('cropland') == 44) ? 1" + // Other Crops
      ": (b('cropland') == 45) ? 1" + // Sugarcane
      ": (b('cropland') == 46) ? 1" + // Sweet Potatoes
      ": (b('cropland') == 47) ? 1" + // Misc Vegs & Fruits
      ": (b('cropland') == 48) ? 1" + // Watermelons
      ": (b('cropland') == 49) ? 1" + // Onions
      ": (b('cropland') == 50) ? 1" + // Cucumbers
      ": (b('cropland') == 51) ? 1" + // Chick Peas
      ": (b('cropland') == 52) ? 1" + // Lentils
      ": (b('cropland') == 53) ? 1" + // Peas
      ": (b('cropland') == 54) ? 1" + // Tomatoes
      ": (b('cropland') == 55) ? 1" + // Caneberries
      ": (b('cropland') == 56) ? 1" + // Hops
      ": (b('cropland') == 57) ? 1" + // Herbs
      ": (b('cropland') == 58) ? 1" + // Clover/Wildflowers
      ": (b('cropland') == 59) ? 1" + // Sod/Grass Seed
      ": (b('cropland') == 60) ? 1" + // Switchgrass
      ": (b('cropland') == 61) ? 1" + // Fallow/Idle Cropland
      ": (b('cropland') == 66) ? 1" + // Cherries
      ": (b('cropland') == 67) ? 1" + // Peaches
      ": (b('cropland') == 68) ? 1" + // Apples
      ": (b('cropland') == 69) ? 1" + // Grapes
      ": (b('cropland') == 70) ? 1" + // Christmas Trees
      ": (b('cropland') == 71) ? 1" + // Other Tree Crops
      ": (b('cropland') == 72) ? 1" + // Citrus
      ": (b('cropland') == 74) ? 1" + // Pecans
      ": (b('cropland') == 75) ? 1" + // Almonds
      ": (b('cropland') == 76) ? 1" + // Walnuts
      ": (b('cropland') == 77) ? 1" + // Pears
      ": (b('cropland') == 92) ? 1" + // Aquaculture
      ": (b('cropland') == 204) ? 1" + // Pistachios
      ": (b('cropland') == 205) ? 1" + // Triticale
      ": (b('cropland') == 206) ? 1" + // Carrots
      ": (b('cropland') == 207) ? 1" + // Asparagus
      ": (b('cropland') == 208) ? 1" + // Garlic
      ": (b('cropland') == 209) ? 1" + // Cantaloupes
      ": (b('cropland') == 210) ? 1" + // Prunes
      ": (b('cropland') == 211) ? 1" + // Olives
      ": (b('cropland') == 212) ? 1" + // Oranges
      ": (b('cropland') == 213) ? 1" + // Honeydew Melons
      ": (b('cropland') == 214) ? 1" + // Broccoli
      ": (b('cropland') == 215) ? 1" + // Avocados
      ": (b('cropland') == 216) ? 1" + // Peppers
      ": (b('cropland') == 217) ? 1" + // Pomegranates
      ": (b('cropland') == 218) ? 1" + // Nectarines
      ": (b('cropland') == 219) ? 1" + // Greens
      ": (b('cropland') == 220) ? 1" + // Plums
      ": (b('cropland') == 221) ? 1" + // Strawberries
      ": (b('cropland') == 222) ? 1" + // Squash
      ": (b('cropland') == 223) ? 1" + // Apricots
      ": (b('cropland') == 224) ? 1" + // Vetch
      ": (b('cropland') == 225) ? 1" + // Dbl Crop WinWht/Corn
      ": (b('cropland') == 226) ? 1" + // Dbl Crop Oats/Corn
      ": (b('cropland') == 227) ? 1" + // Lettuce
      ": (b('cropland') == 228) ? 1" + // Dbl Crop Triticale/Corn
      ": (b('cropland') == 229) ? 1" + // Pumpkins
      ": (b('cropland') == 230) ? 1" + // Dbl Crop Lettuce/Durum Wht
      ": (b('cropland') == 231) ? 1" + // Dbl Crop Lettuce/Cantaloupe
      ": (b('cropland') == 232) ? 1" + // Dbl Crop Lettuce/Cotton
      ": (b('cropland') == 233) ? 1" + // Dbl Crop Lettuce/Barley
      ": (b('cropland') == 234) ? 1" + // Dbl Crop Durum Wht/Sorghum
      ": (b('cropland') == 235) ? 1" + // Dbl Crop Barley/Sorghum
      ": (b('cropland') == 236) ? 1" + // Dbl Crop WinWht/Sorghum
      ": (b('cropland') == 237) ? 1" + // Dbl Crop Barley/Corn
      ": (b('cropland') == 238) ? 1" + // Dbl Crop WinWht/Cotton
      ": (b('cropland') == 239) ? 1" + // Dbl Crop Soybeans/Cotton
      ": (b('cropland') == 240) ? 1" + // Dbl Crop Soybeans/Oats
      ": (b('cropland') == 241) ? 1" + // Dbl Crop Corn/Soybeans
      ": (b('cropland') == 242) ? 1" + // Blueberries
      ": (b('cropland') == 243) ? 1" + // Cabbage
      ": (b('cropland') == 244) ? 1" + // Cauliflower
      ": (b('cropland') == 245) ? 1" + // Celery
      ": (b('cropland') == 246) ? 1" + // Radishes
      ": (b('cropland') == 247) ? 1" + // Turnips
      ": (b('cropland') == 248) ? 1" + // Eggplants
      ": (b('cropland') == 249) ? 1" + // Gourds
      ": (b('cropland') == 250) ? 1" + // Cranberries
      ": (b('cropland') == 254) ? 1" + // Dbl Crop Barley/Soybeans
      ": 0"
    );
};

// 2) CLASSIFICATION
var classifyPixel = function(image) {
  return image.expression(
    "(b('cropland') == 2)   ? 1" +
    ": (b('cropland') == 5)   ? 1" +
    ": (b('cropland') == 26)  ? 1" +
    ": (b('cropland') == 232) ? 1" +
    ": (b('cropland') == 238) ? 1" +
    ": (b('cropland') == 239) ? 1" +
    ": (b('cropland') == 240) ? 1" +
    ": (b('cropland') == 241) ? 1" +
    ": (b('cropland') == 254) ? 1" +
    ": (b('cropland') == 1)   ? 2" +
    ": (b('cropland') == 3)   ? 2" +
    ": (b('cropland') == 4)   ? 2" +
    ": (b('cropland') == 21)  ? 2" +
    ": (b('cropland') == 22)  ? 2" +
    ": (b('cropland') == 23)  ? 2" +
    ": (b('cropland') == 24)  ? 2" +
    ": (b('cropland') == 25)  ? 2" +
    ": (b('cropland') == 27)  ? 2" +
    ": (b('cropland') == 28)  ? 2" +
    ": (b('cropland') == 29)  ? 2" +
    ": (b('cropland') == 30)  ? 2" +
    ": (b('cropland') == 205) ? 2" +
    ": (b('cropland') == 225) ? 2" +
    ": (b('cropland') == 226) ? 2" +
    ": (b('cropland') == 228) ? 2" +
    ": (b('cropland') == 230) ? 2" +
    ": (b('cropland') == 233) ? 2" +
    ": (b('cropland') == 234) ? 2" +
    ": (b('cropland') == 235) ? 2" +
    ": (b('cropland') == 236) ? 2" +
    ": (b('cropland') == 237) ? 2" +
    ": (b('cropland') == 6)   ? 3" +
    ": (b('cropland') == 10)  ? 3" +
    ": (b('cropland') == 11)  ? 3" +
    ": (b('cropland') == 12)  ? 3" +
    ": (b('cropland') == 13)  ? 3" +
    ": (b('cropland') == 14)  ? 3" +
    ": (b('cropland') == 31)  ? 3" +
    ": (b('cropland') == 32)  ? 3" +
    ": (b('cropland') == 33)  ? 3" +
    ": (b('cropland') == 34)  ? 3" +
    ": (b('cropland') == 35)  ? 3" +
    ": (b('cropland') == 36)  ? 3" +
    ": (b('cropland') == 37)  ? 3" +
    ": (b('cropland') == 38)  ? 3" +
    ": (b('cropland') == 39)  ? 3" +
    ": (b('cropland') == 41)  ? 3" +
    ": (b('cropland') == 42)  ? 3" +
    ": (b('cropland') == 43)  ? 3" +
    ": (b('cropland') == 44)  ? 3" +
    ": (b('cropland') == 45)  ? 3" +
    ": (b('cropland') == 46)  ? 3" +
    ": (b('cropland') == 47)  ? 3" +
    ": (b('cropland') == 48)  ? 3" +
    ": (b('cropland') == 49)  ? 3" +
    ": (b('cropland') == 50)  ? 3" +
    ": (b('cropland') == 51)  ? 3" +
    ": (b('cropland') == 52)  ? 3" +
    ": (b('cropland') == 53)  ? 3" +
    ": (b('cropland') == 54)  ? 3" +
    ": (b('cropland') == 55)  ? 3" +
    ": (b('cropland') == 56)  ? 3" +
    ": (b('cropland') == 57)  ? 3" +
    ": (b('cropland') == 58)  ? 3" +
    ": (b('cropland') == 59)  ? 3" +
    ": (b('cropland') == 60)  ? 3" +
    ": (b('cropland') == 66)  ? 3" +
    ": (b('cropland') == 67)  ? 3" +
    ": (b('cropland') == 68)  ? 3" +
    ": (b('cropland') == 69)  ? 3" +
    ": (b('cropland') == 70)  ? 3" +
    ": (b('cropland') == 71)  ? 3" +
    ": (b('cropland') == 72)  ? 3" +
    ": (b('cropland') == 74)  ? 3" +
    ": (b('cropland') == 75)  ? 3" +
    ": (b('cropland') == 76)  ? 3" +
    ": (b('cropland') == 77)  ? 3" +
    ": (b('cropland') == 92)  ? 3" +
    ": (b('cropland') == 204) ? 3" +
    ": (b('cropland') == 206) ? 3" +
    ": (b('cropland') == 207) ? 3" +
    ": (b('cropland') == 208) ? 3" +
    ": (b('cropland') == 209) ? 3" +
    ": (b('cropland') == 210) ? 3" +
    ": (b('cropland') == 211) ? 3" +
    ": (b('cropland') == 212) ? 3" +
    ": (b('cropland') == 213) ? 3" +
    ": (b('cropland') == 214) ? 3" +
    ": (b('cropland') == 215) ? 3" +
    ": (b('cropland') == 216) ? 3" +
    ": (b('cropland') == 217) ? 3" +
    ": (b('cropland') == 218) ? 3" +
    ": (b('cropland') == 219) ? 3" +
    ": (b('cropland') == 220) ? 3" +
    ": (b('cropland') == 221) ? 3" +
    ": (b('cropland') == 222) ? 3" +
    ": (b('cropland') == 223) ? 3" +
    ": (b('cropland') == 224) ? 3" +
    ": (b('cropland') == 227) ? 3" +
    ": (b('cropland') == 229) ? 3" +
    ": (b('cropland') == 231) ? 3" +
    ": (b('cropland') == 242) ? 3" +
    ": (b('cropland') == 243) ? 3" +
    ": (b('cropland') == 244) ? 3" +
    ": (b('cropland') == 245) ? 3" +
    ": (b('cropland') == 246) ? 3" +
    ": (b('cropland') == 247) ? 3" +
    ": (b('cropland') == 248) ? 3" +
    ": (b('cropland') == 249) ? 3" +
    ": (b('cropland') == 250) ? 3" +
    ": 0"
  ).rename('category');
};

// 3) SEQUENCE FUNCTION (to simplify the validation function).
// 2009:2015 as seq(2009, 2015) instead of [2009,...,2015]
var seq = function(from, to) {
  var arr = [];
  for (var y = from; y <= to; y++) arr.push(y);
  return arr;
};

// 4) VALIDATION FUNCTION
var validateState = function(stateName, countYear, maskYears) {

  // Build union mask across specified period
  var unionMask = makeMask(maskYears[0]);
  for (var i = 1; i < maskYears.length; i++) {
    unionMask = unionMask.or(makeMask(maskYears[i]));
  }

  // Load CDL for countYear, apply union mask, classify
  var cdl = ee.Image("USDA/NASS/CDL/" + countYear).select('cropland');
  var masked = cdl.updateMask(unionMask);
  var classified = classifyPixel(masked);

  // Get state geometry
  var state = ee.FeatureCollection("TIGER/2016/States")
    .filter(ee.Filter.eq('NAME', stateName));

  // Count pixels using native CDL projection (matches R)
  var counts = classified.reduceRegion({
    reducer: ee.Reducer.frequencyHistogram(),
    geometry: state.geometry(),
    scale: 30,
    crs: cdl.projection(),
    maxPixels: 1e13,
    tileScale: 16
  });

  // Export label: State_countYear_maskFromYear_maskToYear
  var label = stateName.replace(' ', '_') + '_' +
              countYear + '_mask' +
              maskYears[0] + '_' + maskYears[maskYears.length - 1];

  Export.table.toDrive({
    collection: ee.FeatureCollection([ee.Feature(null, counts)]),
    description: 'Validation_' + label,
    folder: 'Dicamba_Validation',
    fileFormat: 'CSV'
  });

  print('Queued export: Validation_' + label);
};

// 5) VALIDATION CALLS
// First argument: state of Interest (only 1 state per call).
// Second argument: year of interest for pixel counting.
// Third argument: period range for the union mask. 

validateState('Alabama',      2009, seq(2009, 2011));
validateState('Alabama',      2010, seq(2009, 2011));
validateState('Alabama',      2011, seq(2009, 2011));
validateState('Rhode Island', 2009, seq(2009, 2011));
validateState('Rhode Island', 2010, seq(2009, 2011));
validateState('Rhode Island', 2011, seq(2009, 2011));

// HOW TO READ THE OUTPUT CSV
// The exported CSV has 3 columns: system:index, category, .geo
// We only look at the second column (category).
// It contains pixel counts for each classification category:
//   0 = NonCrop, 1 = GM, 2 = Tolerant, 3 = Vulnerable
// Then, we can compare against R output. From the manual inspection we did for some states,
// we should have differences <1% (attributable to boundary pixel handling: GEE don't give integer).

