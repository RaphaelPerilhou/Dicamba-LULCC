# This script verifies that all CDL-mapped Census commodities are available at the
# county level in the 2012 Census of Agriculture, resolves ambiguous short_desc
# (e.g. subcategories to sum), and outputs the final area dataset and short_desc mapping.

rm(list = ls())
library(tidyverse)
library(readxl)
library(data.table)

# Large, we use data.table
census <- fread("data/qs.census2012.txt", sep = "\t", quote = "")

colnames(census)

availability <- census[
  SOURCE_DESC == "CENSUS" &
    AGG_LEVEL_DESC == "COUNTY" &
    YEAR == 2012 &
    DOMAIN_DESC == "TOTAL"
][, .(
  GEOID = sprintf("%02d%03d", STATE_FIPS_CODE, COUNTY_CODE),
  county_name = COUNTY_NAME,
  state_fips = STATE_FIPS_CODE,
  commodity = COMMODITY_DESC,
  statisticcat = STATISTICCAT_DESC,
  short_desc = SHORT_DESC,
  value = VALUE
)]


#Check we have all counties:
county_lookup <- read.csv("data/county_lookup.csv", stringsAsFactors = FALSE)

# Pad county_lookup GEOIDs to 5 characters to match availability
county_lookup$GEOID_padded <- sprintf("%05d", as.integer(county_lookup$GEOID))

missing_geoids <- setdiff(
  county_lookup$GEOID_padded,
  unique(availability$GEOID)
)
length(missing_geoids)

# See which counties they are
county_lookup[county_lookup$GEOID_padded %in% missing_geoids, ]

#Then for them we cannot correct because no "SCORE" possible, but looking at LSAD
#we can see they are all independent cities or DC, so no really farmlands, maybe we
#can exclude them from the analysis.

#Keep only contiguous state counties.
states_sf <- readRDS("data/SF/states_2016.rds")

contiguous_statefps <- states_sf %>%
  sf::st_drop_geometry() %>%
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) %>%
  pull(STATEFP)

availability_clean <- availability[GEOID %in% county_lookup$GEOID_padded]

# check
uniqueN(availability_clean$GEOID)

# check different statistics
unique(availability_clean$statisticcat)

# we keep only AREA related stats
keep_stats <- c(
  "AREA HARVESTED",
  "AREA BEARING",
  "AREA NON-BEARING",
  "AREA BEARING & NON-BEARING",
  "AREA IN PRODUCTION",
  "AREA GROWN",
  "AREA NOT HARVESTED",
  "AREA"
)

availability_clean <- availability_clean[statisticcat %in% keep_stats]

length(setdiff(county_lookup$GEOID_padded, unique(availability_clean$GEOID))) #still 38 counties missing (independent cities mostly)
#####
# Check if it's ok to use `BEARING & NON-BEARING`
#####
#compare bearing vs bearing & non-bearing
available_bearing <- availability_clean[statisticcat == "AREA BEARING"]
available_bea_nonbea <- availability_clean[
  statisticcat == "AREA BEARING & NON-BEARING"
]

intersect(
  unique(available_bearing$commodity),
  unique(available_bea_nonbea$commodity)
)
setdiff(
  unique(available_bearing$commodity),
  unique(available_bea_nonbea$commodity)
)
#commodities with stats == bearing are also having the stat == bearing & non bearing
setdiff(
  unique(available_bea_nonbea$commodity),
  unique(available_bearing$commodity)
)
#Orchards is available with the stat == bearing & non-bearing but not with stat == bearing

#check for `HARVESTED`
available_harvested <- availability_clean[statisticcat == "AREA HARVESTED"]
unique(available_harvested$commodity)

#####
# Check for two counties if everything is available:
#####
fresno <- availability_clean[GEOID == "06019"] # Fresno (California)
story <- availability_clean[GEOID == "19169"] # Story (Iowa)

# What each has
unique(fresno$commodity)
unique(story$commodity)

# Direct comparison
in_both <- intersect(unique(fresno$commodity), unique(story$commodity))
fresno_only <- setdiff(unique(fresno$commodity), unique(story$commodity))
story_only <- setdiff(unique(story$commodity), unique(fresno$commodity))

cat("In both: ", length(in_both), "\n")
cat("Fresno only:  ", length(fresno_only), "\n")
cat("Story only:   ", length(story_only))

