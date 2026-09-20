# Reproducibility package for the IHD–DD revision

**Manuscript:** *Global co-occurrence patterns of ischaemic heart disease and depressive disorders, with an exploratory screen of shared genetically associated traits*  
**Journal:** International Journal of Health Geographics  
**Submission ID:** 61a39b35-8588-492a-bc38-1640628b2633  
**Package date:** 2026-09-20  
**Repository:** https://github.com/casper4869/IHD-DD-reproducibility<br>
**Prepared release:** `v1.0.0`<br>
**Status:** `PUBLIC_REPOSITORY; VERSIONED_RELEASE_AND_ZENODO_DOI_PENDING`

This public repository collects the corrected scripts, machine-readable outputs, figures, diagnostics, software records, and data-access instructions available for the revision. Release `v1.0.0` is prepared for permanent Zenodo archiving; the DOI will be added after Zenodo mints it. The graphical abstract is intentionally absent because it will not be submitted.

## What is reproducible now

| Component | Package status | Main evidence |
|---|---|---|
| Figure 2 and Supplementary Table S1 | Available and independently checked | Panels A–B regenerated from unrounded sex-specific BH q values (46/204 female and 109/204 male locations displayed), C–D retained from the submitted source, E–F regenerated from corrected weighted correlations, exact 204-row display crosswalk, population merge checks, 45-unit cartographic/SID sensitivity, hashes, session information, and final-state independent review |
| Figure 4 forecast audit | Available | Original-specification reconstruction, harmonised sensitivity analysis, rolling-origin checks, instability/clipping diagnostics, source tables, final figure, logs, and independent audit |
| Exploratory MR reconstruction and final 29-candidate reporting set | Available from preserved aggregate results | Complete 15,703-row catalogue-to-analysis status manifest, 11,988-row outcome-specific schedules, 11,987-row common-candidate table, saved aggregate estimates, source hashes, alternative candidate sets, final 29-candidate Table 1/Figure 7 source tables, and session information |
| SDI-adjusted temporal-precedence analysis / Supplementary Table S2 / Figure 5 | Available with exploratory interpretation | Corrected directional equations with SDI as exogenous control, unrounded directional BH families, lag, covariance-estimator and 45-unit cartographic/SID sensitivities, diagnostics, checksums, session information, and corrected Figure 5; the final reporting explicitly leads with the large Newey–West/HC3 difference |
| GWR and cartographic/SID sensitivity / Figure 6 | Available and independently checked | Exact submitted GWR specification, 204-location and 45-unit-excluded fits (retained n = 159), independent local-coefficient reconstruction, bandwidth trace, source tables, checksums, and a minimally revised coordinate-point Figure 6 whose shared colour scale covers the complete coefficient range without truncation |
| SNP-level MR sensitivity analyses | Not reconstructable from the preserved historical files | The exact historical DD run used for the submitted 50-row table and SNP-level instruments/harmonised objects were not retained; MR-Egger, weighted median, heterogeneity, pleiotropy, leave-one-out, MR-PRESSO, Steiger and instrument-strength analyses therefore cannot be recreated from this archive |
| Public archival record | Repository public; DOI pending | The reviewed files are public on GitHub. Release `v1.0.0` will be archived by Zenodo and the resulting version-specific DOI will be added before the final response is submitted |

The MR component is explicitly exploratory. There was no manual pre-screening of phenotypes by name, clinical relevance, expected direction, modifiability, or result. The 15,703 rows are catalogue metadata records; 11,988 exposure jobs were scheduled per outcome after technical ancestry/data-class scoping and removal of the target outcome itself. The preserved archive contains 5,880 IHD and 11,775 DD aggregate estimates. The agnostic Set A contains 49 traits. The final Set B contains 29 traits after a post-screen removal of `finn-b-*` exposures to reduce participant-overlap and same-biobank dependence because both outcomes were FinnGen datasets. This is a reporting safeguard rather than a universal MR requirement. The results support hypothesis generation and do not establish causal effects. See `MR_SCREEN_FLOW.md`.

## Directory contents

