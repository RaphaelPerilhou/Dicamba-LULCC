var cdls = ee.ImageCollection("USDA/NASS/CDL"); 

/////////////////////////////////
// AG MASK
// Function to create AG mask for each year. 
// The agricultural mask is applied consistently across all years 2009-2018.
// We use manually defined crop codes (codes 1-61, 66-80, 92, 200-255) based
// on USDA NASS CDL metadata (USDA NASS, 2014).
// The manual list ensure that we don't introduce non-agricultural pixels such as forest (141).
/////////////////////////////////
var makeMask = function(year) {
  return ee.Image("USDA/NASS/CDL/" + year)
  .select('cropland')
  .expression(
// CROPS 1-20
"(b('cropland') == 1) ? 1" +   // Corn
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
// GRAINS, HAY, SEEDS 21-40
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
// CROPS 41-60
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
// NON-CROP 61 (Fallow: retained as actively managed agricultural land)
": (b('cropland') == 61) ? 1" + // Fallow/Idle Cropland
// CROPS 66-80
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
// OTHER: Aquaculture (92)
": (b('cropland') == 92) ? 1" + // Aquaculture          
// CROPS 200-255
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
": 0");
};

var mask2008 = makeMask(2008);
var mask2009 = makeMask(2009);
var mask2010 = makeMask(2010);
var mask2011 = makeMask(2011);
var mask2012 = makeMask(2012);
var mask2013 = makeMask(2013);
var mask2014 = makeMask(2014);
var mask2015 = makeMask(2015);
var mask2016 = makeMask(2016);
var mask2017 = makeMask(2017);
var mask2018 = makeMask(2018);

// Create a union mask: Only remove pixels that never have been agricultural 
// in the whole study period (2009-2018).

var everCultivated = mask2009
  .or(mask2010)
  .or(mask2011)
  .or(mask2012)
  .or(mask2013)
  .or(mask2014)
  .or(mask2015)
  .or(mask2016)
  .or(mask2017)
  .or(mask2018);

// Yearly CDLs, masked with union mask
var cdlsLayers = {};

var makeCdlLayer = function(year) {
  var image = ee.Image("USDA/NASS/CDL/" + year)
    .select('cropland')
    .updateMask(everCultivated);
  Map.addLayer(image, {}, 'CDL ' + year, false);
  cdlsLayers[year] = image;
};

makeCdlLayer(2009);
makeCdlLayer(2010);
makeCdlLayer(2011);
makeCdlLayer(2012);
makeCdlLayer(2013);
makeCdlLayer(2014);
makeCdlLayer(2015);
makeCdlLayer(2016);
makeCdlLayer(2017);
makeCdlLayer(2018);

/////////////////////////////////
// THREE-WAY CROP CLASSIFICATION + Non-crop
// Categories per pixel per year:
//   1 = GM-enabled (soy/cotton + double crops with GM component)
//   2 = Tolerant (true cereals with Dicamba tolerance)
//   3 = Vulnerable (other agricultural codes)
//   0 = Non-crop (pixel in union mask but not agricultural this year)
// Priority rule for mixed double crops: GM-enabled > Tolerant > Vulnerable
/////////////////////////////////

