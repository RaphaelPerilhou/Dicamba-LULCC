// Monday 18/09/2026
var cdls = ee.ImageCollection("USDA/NASS/CDL"); 

/////////////////////////////////
// AG MASK
// Function to create AG mask for each year. 
// Note: Before 2013 the 'cultivated' band did not exist. Hence, we look if it's either of cropland type.
/////////////////////////////////
var makeMask = function(year) {
  if (year <= 2012) {
     return ee.Image("USDA/NASS/CDL/" + year)
  .select('cropland')
  .expression(                  // source: https://www.nass.usda.gov/Research_and_Science/Cropland/metadata/year_cultivated_layer_metadata.php
"(b('cropland') == 1) ? 1" + 
": (b('cropland') == 2) ? 1" + 
": (b('cropland') == 3) ? 1" + 
": (b('cropland') == 4) ? 1" + 
": (b('cropland') == 5) ? 1" + 
": (b('cropland') == 6) ? 1" + 
": (b('cropland') == 10) ? 1" + 
": (b('cropland') == 11) ? 1" + 
": (b('cropland') == 12) ? 1" + 
": (b('cropland') == 13) ? 1" + 
": (b('cropland') == 14) ? 1" + 
": (b('cropland') == 21) ? 1" + 
": (b('cropland') == 22) ? 1" + 
": (b('cropland') == 23) ? 1" + 
": (b('cropland') == 24) ? 1" + 
": (b('cropland') == 25) ? 1" + 
": (b('cropland') == 26) ? 1" + 
": (b('cropland') == 27) ? 1" + 
": (b('cropland') == 28) ? 1" + 
": (b('cropland') == 29) ? 1" + 
": (b('cropland') == 30) ? 1" + 
": (b('cropland') == 31) ? 1" + 
": (b('cropland') == 32) ? 1" + 
": (b('cropland') == 33) ? 1" + 
": (b('cropland') == 34) ? 1" + 
": (b('cropland') == 35) ? 1" + 
": (b('cropland') == 36) ? 1" + 
": (b('cropland') == 38) ? 1" + 
": (b('cropland') == 39) ? 1" + 
": (b('cropland') == 41) ? 1" + 
": (b('cropland') == 42) ? 1" + 
": (b('cropland') == 43) ? 1" + 
": (b('cropland') == 44) ? 1" + 
": (b('cropland') == 45) ? 1" + 
": (b('cropland') == 46) ? 1" + 
": (b('cropland') == 47) ? 1" + 
": (b('cropland') == 48) ? 1" + 
": (b('cropland') == 49) ? 1" + 
": (b('cropland') == 50) ? 1" + 
": (b('cropland') == 51) ? 1" + 
": (b('cropland') == 52) ? 1" + 
": (b('cropland') == 53) ? 1" + 
": (b('cropland') == 54) ? 1" + 
": (b('cropland') == 55) ? 1" + 
": (b('cropland') == 56) ? 1" + 
": (b('cropland') == 57) ? 1" + 
": (b('cropland') == 58) ? 1" + 
": (b('cropland') == 61) ? 1" + 
": (b('cropland') == 66) ? 1" + 
": (b('cropland') == 67) ? 1" + 
": (b('cropland') == 68) ? 1" + 
": (b('cropland') == 69) ? 1" + 
": (b('cropland') == 70) ? 1" + 
": (b('cropland') == 71) ? 1" + 
": (b('cropland') == 72) ? 1" + 
": (b('cropland') == 74) ? 1" + 
": (b('cropland') == 75) ? 1" + 
": (b('cropland') == 76) ? 1" + 
": (b('cropland') == 77) ? 1" + 
": (b('cropland') == 204) ? 1" + 
": (b('cropland') == 205) ? 1" + 
": (b('cropland') == 206) ? 1" + 
": (b('cropland') == 207) ? 1" + 
": (b('cropland') == 208) ? 1" + 
": (b('cropland') == 209) ? 1" + 
": (b('cropland') == 210) ? 1" + 
": (b('cropland') == 211) ? 1" + 
": (b('cropland') == 212) ? 1" + 
": (b('cropland') == 213) ? 1" + 
": (b('cropland') == 214) ? 1" + 
": (b('cropland') == 216) ? 1" + 
": (b('cropland') == 217) ? 1" + 
": (b('cropland') == 218) ? 1" + 
": (b('cropland') == 219) ? 1" + 
": (b('cropland') == 220) ? 1" + 
": (b('cropland') == 221) ? 1" + 
": (b('cropland') == 222) ? 1" + 
": (b('cropland') == 223) ? 1" + 
": (b('cropland') == 224) ? 1" + 
": (b('cropland') == 225) ? 1" + 
": (b('cropland') == 226) ? 1" + 
": (b('cropland') == 227) ? 1" + 
": (b('cropland') == 229) ? 1" + 
": (b('cropland') == 230) ? 1" + 
": (b('cropland') == 231) ? 1" + 
": (b('cropland') == 232) ? 1" + 
": (b('cropland') == 233) ? 1" + 
": (b('cropland') == 234) ? 1" + 
": (b('cropland') == 235) ? 1" + 
": (b('cropland') == 236) ? 1" + 
": (b('cropland') == 237) ? 1" + 
": (b('cropland') == 238) ? 1" + 
": (b('cropland') == 239) ? 1" + 
": (b('cropland') == 240) ? 1" + 
": (b('cropland') == 241) ? 1" + 
": (b('cropland') == 242) ? 1" + 
": (b('cropland') == 243) ? 1" + 
": (b('cropland') == 244) ? 1" + 
": (b('cropland') == 245) ? 1" + 
": (b('cropland') == 246) ? 1" + 
": (b('cropland') == 247) ? 1" + 
": (b('cropland') == 248) ? 1" + 
": (b('cropland') == 249) ? 1" + 
": (b('cropland') == 250) ? 1" + 
": (b('cropland') == 254) ? 1" + 
": 0");
// } else if (year === 2018) { return cdls .filterDate('2018-01-01', '2018-12-31') .select('cultivated_land').first() .eq(2)
}
else {
  return ee.Image("USDA/NASS/CDL/"+ year)
  .select('cultivated')
  .eq(2); 
}}

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