- `code/`: corrected analysis scripts currently available, including offline MR audit/reporting scripts, an offline-by-default catalogue provenance check, and the disabled-by-default rate-limited optional OpenGWAS sensitivity script. Path-redacted Figure 1, Figure 3, and SDI `.R.txt` files are quarantined under `code/historical_reference/` as non-executable records with explicit limitations.
- `derived_data/`: machine-readable outputs and QA evidence produced by the corrected scripts.
- `figures/`: revised figures in publication and preview formats. Historical Figure 1/Figure 3 TIFF and Illustrator assets are omitted because their embedded metadata retains machine-specific source paths.
- `reports/`: cross-component audit material added during packaging.
- `environment/`: software and session records.
- `manifests/`: script, input, legacy-artifact, and package-file inventories.
- `documents/`: the rebuilt supplementary DOCX checked against corrected S1 and S2 source tables.
- `source_data/mr/`: the preserved 15,703-row OpenGWAS catalogue snapshot and compact IHD/DD aggregate result files (`bb.csv` and `END.csv`).
- `source_data/legacy_figure1/` and `source_data/legacy_figure3/`: small derived source/count tables retained for historical audit; these are not raw-to-final analysis inputs.
- `data_access_protocol.md`: step-by-step retrieval and reconstruction instructions for third-party data.
- `MR_RECONSTRUCTION_README.md`: MR reconstruction, selection rules, source-file map, online-access safeguards, and remaining limitations.
- `MR_SCREEN_FLOW.md`: plain-language accounting of the 15,703 → 11,988 → 5,880/11,775 → 49 → 29 flow and the absence of manual phenotype pre-selection.
- `SECURITY_AND_ACCESS.md`: credential handling and OpenGWAS no-crawling rules.
- `RELEASE_CHECKLIST.md` and `ZENODO_METADATA.md`: release status and the metadata supplied to GitHub/Zenodo.

## Run order

The commands below describe the analysis order used in the revision workspace. Paths must be changed after the package and third-party inputs are moved to a new computer. Do not run the legacy scripts from `Part2`, `Part4`, `Part5`, or `Part7` as substitutes for the corrected scripts in this package.

### 1. Correct Figure 2A–B, Figure 2E–F, and Supplementary Table S1

Required inputs are listed as `F2-*` in `manifests/input_data_inventory.csv`. The correction script was run from the revision `02_analysis` directory and expects a read-only directory named `immutable_population_source` that contains the 21 downloaded GBD population CSV files.

```powershell
Set-Location '<revision-root>/02_analysis'
Rscript 01_correct_correlations_figure2.R
Rscript 02_compose_full_figure2.R
Rscript 05_correlation_small_island_sensitivity.R
```

The first command creates the corrected S1 table, 6,936 estimable country–sex–age temporal-correlation records, an explicit failure table for the three younger age groups with constant IHD series, QA tables, and panels E–F. The second regenerates A–B from corrected unrounded-P sex-specific BH q values, retains only the conceptually valid submitted C–D crop, and inserts corrected E–F. It also exports the exact 204-row GBD-location-to-ISO3-to-geometry crosswalk and cartographic procedure in `derived_data/figure2/`; 203 locations match the bundled geometry and Tokelau is explicitly unmatched. The third excludes 45 pre-specified units (44 `SID`-classified units plus Tokelau, which is absent from the bundled country geometry), re-adjusts S1 within 159 tests per sex, and compares the Figure 2E–F distributions and age-specific medians with the full analysis. The retained-family q < 0.05 counts are 43/159 for females and 90/159 for males; correlations of full versus excluded-set age medians are 0.883 and 0.941, respectively, with the sign preserved for all 17 estimable age groups.

### 2. Recompute directional temporal precedence and Supplementary Table S2

Required inputs are listed as `GR-*` in the input inventory.

```powershell
Set-Location '<revision-root>/02_analysis'
Rscript 03_correct_granger_sensitivity.R
```

