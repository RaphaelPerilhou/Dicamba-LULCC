#######
# Diagnostics on baseline
#######
rm(list = ls())
library(tidyverse)
library(knitr)

baseline <- read_csv("outputs/baseline_measures.csv")

# ---------------# ---------------# ---------------
# Check for NAs
sum(is.na(baseline$mean_conf_category))

#Verify NAs are just when no CDL pixels. (total = 413 NAs)
# How many of the 413 NA confidence rows have acres_cdl == 0?
cat(
  "NA conf AND acres_cdl == 0:",
  sum(is.na(baseline$mean_conf_category) & baseline$acres_cdl == 0),
  "\n"
)
#Reassuring, we are sure all pixels with CDL classification also have a confidence value

# ---------------# ---------------# ---------------
#How many acres_census == 0 ?
cat("acres_census == 0:", sum(baseline$acres_census == 0), "\n")

#How many have both acres_cdl == 0 and census_acres == 0 ?
cat(
  " acres_cdl == 0 AND acres_census == 0: n =",
  sum(baseline$acres_cdl == 0 & baseline$acres_census == 0),
  "\n % of CDL = 0 & Census = 0 relative to Census = 0:",
  round(
    (sum(
      baseline$acres_cdl == 0 &
        baseline$acres_census == 0
    ) /
      sum(baseline$acres_census == 0)) *
      100,
    2
  ),
  "%\n"
)
# ---------------# ---------------# ---------------

baseline01001 <- baseline %>% filter(GEOID == "01001")

sum(baseline01001$acres_cdl)
#get each category acres_CDL as % of total
(baseline01001 %>% filter(Category == "GM"))$acres_cdl /
  sum(baseline01001$acres_cdl)
(baseline01001 %>% filter(Category == "Tolerant"))$acres_cdl /
  sum(baseline01001$acres_cdl)
(baseline01001 %>% filter(Category == "Vulnerable"))$acres_cdl /
  sum(baseline01001$acres_cdl)

#A good measure of improvement for county i category c after applying a model could be.
# (|delta_baseline_{i,c}|-|delta_model_{i,c}|)/|delta_baseline_{i,c}| * acres_CDL_{i,c}/acres_CDL_i

#We accompany with an absolute improvement measure:
# |delta_baseline_{i,c}|-|delta_model_{i,c}|

#Now, we exclude missing geoids and zero_acres_census

#Load counties:
missing_geoid <- read_csv(
  "data/metadata/missing_geoid_census.csv",
  col_types = cols(GEOID = col_character())
) %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  pull(GEOID)

#For the moment we also exclude the cunties where census reports 0 acres
# across all 3 categories.
zero_acres_geoids <- read_csv("data/metadata/zero_census_acres_geoids.csv") %>%
  mutate(GEOID = sprintf("%05d", as.integer(GEOID))) %>%
  pull(GEOID)

counties_selected <- read.csv(
  "data/county_lookup.csv",
  colClasses = "character"
) %>%
  mutate(
    GEOID = sprintf("%05d", as.integer(GEOID)),
    STATEFP = sprintf("%02d", as.integer(STATEFP))
  ) %>%
  filter(!GEOID %in% missing_geoid, !GEOID %in% zero_acres_geoids) %>%
  select(GEOID, STATEFP)


#Load baseline
baseline_selected <- baseline %>% filter(GEOID %in% counties_selected$GEOID)
#######################################################
########### DELTA PCT TOTAL
#######################################################

mean(baseline_selected$delta_pct_total)
mean(abs(baseline_selected$delta_pct_total))
median(baseline_selected$delta_pct_total)

max(baseline_selected$delta_pct_total)
min(baseline_selected$delta_pct_total) #min boundede at -1 by construction

#but we have a huge max = 111, how many counties have such a small census total and big cdl

#Hence, we look for outliers

quantile(
  baseline_selected$delta_pct_total,
  probs = c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 0.995, 0.999)
)

p99_threshold <- quantile(
  baseline_selected$delta_pct_total,
  probs = 0.99,
  na.rm = TRUE
)
above1_threshold <- ecdf(baseline_selected$delta_pct_total)(1) #97.6%

#trim above 99%
outliers_p99 <- baseline_selected %>%
  filter(delta_pct_total > p99_threshold) %>%
  select(GEOID, Category, acres_cdl, acres_census, delta_pct_total) %>%
  arrange(desc(delta_pct_total))

#trim above 1
outliers_above1 <- baseline_selected %>%
  filter(delta_pct_total > 1) %>%
  select(GEOID, Category, acres_cdl, acres_census, delta_pct_total) %>%
  arrange(desc(delta_pct_total))

#We check which states are more concerned, to see relevance for our Dicamba Analysis.
county_lookup <- read.csv(
  "data/county_lookup.csv",
  colClasses = "character"
) %>%
  mutate(
    GEOID = sprintf("%05d", as.integer(GEOID)),
    STATEFP = sprintf("%02d", as.integer(STATEFP))
  )