// print(mask2018) // test

// Yearly CDLs, Masked 
// We add the croplands' layers.

var cdlsLayers = {}; //we create an empty list so we can store the objects. 

var makeCdlLayer = function(year, mask) {
  var image = ee.Image("USDA/NASS/CDL/" + year)
    .select('cropland')
    .updateMask(mask);
  Map.addLayer(image, {}, 'CDL ' + year, false);
  cdlsLayers[year] = image; //store for later use.
};

makeCdlLayer(2009, mask2009);
makeCdlLayer(2010, mask2010);
makeCdlLayer(2011, mask2011);
makeCdlLayer(2012, mask2012);
makeCdlLayer(2013, mask2013);
makeCdlLayer(2014, mask2014);
makeCdlLayer(2015, mask2015);
makeCdlLayer(2016, mask2016);
makeCdlLayer(2017, mask2017);
makeCdlLayer(2018, mask2018);

/////////////////////////////////
// ONE YEAR-ONE BAND IMAGE OF LCs
/////////////////////////////////
var blank = ee.Image(0);

var master = blank
  .addBands(cdlsLayers[2009])
  .addBands(cdlsLayers[2010])
  .addBands(cdlsLayers[2011])
  .addBands(cdlsLayers[2012])
  .addBands(cdlsLayers[2013])
  .addBands(cdlsLayers[2014])
  .addBands(cdlsLayers[2015])
  .addBands(cdlsLayers[2016])
  .addBands(cdlsLayers[2017])
  .addBands(cdlsLayers[2018])
  .select(['croplan.*'], ['cdls2009', 'cdls2010', 'cdls2011',
                          'cdls2012', 'cdls2013', 'cdls2014',
                          'cdls2015', 'cdls2016', 'cdls2017',
                          'cdls2018']);