The script models annual log changes, treats SDI change as an exogenous control, tests each direction in its intended equation, and applies BH adjustment separately to 204 unrounded P values per direction. It also runs fixed-lag, HC3 covariance, and 45-unit cartographic/SID-exclusion sensitivities. The excluded-set Newey–West classification is 1 bidirectional, 0 IHD-to-DD, 147 DD-to-IHD, and 11 neither among 159 retained units. The primary 204-unit classification is highly sensitive to covariance choice (182 DD-to-IHD under Newey–West versus 11 under HC3) and to short-series diagnostics, so the included full table and QA files must accompany any narrative statement.

Rebuild the corrected exploratory Figure 5 after the table is regenerated:

```powershell
Rscript 06_create_figure5_corrected.R
```

### 3. Verify GWR and run the small-island sensitivity

Required inputs are listed as `GWR-*` in the input inventory. The script was run from `02_analysis` with a read-only directory junction named `immutable_part7_source` pointing to the original Part 7 inputs.

```powershell
Set-Location '<revision-root>/02_analysis'
Rscript 04_gwr_small_island_sensitivity.R
```

The script fits two 2021 Gaussian fixed-bandwidth models using great-circle distances and separately selected leave-one-out cross-validation bandwidths: `IHD_z ~ DD_z + SDI_z + PM25_z` and `DD_z ~ IHD_z + SDI_z + PM25_z`. It repeats both models after excluding the 45 pre-specified cartographic/SID units while retaining the full-sample standardisation scale (n = 159). Full-versus-excluded local-coefficient correlations are 0.882 for the DD association with IHD and 0.829 for the IHD association with DD; sign agreement is 88.05% and 93.08%, respectively. An independent weighted-least-squares reconstruction matches the `spgwr` local coefficients. The release uses a minimally revised Figure 6 that retains the submitted coordinate-point design. Its two panels share a symmetric ±1.7 colour scale covering the complete observed range; the submitted figure saturated 12 coefficients outside −1 to 1.

Rebuild the display from the included audited coefficient table without any network request:

```powershell
Rscript code/gwr/05_build_figure6.R `
  derived_data/figure6/Figure6_source_data.csv `
  figures `
  derived_data/figure6
```

### 4. Reproduce and audit the forecast analysis

Required inputs are the three 204-country matrices listed as `FC-*` in the input inventory.

```powershell
Set-Location '<revision-root>/02_analysis/forecast'
Rscript run_forecast_revision.R '<project-root>/Part5'
Rscript audit_archived_arimax.R
Rscript prepare_forecast_report.R
```

For an independent clean run, use a new empty forecast output directory and do not reuse the cached `.rds` fits. The cache files are omitted from this reviewer package because they are computational conveniences rather than source data and are not automatically keyed to code or input hashes.

### 5. Rebuild the final MR reporting tables and Figure 7

The offline reconstruction outputs are in `derived_data/mr/`. Rebuild Sets A-C from the packaged catalogue and aggregate results into a new directory; this makes no network request:

```powershell
python code/mr/alternative_sets/build_alternative_mr_sets.py `
  --output-dir '<new-candidate-set-output-directory>'
```

The final reporting script starts from Set B (29 candidates) and also makes no network request:

```powershell
Rscript code/mr/02_build_final_mr_reporting.R `
  derived_data/mr/alternative_sets/set_B_setA_excluding_finn_b_exposures.csv `
  '<new-output-directory>'
```

The script verifies that all 29 candidates use IVW for both outcomes, have BH q < 0.05 for both outcomes, have concordant effect directions, and contain no `finn-b-*` exposure. The current Figure 7 PDF, TIFF, and PNG are in `figures/`; their 29-candidate source tables, QA, and session record are in `derived_data/figure7/` and mirrored in `derived_data/mr/final_reporting/`. The former 50-row composite-score display files and scripts are excluded from this release.

### 6. Rebuild and validate the supplementary tables

The packaged DOCX contains the corrected 204-row S1 and 204-row S2 tables. Its validator compares every displayed cell with the source CSV after the builder's declared formatting.

```powershell
python code/supplement/build_supplement_docx.py `
  --s1 derived_data/figure2/Supplementary_Table_S1_corrected.csv `
  --s2 derived_data/granger/Supplementary_Table_S2_corrected.csv `
  --output documents/Supplementary_Materials_Revised.docx

