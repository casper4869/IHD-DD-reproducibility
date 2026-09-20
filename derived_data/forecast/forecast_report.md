# Figure 4 redraw and internal forecast audit report

## Revised manuscript Figure 4

The main manuscript Figure 4 is the minimal R redraw in `../../figures/Figure4.*`. Panel A shows the archived VARX trajectory and panel B shows the archived ARIMAX trajectory. Both panels retain the identical historical counts for 1992–2021; the projected counts for 2022–2030 are 17/16/21/19/20/18/19/20/19 for VARX and 15/14/14/14/15/14/14/14/14 for ARIMAX, preserving the archived 2030 endpoints of 19 and 14.

The figure is rendered from `results/Figure4_minimal_source.csv` by `../../code/forecast/02_draw_figure4_minimal.R` without refitting either model. Titles, subtitles, model names, legends, prose annotations, endpoint callouts, and the heuristic ±15% ribbon were removed from the graphic. Panel/model mapping, visual encodings, model assumptions, endpoint values, and uncertainty limitations are carried in the figure legend. Automated and visual QA are recorded in `qa/Figure4_minimal_QA_REPORT.md` and `qa/Figure4_minimal_QA_checks.csv`.

The archived ARIMAX 2030 classification and submitted figure report 14 countries; a current raw-scale `auto.arima` rerun returns 13. The retained materials do not determine the cause; unrecorded software or model-selection state is one possible explanation. The redraw locks the archived manuscript trajectory and explicitly retains the 13-country rerun and 15-country log-scale sensitivity below as implementation uncertainty. No result was silently substituted.

The byte-identical original submitted artwork is preserved under `../../figures/original_submitted_not_for_resubmission/`; the additional common-scale display is retained under `../../figures/internal_audit_not_for_submission/`.

## Internal audit and sensitivity analysis

> **Scope:** The remaining sections describe post-submission audit/sensitivity analyses. They do not define the main Figure 4 trajectory.


## Decision

The original VARX count of 19 for 2030 is computationally reproducible, but it is not a validated forecast. 176 of 204 full-fit country VARX models have companion spectral radius >= 1, and their forecasts are subject to arbitrary historical-range clipping. Removing that clipping produces non-finite rate forecasts, so a full-denominator co-high count becomes unavailable from 2026. The instability must be reported; the original statement that all VARX models were stable is unsupported.

The current reproducible raw-scale ARIMAX implementation yields 13 countries in 2030, compared with 14 in the archived table. The common log1p sensitivity yields 15. The later log1p/clipped ARIMAX block in the legacy script can produce the same archived count, but does not recover its rate vectors; matching an aggregate count does not establish provenance. Historical model/software state is not documented sufficiently to explain this discrepancy.

The internal audit display documents specification sensitivity and should not be used to replace the archived trajectory in the minimal manuscript Figure 4 or restore a confident policy prediction. Keep scenario language, omit unsupported interval bands, and avoid implications of precise forecasts. A replacement stabilised VARX model would be a separately disclosed methodology change and has not been silently substituted.

## Inputs and target

Three unchanged country-by-year matrices contain 204 unique, matching countries/territories and 30 complete annual observations from 1992 to 2021. Rates are age-standardized incidence rates per 100,000. SDI values lie between zero and one. No countries, years or negative observations were dropped. Original inputs were fingerprinted before and after execution.

Each annual high-high classification is the intersection of the top rank quartile for IHD and the top rank quartile for DD, calculated separately for that year and forecast specification. Each top quartile contains 51 countries; therefore the intersection can contain at most 51. Alphabetic country ordering resolves ties deterministically. A rising count does not directly imply a rising global mean, rising absolute burden or individual comorbidity. Country counts are not population weighted.

Historical counts are 14 in 1992 and 15 in 2021.

## Locked model specifications