fresno_only
story_only

#Is the difference because not available in the census or not available in real, like different culture ?
#We can trust CENSUS, and have no way to check anyway. Hence, if not available, we assume it's just because no land of category X.

#####
# Check the dictionary CENSUS categories are all available with our STATS of interest
#####
cdl_census_map <- read_excel(
  "data/metadata/CDL_CENSUS_MAP.xlsx",
  sheet = "Sheet1"
)

census_commodities_in_map <- cdl_census_map %>%
  pull(`Census Commodity`) %>%
  na.omit() %>%
  unique() %>%
  sort()

check_coverage <- function(stat_cats, label) {
  relevant <- availability_clean[
    statisticcat %in%
      stat_cats &
      grepl(
        "ACRES HARVESTED$|ACRES BEARING & NON-BEARING$|ACRES IN PRODUCTION$",
        short_desc
      ) &
      !grepl("IRRIGATED", short_desc)
  ]
  missing <- setdiff(census_commodities_in_map, unique(relevant$commodity))
  cat("\n", label, "\n")
  if (length(missing) == 0) {
    cat("All covered\n")
  } else {
    cat("Missing (", length(missing), "):\n", paste0("  - ", missing, "\n"))
  }
}

check_coverage(
  c("AREA HARVESTED", "AREA BEARING & NON-BEARING"),
  c("AREA HARVESTED", "AREA BEARING & NON-BEARING")
)
unique(availability_clean[commodity == "CUT CHRISTMAS TREES", short_desc])
#FOR CUT CHRISTMAS TREES, we will take"CUT CHRISTMAS TREES - ACRES IN PRODUCTION"

###### THIS IS NOT USED ANYMORE, AS WE MODIFIED THE EXCEL FILE THANKS TO THE CODE.
#SMALL GRAINS not available on CENSUS with those stats.
#quick check if available for "NON-BEARING".
#available_nonbea <- availability_clean[statisticcat=="AREA NON-BEARNING"]
#check_coverage(
#  union(union(unique(available_harvested$commodity), unique(available_bea_nonbea$commodity)), unique(available_nonbea$commodity)),
#  "AREA HARVESTED | BEARING & NON-BEARING | NON-BEARING"
#)
#Ok, then we look which stat is available for SMALL GRAINS.
#available_smallgrains <- census[COMMODITY_DESC == "SMALL GRAINS"]
#unique(available_smallgrains$COUNTY_CODE) #NA for county, we can't use it.
######

# save
write.csv(
  availability_clean,
  "outputs/county_census_check/census_stats_availability.csv",
  row.names = FALSE
)

####
# Check that the most aggregated version is available
####
target_commodities <- census_commodities_in_map

area_stats <- availability_clean[
  statisticcat %in%
    c("AREA HARVESTED", "AREA BEARING & NON-BEARING", "AREA IN PRODUCTION") &
    grepl(
      "ACRES HARVESTED$|ACRES BEARING & NON-BEARING$|ACRES IN PRODUCTION$",
      short_desc
    ) &
    !grepl("IRRIGATED", short_desc)
]

#check that we don't loose counties in addition of the 37 independent cities + DC
length(setdiff(unique(county_lookup$GEOID_padded), unique(area_stats$GEOID))) #44 ? 6 more, which ones ?
missing_county_areastat <- setdiff(
  unique(county_lookup$GEOID_padded),
  unique(area_stats$GEOID)
)
county_lookup[
  county_lookup$GEOID_padded %in%
    missing_county_areastat &
    !county_lookup$GEOID_padded %in% missing_geoids,
]

#We know the counties we loose are because the statisticcat is not available. For manual check, we can go acrros all counties:
#8111
geoid8111 <- census[
  census$STATE_FIPS_CODE == 8 &
    census$COUNTY_CODE == 111
] #Only total land area measure, not crop.
#26083
geoid26083 <- census[
  census$STATE_FIPS_CODE == 26 &
    census$COUNTY_CODE == 083
]
unique(geoid26083$STATISTICCAT_DESC) #No measure of interest
#....

has_aggregated <- sapply(target_commodities, function(com) {
  patterns <- paste0("^", com, " - ACRES (HARVESTED|BEARING & NON-BEARING)$")
  any(grepl(patterns, area_stats[commodity == com, short_desc]))
})