Map.addLayer(master, {}, 'master', false);
print(master)

/////////////////////////////////
// PIXEL BY PIXEL CHANGE PROB
// The function depends on 3 paramaters: the years from which is the change,
// to the years it changed, and the direction from soybean/cotton or to soybean/cotton.
/////////////////////////////////

var changeFROM = {}
var changeTO = {}

var makeChange = function(year_from,year_to, direction){
  
  var yearsID = String(year_from) + String(year_to) //We need it to store the object in a more readable way.
  
  if (direction == 'to'){
   var changeTo = cdlsLayers[year_to].expression(
     "(b('cropland') == 2) ? 1" +        // select cotton (is cotton NOW)
    ": (b('cropland') == 5) ? 1" +      // select soybean (is soybean NOW)
    ": (b('cropland') == 26) ? 1" +     // Dbl Crop WinWht/Soybeans  
    ": (b('cropland') == 232) ? 1" +    // Dbl Crop Lettuce/Cotton     
    ": (b('cropland') == 238) ? 1" +    // Dbl Crop WinWht/Cotton
    ": (b('cropland') == 239) ? 1" +    // Dbl Crop Soybeans/Cotton
    ": (b('cropland') == 240) ? 1" +    // Dbl Crop Soybeans/Oats
    ": (b('cropland') == 241) ? 1" +    // Dbl Crop Corn/Soybeans
    ": (b('cropland') == 254) ? 1" +    // Dbl Crop Barley/Soybeans
          ": 0"
          )
        .multiply(cdlsLayers[year_from].expression(
     "(b('cropland') == 2) ? 0" +        // select cotton (is cotton NOW)
    ": (b('cropland') == 5) ? 0" +      // select soybean (is soybean NOW)
    ": (b('cropland') == 26) ? 0" +     // Dbl Crop WinWht/Soybeans  
    ": (b('cropland') == 232) ? 0" +    // Dbl Crop Lettuce/Cotton     
    ": (b('cropland') == 238) ? 0" +    // Dbl Crop WinWht/Cotton
    ": (b('cropland') == 239) ? 0" +    // Dbl Crop Soybeans/Cotton
    ": (b('cropland') == 240) ? 0" +    // Dbl Crop Soybeans/Oats
    ": (b('cropland') == 241) ? 0" +    // Dbl Crop Corn/Soybeans
    ": (b('cropland') == 254) ? 0" +    // Dbl Crop Barley/Soybeans
          ": 1"
       )
     )
  Map.addLayer(changeTo, {}, 'changeTO'+yearsID, false);
  changeTO[yearsID] = changeTo;
  }
  else if (direction == 'from') {
    var changeFrom = cdlsLayers[year_to].expression(
     "(b('cropland') == 2) ? 0" +        // select cotton (is cotton NOW)
    ": (b('cropland') == 5) ? 0" +      // select soybean (is soybean NOW)
    ": (b('cropland') == 26) ? 0" +     // Dbl Crop WinWht/Soybeans  
    ": (b('cropland') == 232) ? 0" +    // Dbl Crop Lettuce/Cotton     
    ": (b('cropland') == 238) ? 0" +    // Dbl Crop WinWht/Cotton
    ": (b('cropland') == 239) ? 0" +    // Dbl Crop Soybeans/Cotton
    ": (b('cropland') == 240) ? 0" +    // Dbl Crop Soybeans/Oats
    ": (b('cropland') == 241) ? 0" +    // Dbl Crop Corn/Soybeans
    ": (b('cropland') == 254) ? 0" +    // Dbl Crop Barley/Soybeans
          ": 1"
          )
        .multiply(cdlsLayers[year_from].expression(
     "(b('cropland') == 2) ? 1" +        // select cotton (is cotton NOW)
    ": (b('cropland') == 5) ? 1" +      // select soybean (is soybean NOW)
    ": (b('cropland') == 26) ? 1" +     // Dbl Crop WinWht/Soybeans  
    ": (b('cropland') == 232) ? 1" +    // Dbl Crop Lettuce/Cotton     
    ": (b('cropland') == 238) ? 1" +    // Dbl Crop WinWht/Cotton
    ": (b('cropland') == 239) ? 1" +    // Dbl Crop Soybeans/Cotton
    ": (b('cropland') == 240) ? 1" +    // Dbl Crop Soybeans/Oats
    ": (b('cropland') == 241) ? 1" +    // Dbl Crop Corn/Soybeans
    ": (b('cropland') == 254) ? 1" +    // Dbl Crop Barley/Soybeans
          ": 0"
       )
     )
  Map.addLayer(changeFrom, {}, 'changeFROM'+yearsID, false);
  changeFROM[yearsID] = changeFrom;
  }
  else {
    print("Invalid direction parameters: please write 'from' or 'to'. ")
  }
}