| Component | Original VARX | Original ARIMAX | Common-scale sensitivity |
| --- | --- | --- | --- |
| Response | Joint log(1 + IHD), log(1 + DD) | Separate raw incidence series | Both models use log(1 + incidence) |
| Dynamics | VARX with fixed p = 2 and intercept | auto.arima, nonseasonal annual series | Dynamics retained within each model |
| Exogenous predictor | Same-year SDI | SDI regression with ARIMA errors | SDI retained |
| Future SDI | Last observed value repeated | Last observed value repeated | Same fixed-SDI scenario |
| Selection | No lag search in source code | Default AICc/stepwise search and KPSS-based differencing | ARIMAX order learned only from training data |
| Back-transform | exp(log prediction) - 1, no bias adjustment | Not applicable | exp(log prediction) - 1, no bias adjustment |
| Range restriction | Historical minimum to 1.5 x historical maximum | None | Zero floor only; no historical-range clipping |
| Count uncertainty | Unsupported +/-15% ribbon removed | Unsupported +/-15% ribbon removed | No count intervals fabricated |

Back-transformed log-scale values are plug-in conditional point predictions, not unbiased estimates of arithmetic means. ARIMAX can difference its response and uses separate univariate dynamics; VARX p = 2 models undifferenced joint log levels and includes cross-series lags. The two model families therefore encode different dynamic assumptions even under the common scale. The original manuscript's claimed BIC/FPE lag selection, universal stability checks and prediction intervals are not supported by the original implementation.

## Reproduction and numerical audit

| model | reproduced_2030_count | saved_2030_count | max_IHD_abs_difference | max_DD_abs_difference | country_set_equal |
| --- | --- | --- | --- | --- | --- |
| VARX | 19 | 19 | 0.000000000005 | 0.0000000000491 | TRUE |
| ARIMAX | 13 | 14 | 41.600000000000 | 2620.0000000000000 | TRUE |

The original model code blocks were executed unchanged in separate environments on copied inputs. The model wrapper used for validation was checked against those outputs. An ASCII temporary execution folder bypassed a Windows/vroom path-encoding issue; numerical code and inputs were unchanged, and generated baseline artifacts were archived.

| specification | count_2030 | max_IHD_abs_difference_from_archive | max_DD_abs_difference_from_archive | root_mean_square_IHD_difference | root_mean_square_DD_difference |
| --- | --- | --- | --- | --- | --- |
| log1p_unclipped | 15 | 412 | 976 | 48.3 | 233 |
| log1p_clipped | 14 | 508 | 976 | 65.6 | 233 |

The second ARIMAX implementation in the legacy script applies log transformation and historical-range clipping for a separate population-weighted table. Its existence creates a version-selection ambiguity. The revision retains all candidate comparisons and never chooses the variant merely because it returns 14 or 19.

Full-fit diagnostics:

| specification | model | n_failed | n_unstable_VARX | maximum_VARX_root | IHD_lower_clips | IHD_upper_clips | DD_lower_clips | DD_upper_clips |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Benchmark | Persistence | 0 | 0 | NA | 0 | 0 | 0 | 0 |
| Harmonized | ARIMAX | 0 | 0 | NA | 0 | 0 | 0 | 0 |
| Harmonized | VARX | 14 | 176 | 3.98 | 0 | 0 | 0 | 0 |
| Original | ARIMAX | 0 | 0 | NA | 0 | 0 | 0 | 0 |
| Original | VARX | 0 | 176 | 3.98 | 732 | 285 | 128 | 954 |

The original VARX clipping affected 181 countries and 2099 of 3672 country-year-disease forecast values. Clipping can suppress explosive forecasts and change cross-country ranks. It does not repair an unstable model.

## Rolling-origin evaluation

Three predeclared expanding training windows end in 2012, 2015 and 2018. They forecast 2013-2021, 2016-2021 and 2019-2021, respectively, using only training-period observations and the last training SDI. ARIMA order selection and VARX clipping bounds are recomputed inside each window. A persistence benchmark repeats the last observed incidence. No forecast model was selected or tuned using these validation outcomes.

Rate metrics are aggregated over 3,672 country-origin-horizon predictions per specification. Count MAE averages over 18 origin-horizon pairs. These overlapping windows are descriptive temporal backtests, not 18 independent samples. Errors compare to GBD modelled point estimates, not directly observed incidence. NA/non-finite metrics are reported without omitting failed countries or changing the denominator.

