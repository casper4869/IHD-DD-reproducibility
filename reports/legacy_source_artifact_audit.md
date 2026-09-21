# Legacy source-artifact audit

This audit searched the existing project tree for evidence that could support the reviewer-facing reproducibility record for raw-to-final GBD processing, Figures 1 and 3, SDI, PM2.5, and coordinates. Files were inventoried by absolute workspace path, byte count, and SHA-256 in `manifests/legacy_source_artifact_inventory.csv`. Syntax checks are in `manifests/legacy_script_parse_audit.csv`.

## What was verified

- The combined local GBD IHD and DD extracts exist and match the hashes already recorded in the main input inventory.
- Twelve selected legacy R scripts parse under R 4.5.0. Parseability is only a syntax check; it does not establish that a script is scientifically correct or runnable on a clean system.
- Seven Figure 1 scripts and the main Figure 1 raster/Illustrator artifacts were located in the private workspace. The two 204-row `Match_updated_with_columns_*` files explicitly store DD as `mark1` and IHD as `mark2`.
- The Figure 3 female and male temporal blocks use annual within-year quartiles for 1992-2021. Each saved count file has 90 rows (30 years by three classes), and the three class counts sum to 204 in every year.
- The SDI source, 204-location name list, transformation script, and derived wide matrix were fingerprinted.
- The Part 6 PM2.5 matrix and the Part 7 matched PM2.5 file are byte-identical: both are 40,070 bytes with SHA-256 `084290b1f9c24eaf980bcb0a354d496b6f46b6594da8171c6b61a88c0bb311b0`. This verifies local file lineage only.
- The 204-row coordinate file was fingerprinted. The legacy GWR script confirms that this file supplies the `lat` and `lng` columns used in the spatial models.

## Why these are not presented as corrected release code

The only root-level file named `Data preprocessing.R` is an older rheumatoid-arthritis/anxiety-disorders example. It does not preprocess IHD or depressive-disorder data, so it cannot be used to claim an end-to-end IHD/DD pipeline.

The Figure 1 scripts contain absolute local paths, round 2021 rates to two decimals before constructing quartiles, perform extensive manual name/polygon handling, and split the final workflow across several scripts plus an Illustrator file. The bivariate source tables are useful audit evidence, but the disease-axis orientation and display transformations were not independently rerun and therefore are not promoted to corrected release code in `v1.0.0`.

The Figure 3 scripts contain obsolete drive-specific paths and combine the temporal typology with unrelated map and correlation code. The saved count tables are structurally coherent, but no clean parameterised script has yet reproduced the exact submitted graphic from immutable inputs.

The SDI script performs a positional deletion of row 105 before matching. The available code does not document why that row is removed, and the source file lacks a complete provider query record. A release script should replace positional deletion with an explicit identifier-based rule and preserve a merge audit.

## Provenance gaps that remain exact and unresolved

| Item | What is known | What is still required |
|---|---|---|
| GBD raw-to-final processing | Raw IHD/DD extracts and many derived matrices are locally present and fingerprinted | One corrected script that filters the exact incidence records, validates 204 locations/years/sex/age strata, and emits every downstream matrix with checksums |
| Figure 1 | Legacy scripts, 204-row source tables, TIFF, and Illustrator source were found in the private workspace; the public package includes path-redacted script references and derived tables, while display assets with embedded local-path metadata are omitted | Full-precision quartile recomputation, stable location-ID mapping, disease-axis audit, display crosswalk, and a clean exact-output build |
| Figure 3 | Legacy scripts and internally coherent 1992-2021 count tables were found | Clean entry point, input identity, exact class rule audit, and exact-output visual comparison |
| PM2.5 | The two local copies are byte-identical and cover 204 locations by 30 years | Provider, product/version, unit, retrieval date, licence, country aggregation/matching method, and upstream extraction code |
| Coordinates | A 204-row `location_name,lat,lng` file is present and used by GWR | Source gazetteer/geocoder, coordinate definition, version, retrieval date, licence, and matching code |
| SDI | Source, name list, script, and 204-row output are present | Provider query metadata and replacement of unexplained positional row deletion with an auditable ID-based rule |

The current package therefore documents these files as located evidence with explicit limitations. Sanitised script copies are quarantined under `code/historical_reference/`, and the small derived Figure 1/3 source tables are included for audit. Historical TIFF and Illustrator assets are omitted because their embedded metadata retains machine-specific source paths. None of these records is labelled as a corrected entry point or an independently reproducible raw-to-final workflow.
