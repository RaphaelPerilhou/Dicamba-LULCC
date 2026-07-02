rm(list = ls())
library(tidyverse)
library(readxl)

# Load data
census_area <- read.csv("data/CENSUS/census_area_2012.csv") %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID)))
county_lookup <- read.csv(
  "data/county_lookup.csv",
  stringsAsFactors = FALSE
) %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID)))

shortdesc_map <- read.csv("data/metadata/census_shortdesc_map.csv")
cdl_census_map <- read_excel("data/metadata/CDL_CENSUS_MAP.xlsx")

length(setdiff(county_lookup$GEOID, census_area$GEOID))

# Step 1: Flag and clean suppressed values
# (D) = withheld to avoid disclosing data for individual operations
# (Z) = less than half the unit shown
# Others can be found here: https://quickstats.nass.usda.gov/src/glossary.pdf

census_area <- census_area %>%
  mutate(
    value = gsub(",", "", value),
    suppressed = !grepl("^[0-9]+$", value),
    value_clean = suppressWarnings(ifelse(suppressed, 0, as.numeric(value)))
  )

suppressed_log <- census_area %>%
  filter(suppressed) %>%
  select(GEOID, commodity, short_desc, value)

cat("Suppressed non_numeric value:", nrow(suppressed_log), "\n")

# Step 2: Aggregate subcategories of commodity (e.g bell pepper + chile pepper)
agg_commodity <- census_area %>%
  group_by(GEOID, commodity) %>%
  summarise(
    acres = sum(value_clean, na.rm = TRUE),
    n_suppressed = sum(suppressed),
    .groups = "drop"
  )

# Step 3: Join category from CDL map
commodity_category <- cdl_census_map %>%
  filter(`Has Census` == 1) %>%
  mutate(`Census Commodity` = trimws(`Census Commodity`)) %>%
  select(`Census Commodity`, Category, `Category Code`) %>%
  distinct()

commodity_category <- agg_commodity %>%
  left_join(commodity_category, by = c("commodity" = "Census Commodity"))

# Step 4: Aggregate to category level
census_category <- commodity_category %>%
  group_by(GEOID, `Category Code`, Category) %>%
  summarise(
    acres_census = sum(acres, na.rm = TRUE),
    n_suppressed = sum(n_suppressed),
    .groups = "drop"
  ) %>%
  arrange(`Category Code`)

length(unique(census_category$GEOID)) #Not 3 rows per county because some county don't have the 3 categories

# Output
# wanna check for some counties:
#if want every GEOID:
# county_list <- unique(census_category$GEOID)
county_list <- c("01033")

cat("\n── Commodity-level acres ──\n")
for (i in county_list) {
  name <- county_lookup$NAME[county_lookup$GEOID == i][1]
  cat("\n", i, "—", name, "\n")
  agg_commodity %>%
    filter(GEOID == i) %>%
    select(commodity, acres, n_suppressed) %>%
    print()
}

cat("\n── Category-level acres ──\n")
for (i in county_list) {
  name <- county_lookup$NAME[county_lookup$GEOID == i][1]
  cat("\n", i, "—", name, "\n")
  census_category %>%
    filter(GEOID == i) %>%
    select(Category, acres_census, n_suppressed) %>%
    print()
}

cat("\n── Suppressed short_desc ──\n")
for (i in county_list) {
  name <- county_lookup$NAME[county_lookup$GEOID == i][1]
  cat("\n", i, "-", name, "\n")
  suppressed_log %>%
    filter(GEOID == i) %>%
    select(commodity, value) %>%
    print()
}

#Save outputs (for all GEOID)

write_csv(
  agg_commodity %>% arrange(GEOID, commodity),
  "outputs/commodity_census_acres_2012.csv"
)

write_csv(
  census_category %>% arrange(GEOID, `Category Code`),
  "outputs/category_census_acres_2012.csv"
)

write_csv(
  suppressed_log %>% arrange(GEOID, commodity),
  "outputs/census_suppressed_log.csv"
)