counties_p99 <- county_lookup %>%
  filter(GEOID %in% unique(outliers_p99$GEOID)) %>%
  count(STATEFP, name = "n_counties") %>%
  arrange(desc(n_counties))

counties_above1 <- county_lookup %>%
  filter(GEOID %in% unique(outliers_above1$GEOID)) %>%
  count(STATEFP, name = "n_counties") %>%
  arrange(desc(n_counties))

print(counties_p99)
print(counties_above1)

sum(counties_p99$n_counties)
sum(counties_above1$n_counties)
############################################

n_total <- nrow(baseline_selected)
n_shown <- sum(abs(baseline_selected$delta_pct_total) <= 3, na.rm = TRUE)
n_excluded <- n_total - n_shown
threshold <- 3

p_delta_hist <- baseline_selected %>%
  filter(abs(delta_pct_total) <= threshold) %>%
  ggplot(aes(x = delta_pct_total)) +
  geom_histogram(
    bins = 150,
    fill = "#9966CC",
    color = "white",
    linewidth = 0.15
  ) +
  geom_rug(alpha = 0.25, color = "red", linewidth = 0.3) +
  geom_vline(
    xintercept = 0,
    color = "#C0392B",
    linetype = "dashed",
    linewidth = 0.5
  ) +
  labs(
    title = "Distribution of relative discrepancy (CDL vs. Census)",
    subtitle = paste0(
      "n = ",
      n_shown,
      " of ",
      n_total,
      " counties shown (Delta <",
      threshold,
      "); ",
      n_excluded,
      " extreme values excluded (",
      round(n_excluded / n_total * 100, 2),
      "%)"
    ),
    x = "(CDL acres - Census acres) / Census acres",
    y = "Count"
  )
print(p_delta_hist)

summary_stats <- tibble(
  n_total = n_total,
  n_shown_thresh3 = n_shown,
  n_excluded_thresh3 = n_excluded,
  mean = mean(baseline_selected$delta_pct_total),
  mean_abs = mean(abs(baseline_selected$delta_pct_total)),
  median = median(baseline_selected$delta_pct_total),
  max = max(baseline_selected$delta_pct_total),
  min = min(baseline_selected$delta_pct_total)
)

###### Save outputs
write_csv(summary_stats, "outputs/tables/baseline_summary_stats.csv")
write_csv(counties_p99, "outputs/tables/outlier_counties_p99_by_state.csv")
write_csv(
  counties_above1,
  "outputs/tables/outlier_counties_above1_by_state.csv"
)
write_csv(outliers_p99, "outputs/tables/outliers_p99_detail.csv")
write_csv(outliers_above1, "outputs/tables/outliers_above1_detail.csv")
ggsave(
  "outputs/figures/delta_pct_total_histogram.png",
  p_delta_hist,
  width = 8,
  height = 5,
  dpi = 300
)
############################################
# Convert key summary tables to .tex

writeLines(
  kable(summary_stats, format = "latex", booktabs = TRUE, digits = 4),
  "outputs/tables/baseline_summary_stats.tex"
)

writeLines(
  kable(counties_p99, format = "latex", booktabs = TRUE),
  "outputs/tables/outlier_counties_p99_by_state.tex"
)

writeLines(
  kable(counties_above1, format = "latex", booktabs = TRUE),
  "outputs/tables/outlier_counties_above1_by_state.tex"
)

#######################################################
########### DELTA_ACRES (raw, unnormalized)
#######################################################
#get a magnitude of order of counties acres
mean(
  baseline_selected %>%
    group_by(GEOID) %>%
    summarise(acres_census_total = sum(acres_census, na.rm = TRUE)) %>%
    pull(acres_census_total)
)

max(
  baseline_selected %>%
    group_by(GEOID) %>%
    summarise(acres_census_total = sum(acres_census, na.rm = TRUE)) %>%
    pull(acres_census_total)
)
min(
  baseline_selected %>%
    group_by(GEOID) %>%
    summarise(acres_census_total = sum(acres_census, na.rm = TRUE)) %>%
    pull(acres_census_total)
)

mean(baseline_selected$delta_acres, na.rm = TRUE)
mean(abs(baseline_selected$delta_acres), na.rm = TRUE)
median(baseline_selected$delta_acres, na.rm = TRUE)

max(baseline_selected$delta_acres, na.rm = TRUE)
min(baseline_selected$delta_acres, na.rm = TRUE)

# how many NAs
sum(is.na(baseline_selected$delta_acres))

quantile(
  baseline_selected$delta_acres,
  probs = c(0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 0.995, 0.999),
  na.rm = TRUE
)

# Note: unlike the pct measures, delta_acres has no natural scale to define
# "extreme" — 1000 acres is huge in a small county, negligible in a large one.
# So we identify outliers by rank (largest |delta_acres| values) rather than
# a fixed threshold like > 1 or > 3.

