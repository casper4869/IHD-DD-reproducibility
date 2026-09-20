# Forecast and Figure 4 contract

Locked before execution, 18 September 2026.

## Objective and fixed quality target

The target is the annual number of countries/territories simultaneously in the highest country quartile of IHD and DD age-standardized incidence rates. Country is the prediction unit; all 204 available country/territory series from 1992–2021 are retained. High–high describes relative co-high national incidence, not individual comorbidity or total case burden. The target is recomputed separately for each year/model using deterministic rank quartiles, matching the original analysis; this permits at most 51 high–high countries.

The primary quality target is zero unsupported inferential-interval claims and a complete, reproducible accounting of model assumptions, failures, validation errors, and changes from the original forecasts. This is a deterministic implementation/reporting correction, not an attempt to increase forecast accuracy after inspecting a holdout. No model is selected because it predicts 19 countries or obtains a favorable validation score.

## Locked analysis design

Iteration 0 reproduces the original VARX and ARIMAX numerical code blocks on copies of unchanged inputs. VARX uses log1p rates, fixed lag 2, an intercept and current SDI, constant future SDI, and historical-minimum/1.5-times-historical-maximum clipping. ARIMAX uses raw rates, default nonseasonal auto.arima with SDI and constant future SDI. These baseline results are retained and compared with saved 2030 files.

Iteration 1 removes the false plus/minus 15% bands labelled as 95% intervals. To distinguish model architecture from preprocessing, a prespecified companion sensitivity uses log1p rates for both models and omits historical-range clipping, retaining a zero floor solely for nonnegative incidence. VARX lag remains 2; ARIMAX order is selected within each training subset. This sensitivity is labelled separately and cannot silently replace the original analysis. The flat-SDI scenario is shared by all models. No covariate path observed after a validation origin is used in prediction.

Validation uses three fixed expanding windows ending in 2012, 2015 and 2018, each predicting all remaining years through 2021 (9, 6 and 3 years). A last-observation persistence baseline is included. All preprocessing, order selection and clipping bounds are learned only from each training window. Report IHD/DD RMSE, MAE and MAPE, rank-defined count absolute error, classification agreement, model failures, VARX companion-root stability, and clipping frequency. These overlapping-origin error estimates are descriptive and are not independent replications. There is no iterative tuning on these folds.

Count uncertainty will not be fabricated by transforming individual series intervals or assuming independent countries. The available matrices do not contain joint GBD posterior draws, and 30 annual observations do not identify a credible joint 204-country innovation/parameter/SDI process without additional assumptions. Unless a defensible joint procedure can be specified before seeing results, publish point forecasts without ribbons and explicitly identify model, parameter, GBD input and future-covariate uncertainty as unquantified. Empirical model divergence and backtest errors are not confidence intervals.

Maximum iterations: baseline plus one correction; one additional implementation repair is permitted only for an execution defect. Random seed 20260918; deterministic methods expected. Original data are read-only. Failures or numerical instability are reported rather than hidden by silent dropping.

## Figure contract

Core conclusion: country counts projected to have co-high IHD/DD incidence depend on model specification and should be interpreted as conditional scenarios with unquantified forecast uncertainty.

Archetype: quantitative grid, two equally scaled side-by-side panels. Panel a shows the original specified models with unsupported ribbons removed; panel b shows the common log1p/no historical-range clipping sensitivity. Each panel contains the historical national-count series and both models, so neither model receives privileged emphasis. Include a 2021/2022 boundary, identical count axes, direct endpoint counts, and a statement that point forecasts have no confidence bands. If unstable forecasts make a sensitivity scientifically unusable, retain its machine-readable outputs and report the limitation visibly rather than clipping it to reproduce the baseline.

Backend: R only for computation, graphics and preview. Output: editable SVG, PDF, 600-dpi TIFF and R-generated PNG preview, double-column width 183 mm, height 100–115 mm. Use restrained blue/orange model colors with linetype differences, Arial, no decorative arrows. Machine-readable source tables and input/output SHA-256 fingerprints accompany the figure. Figure legend defines country denominator, annual rank quartiles, model equations/assumptions, no intervals, and the validation design. No image retouching or non-R re-rendering.

The manuscript-level loop owner coordinates independent review and final acceptance. This subtask does not alter the shared loop state, manuscripts, or MR analyses.
