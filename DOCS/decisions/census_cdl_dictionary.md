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

Run `00_metadata_census.R` with the desired reference county. It produces:
- `data/metadata/quickstats_commodities.csv` — full list of commodity names
- `data/metadata/gm_all_stats.csv` — all available short_desc for GM crops
- `data/metadata/tolerant_all_stats.csv` — all available short_desc for Tolerant crops
- `data/metadata/vulnerable_all_stats.csv` — all available short_desc for Vulnerable crops

Reference county: **Fresno CA (GEOID 06019)** — most agriculturally diverse US county,
covers all three categories across field crops, vegetables, and permanent orchards.

---

## General rules

- **Statistic**: use `AREA HARVESTED` for all field crops and vegetables.
  Use `AREA BEARING` for permanent orchards (almonds, walnuts, pistachios,
  olives, oranges, avocados, grapes, stone fruits) — these are not
  "harvested" in the traditional sense but their acreage is stable.
- **No irrigated subsets**: always included in totals. Filtered by
  `!grepl("IRRIGATED", short_desc)` in `nass_query()`.
- **No operations rows**: count farms not acres. Filtered by
  `!grepl("OPERATIONS", short_desc)` in `nass_query()`.
- **No double-counting subtypes**: e.g. `COTTON - ACRES HARVESTED` already
  includes `COTTON, PIMA` and `COTTON, UPLAND`. Use `keep_desc` with `$`
  anchor to match exact `short_desc`.
- **Deduplication**: `first_only = TRUE` in `nass_query()` keeps the first
  occurrence per `short_desc` (Census before Survey) via
  `group_by(short_desc) %>% slice(1)`. Apply to all queries.
- **Comparison level**: category level (GM / Tolerant / Vulnerable).
  CDL pixel counts converted to acres: 1 pixel = 30m × 30m = 900 m² = 0.2224 acres.
- **Rate limiting**: add `Sys.sleep(0.5)` in `nass_query()` when running
  for many counties to avoid 403 errors.

---

## GM-enabled (Category 1)

| CDL Code | CDL Name | QuickStats Commodity | `keep_desc` | Notes |
|----------|----------|----------------------|-------------|-------|
| 2 | Cotton | `COTTON` | `^COTTON - ACRES HARVESTED$` | Total only — includes Pima + Upland |
| 5 | Soybeans | `SOYBEANS` | `^SOYBEANS - ACRES HARVESTED$` | |
| 26 | Dbl Crop WinWht/Soybeans | — | — | No Census counterpart |
| 232 | Dbl Crop Lettuce/Cotton | — | — | No Census counterpart |
| 238 | Dbl Crop WinWht/Cotton | — | — | No Census counterpart |
| 239 | Dbl Crop Soybeans/Cotton | — | — | No Census counterpart |
| 240 | Dbl Crop Soybeans/Oats | — | — | No Census counterpart |
| 241 | Dbl Crop Corn/Soybeans | — | — | No Census counterpart |
| 254 | Dbl Crop Barley/Soybeans | — | — | No Census counterpart |

---

## Tolerant (Category 2)

| CDL Code | CDL Name | QuickStats Commodity | `keep_desc` | Notes |
|----------|----------|----------------------|-------------|-------|
| 1 | Corn | `CORN` | `^CORN, GRAIN - ACRES HARVESTED$` + `^CORN, SILAGE - ACRES HARVESTED$` | Two separate queries — CDL does not distinguish |
| 3 | Rice | `RICE` | `^RICE - ACRES HARVESTED$` | |
| 4 | Sorghum | `SORGHUM` | `^SORGHUM, GRAIN - ACRES HARVESTED$\|^SORGHUM, SILAGE - ACRES HARVESTED$` | CDL does not distinguish |
| 12 | Sweet Corn | `SWEET CORN` | `^SWEET CORN - ACRES HARVESTED$` | |
| 13 | Pop or Orn Corn | `POPCORN` | `^POPCORN - ACRES HARVESTED$` | |
| 21 | Barley | `BARLEY` | `^BARLEY - ACRES HARVESTED$` | |
| 22 | Durum Wheat | `WHEAT` | `^WHEAT - ACRES HARVESTED$` | Subtype of WHEAT total |
| 23 | Spring Wheat | `WHEAT` | `^WHEAT - ACRES HARVESTED$` | Subtype of WHEAT total |
| 24 | Winter Wheat | `WHEAT` | `^WHEAT - ACRES HARVESTED$` | Subtype of WHEAT total |
| 25 | Other Small Grains | `SMALL GRAINS` | `^SMALL GRAINS - ACRES HARVESTED$` | |
| 27 | Rye | `RYE` | `^RYE - ACRES HARVESTED$` | |
| 28 | Oats | `OATS` | `^OATS - ACRES HARVESTED$` | |
| 29 | Millet | `MILLET` | `^MILLET - ACRES HARVESTED$` | |
| 30 | Speltz | `EMMER & SPELT` | `^EMMER & SPELT - ACRES HARVESTED$` | SPELTZ not in QuickStats |
| 45 | Sugarcane | `SUGARCANE` | `^SUGARCANE - ACRES HARVESTED$` | |
| 205 | Triticale | `TRITICALE` | `^TRITICALE - ACRES HARVESTED$` | |
| 225–237 | Double crops (Tolerant) | — | — | No Census counterpart |

