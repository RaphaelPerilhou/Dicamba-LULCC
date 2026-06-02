# CDL Crop Classification — Decision Log

## Overview

This document records the final classification of USDA Cropland Data Layer (CDL)
codes we use. It explains the category scheme, the priority rules for double crops.
It is the authoritative reference for both the R pipeline
(`cdltools`) and the GEE validation script (`Validation_script.js`), which must
remain in sync.


## Category Scheme

| Cat. Code | Label        | Definition |
|-----------|--------------|------------|
| 0         | NonCrop      | Inside the union mask but not actively cropped this year (fallow/idle) |
| 1         | GM-enabled   | Crops with commercially deployed GM-Dicamba tolerance (soy, cotton, and double crops with a GM component) |
| 2         | Tolerant     | True cereals and monocots with inherent or commercial Dicamba tolerance, and related double crops |
| 3         | Vulnerable   | Dicots |
| 99        | Others       | Pixel is inside the union mask but its CDL code that year is not mapped to {0, 1, 2, 3} |
| NA        | Outside mask | Pixel was never agricultural across the full study period. We exclude them from the analysis |

## Priority Rule for Double Crops

When a CDL double-crop code combines components from different categories, the
**highest-priority category wins**:

```
GM-enabled (1) > Tolerant (2) > Vulnerable (3)
```

Examples:
- Dbl Crop WinWht/Soybeans (26) -> GM-enabled (soy component)
- Dbl Crop Lettuce/Durum Wht (230) -> Tolerant (wheat over lettuce)
- Dbl Crop Lettuce/Cantaloupe (231) -> Vulnerable (both components vulnerable)

**Remark**: More details on `docs/context/double_cropping.md`

## 99: Others

A pixel enters the union mask if it carried **any** in-mask CDL code in **at
least one year** of the study period. Once inside the mask, a pixel is
classified each year according to its CDL code.

Any pixel inside the union mask whose CDL code that year is **not explicitly
mapped to {0, 1, 2, 3}** receives **99**. This covers all special cases such as
pixels that were forest, pasture, developed, or any other non-agricultural
cover in years before or after they were agricultural. For example, a pixel
that was Soy in 2012 (and thus enters the mask) but shows Forest (63) in 2009
will be classified as 99 in 2009.

```r
classified <- ifel(
  !is.na(union_mask) & is.na(classified), 99L,
  classified
)
```

## Full Classification Table

### NonCrop (0)

| Code | Land Cover | Section |
|------|------------|---------|
| 61 | Fallow/Idle Cropland | Non-Crop 61-65 |

> Fallow is actively managed cropland resting between rotations. It is the
> **only** NonCrop code.

### GM-enabled (1)

| Code | Land Cover | Section | Notes |
|------|------------|---------|-------|
| 2 | Cotton | Crops 1-60 | |
| 5 | Soybeans | Crops 1-60 | |
| 26 | Dbl Crop WinWht/Soybeans | Crops 1-60 | GM priority over Tolerant |
| 232 | Dbl Crop Lettuce/Cotton | Crops 200-255 | GM priority over Vulnerable |
| 238 | Dbl Crop WinWht/Cotton | Crops 200-255 | GM priority over Tolerant |
| 239 | Dbl Crop Soybeans/Cotton | Crops 200-255 | |
| 240 | Dbl Crop Soybeans/Oats | Crops 200-255 | GM priority over Tolerant |
| 241 | Dbl Crop Corn/Soybeans | Crops 200-255 | GM priority over Tolerant |
| 254 | Dbl Crop Barley/Soybeans | Crops 200-255 | GM priority over Tolerant |

### Tolerant (2)

| Code | Land Cover | Section | Notes |
|------|------------|---------|-------|
| 1 | Corn | Crops 1-60 | |
| 3 | Rice | Crops 1-60 | |
| 4 | Sorghum | Crops 1-60 | |
| 12 | Sweet Corn | Crops 1-60 | |
| 13 | Pop or Orn Corn | Crops 1-60 | |
| 21 | Barley | Crops 1-60 | |
| 22 | Durum Wheat | Crops 1-60 | |
| 23 | Spring Wheat | Crops 1-60 | |
| 24 | Winter Wheat | Crops 1-60 | |
| 25 | Other Small Grains | Crops 1-60 | |
| 27 | Rye | Crops 1-60 | |
| 28 | Oats | Crops 1-60 | |
| 29 | Millet | Crops 1-60 | |
| 30 | Speltz | Crops 1-60 | |
| 45 | Sugarcane | Crops 1-60 | |
| 205 | Triticale | Crops 200-255 | |
| 225 | Dbl Crop WinWht/Corn | Crops 200-255 | |
| 226 | Dbl Crop Oats/Corn | Crops 200-255 | |
| 228 | Dbl Crop Triticale/Corn | Crops 200-255 | |
| 230 | Dbl Crop Lettuce/Durum Wht | Crops 200-255 | Tolerant priority over Vulnerable |
| 233 | Dbl Crop Lettuce/Barley | Crops 200-255 | Tolerant priority over Vulnerable |
| 234 | Dbl Crop Durum Wht/Sorghum | Crops 200-255 | |
| 235 | Dbl Crop Barley/Sorghum | Crops 200-255 | |
| 236 | Dbl Crop WinWht/Sorghum | Crops 200-255 | |
| 237 | Dbl Crop Barley/Corn | Crops 200-255 | |

