# Dicamba Research LULCC

Research project investigating crop land-cover-change in the US, focusing on
Dicamba-tolerant crop adoption (soybean, cotton) and its impact on vulnerable
crops. Uses the USDA NASS CDL (2009–2018) at 30m resolution.

After initial building of the logic on GEE, the pipeline has been moved mainly in R (unmanageable/timeout in GEE) and use TSE HPC cluster.

## Structure

```
├── GEE/codes/          JavaScript exploration scripts
├── R/codes/            Main analysis pipeline (run in order)
└── docs/               Methodological documentation
    ├── context/            Project overview, background notes
    └── decisions/          Classification and directory structure decisions
```

> `data/` and `outputs/` are generated locally by the R scripts — not tracked on GitHub.

## Status

| Step | Script | Status |
|---|---|---|
| Download Census shapefiles | `R/codes/000_get_SF_files.R` | done |
| Clip national CDL to counties | `R/codes/00_setup_and_clip.R` | tested on 2 states for the 2009–2011 period |
| Mask + classify pixels | `R/codes/01_mask_and_classify.R` | draft finished but improvement needed |
| Transition matrices | `R/codes/02_transition_matrix.R` | draft finished but improvement needed |
| Merge & align national confidence raster | `R/codes/03_confidence_NAT.R` | done for 2012 |
| Clip national confidence to counties | `R/codes/04_clip_confidence.R` | done for 2012 |
| Check Census of Agriculture availability | `R/codes/05_availability_census.R` | done for 2012 |
| Compute Census acres by category | `R/codes/06_census_acres.R` | done for 2012 |
| Compute baseline bias (CDL vs Census) | `R/codes/07_bias_measure.R` | done for 2012 |
| Compute baseline confidence quality index | `R/codes/08_confidence_baseline.R` | done for 2012 |
| Scale up to 48 states / all years | — | pending |
| Statistical analysis / reclassification model | — | pending |

## Key Links

- [CDL download (SARS)](https://www.nass.usda.gov/Research_and_Science/Cropland/SARS1a.php) use this, not the Geospatial Data Gateway which use a different projection :"In order to conform to Geospatial Data Gateway technical specifications, any CDL data downloaded through the Geospatial Data Gateway is re-projected from Albers to the dominant Universal Transverse Mercator (UTM) zone with a spheroid of GRS 1980 and datum of NAD83".
- [CDL on GEE](https://developers.google.com/earth-engine/datasets/catalog/USDA_NASS_CDL)
- See `docs/context/use_of_projection.md` for CRS checks (CDL / R / GEE)
- See `docs/context/double_cropping.md` for double-crop priority rules

## Author

Raphaël Perilhou