**Note on WHEAT:** total `^WHEAT - ACRES HARVESTED$` is used — already includes
Winter, Spring Durum, and Spring (Excl Durum) subtypes. Do not add subtypes separately.

---

## Vulnerable (Category 3)

| CDL Code | CDL Name | QuickStats Commodity | `statisticcat_desc` | `keep_desc` | Notes |
|----------|----------|----------------------|---------------------|-------------|-------|
| 6 | Sunflower | `SUNFLOWER` | AREA HARVESTED | `^SUNFLOWER - ACRES HARVESTED$` | |
| 10 | Peanuts | `PEANUTS` | AREA HARVESTED | `^PEANUTS - ACRES HARVESTED$` | |
| 11 | Tobacco | `TOBACCO` | AREA HARVESTED | `^TOBACCO - ACRES HARVESTED$` | |
| 14 | Mint | `MINT` | AREA HARVESTED | `^MINT - ACRES HARVESTED$` | |
| 31 | Canola | `CANOLA` | AREA HARVESTED | `^CANOLA - ACRES HARVESTED$` | |
| 32 | Flaxseed | `FLAXSEED` | AREA HARVESTED | `^FLAXSEED - ACRES HARVESTED$` | |
| 33 | Safflower | `SAFFLOWER` | AREA HARVESTED | `^SAFFLOWER - ACRES HARVESTED$` | |
| 34 | Rape Seed | `RAPESEED` | AREA HARVESTED | `^RAPESEED - ACRES HARVESTED$` | One word in QuickStats |
| 35 | Mustard | `MUSTARD` | AREA HARVESTED | `^MUSTARD - ACRES HARVESTED$` | |
| 36 | Alfalfa | `HAY` | AREA HARVESTED | `^HAY, ALFALFA - ACRES HARVESTED$` | |
| 37 | Other Hay | `HAY` | AREA HARVESTED | `^HAY - ACRES HARVESTED$` | Total HAY includes alfalfa — both queried together |
| 38 | Camelina | `CAMELINA` | AREA HARVESTED | `^CAMELINA - ACRES HARVESTED$` | |
| 39 | Buckwheat | `BUCKWHEAT` | AREA HARVESTED | `^BUCKWHEAT - ACRES HARVESTED$` | |
| 41 | Sugarbeets | `SUGARBEETS` | AREA HARVESTED | `^SUGARBEETS - ACRES HARVESTED$` | |
| 42+51 | Dry Beans + Chick Peas | `BEANS` | AREA HARVESTED | `^BEANS, DRY EDIBLE, INCL CHICKPEAS - ACRES HARVESTED$` | CDL 42+51 mapped to single Census aggregate |
| 43 | Potatoes | `POTATOES` | AREA HARVESTED | `^POTATOES - ACRES HARVESTED$` | |
| 44 | Other Crops | — | — | — | **Excluded** — no Census counterpart |
| 46 | Sweet Potatoes | `SWEET POTATOES` | AREA HARVESTED | `^SWEET POTATOES - ACRES HARVESTED$` | |
| 47 | Misc Vegs & Fruits | — | — | — | **Excluded** — too broad |
| 48+209+213 | Watermelons + Cantaloupes + Honeydew | `MELONS` | AREA HARVESTED | `^MELONS, CANTALOUP\|^MELONS, HONEYDEW\|^MELONS, WATERMELON` | Three CDL codes mapped to one Census commodity |
| 49 | Onions | `ONIONS` | AREA HARVESTED | `^ONIONS, DRY\|^ONIONS, GREEN` | Dry + Green summed |
| 50 | Cucumbers | `CUCUMBERS` | AREA HARVESTED | `^CUCUMBERS - ACRES HARVESTED$` | |
| 52 | Lentils | `LENTILS` | AREA HARVESTED | `^LENTILS - ACRES HARVESTED$` | |
| 53 | Peas | `PEAS` | AREA HARVESTED | `^PEAS, CHINESE\|^PEAS, GREEN, \(EXCL\|^PEAS, GREEN, SOUTHERN` | All subtypes summed |
| 54 | Tomatoes | `TOMATOES` | AREA HARVESTED | `^TOMATOES, IN THE OPEN - ACRES HARVESTED$` | `first_only=TRUE` — multiple sources |
| 55 | Caneberries | `CANEBERRIES` | AREA HARVESTED | `^CANEBERRIES - ACRES HARVESTED$` | |
| 56 | Hops | `HOPS` | AREA HARVESTED | `^HOPS - ACRES HARVESTED$` | |
| 57 | Herbs | `HERBS` | AREA HARVESTED | `^HERBS - ACRES HARVESTED$` | |
| 58 | Clover/Wildflowers | — | — | — | **Excluded** — partial match only |
| 66 | Cherries | `CHERRIES` | AREA BEARING | `^CHERRIES - ACRES BEARING$` | |
| 67 | Peaches | `PEACHES` | AREA BEARING | `^PEACHES, CLINGSTONE\|^PEACHES, FREESTONE` | No total available — sum subtypes |
| 68 | Apples | `APPLES` | AREA BEARING | `^APPLES - ACRES BEARING$` | |
| 69 | Grapes | `GRAPES` | AREA BEARING | `^GRAPES - ACRES BEARING$` | |
| 70 | Christmas Trees | `CUT CHRISTMAS TREES` | AREA HARVESTED | `^CUT CHRISTMAS TREES - ACRES HARVESTED$` | May be (D) in many counties |
| 71 | Other Tree Crops | — | — | — | **Excluded** — partial match only |
| 72 | Citrus | `ORANGES` | AREA BEARING | `^ORANGES - ACRES BEARING$` | CITRUS TOTALS excluded — already includes ORANGES |
| 74 | Pecans | `PECANS` | AREA BEARING | `^PECANS - ACRES BEARING$` | |
| 75 | Almonds | `ALMONDS` | AREA BEARING | `^ALMONDS - ACRES BEARING$` | |
| 76 | Walnuts | `WALNUTS` | AREA BEARING | `^WALNUTS, ENGLISH - ACRES BEARING$` | Only type in QuickStats |
| 77 | Pears | `PEARS` | AREA BEARING | `^PEARS - ACRES BEARING$` | |
| 204 | Pistachios | `PISTACHIOS` | AREA BEARING | `^PISTACHIOS - ACRES BEARING$` | |
| 206 | Carrots | `CARROTS` | AREA HARVESTED | `^CARROTS - ACRES HARVESTED$` | |
| 207 | Asparagus | `ASPARAGUS` | AREA HARVESTED | `^ASPARAGUS - ACRES HARVESTED$` | |
| 208 | Garlic | `GARLIC` | AREA HARVESTED | `^GARLIC - ACRES HARVESTED$` | |
| 210 | Prunes | `PRUNES` | AREA BEARING | `^PRUNES - ACRES BEARING$` | |
| 211 | Olives | `OLIVES` | AREA BEARING | `^OLIVES - ACRES BEARING$` | |
| 212 | Oranges | `ORANGES` | AREA BEARING | `^ORANGES - ACRES BEARING$` | |
| 214 | Broccoli | `BROCCOLI` | AREA HARVESTED | `^BROCCOLI - ACRES HARVESTED$` | |
| 215 | Avocados | `AVOCADOS` | AREA BEARING | `^AVOCADOS - ACRES BEARING$` | May be (D) — filtered automatically |
| 216 | Peppers | `PEPPERS` | AREA HARVESTED | `^PEPPERS, BELL\|^PEPPERS, CHILE` | Bell + Chile summed |
| 217 | Pomegranates | `POMEGRANATES` | AREA BEARING | `^POMEGRANATES - ACRES BEARING$` | |
| 218 | Nectarines | `NECTARINES` | AREA BEARING | `^NECTARINES - ACRES BEARING$` | |
| 219 | Greens | `GREENS` | AREA HARVESTED | `^GREENS - ACRES HARVESTED$` | |
| 220 | Plums | `PLUMS & PRUNES` | AREA BEARING | `^PLUMS & PRUNES - ACRES BEARING$` | |
| 221 | Strawberries | `STRAWBERRIES` | AREA HARVESTED | `^STRAWBERRIES - ACRES HARVESTED$` | |
| 222 | Squash | `SQUASH` | AREA HARVESTED | `^SQUASH - ACRES HARVESTED$` | |
| 223 | Apricots | `APRICOTS` | AREA BEARING | `^APRICOTS - ACRES BEARING$` | |
| 224 | Vetch | — | — | — | **Excluded** — no Census counterpart |
| 227 | Lettuce | `LETTUCE` | AREA HARVESTED | `^LETTUCE - ACRES HARVESTED$` | |
| 229 | Pumpkins | `PUMPKINS` | AREA HARVESTED | `^PUMPKINS - ACRES HARVESTED$` | |
| 231 | Dbl Crop Lettuce/Cantaloupe | — | — | — | No Census counterpart |
| 242 | Blueberries | `BLUEBERRIES` | AREA HARVESTED | `^BLUEBERRIES - ACRES HARVESTED$` | |
| 243 | Cabbage | `CABBAGE` | AREA HARVESTED | `^CABBAGE - ACRES HARVESTED$` | |
| 244 | Cauliflower | `CAULIFLOWER` | AREA HARVESTED | `^CAULIFLOWER - ACRES HARVESTED$` | |
| 245 | Celery | `CELERY` | AREA HARVESTED | `^CELERY - ACRES HARVESTED$` | |
| 246 | Radishes | `RADISHES` | AREA HARVESTED | `^RADISHES - ACRES HARVESTED$` | |
| 247 | Turnips | `TURNIPS` | AREA HARVESTED | `^TURNIPS - ACRES HARVESTED$` | |
| 248 | Eggplants | `EGGPLANT` | AREA HARVESTED | `^EGGPLANT - ACRES HARVESTED$` | No S in QuickStats |
| 249 | Gourds | `GOURDS` | AREA HARVESTED | `^GOURDS - ACRES HARVESTED$` | |
| 250 | Cranberries | `CRANBERRIES` | AREA HARVESTED | `^CRANBERRIES - ACRES HARVESTED$` | |