for (com in target_commodities[!has_aggregated]) {
  cat(" -", com, "\n")
}

#BEANS
unique(area_stats[commodity == "BEANS", short_desc])

#SUM:
# "BEANS, SNAP - ACRES HARVESTED"
# "BEANS, GREEN, LIMA - ACRES HARVESTED"
# "BEANS, DRY EDIBLE, (EXCL LIMA) - ACRES HARVESTED"
# "BEANS, DRY EDIBLE, LIMA - ACRES HARVESTED"

#BLUEBERRIES
unique(area_stats[commodity == "BLUEBERRIES", short_desc])
#SUM:
# "BLUEBERRIES, TAME - ACRES HARVESTED"
# "BLUEBERRIES, WILD - ACRES HARVESTED"

#CABBAGE
unique(area_stats[commodity == "CABBAGE", short_desc])
#SUM:
# "CABBAGE, HEAD - ACRES HARVESTED"
# "CABBAGE, CHINESE - ACRES HARVESTED"
# "CABBAGE, MUSTARD - ACRES HARVESTED"

#CHERRIES
unique(area_stats[commodity == "CHERRIES", short_desc])
#SUM:
# "CHERRIES, TART - ACRES BEARING & NON-BEARING"
# "CHERRIES, SWEET - ACRES BEARING & NON-BEARING"

#CORN
unique(area_stats[commodity == "CORN", short_desc])
#SUM:
# "CORN, GRAIN - ACRES HARVESTED"
# "CORN, SILAGE - ACRES HARVESTED"

#CUT CHRISTMAS TREES
unique(area_stats[commodity == "CUT CHRISTMAS TREES", short_desc])
#Only one, we use the "CUT CHRISTMAS TREES - ACRES IN PRODUCTION"

#GREENS
unique(area_stats[commodity == "GREENS", short_desc])
#SUM:
# "GREENS, TURNIP - ACRES HARVESTED"
# "GREENS, COLLARD - ACRES HARVESTED"
# "GREENS, MUSTARD - ACRES HARVESTED"
# "GREENS, KALE - ACRES HARVESTED"

#HERBS
unique(area_stats[commodity == "HERBS", short_desc])
#SUM:
# "HERBS, FRESH CUT - ACRES HARVESTED"
# "HERBS, DRY - ACRES HARVESTED"

#MELONS
unique(area_stats[commodity == "MELONS", short_desc])
#SUM:
# "MELONS, CANTALOUP - ACRES HARVESTED"
# "MELONS, HONEYDEW - ACRES HARVESTED"
# "MELONS, WATERMELON - ACRES HARVESTED"

#MILLET
unique(area_stats[commodity == "MILLET", short_desc])
#Only one: "MILLET, PROSO - ACRES HARVESTED"

#MINT
unique(area_stats[commodity == "MINT", short_desc])
#SUM:
# "MINT, OIL - ACRES HARVESTED"
# "MINT, TEA LEAVES - ACRES HARVESTED"

#MUSTARD
unique(area_stats[commodity == "MUSTARD", short_desc])
#Only one: "MUSTARD, SEED - ACRES HARVESTED"

#ONIONS
unique(area_stats[commodity == "ONIONS", short_desc])
#SUM:
# "ONIONS, DRY - ACRES HARVESTED"
# "ONIONS, GREEN - ACRES HARVESTED"

#PEAS
unique(area_stats[commodity == "PEAS", short_desc])
#SUM:
# "PEAS, GREEN, (EXCL SOUTHERN) - ACRES HARVESTED"
# "PEAS, GREEN, SOUTHERN (COWPEAS) - ACRES HARVESTED"
# "PEAS, DRY, SOUTHERN (COWPEAS) - ACRES HARVESTED"
# "PEAS, CHINESE (SUGAR & SNOW) - ACRES HARVESTED"
# "PEAS, DRY EDIBLE - ACRES HARVESTED"
# "PEAS, AUSTRIAN WINTER - ACRES HARVESTED"

#PEPPERS
unique(area_stats[commodity == "PEPPERS", short_desc])
#SUM:
# "PEPPERS, BELL - ACRES HARVESTED"
# "PEPPERS, CHILE - ACRES HARVESTED"

