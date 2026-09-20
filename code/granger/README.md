# Granger analysis code and interpretation

This directory separates the **submitted main analysis** from later, target-specific sensitivity analyses. All scripts operate on local files only; none downloads data or contacts a website.

## Submitted three-variable VAR analysis

`reproduce_archived_granger_main.R` is the concise public entry point for the submitted country-level analysis. For each of 204 locations it fits a VAR containing IHD incidence, DD incidence, and SDI, selects lag 1 or 2 by AIC, applies `vars::causality()` with IHD and DD in turn as the source variable, and adjusts the 204 P values in each labelled family separately by Benjamini-Hochberg.

The test scope needs care. In a three-variable `vars` model, the IHD-labelled call jointly tests lagged IHD terms in **both the DD and SDI equations**. The DD-labelled call jointly tests lagged DD terms in **both the IHD and SDI equations**. Therefore, the archived `IHD_to_DD` and `DD_to_IHD` names are legacy labels for system-level block-exogeneity tests. They are not disease-to-disease-only tests and do not establish temporal or biological causation.

Run the concise reconstruction as follows:

```text
Rscript code/granger/reproduce_archived_granger_main.R <input-directory> <output-directory> [archived-results.csv] [encoding]
```

The input directory must contain:

- `IHD_1992_2021_matrix.csv`
- `DD_1992_2021_matrix.csv`
- `SDI_1992_2021_matrix.csv`

The three matrices are not redistributed because their source estimates are subject to the provider's terms. Retrieval instructions and exact local fingerprints are provided in `data_access_protocol.md`, `manifests/input_data_inventory.csv`, and `derived_data/granger/archived_main_reconstruction/source_provenance.json`.

When the optional archived-results file is supplied, the script checks every raw P value, BH-adjusted P value, selected lag, and country classification to a tolerance of `1e-12`. The included comparison passed for all 204 locations; the four legacy-category counts were 94, 20, 70, and 20.

`archived_GBD_6_parameterized.R` retains the full located archival workflow with file paths parameterised. It includes the submitted three-variable block, the subsequent two-variable/no-SDI block, and an optional historical map block. Use `--render-map` only for provenance inspection. The historical map labels are not corrected inference and the output must not replace the retained manuscript Figure 5.

```text
Rscript code/granger/archived_GBD_6_parameterized.R <input-directory> <output-directory>
```

`audit_causality_scope.R` independently inspects three example fits and verifies from the test degrees of freedom that each source-variable call jointly restricts two target equations:

```text
Rscript code/granger/audit_causality_scope.R <input-directory> <output-directory>
```

The executed QA outputs are under `derived_data/granger/archived_main_reconstruction/`, and the interpretation report is `reports/granger_archived_main_reconstruction.md`.

## Submitted-system 45-unit exclusion sensitivity

`derive_submitted_system_test_exclusion_sensitivity.py` addresses the cartographic/small-island sensitivity for the **submitted system-test results**. It excludes the same prespecified 45 units used elsewhere in the revision (44 units carrying the bundled `SID` attribute plus Tokelau), retains 159 locations, and reapplies Benjamini-Hochberg adjustment separately to the two submitted raw-P-value families.

```text
python code/granger/derive_submitted_system_test_exclusion_sensitivity.py
```

The script is an offline aggregate-result transformation. It does not refit the VAR, contact a website, or convert the legacy labels into disease-to-disease-only tests. The retained-set classifications are 71 significant in both labelled families, 13 in the IHD-labelled family only, 60 in the DD-labelled family only, and 15 in neither. Row-level P and q values are in `derived_data/granger/submitted_system_test_small_island_exclusion.csv`; the four counts are in `derived_data/granger/submitted_system_test_small_island_exclusion_counts.csv`.

## Later target-specific sensitivity analysis

`03_correct_granger_sensitivity.R` is a post-submission sensitivity analysis. It fits separate directional annual-log-change equations with SDI change as an exogenous control, tests each disease equation directly, and examines lag, covariance-estimator, and 45-unit cartographic/SID exclusions. Its estimands and numerical results differ from the submitted three-variable VAR. It is an internal robustness analysis and does not replace the submitted Figure 5 or the main system-test classifications.

`diagnostic_spec_probe.R` and `06_create_figure5_corrected.R` support that sensitivity analysis. The latter creates an audit-only two-map display under `figures/internal_audit_not_for_submission/`; it is not a manuscript figure.