python code/supplement/validate_supplement_docx.py `
  --docx documents/Supplementary_Materials_Revised.docx `
  --s1 derived_data/figure2/Supplementary_Table_S1_corrected.csv `
  --s2 derived_data/granger/Supplementary_Table_S2_corrected.csv `
  --builder code/supplement/build_supplement_docx.py `
  --report reports/supplement_validation.md
```

### 7. Validate the historical OpenGWAS catalogue snapshot offline

```powershell
Rscript code/mr/00_catalogue_snapshot_provenance.R
```

With no enabling environment variable, this command only validates the included `ao.csv` and makes no network request. The preserved 15,703-row file is the analysis snapshot; replacing it with today's catalogue would change the historical analysis universe.

### 8. Optional OpenGWAS sensitivity rerun (not executed for this revision)

`code/mr/opengwas_sensitivity_rerun_RATE_LIMITED.R` is an optional future instrument-level sensitivity workflow for the final 29 candidates. It is **off by default** and makes no request unless `RUN_OPENGWAS_SENSITIVITY=YES` is set explicitly. It is not a crawler. It runs sequentially, caches each completed exposure, resumes without repeating completed work, paces every top-level API operation with a default 90-second interval plus jitter, enforces a minimum interval of 60 seconds, prevents back-to-back exposure/outcome requests, honours OpenGWAS allowance checks, does not override HTTP 429 protection, and stops on `429`/`Retry-After` signals. Review the current OpenGWAS authentication and allowance documentation before any future use. No online rerun was performed in preparing this package.

## Integrity rules

1. Treat provider downloads and the archived MR catalogue/aggregate files as immutable.
2. Verify every input against `manifests/input_data_inventory.csv` or the component checksum tables before analysis.
3. Preserve unrounded values through testing and multiplicity correction; round only for display.
4. Record every changed file in `manifests/package_file_manifest_sha256.csv` and create a new release version rather than overwriting an archived release.
5. Keep credentials out of the repository. In particular, never commit an `OPENGWAS_JWT` token, never parallelise the optional OpenGWAS workflow, and never override provider rate-limit signals. The primary reconstruction is offline and does not require a token.
6. Do not describe model-based GBD estimates as individual-level observations, and do not label national Granger temporal precedence as biological causation.

`manifests/package_file_manifest_sha256.csv` covers every package file except itself; self-inclusion would make a stable checksum impossible. The checksum of any distributed ZIP archive should be stored beside the ZIP.

## Disclosed limitations and remaining archive steps

- The complete historical DD SNP-level run used for the submitted 50-row table is unavailable. The revised analysis therefore replaces that table with the traceable 29-candidate aggregate reconstruction and explicitly withholds SNP-level pleiotropy/sensitivity claims.
- Curate raw-to-final preprocessing and Figure 1/Figure 3 into clean parameterised scripts. Sanitised historical Figure 1, Figure 3, and SDI `.R.txt` references are included with original hashes and limitations, but they are not corrected release entry points and must not be executed as the reproducible workflow.
- Confirm the original source, version, units, retrieval date, and licence for the processed PM2.5 matrix; the two local copies are byte-identical, which verifies local lineage but not external provenance.
- Confirm the source gazetteer/geocoder, coordinate definition, version, retrieval date, licence, and matching code for the 204-row coordinate file.
- Record release-specific FinnGen/Risteys endpoint exports, release number, and access date.
- Parameterise any remaining archival local paths needed for clean reruns and verify the release commands in a clean environment.
- Add the Zenodo DOI to this repository and the manuscript-facing Data and Code Availability statement after Zenodo archives `v1.0.0`.
- Test the version-specific DOI and public file download outside the depositor account before resubmission.

## Rights

This is a publicly accessible, mixed-rights archive. No repository-wide reuse licence is granted in `v1.0.0`; author-created material retains its existing rights unless a file states otherwise, and third-party material remains subject to its original provider terms. The Zenodo record therefore uses `Other (Not Open)` while keeping the files publicly accessible for transparency and independent verification. See `RIGHTS_AND_LICENSING.md`.