#POPCORN
unique(area_stats[commodity == "POPCORN", short_desc])
#Only one: "POPCORN, SHELLED - ACRES HARVESTED"

#SORGHUM
unique(area_stats[commodity == "SORGHUM", short_desc])
#SUM:
# "SORGHUM, GRAIN - ACRES HARVESTED"
# "SORGHUM, SILAGE - ACRES HARVESTED"
# "SORGHUM, SYRUP - ACRES HARVESTED"

#SUGARCANE
unique(area_stats[commodity == "SUGARCANE", short_desc])
#SUM:
# "SUGARCANE, SUGAR - ACRES HARVESTED"
# "SUGARCANE, SEED - ACRES HARVESTED"

#TOMATOES
unique(area_stats[commodity == "TOMATOES", short_desc])
#Keep only: "TOMATOES, IN THE OPEN - ACRES HARVESTED"

#WALNUTS
unique(area_stats[commodity == "WALNUTS", short_desc])
#Only one: "WALNUTS, ENGLISH - ACRES BEARING & NON-BEARING"

################################################################################
#

length(target_commodities[has_aggregated]) # already aggregated
length(target_commodities[!has_aggregated]) # we choose how to aggregate
# should sum to:
length(census_commodities_in_map)

simple_mapping <- sapply(target_commodities[has_aggregated], function(com) {
  descs <- unique(area_stats[commodity == com, short_desc])
  descs[1]
})

# For complex commodities (no aggregated version), we define manually
complex_mapping <- c(
  # BEANS
  "BEANS, SNAP - ACRES HARVESTED",
  "BEANS, GREEN, LIMA - ACRES HARVESTED",
  "BEANS, DRY EDIBLE, (EXCL LIMA) - ACRES HARVESTED",
  "BEANS, DRY EDIBLE, LIMA - ACRES HARVESTED",
  # BLUEBERRIES
  "BLUEBERRIES, TAME - ACRES HARVESTED",
  "BLUEBERRIES, WILD - ACRES HARVESTED",
  # CABBAGE
  "CABBAGE, HEAD - ACRES HARVESTED",
  "CABBAGE, CHINESE - ACRES HARVESTED",
  "CABBAGE, MUSTARD - ACRES HARVESTED",
  # CHERRIES
  "CHERRIES, TART - ACRES BEARING & NON-BEARING",
  "CHERRIES, SWEET - ACRES BEARING & NON-BEARING",
  # CORN
  "CORN, GRAIN - ACRES HARVESTED",
  "CORN, SILAGE - ACRES HARVESTED",
  # CUT CHRISTMAS TREES
  "CUT CHRISTMAS TREES - ACRES IN PRODUCTION",
  # GREENS
  "GREENS, TURNIP - ACRES HARVESTED",
  "GREENS, COLLARD - ACRES HARVESTED",
  "GREENS, MUSTARD - ACRES HARVESTED",
  "GREENS, KALE - ACRES HARVESTED",
  # HERBS
  "HERBS, FRESH CUT - ACRES HARVESTED",
  "HERBS, DRY - ACRES HARVESTED",
  # MELONS
  "MELONS, CANTALOUP - ACRES HARVESTED",
  "MELONS, HONEYDEW - ACRES HARVESTED",
  "MELONS, WATERMELON - ACRES HARVESTED",
  # MILLET
  "MILLET, PROSO - ACRES HARVESTED",
  # MINT
  "MINT, OIL - ACRES HARVESTED",
  "MINT, TEA LEAVES - ACRES HARVESTED",
  # MUSTARD
  "MUSTARD, SEED - ACRES HARVESTED",
  # ONIONS
  "ONIONS, DRY - ACRES HARVESTED",
  "ONIONS, GREEN - ACRES HARVESTED",
  # PEAS
  "PEAS, GREEN, (EXCL SOUTHERN) - ACRES HARVESTED",
  "PEAS, GREEN, SOUTHERN (COWPEAS) - ACRES HARVESTED",
  "PEAS, DRY, SOUTHERN (COWPEAS) - ACRES HARVESTED",
  "PEAS, CHINESE (SUGAR & SNOW) - ACRES HARVESTED",
  "PEAS, DRY EDIBLE - ACRES HARVESTED",
  "PEAS, AUSTRIAN WINTER - ACRES HARVESTED",
  # PEPPERS
  "PEPPERS, BELL - ACRES HARVESTED",
  "PEPPERS, CHILE - ACRES HARVESTED",
  # POPCORN
  "POPCORN, SHELLED - ACRES HARVESTED",
  # SORGHUM
  "SORGHUM, GRAIN - ACRES HARVESTED",
  "SORGHUM, SILAGE - ACRES HARVESTED",
  "SORGHUM, SYRUP - ACRES HARVESTED",
  # SUGARCANE
  "SUGARCANE, SUGAR - ACRES HARVESTED",
  "SUGARCANE, SEED - ACRES HARVESTED",
  # TOMATOES
  "TOMATOES, IN THE OPEN - ACRES HARVESTED",
  # WALNUTS
  "WALNUTS, ENGLISH - ACRES BEARING & NON-BEARING"
)

