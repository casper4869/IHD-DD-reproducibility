# Public repository v1.0.0 QA

QA date: 2026-09-20

## Structural and safety checks

- All 16 release `.R` scripts and all 12 quarantined historical `.R.txt` references parsed successfully under R 4.5.0; zero parse failures. The 12 references comprise 10 Figure 1/Figure 3/SDI records and two MR provenance records.
- All three packaged Python scripts passed AST parsing.
- All 114 packaged CSV files were read with a standards-compliant parser; zero row-width failures.
- The packaged supplementary DOCX passed ZIP/XML relationship checks and the independent 204-row S1/204-row S2 content validator. Four nonportable XLSX convenience exports with broken drawing relationships were excluded; their authoritative CSV tables and generation code remain included.
- `.zenodo.json` passed JSON parsing with four creators, version `1.0.0`, open file access, and the conservative `other-closed` rights identifier. `CITATION.cff` passed YAML parsing with the same four creators and version.
- The largest file is `figures/Figure2_EF_corrected.tif` at 26,220,552 bytes, below GitHub's per-file limit.
- A byte-level scan found no GitHub token, literal JWT, private key, or quoted password assignment.
- No `__pycache__` file is present.
- Machine-specific project/revision roots in public text records were replaced by `<LOCAL_PROJECT_ROOT>` or `<LOCAL_REVISION_WORKSPACE>`.
- Historical Figure 1/Figure 3 TIFF and Illustrator assets with embedded machine-specific path metadata were excluded; path-redacted script records, derived audit tables, and private-original hashes remain. Superseded internal analysis-closure iteration reports were also excluded, leaving final-state QA records.

## MR catalogue and scheduling checks

- `source_data/mr/ao.csv` contains 15,703 rows and 15,703 unique OpenGWAS IDs. The count is explicitly described as a historical catalogue snapshot rather than completed MR analyses.
- `code/mr/00_catalogue_snapshot_provenance.R` validated all 15,703 rows offline and reported that no OpenGWAS request was made.
- The reconstructed status manifest contains 15,703 rows, including 11,989 European-ancestry catalogue records.
- The manifest contains 11,988 scheduled exposures for IHD and 11,988 for DD. Its scope/scheduling fields contain no `inclusion`, `exclusion`, or `decision` column name that could imply a manual phenotype review.
- Compact aggregate files contribute 5,880 saved IHD and 11,775 saved DD estimates. Missing scheduled outputs remain labelled `no saved estimate; exact reason not recorded`.
- The documentation states that no phenotype was manually pre-selected by name, relevance, modifiability, expected direction, or result.

## Candidate-set and final-reporting checks

- An independent offline rerun of `build_alternative_mr_sets.py` reproduced seven substantive candidate-set CSVs byte for byte.
- Set A contains 49 traits. Set B contains 29 traits after the post-screen `finn-b-*` safeguard; it contains zero `finn-b-*` IDs, 20 concordant-positive traits, and 9 concordant-negative traits. Set C contains 18 traits and is labelled descriptive sensitivity only.
- The repository explains that the Set B safeguard reduces participant-overlap and same-biobank dependence because both outcomes are FinnGen datasets; it is not presented as a universal different-database requirement.
- An independent offline rerun of `02_build_final_mr_reporting.R` reproduced `Table1_candidate_traits_29.csv`, `Table1_display_source_29.csv`, and `Figure7_Table1_QA.csv` byte for byte.

## Figure 6 checks

- The included Figure 6 source table contains 408 rows: 204 study units for each directional GWR panel, with one recorded representative coordinate per study unit.
- The complete observed coefficient range is −1.607 to 1.045. The submitted ±1 colour scale saturated 12 estimates; the minimally revised figure uses one symmetric ±1.7 scale and truncates none.
- A clean offline rerun of `code/gwr/05_build_figure6.R` reproduced the packaged PNG, SVG, and TIFF byte for byte. The TIFF is 4,322 × 3,685 pixels at 600 dpi. Visual inspection confirmed the original two-panel coordinate-point evidence form and the corrected shared scale.

## OpenGWAS access safeguards

- Primary catalogue/status reconstruction, candidate-set reconstruction, and final reporting require no network access.
- The historical catalogue capture loop is included only as a `.txt` provenance reference with an explicit do-not-run warning.
- With `RUN_OPENGWAS_SENSITIVITY` unset, the optional sensitivity script terminated at its safety gate with `No API request was made`.
- The optional workflow is restricted to 29 candidates, sequential, cached, resumable, paced at a default 90 seconds plus jitter with a 60-second minimum, and configured to stop on allowance/HTTP 429 signals. `OPENGWAS_JWT` is read only from the user's environment.

## Scope limits and remaining author actions

The exact old-table DD SNP-level run, harmonised instruments, and SNP-level sensitivity outputs were not retained; MR-Egger, weighted-median, heterogeneity, pleiotropy, leave-one-out, MR-PRESSO, Steiger, and F-statistic claims are therefore not reconstructed from aggregate files. PM2.5, coordinate, and release-specific FinnGen/Risteys provenance remain disclosed limitations. The repository URL, version, creators/affiliations, and rights-retained mixed-rights statement are recorded in the release metadata; ORCIDs and funding are omitted because none were verified. The Zenodo DOI is added after archival.

The final `v1.0.0` tree contains 251 files including the manifest; its 250 manifest rows cover every other file, and all recorded byte counts and SHA-256 values passed. `manifests/package_file_manifest_sha256.csv` excludes itself to avoid a recursive self-checksum.
