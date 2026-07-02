rm(list = ls())

##
library(tidyverse)
library(DescTools)
census_acres <- read_csv("outputs/category_census_acres_2012.csv")
#path to cassified file (function of the stateFP and GEOID)
#example for state 01, year 2009 and geoid 01005
# data/classified/01/Classified_2009_01005.tif
classification_summary <- read_csv("outputs/classification_summary.csv") %>%
  filter(year == 2012) %>%
  mutate(GEOID = sprintf("%05d", as.integer(geoid))) %>%
  select(GEOID, GM, Tolerant, Vulnerable) %>%
  pivot_longer(
    cols = c(GM, Tolerant, Vulnerable),
    names_to = "Category",
    values_to = "pixels_cdl"
  ) %>%
  mutate(
    acres_cdl = pixels_cdl * 0.222395,
    `Category Code` = case_when(
      Category == "GM" ~ 1,
      Category == "Tolerant" ~ 2,
      Category == "Vulnerable" ~ 3
    )
  )

#create the bias variable and keep only counties available in census.
missing_geoid <- read_csv("data/metadata/missing_geoid_census.csv") %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID)))
missing_geoid <- unique(missing_geoid$GEOID)

bias <- classification_summary %>%
  filter(!GEOID %in% missing_geoid) %>%
  left_join(census_acres, by = c("GEOID", "Category Code", "Category")) %>%
  mutate(
    delta_acres = acres_cdl - acres_census,

    # delta_pct_census = (CDL - Census) / Census
    # Positive: CDL overcounts relative to Census (e.g. 0.2 = CDL maps 20% more than Census reports)
    # Negative: CDL undercounts relative to Census (e.g. -0.5 = CDL maps 50% less than Census reports)
    # NA when Census = 0 but CDL > 0 (no reference to normalise against)
    delta_pct_census = case_when(
      acres_census == 0 & acres_cdl == 0 ~ 0,
      acres_census == 0 & acres_cdl != 0 ~ NA_real_,
      TRUE ~ (acres_cdl - acres_census) / acres_census
    ),

    # delta_pct_CDL = (CDL - Census) / CDL
    # Positive: CDL overcounts — a fraction of its own mapped area has no Census counterpart
    #           (e.g. 0.3 = 30% of CDL-mapped acres exceed Census)
    # Negative: CDL undercounts — Census reports more than CDL mapped
    # NA when CDL = 0 but Census > 0 (CDL maps nothing, cannot normalise)
    delta_pct_CDL = case_when(
      acres_census == 0 & acres_cdl == 0 ~ 0,
      acres_census != 0 & acres_cdl == 0 ~ NA_real_,
      TRUE ~ (acres_cdl - acres_census) / acres_cdl
    )
  ) %>%

  # delta_pct_total = (CDL - Census) / sum(Census across all 3 categories)
  # acres_census_total is fixed for a given county.
  #
  # Example = 10% : "CDL overestimates GM acreage by an amount equal to 10% of
  #                   the county's total Census-reported cropland."

  # Not comparable across counties of different sizes so use for within-county
  # analysis only, not cross-county ranking.
  group_by(GEOID) %>%
  mutate(
    acres_census_total = sum(acres_census, na.rm = TRUE),
    delta_pct_total = (acres_cdl - acres_census) / acres_census_total
  ) %>%
  ungroup()

sum(is.na(bias$delta_pct_census))
sum(is.na(bias$delta_pct_CDL))
sum(is.na(bias$delta_acres))
sum(bias$acres_cdl == 0)
#That was just to get a magnitude intuition.

# Flag counties where Census reports zero across all 3 categories
# Do NOT remove as zero Census may reflect suppression or land use/cover mismatch
# rather than true absence of crops. Models may still improve CDL for these counties.
bias <- bias %>%
  group_by(GEOID) %>%
  mutate(zero_census_total = sum(acres_census, na.rm = TRUE) == 0) %>%
  ungroup()

cat(
  "Counties with zero total Census acres (flagged, not removed):",
  sum(bias$zero_census_total) / 3,
  "\n"
)

# Save list of flagged counties for reference in downstream scripts
bias %>%
  filter(zero_census_total) %>%
  distinct(GEOID) %>%
  write_csv("data/metadata/zero_census_acres_geoids.csv")
cat("Saved: data/metadata/zero_census_acres_geoids.csv\n")

write_csv(bias, "outputs/baseline_bias.csv")
