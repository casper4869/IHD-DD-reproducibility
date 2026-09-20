# Reproducibility scope audit

## Included and traceable

- The Figure 2 correction has explicit source-file hashes, a reproducible definition of both correlation estimands, unrounded P-value handling, sex-specific BH families, population matching checks, and an explicit record that the three younger age groups are non-estimable because their IHD series are constant. Panels A–B are regenerated from corrected q values (46/204 female and 109/204 male displayed), C–D alone are retained from the submitted source, and E–F are regenerated. The package includes the exact 204-row display crosswalk, cartographic procedure, final-state independent review, and a 45-unit cartographic/SID sensitivity for S1 and all 17 estimable Figure 2E-F age groups.
- The forecast component contains a reproducible reconstruction of the original VARX and ARIMAX specifications, model-instability and clipping diagnostics, harmonised-scale sensitivity analysis, rolling-origin validation, a balanced source table/figure, and an explicit explanation for removing the former non-statistical ±15% ribbon.
- The exploratory MR component includes the preserved 15,703-row catalogue, a complete reconstructed catalogue-to-analysis status manifest, compact IHD/DD aggregate results, all-source hashes, three explicitly defined candidate sets, and the final 29-candidate Table 1/Figure 7 source tables with a session record. The final display uses separate IHD and DD BH-q axes rather than the former composite score.
- The corrected temporal-precedence analysis has separate directional equations, SDI as an exogenous control, unrounded direction-specific BH families, fixed-lag, HC3, and 45-unit exclusion sensitivities, full country-level results, diagnostics, checksums, and a session record. Its classification remains provisional for inferential use because the short series and covariance/diagnostic sensitivity materially affect interpretation. A corrected Figure 5 displays the Newey-West/HC3 contrast as an exploratory specification-sensitivity result.
- The GWR component records the actual 2021 estimands, full-sample standardisation, Gaussian fixed kernels, great-circle distances, leave-one-out cross-validation bandwidths, full and 45-unit-excluded fits (retained n = 159), local coefficient source data, and an independent weighted-least-squares reconstruction that matches the `spgwr` coefficients. The minimally revised Figure 6 preserves the original coordinate-point layout and uses one complete shared colour scale instead of saturating 12 coefficients outside −1 to 1.
- The supplementary DOCX builder and validator reproduce the fixed-grid display from corrected S1/S2 CSVs; the packaged validation confirms 204 displayed rows for each table and exact formatted-cell agreement.
- Private-workspace legacy preprocessing, Figure 1, Figure 3, SDI, PM2.5, and coordinate artifacts are fingerprinted in a separate inventory. The public package includes only path-redacted `.R.txt` reference copies for the located Figure 1, Figure 3, and SDI scripts plus small derived audit tables; raw provider files and historical display assets remain private. This provides an auditable gap record without presenting the legacy scripts as corrected entry points.

## Included for audit but not endorsed as valid revised analysis

- Legacy Figure 2/S1 values appear only in comparison files.
- Forecast reconstruction outputs are retained to demonstrate why the precise VARX headline is not supportable. Their presence does not validate the original forecast.
- The former 50-row Table 1/Figure 7 composite-score transformation files and scripts are excluded from the release. Only `derived_data/mr/manifest/04_table1_local_run_crosscheck.csv` retains the row-level comparison needed to document why the old table was replaced; it is clearly labelled as an audit cross-check and is not a current display source.

## Not included

- Raw GBD/IHME files and processed matrices are not duplicated into the package because provider redistribution rights have not been confirmed. Exact local fingerprints and retrieval steps are supplied instead.
- Fit-cache `.rds` files are omitted because they are unkeyed computational caches and can conceal stale results. Clean reruns should regenerate them.
- Legacy scripts with unresolved or mismatched specifications appear only as non-executable, path-redacted `.R.txt` provenance records and are not offered as the revised code path.
- OpenGWAS credentials, account information, and tokens are never included.

## Known scope gaps

- The exact submitted-table DD SNP-level run, harmonised instruments, and pleiotropy/sensitivity estimators were not retained. This is a disclosed permanent limitation; the aggregate 15,703-record catalogue-to-analysis status manifest itself is included.
- Curated parameterised raw-to-final, Figure 1, and Figure 3 entry points; private-original fingerprints and the path-redacted reference records remain insufficient for clean reruns.
- Verified external source metadata and generation code for PM2.5 and coordinates.
- Release-specific FinnGen/Risteys endpoint metadata and exports.
- Parameterised release paths and a clean-environment rerun.

This audit supports public deposition of the current aggregate-result reconstruction at https://github.com/casper4869/IHD-DD-reproducibility with the stated limits and rights-retained terms. The version `1.0.0` Zenodo DOI will be added after archival. The audit does not support wording that the historical SNP-level DD run or MR sensitivity analyses are reproducible; unresolved non-MR provenance remains explicitly disclosed.