var classifyPixel = function(image) {
  return image.expression(

    // 1: GM-ENABLED = Soy, Cotton + double crops (priority rule applies)
    "(b('cropland') == 2)   ? 1" +   // Cotton
    ": (b('cropland') == 5)   ? 1" + // Soybeans
    ": (b('cropland') == 26)  ? 1" + // Dbl Crop WinWht/Soybeans    [GM > Tolerant]
    ": (b('cropland') == 232) ? 1" + // Dbl Crop Lettuce/Cotton      [GM > Vulnerable]
    ": (b('cropland') == 238) ? 1" + // Dbl Crop WinWht/Cotton       [GM > Tolerant]
    ": (b('cropland') == 239) ? 1" + // Dbl Crop Soybeans/Cotton     [GM + GM]
    ": (b('cropland') == 240) ? 1" + // Dbl Crop Soybeans/Oats       [GM > Tolerant]
    ": (b('cropland') == 241) ? 1" + // Dbl Crop Corn/Soybeans       [GM > Tolerant]
    ": (b('cropland') == 254) ? 1" + // Dbl Crop Barley/Soybeans     [GM > Tolerant]

    // 2: TOLERANT = True cereals with Dicamba tolerance
    ": (b('cropland') == 1)   ? 2" + // Corn
    ": (b('cropland') == 3)   ? 2" + // Rice
    ": (b('cropland') == 4)   ? 2" + // Sorghum
    ": (b('cropland') == 21)  ? 2" + // Barley
    ": (b('cropland') == 22)  ? 2" + // Durum Wheat
    ": (b('cropland') == 23)  ? 2" + // Spring Wheat
    ": (b('cropland') == 24)  ? 2" + // Winter Wheat
    ": (b('cropland') == 25)  ? 2" + // Other Small Grains
    ": (b('cropland') == 27)  ? 2" + // Rye
    ": (b('cropland') == 28)  ? 2" + // Oats
    ": (b('cropland') == 29)  ? 2" + // Millet
    ": (b('cropland') == 30)  ? 2" + // Speltz
    ": (b('cropland') == 205) ? 2" + // Triticale
    ": (b('cropland') == 225) ? 2" + // Dbl Crop WinWht/Corn         [Tolerant + Tolerant]
    ": (b('cropland') == 226) ? 2" + // Dbl Crop Oats/Corn           [Tolerant + Tolerant]
    ": (b('cropland') == 228) ? 2" + // Dbl Crop Triticale/Corn      [Tolerant + Tolerant]
    ": (b('cropland') == 230) ? 2" + // Dbl Crop Lettuce/Durum Wht   [Tolerant > Vulnerable]
    ": (b('cropland') == 233) ? 2" + // Dbl Crop Lettuce/Barley      [Tolerant > Vulnerable]
    ": (b('cropland') == 234) ? 2" + // Dbl Crop Durum Wht/Sorghum   [Tolerant + Tolerant]
    ": (b('cropland') == 235) ? 2" + // Dbl Crop Barley/Sorghum      [Tolerant + Tolerant]
    ": (b('cropland') == 236) ? 2" + // Dbl Crop WinWht/Sorghum      [Tolerant + Tolerant]
    ": (b('cropland') == 237) ? 2" + // Dbl Crop Barley/Corn         [Tolerant + Tolerant]

    // 3: VULNERABLE = All other FSA-defined agricultural codes
    ": (b('cropland') == 6)   ? 3" + // Sunflower (oilseed, not a true cereal)
    ": (b('cropland') == 10)  ? 3" + // Peanuts
    ": (b('cropland') == 11)  ? 3" + // Tobacco
    ": (b('cropland') == 12)  ? 3" + // Sweet Corn
    ": (b('cropland') == 13)  ? 3" + // Pop or Orn Corn
    ": (b('cropland') == 14)  ? 3" + // Mint
    ": (b('cropland') == 31)  ? 3" + // Canola
    ": (b('cropland') == 32)  ? 3" + // Flaxseed
    ": (b('cropland') == 33)  ? 3" + // Safflower
    ": (b('cropland') == 34)  ? 3" + // Rape Seed
    ": (b('cropland') == 35)  ? 3" + // Mustard
    ": (b('cropland') == 36)  ? 3" + // Alfalfa
    ": (b('cropland') == 37)  ? 3" + // Other Hay/Non Alfalfa
    ": (b('cropland') == 38)  ? 3" + // Camelina
    ": (b('cropland') == 39)  ? 3" + // Buckwheat
    ": (b('cropland') == 41)  ? 3" + // Sugarbeets
    ": (b('cropland') == 42)  ? 3" + // Dry Beans
    ": (b('cropland') == 43)  ? 3" + // Potatoes
    ": (b('cropland') == 44)  ? 3" + // Other Crops
    ": (b('cropland') == 45)  ? 3" + // Sugarcane
    ": (b('cropland') == 46)  ? 3" + // Sweet Potatoes
    ": (b('cropland') == 47)  ? 3" + // Misc Vegs & Fruits
    ": (b('cropland') == 48)  ? 3" + // Watermelons
    ": (b('cropland') == 49)  ? 3" + // Onions
    ": (b('cropland') == 50)  ? 3" + // Cucumbers
    ": (b('cropland') == 51)  ? 3" + // Chick Peas
    ": (b('cropland') == 52)  ? 3" + // Lentils
    ": (b('cropland') == 53)  ? 3" + // Peas
    ": (b('cropland') == 54)  ? 3" + // Tomatoes
    ": (b('cropland') == 55)  ? 3" + // Caneberries
    ": (b('cropland') == 56)  ? 3" + // Hops
    ": (b('cropland') == 57)  ? 3" + // Herbs
    ": (b('cropland') == 58)  ? 3" + // Clover/Wildflowers
    ": (b('cropland') == 59)  ? 3" + // Sod/Grass Seed
    ": (b('cropland') == 60)  ? 3" + // Switchgrass
    ": (b('cropland') == 66)  ? 3" + // Cherries
    ": (b('cropland') == 67)  ? 3" + // Peaches
    ": (b('cropland') == 68)  ? 3" + // Apples
    ": (b('cropland') == 69)  ? 3" + // Grapes
    ": (b('cropland') == 70)  ? 3" + // Christmas Trees
    ": (b('cropland') == 71)  ? 3" + // Other Tree Crops
    ": (b('cropland') == 72)  ? 3" + // Citrus
    ": (b('cropland') == 74)  ? 3" + // Pecans
    ": (b('cropland') == 75)  ? 3" + // Almonds
    ": (b('cropland') == 76)  ? 3" + // Walnuts
    ": (b('cropland') == 77)  ? 3" + // Pears
    ": (b('cropland') == 92)  ? 3" + // Aquaculture
    ": (b('cropland') == 204) ? 3" + // Pistachios
    ": (b('cropland') == 206) ? 3" + // Carrots
    ": (b('cropland') == 207) ? 3" + // Asparagus
    ": (b('cropland') == 208) ? 3" + // Garlic
    ": (b('cropland') == 209) ? 3" + // Cantaloupes
    ": (b('cropland') == 210) ? 3" + // Prunes
    ": (b('cropland') == 211) ? 3" + // Olives
    ": (b('cropland') == 212) ? 3" + // Oranges
    ": (b('cropland') == 213) ? 3" + // Honeydew Melons
    ": (b('cropland') == 214) ? 3" + // Broccoli
    ": (b('cropland') == 215) ? 3" + // Avocados
    ": (b('cropland') == 216) ? 3" + // Peppers
    ": (b('cropland') == 217) ? 3" + // Pomegranates
    ": (b('cropland') == 218) ? 3" + // Nectarines
    ": (b('cropland') == 219) ? 3" + // Greens
    ": (b('cropland') == 220) ? 3" + // Plums
    ": (b('cropland') == 221) ? 3" + // Strawberries
    ": (b('cropland') == 222) ? 3" + // Squash
    ": (b('cropland') == 223) ? 3" + // Apricots
    ": (b('cropland') == 224) ? 3" + // Vetch
    ": (b('cropland') == 227) ? 3" + // Lettuce
    ": (b('cropland') == 229) ? 3" + // Pumpkins
    ": (b('cropland') == 231) ? 3" + // Dbl Crop Lettuce/Cantaloupe [Vulnerable + Vulnerable]
    ": (b('cropland') == 242) ? 3" + // Blueberries
    ": (b('cropland') == 243) ? 3" + // Cabbage
    ": (b('cropland') == 244) ? 3" + // Cauliflower
    ": (b('cropland') == 245) ? 3" + // Celery
    ": (b('cropland') == 246) ? 3" + // Radishes
    ": (b('cropland') == 247) ? 3" + // Turnips
    ": (b('cropland') == 248) ? 3" + // Eggplants
    ": (b('cropland') == 249) ? 3" + // Gourds
    ": (b('cropland') == 250) ? 3" + // Cranberries

    // 0: NON-CROP
    ": 0"
  );
};

