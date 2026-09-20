# Packaging resolution log

## Figure 2 independent-review findings

The initial independent review identified three reproducibility-documentation defects after confirming the S1/E–F numerical results. A later manuscript-to-artifact audit found a fourth defect: the submitted A–B maps used rounded raw-P masking rather than the revised sex-specific BH q-value rule. `reports/Figure2_independent_review.md` is the retained final-state review; superseded internal iteration records are excluded from the public package.

1. **Path-string hashes in the full-composite script.** The final source and package copies of `code/figure2/02_compose_full_figure2.R` call `digest::digest(file = f, ...)` for both input and output manifests. `derived_data/figure2/Figure2_full_input_checksums_sha256.csv` and `Figure2_full_output_checksums_sha256.csv` contain independently verifiable file-content SHA-256 values.
2. **Stale duplicate-key artifact.** The correction script now overwrites `population_duplicate_keys.csv` on every run. The included current-run file contains the header schema and zero data rows, consistent with `population_merge_coverage.csv` and the independent reconstruction that found zero duplicate keys.
3. **Non-estimable younger ages.** `derived_data/figure2/calculation_notes.md` and the top-level run instructions now state that `<5`, `5-9`, and `10-14` years are non-estimable because the annual IHD series are constant; panels E-F display the 17 estimable groups from `15-19` through `95+`.
4. **A–B display rule.** Panels A–B are regenerated from corrected unrounded-P sex-specific BH q values; exactly 46/204 female and 109/204 male locations are coloured. The final composite retains only C–D from the submitted raster. The package includes the exact 204-row ISO3/geometry crosswalk, cartographic procedure, and numerical/raster QA.

The corrected scripts were rerun after these resolutions. The package-level checksum manifest was generated from the final artifacts and supersedes stale checksum references copied from earlier runs.

## Nonportable XLSX convenience exports

Final OOXML relationship validation found broken drawing/VML references and incorrect declared worksheet dimensions in four convenience workbooks (`Supplementary_Table_S1_corrected.xlsx`, `correlation_SID_excluded_sensitivity.xlsx`, `Supplementary_Table_S2_corrected.xlsx`, and `GWR_verified_results.xlsx`). They were excluded from the public release rather than represented as portable outputs. Their authoritative CSV tables, generation scripts, execution-time hashes, and the independently validated supplementary DOCX remain included. Execution-time component checksum records may therefore name these omitted local artifacts; the top-level package manifest is the authoritative inventory of distributed files.

## Historical display assets

The private Figure 1 and Figure 3 TIFF and Illustrator files contain machine-specific source-path metadata. They were excluded from the public package. Derived audit tables, sanitised `.R.txt` code references, and the private-original hashes in `manifests/legacy_source_artifact_inventory.csv` retain the auditable historical record without distributing those local paths.
