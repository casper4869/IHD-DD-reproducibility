# Submitted three-variable Granger analysis: offline reconstruction audit

The retained main script and its duplicate have the same SHA-256 value (`9946171103c0af8a9bea4ea3b1405f6021740aaefef6e5180d05f6bfe69c8c68`). A path-parameterised reconstruction reproduced all 204 country classifications in the retained result table.

| Legacy classification | Accurate system-test meaning | Countries |
|---|---|---:|
| Bidirectional | Both IHD-source and DD-source system tests significant | 94 |
| IHD→DD | IHD-source system test only significant | 20 |
| DD→IHD | DD-source system test only significant | 70 |
| No significant/NA | Neither system test significant | 20 |

All selected lags matched. All raw and Benjamini-Hochberg-adjusted P values agreed within `1e-12`; the largest absolute difference was `4.996004e-16`. The three input matrices each contained 204 locations and 30 annual values for 1992–2021.

The submitted model contains IHD incidence, DD incidence, and SDI as endogenous variables. With `vars::causality(model, cause = "IHD_val")`, the null jointly restricts lagged IHD terms in both the DD and SDI equations. The DD call likewise restricts lagged DD terms in both the IHD and SDI equations. The legacy arrow labels therefore do not isolate prediction of the other disease. They are retained solely to reproduce the submitted columns and map categories.

The reconstruction preserves the absence of detrending, differencing, stationarity restrictions, and alternative covariance estimators in the submitted workflow. Reproduction of the archived numbers does not establish inferential validity. Results remain ecological, can be affected by time-varying confounding and model specification, and cannot support individual-level or biological causal claims.

The submitted-system exclusion sensitivity uses the archived raw P values and the prespecified 45-unit cartographic/SID exclusion list. After retaining 159 locations and reapplying Benjamini-Hochberg adjustment separately to both labelled families, 71 locations were significant in both families, 13 in the IHD-labelled family only, 60 in the DD-labelled family only, and 15 in neither. This is a machine-readable aggregate-result sensitivity, not a VAR refit, and the labels retain their joint-system-test meaning. Row-level results and counts are provided in `derived_data/granger/submitted_system_test_small_island_exclusion*.csv`.

The later script `code/granger/03_correct_granger_sensitivity.R` answers a different question with target-specific equations and robustness checks. Its results are reported separately and do not replace the submitted three-variable classifications.

Evidence files are in `derived_data/granger/archived_main_reconstruction/`: the all-pass archive comparison, category counts, three-country test-scope examples, accurately named system-test table, source hashes, and R session information. The submitted-system 45-unit exclusion outputs sit alongside that directory under `derived_data/granger/`.