/////////////////////////////////
// APPLY CLASSIFICATION TO EACH YEAR
/////////////////////////////////
var classifiedLayers = {};

var makeClassifiedLayer = function(year) {
  var image = cdlsLayers[year]; 
  var classified = classifyPixel(image).rename('category');
  Map.addLayer(classified, {
    min: 0, max: 3,
    palette: ['grey',     // 0 = non-crop (grey)
              'pink',     // 1 = GM-enabled (pink)
              'yellow',   // 2 = Tolerant (yellow)
              'green'     // 3 = Vulnerable (green)
             ]
  }, 'Classified ' + year, false);
  classifiedLayers[year] = classified;
};

makeClassifiedLayer(2009);
makeClassifiedLayer(2010);
makeClassifiedLayer(2011);
makeClassifiedLayer(2012);
makeClassifiedLayer(2013);
makeClassifiedLayer(2014);
makeClassifiedLayer(2015);
makeClassifiedLayer(2016);
makeClassifiedLayer(2017);
makeClassifiedLayer(2018);
/////////////////////////////////
// EXPLORATORY: Surface of problematic double crops
/////////////////////////////////

var cdl2017 = ee.Image("USDA/NASS/CDL/2017").select('cropland');

// Create a mask of ONLY the 3 problematic codes
var problematicMask = cdl2017.eq(230)
  .or(cdl2017.eq(232))
  .or(cdl2017.eq(233));