# Combine all selected short_desc strings
all_selected_descs <- c(simple_mapping, complex_mapping)

# Build the mapping dataframe
simple_df <- data.frame(
  commodity = names(simple_mapping),
  short_desc = unname(simple_mapping),
  stringsAsFactors = FALSE
)

complex_df <- data.frame(
  commodity = c(
    rep("BEANS", 4),
    rep("BLUEBERRIES", 2),
    rep("CABBAGE", 3),
    rep("CHERRIES", 2),
    rep("CORN", 2),
    rep("CUT CHRISTMAS TREES", 1),
    rep("GREENS", 4),
    rep("HERBS", 2),
    rep("MELONS", 3),
    rep("MILLET", 1),
    rep("MINT", 2),
    rep("MUSTARD", 1),
    rep("ONIONS", 2),
    rep("PEAS", 6),
    rep("PEPPERS", 2),
    rep("POPCORN", 1),
    rep("SORGHUM", 3),
    rep("SUGARCANE", 2),
    rep("TOMATOES", 1),
    rep("WALNUTS", 1)
  ),
  short_desc = c(
    "BEANS, SNAP - ACRES HARVESTED",
    "BEANS, GREEN, LIMA - ACRES HARVESTED",
    "BEANS, DRY EDIBLE, (EXCL LIMA) - ACRES HARVESTED",
    "BEANS, DRY EDIBLE, LIMA - ACRES HARVESTED",
    "BLUEBERRIES, TAME - ACRES HARVESTED",
    "BLUEBERRIES, WILD - ACRES HARVESTED",
    "CABBAGE, HEAD - ACRES HARVESTED",
    "CABBAGE, CHINESE - ACRES HARVESTED",
    "CABBAGE, MUSTARD - ACRES HARVESTED",
    "CHERRIES, TART - ACRES BEARING & NON-BEARING",
    "CHERRIES, SWEET - ACRES BEARING & NON-BEARING",
    "CORN, GRAIN - ACRES HARVESTED",
    "CORN, SILAGE - ACRES HARVESTED",
    "CUT CHRISTMAS TREES - ACRES IN PRODUCTION",
    "GREENS, TURNIP - ACRES HARVESTED",
    "GREENS, COLLARD - ACRES HARVESTED",
    "GREENS, MUSTARD - ACRES HARVESTED",
    "GREENS, KALE - ACRES HARVESTED",
    "HERBS, FRESH CUT - ACRES HARVESTED",
    "HERBS, DRY - ACRES HARVESTED",
    "MELONS, CANTALOUP - ACRES HARVESTED",
    "MELONS, HONEYDEW - ACRES HARVESTED",
    "MELONS, WATERMELON - ACRES HARVESTED",
    "MILLET, PROSO - ACRES HARVESTED",
    "MINT, OIL - ACRES HARVESTED",
    "MINT, TEA LEAVES - ACRES HARVESTED",
    "MUSTARD, SEED - ACRES HARVESTED",
    "ONIONS, DRY - ACRES HARVESTED",
    "ONIONS, GREEN - ACRES HARVESTED",
    "PEAS, GREEN, (EXCL SOUTHERN) - ACRES HARVESTED",
    "PEAS, GREEN, SOUTHERN (COWPEAS) - ACRES HARVESTED",
    "PEAS, DRY, SOUTHERN (COWPEAS) - ACRES HARVESTED",
    "PEAS, CHINESE (SUGAR & SNOW) - ACRES HARVESTED",
    "PEAS, DRY EDIBLE - ACRES HARVESTED",
    "PEAS, AUSTRIAN WINTER - ACRES HARVESTED",
    "PEPPERS, BELL - ACRES HARVESTED",
    "PEPPERS, CHILE - ACRES HARVESTED",
    "POPCORN, SHELLED - ACRES HARVESTED",
    "SORGHUM, GRAIN - ACRES HARVESTED",
    "SORGHUM, SILAGE - ACRES HARVESTED",
    "SORGHUM, SYRUP - ACRES HARVESTED",
    "SUGARCANE, SUGAR - ACRES HARVESTED",
    "SUGARCANE, SEED - ACRES HARVESTED",
    "TOMATOES, IN THE OPEN - ACRES HARVESTED",
    "WALNUTS, ENGLISH - ACRES BEARING & NON-BEARING"
  ),
  stringsAsFactors = FALSE
)