---

## CDL codes with no Census counterpart

Excluded from validation. Pixels ARE counted in CDL acres → upward bias for Vulnerable.

| CDL Code | CDL Name | Reason |
|----------|----------|--------|
| 44 | Other Crops | Too broad |
| 47 | Misc Vegs & Fruits | Too broad |
| 58 | Clover/Wildflowers | Partial match only |
| 71 | Other Tree Crops | Partial match only |
| 224 | Vetch | No Census counterpart |
| All double crops | 26,232,238,239,240,241,254,225–237,231 | Not tracked separately in Census |

---

## Special cases

**MELONS:** QuickStats aggregates watermelons (CDL 48) + cantaloupes (CDL 209)
+ honeydew (CDL 213). Sum all three `short_desc` rows.

**HAY:** CDL 36 (Alfalfa) → `HAY, ALFALFA - ACRES HARVESTED`;
CDL 37 (Other Hay) → `HAY - ACRES HARVESTED` (total). Both queried together
with a single `keep_desc` OR pattern. Sum of both rows = CDL 36 + 37 total.

**PEACHES:** No total available in QuickStats — sum
`PEACHES, CLINGSTONE - ACRES BEARING` + `PEACHES, FREESTONE - ACRES BEARING`.

**WALNUTS:** Only `WALNUTS, ENGLISH` available. Use
`^WALNUTS, ENGLISH - ACRES BEARING$` not `^WALNUTS - ACRES BEARING$`.

**CITRUS TOTALS:** Excluded — already included in `ORANGES - ACRES BEARING`.
Using both would double-count.

**TOMATOES:** Multiple sources (Census + Survey) return same `short_desc`.
Use `first_only = TRUE` to keep Census row only.

**CORN:** Two separate queries required (grain + silage) each with
`first_only = TRUE`, because a single query with OR pattern would
deduplicate across both `short_desc` values incorrectly.

**CHICKPEAS (CDL 51):** Mapped together with Dry Beans (CDL 42) via
`BEANS, DRY EDIBLE, INCL CHICKPEAS - ACRES HARVESTED` in QuickStats.
No separate CHICKPEAS commodity available at county level.