### Vulnerable (3)

| Code | Land Cover | Section |
|------|------------|---------|
| 6 | Sunflower | Crops 1-60 |
| 10 | Peanuts | Crops 1-60 |
| 11 | Tobacco | Crops 1-60 |
| 14 | Mint | Crops 1-60 |
| 31 | Canola | Crops 1-60 |
| 32 | Flaxseed | Crops 1-60 |
| 33 | Safflower | Crops 1-60 |
| 34 | Rape Seed | Crops 1-60 |
| 35 | Mustard | Crops 1-60 |
| 36 | Alfalfa | Crops 1-60 |
| 37 | Other Hay/Non Alfalfa | Crops 1-60 |
| 38 | Camelina | Crops 1-60 |
| 39 | Buckwheat | Crops 1-60 |
| 41 | Sugarbeets | Crops 1-60 |
| 42 | Dry Beans | Crops 1-60 |
| 43 | Potatoes | Crops 1-60 |
| 44 | Other Crops | Crops 1-60 |
| 46 | Sweet Potatoes | Crops 1-60 |
| 47 | Misc Vegs & Fruits | Crops 1-60 |
| 48 | Watermelons | Crops 1-60 |
| 49 | Onions | Crops 1-60 |
| 50 | Cucumbers | Crops 1-60 |
| 51 | Chick Peas | Crops 1-60 |
| 52 | Lentils | Crops 1-60 |
| 53 | Peas | Crops 1-60 |
| 54 | Tomatoes | Crops 1-60 |
| 55 | Caneberries | Crops 1-60 |
| 56 | Hops | Crops 1-60 |
| 57 | Herbs | Crops 1-60 |
| 58 | Clover/Wildflowers | Crops 1-60 |
| 66 | Cherries | Crops 66-80 |
| 67 | Peaches | Crops 66-80 |
| 68 | Apples | Crops 66-80 |
| 69 | Grapes | Crops 66-80 |
| 70 | Christmas Trees | Crops 66-80 |
| 71 | Other Tree Crops | Crops 66-80 |
| 72 | Citrus | Crops 66-80 |
| 74 | Pecans | Crops 66-80 |
| 75 | Almonds | Crops 66-80 |
| 76 | Walnuts | Crops 66-80 |
| 77 | Pears | Crops 66-80 |
| 204 | Pistachios | Crops 200-255 |
| 206 | Carrots | Crops 200-255 |
| 207 | Asparagus | Crops 200-255 |
| 208 | Garlic | Crops 200-255 |
| 209 | Cantaloupes | Crops 200-255 |
| 210 | Prunes | Crops 200-255 |
| 211 | Olives | Crops 200-255 |
| 212 | Oranges | Crops 200-255 |
| 213 | Honeydew Melons | Crops 200-255 |
| 214 | Broccoli | Crops 200-255 |
| 215 | Avocados | Crops 200-255 |
| 216 | Peppers | Crops 200-255 |
| 217 | Pomegranates | Crops 200-255 |
| 218 | Nectarines | Crops 200-255 |
| 219 | Greens | Crops 200-255 |
| 220 | Plums | Crops 200-255 |
| 221 | Strawberries | Crops 200-255 |
| 222 | Squash | Crops 200-255 |
| 223 | Apricots | Crops 200-255 |
| 224 | Vetch | Crops 200-255 |
| 227 | Lettuce | Crops 200-255 |
| 229 | Pumpkins | Crops 200-255 |
| 231 | Dbl Crop Lettuce/Cantaloupe | Crops 200-255 |
| 242 | Blueberries | Crops 200-255 |
| 243 | Cabbage | Crops 200-255 |
| 244 | Cauliflower | Crops 200-255 |
| 245 | Celery | Crops 200-255 |
| 246 | Radishes | Crops 200-255 |
| 247 | Turnips | Crops 200-255 |
| 248 | Eggplants | Crops 200-255 |
| 249 | Gourds | Crops 200-255 |
| 250 | Cranberries | Crops 200-255 |


### Unclassified (99)

Any CDL code **not** explicitly mapped to {0, 1, 2, 3} above will receive 99
if the pixel is inside the union mask.


## Implementation Notes

- **GEE sync required**: any change to this classification must be mirrored
  in `Validation_script.js`.
