# Dicamba Research LULCC

Research project investigating crop land-cover-change in the US, focusing on
Dicamba-tolerant crop adoption (soybean, cotton) and its impact on vulnerable
crops. Uses the USDA NASS CDL (2009–2018) at 30m resolution.

After initial building of the logic on GEE, the pipeline has been moved mainly in R (unmanageable/timeout in GEE) and use TSE HPC cluster.

## Structure

```
├── GEE/codes/          JavaScript exploration scripts
├── R/codes/            Main analysis pipeline (run in order)
└── DOCS/notes/         Methodological documentation
```

> `data/` and `outputs/` are generated locally by the R scripts — not tracked on GitHub.

## Status

| Step | Script | Status |
|---|---|---|
| Clip national CDL to states | `R/00_setup_and_clip.R` | tested on 2 states for the 2009–2011 period |
| Mask + classify pixels | `R/01_mask_and_classify.R` | draft finished but improvement needed |
| Transition matrices | `R/02_transition_matrix.R` | draft finished but imrpovement needed |
| Scale up to 48 states | wait for ANUBIS | pending |
| Statistical analysis | TBD | pending |

## Key Links

- [CDL download (SARS)](https://www.nass.usda.gov/Research_and_Science/Cropland/SARS1a.php) use this, not the Geospatial Data Gateway which use a different projection :"In order to conform to Geospatial Data Gateway technical specifications, any CDL data downloaded through the Geospatial Data Gateway is re-projected from Albers to the dominant Universal Transverse Mercator (UTM) zone with a spheroid of GRS 1980 and datum of NAD83".
- [CDL on GEE](https://developers.google.com/earth-engine/datasets/catalog/USDA_NASS_CDL)
- See `DOCS/notes/use_of_projection.md` for CRS checks (CDL / R / GEE)
- See `DOCS/notes/double_cropping.md` for double-crop priority rules

## Author

Raphaël Perilhou
