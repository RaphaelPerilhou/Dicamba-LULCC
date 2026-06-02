# Union Mask: Design and Special Cases

## What it is

A single binary mask built once across the full study period (2009–2018). A pixel
is retained (value = 1) if it carried an agricultural CDL code in **at least one**
year. Pixels that were never agricultural in any year are excluded (NA).

```r
union_mask = mask_2009 OR mask_2010 OR ... OR mask_2018
```

## Why not a yearly mask?

Following Lark et al. (2017), a yearly mask introduces two biases:

- It hides real crop vs non-crop transitions by excluding the pixel in the year it
  transitions out of agriculture.
- It amplifies apparent cropland expansion because the CDL underestimates cultivated
  area in early years, so yearly masks exclude more pixels in early years simply
  due to data quality, not actual land use.

## Classification within the union mask

For each year, every pixel in the union mask is classified as:

| Code | Category | When assigned |
|---|---|---|
| 1 | GM-enabled | Pixel carries a GM crop code this year |
| 2 | Tolerant | Pixel carries a tolerant cereal code this year |
| 3 | Vulnerable | Pixel carries any other agricultural code this year |
| 0 | NonCrop | Pixel is in union mask but not agricultural this year |

## Edge cases

**Pixel agricultural in only one year:**
A pixel that was Soy in 2009 and Open Water (111) in all other years is retained
by the union mask. In 2009 it is classified as GM (1). In all other years its CDL
code is not mapped to {0, 1, 2, 3}, so it receives 99 (Unclassified). This
can reflect various situations (e.g cropland abandonment, temporary land use change,
CDL misclassification, or a genuine transition to a land cover type outside the
agricultural classification scheme). Rather than forcing an arbitrary category or
dropping the pixel entirely, 99 preserves these ambiguous observations in the
transition matrix while flagging them as requiring caution in interpretation.
```r
# Pixels inside union mask but unclassified (not in reclass_table) become 99
# Pixels outside union mask stay NA (excluded entirely)
classified <- ifel(
  !is.na(union_mask) & is.na(classified), 99L,
  classified
)
```
**Fallow/Idle Cropland (code 61):**
Explicitly included in the agricultural mask and explicitly assigned NonCrop (0)
in classification. Fallow represents an active agronomic decision within a crop
rotation and should remain in the universe of observed pixels. It is the primary
driver of NonCrop counts, particularly in Great Plains states where dryland
farming involves regular fallow years.

**CDL misclassification:**
If a pixel was genuinely non-agricultural but misclassified as a crop in one year
by the CDL, it enters the union mask and generates a spurious transition. This is
a data quality issue inherent to the CDL, not a methodology issue. At the scale
of millions of pixels it represents negligible noise. <<TRY TO IDENTIFY HOW MANY IT REPRESENTS>>

## Reference

Lark, T.J., Mueller, R.M., Johnson, D.M., Gibbs, H.K. (2017). Measuring
land-use and land-cover change using the U.S. department of agriculture's
cropland data layer: Cautions and recommendations. *Int J Appl Earth Obs
Geoinformation*, 62, 224–235.
