# CDL → Census QuickStats Dictionary

## Overview

This document maps CDL crop codes to their QuickStats commodity names for the
Census of Agriculture 2012. It is the authoritative reference for
`04_census_dictionary.R`.

The mapping is used to compute `Δ_acres = CDL_acres - Census_acres` per
category (GM / Tolerant / Vulnerable) as part of the bias correction score:

$$S_i = w_1 \cdot |\Delta_{\text{acres}}| + w_2 \cdot U$$

---

## How to retrieve the full QuickStats commodity list

```r
library(httr)
library(jsonlite)

url <- paste0(
  "https://quickstats.nass.usda.gov/api/get_param_values/?",
  "key=", NASS_KEY,
  "&param=commodity_desc"
)
res <- GET(url)
all_commodities <- fromJSON(content(res, "text", encoding="UTF-8"))$commodity_desc
write.csv(data.frame(commodity = all_commodities),
          "data/quickstats_commodities.csv", row.names = FALSE)
```

---

## General rules

- **Statistic**: use `AREA HARVESTED` for all field crops and vegetables.
  Use `AREA BEARING` for tree nuts and permanent orchards (almonds, walnuts,
  pistachios, olives, oranges, avocados) since these are not "harvested"
  in the traditional sense but their acreage is stable.
- **No irrigated subsets**: `CORN, IRRIGATED - ACRES HARVESTED` is already
  included in `CORN - ACRES HARVESTED`. Never add irrigated subsets.
- **No operations rows**: rows containing `OPERATIONS WITH AREA HARVESTED`
  count farms, not acres. Always exclude.
- **No double-counting subtypes**: e.g. `COTTON - ACRES HARVESTED` already
  includes `COTTON, PIMA` and `COTTON, UPLAND`. Take the total only.
- **Comparison level**: comparison is done at the **category level**
  (GM / Tolerant / Vulnerable), not at the individual crop level.
  CDL pixel counts are converted to acres: 1 pixel = 30m × 30m = 900 m²
  = 0.2224 acres.

---

## GM-enabled (Category 1)

| CDL Code | CDL Name | QuickStats Commodity | Notes |
|----------|----------|----------------------|-------|
| 2 | Cotton | `COTTON` | Total only — includes Pima + Upland |
| 5 | Soybeans | `SOYBEANS` | |
| 26 | Dbl Crop WinWht/Soybeans | — | Double crop, counted in Soy + Wheat |
| 232 | Dbl Crop Lettuce/Cotton | — | Double crop |
| 238 | Dbl Crop WinWht/Cotton | — | Double crop |
| 239 | Dbl Crop Soybeans/Cotton | — | Double crop |
| 240 | Dbl Crop Soybeans/Oats | — | Double crop |
| 241 | Dbl Crop Corn/Soybeans | — | Double crop |
| 254 | Dbl Crop Barley/Soybeans | — | Double crop |

**QuickStats query:** `SOYBEANS` + `COTTON`, `statisticcat_desc = AREA HARVESTED`
`keep_desc = "^SOYBEANS - ACRES HARVESTED$|^COTTON - ACRES HARVESTED$"`

---

## Tolerant (Category 2)

| CDL Code | CDL Name | QuickStats Commodity | Notes |
|----------|----------|----------------------|-------|
| 1 | Corn | `CORN` | Sum GRAIN + SILAGE (CDL does not distinguish) |
| 3 | Rice | `RICE` | |
| 4 | Sorghum | `SORGHUM` | Sum GRAIN + SILAGE |
| 12 | Sweet Corn | `SWEET CORN` | |
| 13 | Pop or Orn Corn | `POPCORN` | |
| 21 | Barley | `BARLEY` | |
| 22 | Durum Wheat | `WHEAT` | Subtype of WHEAT total |
| 23 | Spring Wheat | `WHEAT` | Subtype of WHEAT total |
| 24 | Winter Wheat | `WHEAT` | Subtype of WHEAT total |
| 25 | Other Small Grains | `SMALL GRAINS` | Aggregate |
| 27 | Rye | `RYE` | |
| 28 | Oats | `OATS` | |
| 29 | Millet | `MILLET` | |
| 30 | Speltz | `EMMER & SPELT` | Speltz does not exist as standalone |
| 45 | Sugarcane | `SUGARCANE` | |
| 205 | Triticale | `TRITICALE` | |
| 225–237 | Double crops (Tolerant) | — | Counted in single-crop components |