// How many problematic pixels. 

var pixelCount = problematicMask.reduceRegion({
  reducer: ee.Reducer.sum(),
  geometry: ee.Geometry.Rectangle([-125, 24, -66, 50]),
  scale: 500000, // Running at 30m scale is long so I run it once and then
                // set the number higher just so the whole code run more smoothly.
                // Set back to 30m if you want to check the value.
  maxPixels: 1e13
});
print('Count at 30m scale (problematic double crop pixels):', pixelCount);

// Result: 43320 pixels.
// That is 43,320 × (30 × 30) = 43,320 × 900m^2 = 38,988,000 m² \approx = 39 km².
// This corresponds to \approx 9,600 acres.
// We are not doing the computation for total pixel of agricultural land here as it
// would be very heavy. However, in 2017, 390 million acres of agricultural land
// were in cropland (https://www.ers.usda.gov/data-products/chart-gallery/chart-detail?chartId=58260).

// Hence we get that it represents approximately 0,0025% of US agricultural land
// (9.600/390,000,000).
// Therefore, our priority rule is negligible. 
//////////////////////////////////
/////////////////////////////////


/////////////////////////////////
// TRANSITION MATRIX APPROACHES

// Four approaches were explored to compute transition matrices.
// All are too computationally heavy (token restriction).
// The pipeline was therefore moved to R,
// using CDL files downloaded directly from the CDL website, and using TSE HPC Cluster. 

// Approaches summary:
//  1. National frequencyHistogram
//    — One reduceRegion() over full US geometry but too slow, timeout at national scale.

//  2. County frequencyHistogram
//    — ReduceRegions() per county, parallelised but still timeout/very slow.

//  3. County binary sum
//    - One reduceRegions() per transition pair (x 16 exports) per year (x10)
//    - Generates too many export jobs, timeout.

//  4. Export already classified county and do the transition matrices in R.
//    - Epprox. 30k exports (3000 counties x 10 years)
//    - GEE export queue limit. 

// NOTE: All function calls are commented out to prevent timeout on load.
/////////////////////////////////


/////////////////////////////////
// APPROACH 1: National frequencyHistogram
// Encodes all 16 transitions as a single integer (from*4 + to),
// then counts pixel frequencies over the full US geometry in one pass.
// Exports one single-row CSV per year pair.
/////////////////////////////////

var us = ee.FeatureCollection("TIGER/2016/States")
  .filter(ee.Filter.neq('STATEFP', '02'))  // exclude Alaska
  .filter(ee.Filter.neq('STATEFP', '15')); // exclude Hawaii

var usGeometry = us.geometry();

