# MR code map

All revision-critical MR reconstruction steps except the explicitly optional online sensitivity script are offline.

- `00_catalogue_snapshot_provenance.R` validates the included 15,703-row `ao.csv` offline by default. An explicitly enabled refresh makes one catalogue request, writes only to a new path, and is not needed for historical reproduction.
- `01_build_exploratory_mr_audit.R` generated the full catalogue-to-analysis status manifest from the historical local archive and verified the numbered one-row result files against the compact aggregates. A complete historical archive path is required because those redundant numbered files are not redistributed.
- `alternative_sets/build_alternative_mr_sets.py` regenerates candidate Sets A-C from the packaged catalogue and aggregate results. It requires an explicit new output directory and makes no network request.
- `02_build_final_mr_reporting.R` verifies the final 29-candidate Set B and generates final table/figure source files.
- The completed final-29-trait instrument-level follow-up is under `../../mr_sensitivity_29/`; it covers 58 exposure-outcome pairs and includes cached inputs, 232 estimator results, diagnostics, leave-one-out/single-SNP output and MR-PRESSO. `opengwas_sensitivity_rerun_RATE_LIMITED.R` remains a disabled-by-default historical safe template. Neither workflow may be parallelised or used as a crawler.

The exploratory screen had no manual phenotype pre-selection. The 49-trait Set A was derived after analysis, and the 29-trait Set B applied the `finn-b-*` reporting safeguard only after that screen. See `../../MR_SCREEN_FLOW.md` and `../../MR_RECONSTRUCTION_README.md` for methods, commands, provenance, safeguards, and limitations.