**QuickStats queries:**

```r
nass_query("CORN",         keep_desc = "^CORN, GRAIN - ACRES HARVESTED$|^CORN, SILAGE - ACRES HARVESTED$")
nass_query("RICE",         keep_desc = "^RICE - ACRES HARVESTED$")
nass_query("SORGHUM",      keep_desc = "^SORGHUM, GRAIN - ACRES HARVESTED$|^SORGHUM, SILAGE - ACRES HARVESTED$")
nass_query("WHEAT",        keep_desc = "^WHEAT - ACRES HARVESTED$")   # total only, includes all subtypes
nass_query("BARLEY",       keep_desc = "^BARLEY - ACRES HARVESTED$")
nass_query("OATS",         keep_desc = "^OATS - ACRES HARVESTED$")
nass_query("RYE",          keep_desc = "^RYE - ACRES HARVESTED$")
nass_query("MILLET",       keep_desc = "^MILLET - ACRES HARVESTED$")
nass_query("EMMER & SPELT",keep_desc = "^EMMER & SPELT - ACRES HARVESTED$")
nass_query("TRITICALE",    keep_desc = "^TRITICALE - ACRES HARVESTED$")
nass_query("SUGARCANE",    keep_desc = "^SUGARCANE - ACRES HARVESTED$")
nass_query("SWEET CORN",   keep_desc = "^SWEET CORN - ACRES HARVESTED$")
nass_query("POPCORN",      keep_desc = "^POPCORN - ACRES HARVESTED$")
nass_query("SMALL GRAINS", keep_desc = "^SMALL GRAINS - ACRES HARVESTED$")
```

---

## Vulnerable (Category 3)