var makeTransitionMatrix_national = function(year_from, year_to) {

  var yearsID = String(year_from) + String(year_to);

  var stacked = classifiedLayers[year_from]
    .rename('from_type')
    .addBands(classifiedLayers[year_to].rename('to_type'));

  // Encode all 16 transitions as a single integer
  var transition = stacked.expression("b('from_type') * 4 + b('to_type')");

  // Count all 16 transitions in one pass over the full US
  var matrix = transition.reduceRegion({
    reducer: ee.Reducer.frequencyHistogram(),
    geometry: usGeometry,
    scale: 30,
    maxPixels: 1e13
  });

  var feature = ee.Feature(null, matrix);
  Export.table.toDrive({
    collection: ee.FeatureCollection([feature]),
    description: 'TM_national_' + yearsID,
    folder: 'Dicamba/TransitionMatrix',
    fileFormat: 'CSV'
  });
};

//makeTransitionMatrix_national(2009, 2010);
//makeTransitionMatrix_national(2010, 2011);
//makeTransitionMatrix_national(2011, 2012);
//makeTransitionMatrix_national(2012, 2013);
//makeTransitionMatrix_national(2013, 2014);
//makeTransitionMatrix_national(2014, 2015);
//makeTransitionMatrix_national(2015, 2016);
//makeTransitionMatrix_national(2016, 2017);
//makeTransitionMatrix_national(2017, 2018);


/////////////////////////////////
// APPROACH 2: County frequencyHistogram (parallelised)
// Same encoding as approach 1, but runs reduceRegions() over all counties
// instead of one reduceRegion() over the full US.
// Exports one row per county per year pair. Total work is the same as Approach 1  but,
// separately smaller so might avoid "timeout".
/////////////////////////////////

var counties = ee.FeatureCollection("TIGER/2016/Counties");

var makeTransitionMatrix_county = function(year_from, year_to) {

  var yearsID = String(year_from) + String(year_to);

  var stacked = classifiedLayers[year_from]
    .rename('from_type')
    .addBands(classifiedLayers[year_to].rename('to_type'));

  var transition = stacked.expression("b('from_type') * 4 + b('to_type')");

  var countyMatrix = transition.reduceRegions({
    collection: counties,
    reducer: ee.Reducer.frequencyHistogram(),
    scale: 30,
    tileScale: 16
  });

  Export.table.toDrive({
    collection: countyMatrix,
    description: 'TM_county_histogram_' + yearsID,
    folder: 'Dicamba/TransitionMatrix',
    fileFormat: 'CSV'
  });
};

//makeTransitionMatrix_county(2009, 2010);
//makeTransitionMatrix_county(2010, 2011);
//makeTransitionMatrix_county(2011, 2012);
//makeTransitionMatrix_county(2012, 2013);
//makeTransitionMatrix_county(2013, 2014);
//makeTransitionMatrix_county(2014, 2015);
//makeTransitionMatrix_county(2015, 2016);
//makeTransitionMatrix_county(2016, 2017);
//makeTransitionMatrix_county(2017, 2018);


/////////////////////////////////
// APPROACH 3: County binary sum (one export per transition pair)
// For each of the 16 (from, to) combinations, creates a binary image
// (1 where the transition occurred, 0 elsewhere) and sums it per county.
// Generates 16 separate export jobs per year pair (16 x 9 = 144 total).
/////////////////////////////////

var makeTransition_binary = function(year_from, year_to, cat_from, cat_to) {

  var yearsID   = String(year_from) + String(year_to);
  var catLabels = {0: 'NC', 1: 'GM', 2: 'Tol', 3: 'Vul'};
  var transID   = catLabels[cat_from] + '_to_' + catLabels[cat_to];

  // Binary image: 1 where pixel = cat_from in year_from AND cat_to in year_to
  var transition = classifiedLayers[year_to].eq(cat_to)
    .multiply(classifiedLayers[year_from].eq(cat_from));

  var countyTransition = transition.reduceRegions({
    collection: counties,
    reducer: ee.Reducer.sum(),
    scale: 30,
    tileScale: 16
  });

  Export.table.toDrive({
    collection: countyTransition,
    description: 'TM_' + transID + '_' + yearsID,
    folder: 'Dicamba/TransitionMatrix',
    fileFormat: 'CSV'
  });
};