| specification | model | IHD_RMSE | IHD_MAE | IHD_MAPE | DD_RMSE | DD_MAE | DD_MAPE | count_MAE | count_max_absolute_error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Benchmark | Persistence | 13.2 | 7.33 | 2.18 | 476 | 272 | 5.66 | 1.000 | 3 |
| Harmonized | ARIMAX | 17.6 | 8.75 | 2.50 | 480 | 270 | 5.62 | 0.889 | 2 |
| Harmonized | VARX | 30.1 | 11.60 | 3.38 | 559 | 304 | 6.34 | 1.330 | 4 |
| Original | ARIMAX | 16.8 | 8.56 | 2.48 | 485 | 273 | 5.70 | 1.280 | 3 |
| Original | VARX | 26.3 | 9.92 | 2.74 | 477 | 275 | 5.78 | 0.944 | 4 |

Both original model families have higher IHD and DD rate RMSE than persistence in these backtests. Differences in count MAE are small and do not establish reliable prediction of incidence levels; a rank-defined count can remain similar despite appreciable country-level rate errors. No model is promoted as superior on the basis of these post-submission exploratory comparisons.

Residual Ljung-Box values and companion roots are supplied as diagnostics only. These exploratory diagnostics were not used for multiple-testing claims or post hoc model selection. Country-level and horizon-specific validation results are saved for examination of poor performance hidden by aggregate metrics.

## Uncertainty and limits

No inferential confidence or prediction bands are shown. The legacy ribbon was exactly 0.85-1.15 times each count, which has no statistical 95% coverage interpretation. Replacing it with independent per-country simulations would impose unverified cross-country independence, ignore GBD posterior dependence and omitted future-SDI/parameter uncertainty, and could falsely narrow uncertainty for a threshold-and-rank count. The available matrices have no joint GBD posterior draws; a credible joint count interval has not been established. Model divergence and validation error are evidence of fragility, not substitutes for a 95% interval.

The fixed-SDI future is a conditional scenario, not a forecast of socioeconomic change. Small annual samples, modelled and rounded incidence inputs, potential structural breaks, serial and spatial dependence, weak extrapolation support, and unquantified parameter/input/covariate uncertainty further limit policy interpretation. In particular, do not emphasize 19 countries as the expected global 2030 outcome.

## Figure specification and acceptance

R generated both panels and every export at 183 x 103 mm. Panel a balances original VARX and ARIMAX specifications; panel b reveals sensitivity to common scaling and removal of historical-range clipping. Both panels use the same country denominator, axes, colors and year boundary. Any unavailable complete-denominator count is visibly marked rather than interpolated or reconstructed by ranking infinities. Source data, SVG, PDF, 600-dpi TIFF and PNG preview accompany the scripts.

Deterministic data/reporting gates pass when the input hashes, wrapper-equivalence checks, 204-country denominator and count bound checks pass. The original-code comparison uses a relative tolerance of 1e-7 to accommodate log(1+x) versus log1p floating-point differences; the maximum observed relative difference is below 3e-8 and no count changes. Statistical validity of the original VARX forecast fails because of extensive instability, and credible count intervals remain unavailable. This finding is an audit result, not a reason to relabel the original forecast as validated. The audit display is retained only in the reproducibility record and is not used as a manuscript replacement; any manuscript forecast wording must avoid a precise 2030 headline; independent review is recorded separately in qa/independent_review.md when complete.

## Reproduction

Run from this analysis directory with R 4.5.0 and the package versions in package_versions.csv:

```text
Rscript run_forecast_revision.R
Rscript audit_archived_arimax.R
Rscript prepare_forecast_report.R
```

The first script caches model fits per model/specification/origin. Existing caches are used only to regenerate reports/exports without repeated fitting. Caches are not keyed automatically to input or code hashes: any future change in data, analytic code, package versions or protocol requires a new empty output directory and clean computation. For a clean independent reproduction, use a new empty output directory containing the scripts and contract; no original source file is overwritten. Execution logs preserve numerical warnings and implementation failures. The repairs were a Windows path workaround and preservation of the matrix dimensions when applying a zero floor; neither changes the locked scientific design.
