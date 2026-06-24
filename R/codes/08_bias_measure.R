rm(list=ls())

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
  pivot_longer(cols = c(GM, Tolerant, Vulnerable),
               names_to  = "Category",
               values_to = "pixels_cdl") %>%
  mutate(
    acres_cdl      = pixels_cdl * 0.222395,
    `Category Code` = case_when(
      Category == "GM"         ~ 1,
      Category == "Tolerant"   ~ 2,
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
  mutate(delta_acres = acres_cdl - acres_census,
         delta_pct = ifelse(acres_cdl == 0 & acres_census == 0, 0, (acres_cdl-acres_census)/acres_census)
         )
sum(is.na(bias$delta_pct))
sum(is.na(bias$delta_acres))
sum(is.infinite(bias$delta_pct)) # value = 0 for census result in many Inf Values. (Division by 0)
#Just to get a magnitude intuition.
#But our measure value will be (delta_baseline - delta_model)/delta_baseline
# with delta_baseline =  the delta_acres we just computed on this script without any reclassification)

#save output
write_csv(bias, "outputs/baseline_bias.csv")