// Avoiding to call 144 times the function: runs all 16 transition pairs for a given year pair
var makeFullMatrix_binary = function(year_from, year_to) {
  [0,1,2,3].forEach(function(from) {
    [0,1,2,3].forEach(function(to) {
      makeTransition_binary(year_from, year_to, from, to);
    });
  });
};

//makeFullMatrix_binary(2009, 2010);
//makeFullMatrix_binary(2010, 2011);
//makeFullMatrix_binary(2011, 2012);
//makeFullMatrix_binary(2012, 2013);
//makeFullMatrix_binary(2013, 2014);
//makeFullMatrix_binary(2014, 2015);
//makeFullMatrix_binary(2015, 2016);
//makeFullMatrix_binary(2016, 2017);
//makeFullMatrix_binary(2017, 2018);

/////////////////////////////////
// TEST of Approach 3 on smaller sample and single transition: Cook County (GEOID 17031) + vul to vul.
// Used to validate approach 3 on a single county before scaling up.
// Exports a pixel-level CSV.
/////////////////////////////////

var testCounty = counties.filter(ee.Filter.eq('GEOID', '17031'));

// Test approach 3 (binary sum) on the Vul to Vul transition only
var transition_test = classifiedLayers[2010].eq(3)
  .multiply(classifiedLayers[2009].eq(3));

var countyTransition_test = transition_test.reduceRegions({
  collection: testCounty,
  reducer: ee.Reducer.sum(),
  scale: 30,
  tileScale: 16
});

Export.table.toDrive({
  collection: countyTransition_test,
  description: 'Test_TM_Vul_to_Vul_County17031_20092010',
  folder: 'Dicamba_Test',
  fileFormat: 'CSV'
});


/////////////////////////////////
// Approach 4: Export each county's pixel classification and do transition matrices in R.
// Test with a single county first
/////////////////////////////////

var testCounty = counties.filter(ee.Filter.eq('GEOID', '17031'));

// Export pixel-level CSV for manual category counts
var countyPixels = classifiedLayers[2009].sampleRegions({
  collection: testCounty,
  scale: 30,
  geometries: false
});

Export.table.toDrive({
  collection: countyPixels,
  description: 'Test_County17031_2009_CSV',
  folder: 'Dicamba_Test',
  fileFormat: 'CSV'
});

/////////////////////////////////
// VALIDATION — Projection check (Rhode Island, 2009)
// Compares pixel counts in GEE with R output to verify projection consistency.
// Identified a mismatch caused by GEE defaulting to WGS84 in reduceRegion().
// Fixed by explicitly passing crs: cdl2009.projection().
// See DOCS/notes/use_of_projection.md for full explanation.
/////////////////////////////////

// Union mask restricted to 2009-2010 only (to match the R test pipeline)
var everCultivated_0910 = mask2009.or(mask2010);
var masked_0910 = classifiedLayers[2009].updateMask(everCultivated_0910);

var ri = ee.FeatureCollection("TIGER/2016/States")
  .filter(ee.Filter.eq('NAME', 'Rhode Island'));

var cdl2009 = ee.Image("USDA/NASS/CDL/2009");

// Print native CDL projection for reference
print('CDL 2009 native projection:', cdl2009.projection());

// Count pixels using native CDL projection (matches R output)
var counts_native = masked_0910.reduceRegion({
  reducer: ee.Reducer.frequencyHistogram(),
  geometry: ri.geometry(),
  scale: 30,
  crs: cdl2009.projection(),  // match native CDL projection (GEE default is WGS84)
  maxPixels: 1e9
});

// Count pixels using GEE default projection (do not match R output)
var counts_default = masked_0910.reduceRegion({
  reducer: ee.Reducer.frequencyHistogram(),
  geometry: ri.geometry(),
  scale: 30,  
  maxPixels: 1e9
});

print('RI 2009 counts (native CDL projection):', counts_native);
print('RI 2009 counts (GEE default projection):', counts_default);