census_shortdesc_map <- rbind(simple_df, complex_df) %>%
  arrange(commodity)

write.csv(
  census_shortdesc_map,
  "data/metadata/census_shortdesc_map.csv",
  row.names = FALSE
)

# Verify all CDL census commodities are covered in the short_desc map
census_shortdesc_map <- read.csv(
  "data/metadata/census_shortdesc_map.csv",
  stringsAsFactors = FALSE
)

cdl_commodities <- cdl_census_map %>%
  pull(`Census Commodity`) %>%
  na.omit() %>%
  trimws() %>% # handle trailing whitespace
  unique()

missing <- setdiff(
  cdl_commodities,
  unique(trimws(census_shortdesc_map$commodity))
)

cat("CDL commodities with census counterpart:", length(cdl_commodities), "\n")
cat(
  "Covered in short_desc map:",
  length(unique(census_shortdesc_map$commodity)),
  "\n"
)
if (length(missing) == 0) {
  cat("All covered\n")
} else {
  cat("Missing:\n", paste0("  - ", missing, "\n"))
}

####
selected_descs <- census_shortdesc_map$short_desc

census_area <- area_stats[short_desc %in% selected_descs]

#check if we miss some counties:
length(setdiff(county_lookup$GEOID_padded, census_area$GEOID)) #46 instead of 44 after statisticcat filter
missing_county_shortdesc <- setdiff(
  unique(county_lookup$GEOID_padded),
  unique(census_area$GEOID)
)

county_lookup[
  county_lookup$GEOID_padded %in%
    missing_county_shortdesc &
    !county_lookup$GEOID_padded %in% missing_geoids &
    !county_lookup$GEOID_padded %in% missing_county_areastat,
]
#manual check
#51,13
unique(
  census[
    census$STATE_FIPS_CODE == 51 &
      census$COUNTY_CODE == 13,
  ]$COMMODITY
) #No commodity of interest that we can map to CDL.

unique(
  census[
    census$STATE_FIPS_CODE == 85 &
      census$COUNTY_CODE == 36,
  ]$COMMODITY
) #No commodity of interest that we can map to CDL.


uniqueN(census_area$commodity) # match length(cdl_commodities)
uniqueN(census_area$short_desc) # match length(census_shortdesc_map)

#####
census_area <- census_area %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID)))

write.csv(census_area, "data/CENSUS/census_area_2012.csv", row.names = FALSE)
#Add a csv for missing GEOIDS and the reason
CENSUS_MISSING1 <- county_lookup[
  county_lookup$GEOID_padded %in% missing_geoids,
] %>%
  mutate(reason = "Not in Census")

CENSUS_MISSING2 <- county_lookup[
  county_lookup$GEOID_padded %in%
    missing_county_areastat &
    !county_lookup$GEOID_padded %in% missing_geoids,
] %>%
  mutate(reason = "No matching statcat")

CENSUS_MISSING3 <- county_lookup[
  county_lookup$GEOID_padded %in%
    missing_county_shortdesc &
    !county_lookup$GEOID_padded %in% missing_geoids &
    !county_lookup$GEOID_padded %in% missing_county_areastat,
] %>%
  mutate(reason = "No matching commodity")

census_missing <- bind_rows(CENSUS_MISSING1, CENSUS_MISSING2, CENSUS_MISSING3)

write.csv(
  census_missing,
  "data/metadata/missing_geoid_census.csv",
  row.names = FALSE
)