| CDL Code | CDL Name | QuickStats Commodity | Notes |
|----------|----------|----------------------|-------|
| 6 | Sunflower | `SUNFLOWER` | |
| 10 | Peanuts | `PEANUTS` | |
| 11 | Tobacco | `TOBACCO` | |
| 14 | Mint | `MINT` | |
| 31 | Canola | `CANOLA` | |
| 32 | Flaxseed | `FLAXSEED` | |
| 33 | Safflower | `SAFFLOWER` | |
| 34 | Rape Seed | `RAPESEED` | One word in QuickStats |
| 35 | Mustard | `MUSTARD` | |
| 36 | Alfalfa | `HAY` | Alfalfa is a subtype — use `HAY, ALFALFA - ACRES HARVESTED` |
| 37 | Other Hay/Non Alfalfa | `HAY & HAYLAGE` | Use `HAY & HAYLAGE - ACRES HARVESTED` minus alfalfa |
| 38 | Camelina | `CAMELINA` | |
| 39 | Buckwheat | `BUCKWHEAT` | |
| 41 | Sugarbeets | `SUGARBEETS` | |
| 42 | Dry Beans | `BEANS` | QuickStats uses BEANS not DRY BEANS |
| 43 | Potatoes | `POTATOES` | Total only |
| 44 | Other Crops | — | No direct Census counterpart — excluded |
| 46 | Sweet Potatoes | `SWEET POTATOES` | |
| 47 | Misc Vegs & Fruits | — | Too broad — excluded |
| 48 | Watermelons | `MELONS` | Watermelons = subtype of MELONS |
| 49 | Onions | `ONIONS` | |
| 50 | Cucumbers | `CUCUMBERS` | |
| 51 | Chick Peas | `CHICKPEAS` | |
| 52 | Lentils | `LENTILS` | |
| 53 | Peas | `PEAS` | |
| 54 | Tomatoes | `TOMATOES` | Use `TOMATOES, IN THE OPEN - ACRES HARVESTED` |
| 55 | Caneberries | `CANEBERRIES` | |
| 56 | Hops | `HOPS` | |
| 57 | Herbs | `HERBS` | |
| 58 | Clover/Wildflowers | `GRASSES & LEGUMES` | Partial match only |
| 66 | Cherries | `CHERRIES` | |
| 67 | Peaches | `PEACHES` | |
| 68 | Apples | `APPLES` | |
| 69 | Grapes | `GRAPES` | |
| 70 | Christmas Trees | `CUT CHRISTMAS TREES` | |
| 71 | Other Tree Crops | `ORCHARDS` | Partial match |
| 72 | Citrus | `CITRUS TOTALS` | Aggregate |
| 74 | Pecans | `PECANS` | |
| 75 | Almonds | `ALMONDS` | `AREA BEARING` |
| 76 | Walnuts | `WALNUTS` | `AREA BEARING` |
| 77 | Pears | `PEARS` | |
| 204 | Pistachios | `PISTACHIOS` | `AREA BEARING` |
| 206 | Carrots | `CARROTS` | |
| 207 | Asparagus | `ASPARAGUS` | |
| 208 | Garlic | `GARLIC` | |
| 209 | Cantaloupes | `MELONS` | Cantaloupe = subtype of MELONS |
| 210 | Prunes | `PRUNES` | |
| 211 | Olives | `OLIVES` | `AREA BEARING` |
| 212 | Oranges | `ORANGES` | `AREA BEARING` |
| 213 | Honeydew | `MELONS` | Honeydew = subtype of MELONS |
| 214 | Broccoli | `BROCCOLI` | |
| 215 | Avocados | `AVOCADOS` | `AREA BEARING` |
| 216 | Peppers | `PEPPERS` | |
| 217 | Pomegranates | `POMEGRANATES` | |
| 218 | Nectarines | `NECTARINES` | |
| 219 | Greens | `GREENS` | |
| 220 | Plums | `PLUMS & PRUNES` | Plums = subtype |
| 221 | Strawberries | `STRAWBERRIES` | |
| 222 | Squash | `SQUASH` | |
| 223 | Apricots | `APRICOTS` | |
| 224 | Vetch | — | No Census counterpart — excluded |
| 227 | Lettuce | `LETTUCE` | |
| 229 | Pumpkins | `PUMPKINS` | |
| 231 | Dbl Crop Lettuce/Cantaloupe | — | Double crop |
| 242 | Blueberries | `BLUEBERRIES` | |
| 243 | Cabbage | `CABBAGE` | |
| 244 | Cauliflower | `CAULIFLOWER` | |
| 245 | Celery | `CELERY` | |
| 246 | Radishes | `RADISHES` | |
| 247 | Turnips | `TURNIPS` | |
| 248 | Eggplants | `EGGPLANT` | No S in QuickStats |
| 249 | Gourds | `GOURDS` | |
| 250 | Cranberries | `CRANBERRIES` | |

---

## CDL codes with no Census counterpart

These codes are inside the union mask and classified as Vulnerable (3) but
have no reliable Census counterpart. They are **excluded from the validation**
and noted explicitly:

| CDL Code | CDL Name | Reason |
|----------|----------|--------|
| 44 | Other Crops | Too broad — no Census equivalent |
| 47 | Misc Vegs & Fruits | Too broad — no Census equivalent |
| 58 | Clover/Wildflowers | Partial match only with `GRASSES & LEGUMES` |
| 71 | Other Tree Crops | Partial match only with `ORCHARDS` |
| 224 | Vetch | No Census counterpart |

---

## MELONS note

QuickStats `MELONS` aggregates watermelons (CDL 48), cantaloupes (CDL 209),
and honeydew (CDL 213). These three CDL codes cannot be separated at the
Census level. The total `MELONS - ACRES HARVESTED` is used and mapped to
the sum of CDL pixels for codes 48 + 209 + 213.

## HAY / Alfalfa note

CDL code 36 = Alfalfa, CDL code 37 = Other Hay/Non Alfalfa.
In QuickStats: `HAY, ALFALFA - ACRES HARVESTED` for code 36,
`HAY & HAYLAGE - ACRES HARVESTED` minus alfalfa for code 37.
In practice, sum both and compare to total `HAY & HAYLAGE`.