p99_threshold_acres <- quantile(
  abs(baseline_selected$delta_acres),
  probs = 0.99,
  na.rm = TRUE
)

#trim above 99% (by absolute magnitude, since large negative deltas matter as much as large positive ones)
outliers_p99_acres <- baseline_selected %>%
  filter(abs(delta_acres) > p99_threshold_acres) %>%
  select(GEOID, Category, acres_cdl, acres_census, delta_acres) %>%
  arrange(desc(abs(delta_acres)))

# Top 20 single largest discrepancies, county-category level, regardless of percentile
top20_delta_acres <- baseline_selected %>%
  select(GEOID, Category, acres_cdl, acres_census, delta_acres) %>%
  arrange(desc(abs(delta_acres))) %>%
  head(20)

#We check which states are more concerned, to see relevance for our Dicamba Analysis.
county_lookup <- read.csv(
  "data/county_lookup.csv",
  colClasses = "character"
) %>%
  mutate(
    GEOID = sprintf("%05d", as.integer(GEOID)),
    STATEFP = sprintf("%02d", as.integer(STATEFP))
  )

counties_p99_acres <- county_lookup %>%
  filter(GEOID %in% unique(outliers_p99_acres$GEOID)) %>%
  count(STATEFP, name = "n_counties") %>%
  arrange(desc(n_counties))

print(counties_p99_acres)
sum(counties_p99_acres$n_counties)

############################################
# Distribution plot
# Since delta_acres has no natural unit-scale cutoff, trim by percentile
# rather than a fixed absolute threshold like |delta| <= 3.

n_total_acres <- sum(!is.na(baseline_selected$delta_acres))

trim_lower <- quantile(
  baseline_selected$delta_acres,
  probs = 0.01,
  na.rm = TRUE
)
trim_upper <- quantile(
  baseline_selected$delta_acres,
  probs = 0.99,
  na.rm = TRUE
)

n_shown_acres <- sum(
  baseline_selected$delta_acres >= trim_lower &
    baseline_selected$delta_acres <= trim_upper,
  na.rm = TRUE
)
n_excluded_acres <- n_total_acres - n_shown_acres

p_delta_hist_acres <- baseline_selected %>%
  filter(delta_acres >= trim_lower, delta_acres <= trim_upper) %>%
  ggplot(aes(x = delta_acres)) +
  geom_histogram(
    bins = 150,
    fill = "#669933",
    color = "white",
    linewidth = 0.15
  ) +
  geom_rug(alpha = 0.25, color = "red", linewidth = 0.3) +
  geom_vline(
    xintercept = 0,
    color = "#C0392B",
    linetype = "dashed",
    linewidth = 0.5
  ) +
  labs(
    title = "Distribution of raw bias (CDL acres - Census acres)",
    subtitle = paste0(
      "n = ",
      n_shown_acres,
      " of ",
      n_total_acres,
      " county-category cells shown (1st-99th percentile); ",
      n_excluded_acres,
      " extreme values excluded (",
      round(n_excluded_acres / n_total_acres * 100, 2),
      "%)"
    ),
    x = "CDL acres - Census acres",
    y = "Count"
  )
print(p_delta_hist_acres)

summary_stats_acres <- tibble(
  n_total = n_total_acres,
  n_shown_p1_p99 = n_shown_acres,
  n_excluded_p1_p99 = n_excluded_acres,
  mean = mean(baseline_selected$delta_acres, na.rm = TRUE),
  mean_abs = mean(abs(baseline_selected$delta_acres), na.rm = TRUE),
  median = median(baseline_selected$delta_acres, na.rm = TRUE),
  max = max(baseline_selected$delta_acres, na.rm = TRUE),
  min = min(baseline_selected$delta_acres, na.rm = TRUE)
)

###### Save outputs
write_csv(
  summary_stats_acres,
  "outputs/tables/baseline_summary_stats_acres.csv"
)
write_csv(
  counties_p99_acres,
  "outputs/tables/outlier_counties_p99_by_state_acres.csv"
)
write_csv(outliers_p99_acres, "outputs/tables/outliers_p99_detail_acres.csv")
write_csv(top20_delta_acres, "outputs/tables/top20_delta_acres.csv")
ggsave(
  "outputs/figures/delta_acres_histogram.png",
  p_delta_hist_acres,
  width = 8,
  height = 5,
  dpi = 300
)

############################################
# Convert key summary tables to .tex

writeLines(
  kable(summary_stats_acres, format = "latex", booktabs = TRUE, digits = 1),
  "outputs/tables/baseline_summary_stats_acres.tex"
)

writeLines(
  kable(counties_p99_acres, format = "latex", booktabs = TRUE),
  "outputs/tables/outlier_counties_p99_by_state_acres.tex"
)

writeLines(
  kable(top20_delta_acres, format = "latex", booktabs = TRUE, digits = 1),
  "outputs/tables/top20_delta_acres.tex"
)