//Change X to soybean/cotton
makeChange(2009,2010, 'to')
makeChange(2010,2011, 'to')
makeChange(2011,2012, 'to')
makeChange(2012,2013, 'to')
makeChange(2013,2014, 'to')
makeChange(2014,2015, 'to')
makeChange(2015,2016, 'to')
makeChange(2016,2017, 'to')
makeChange(2017,2018, 'to')

//Change from soybean/cotton to X
makeChange(2009,2010, 'from')
makeChange(2010,2011, 'from')
makeChange(2011,2012, 'from')
makeChange(2012,2013, 'from')
makeChange(2013,2014, 'from')
makeChange(2014,2015, 'from')
makeChange(2015,2016, 'from')
makeChange(2016,2017, 'from')
makeChange(2017,2018, 'from')

/////////////////////////////////
// AGGREGATE BY COUNTY
/////////////////////////////////
var counties = ee.FeatureCollection("TIGER/2016/Counties");
Map.addLayer(counties, {}, 'counties', false); 

var makeChangeCounty = function(year_from, year_to, direction){
  
  var yearsID = String(year_from) + String(year_to);
  
  if (direction == 'to'){
    var ChangeCountyTo = changeTO[yearsID].reduceRegions({
      reducer: ee.Reducer.sum(),
      collection: counties,
      scale: 30
    }).select(['.*'],null, false);
    
    Export.table.toDrive({
      collection: ChangeCountyTo,
      description: 'changesByCounty'+yearsID+'_toSoyCot',
      folder: 'Dicamba/CDLchanges/ToSoyCott',
      fileFormat: 'CSV'
    });
  }
  
  else if (direction == 'from'){
    var ChangeCountyFrom = changeFROM[yearsID].reduceRegions({
      reducer: ee.Reducer.sum(),
      collection: counties,
      scale: 30
    }).select(['.*'],null, false);
    
    Export.table.toDrive({
      collection: ChangeCountyFrom,
      description: 'changesByCounty'+yearsID+'_fromSoyCot',
      folder: 'Dicamba/CDLchanges/FromSoyCott',
      fileFormat: 'CSV'
    });
  }
  else {
    print("Invalid direction parameters: please write 'from' or 'to'. ")
  }
}

//Call the function: X to Soybean/Cotton:
makeChangeCounty(2009,2010, 'to')
makeChangeCounty(2010,2011, 'to')
makeChangeCounty(2011,2012, 'to')
makeChangeCounty(2012,2013, 'to')
makeChangeCounty(2013,2014, 'to')
makeChangeCounty(2014,2015, 'to')
makeChangeCounty(2015,2016, 'to')
makeChangeCounty(2016,2017, 'to')
makeChangeCounty(2017,2018, 'to')

//Call the function: from Soybean/Cotton to X

makeChangeCounty(2009,2010, 'from')
makeChangeCounty(2010,2011, 'from')
makeChangeCounty(2011,2012, 'from')
makeChangeCounty(2012,2013, 'from')
makeChangeCounty(2013,2014, 'from')
makeChangeCounty(2014,2015, 'from')
makeChangeCounty(2015,2016, 'from')
makeChangeCounty(2016,2017, 'from')
makeChangeCounty(2017,2018, 'from')
