options(stringsAsFactors = FALSE)
if (.Platform$OS.type == "windows") suppressWarnings(Sys.setlocale("LC_CTYPE", "English_United States.UTF-8"))
suppressPackageStartupMessages(library(dplyr))
read <- function(name) read.csv(name, check.names = FALSE)
source_dir <- dirname(read("input_checksums.csv")$file[1])
source_artifacts <- file.path(source_dir, c("GBD_7_1.R", "GBD_7_2.R", "Future_Risk_Quartile_2030_VARX.csv", "Future_Risk_Quartile_2030_ARIMAX.csv"))
write.csv(data.frame(file = source_artifacts, bytes = suppressWarnings(file.info(source_artifacts)$size),
  sha256 = vapply(source_artifacts, function(f) suppressWarnings(digest::digest(file = f, algo = "sha256")), character(1))),
  "source_artifact_checksums.csv", row.names = FALSE)
counts <- read("results/all_country_counts.csv")
diag <- read("results/model_diagnostic_summary.csv")
diagnostics <- read("results/model_diagnostics.csv")
rates <- read("results/validation_summary.csv")
compare <- read("qa/baseline_saved_output_comparison.csv")
variants <- read("qa/archived_arimax_variant_comparison.csv")
country_pred <- read("results/all_country_forecasts.csv")
hist <- read("results/historical_counts.csv")
endpoint <- counts %>% filter(origin == 2021, year == 2030)
full_diag <- diag %>% filter(origin == 2021)
fmt <- function(z) ifelse(is.na(z), "not estimable", ifelse(is.infinite(z), "non-finite", formatC(z, digits = 2, format = "f")))
md_table <- function(z, digits = 3) {
  for (j in seq_along(z)) if (is.numeric(z[[j]])) z[[j]] <- ifelse(is.na(z[[j]]), "NA", ifelse(is.infinite(z[[j]]), "non-finite", format(signif(z[[j]], digits), scientific = FALSE, trim = TRUE)))
  c(paste0("| ", paste(names(z), collapse = " | "), " |"),
    paste0("| ", paste(rep("---", ncol(z)), collapse = " | "), " |"),
    apply(z, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |")))
}
key_count <- function(spec, model) endpoint$n_high[endpoint$specification == spec & endpoint$model == model]
n_orig_varx <- key_count("Original", "VARX")
n_orig_arimax <- key_count("Original", "ARIMAX")
n_harm_arimax <- key_count("Harmonized", "ARIMAX")
n_unstable <- full_diag$n_unstable_VARX[full_diag$specification == "Original" & full_diag$model == "VARX"]
bad <- counts %>% filter(origin == 2021, specification == "Harmonized", model == "VARX", is.na(n_high))
first_bad <- if (nrow(bad)) min(bad$year) else NA_integer_
first_bad_text <- if (is.na(first_bad)) "none" else as.character(first_bad)
clipping <- diagnostics %>% filter(origin == 2021, specification == "Original", model == "VARX") %>%
  summarise(countries_affected = sum(clip_low_IHD + clip_high_IHD + clip_low_DD + clip_high_DD > 0),
    forecast_values_clipped = sum(clip_low_IHD + clip_high_IHD + clip_low_DD + clip_high_DD), denominator_values = 204 * 9 * 2)
write.csv(clipping, "qa/full_VARX_clipping_summary.csv", row.names = FALSE)
capture.output(formals(forecast::auto.arima), file = "qa/auto_arima_defaults.txt")

report <- c(
  "# Forecast audit and Figure 4 revision", "",
  "## Decision", "",
  sprintf("The original VARX count of %s for 2030 is computationally reproducible, but it is not a validated forecast. %s of 204 full-fit country VARX models have companion spectral radius >= 1, and their forecasts are subject to arbitrary historical-range clipping. Removing that clipping produces non-finite rate forecasts, so a full-denominator co-high count becomes unavailable from %s. The instability must be reported; the original statement that all VARX models were stable is unsupported.", n_orig_varx, n_unstable, first_bad_text), "",
  sprintf("The current reproducible raw-scale ARIMAX implementation yields %s countries in 2030, compared with 14 in the archived table. The common log1p sensitivity yields %s. The later log1p/clipped ARIMAX block in the legacy script can produce the same archived count, but does not recover its rate vectors; matching an aggregate count does not establish provenance. Historical model/software state is not documented sufficiently to explain this discrepancy.", n_orig_arimax, n_harm_arimax), "",
  "The revised Figure 4 is an honest audit/sensitivity figure and should not be used to restore a confident policy prediction. Keep scenario language, remove the unsupported 95% bands and all implications of precise forecasts. A replacement stabilized VARX model would be a separately disclosed methodology change and has not been silently substituted.", "",
  "## Inputs and target", "",
  "Three unchanged country-by-year matrices contain 204 unique, matching countries/territories and 30 complete annual observations from 1992 to 2021. Rates are age-standardized incidence rates per 100,000. SDI values lie between zero and one. No countries, years or negative observations were dropped. Original inputs were fingerprinted before and after execution.", "",
  "Each annual high-high classification is the intersection of the top rank quartile for IHD and the top rank quartile for DD, calculated separately for that year and forecast specification. Each top quartile contains 51 countries; therefore the intersection can contain at most 51. Alphabetic country ordering resolves ties deterministically. A rising count does not directly imply a rising global mean, rising absolute burden or individual comorbidity. Country counts are not population weighted.", "",
  sprintf("Historical counts are %s in 1992 and %s in 2021.", hist$n_high[hist$year == 1992], hist$n_high[hist$year == 2021]), "",
  "## Locked model specifications", "",
  "| Component | Original VARX | Original ARIMAX | Common-scale sensitivity |",
  "| --- | --- | --- | --- |",
  "| Response | Joint log(1 + IHD), log(1 + DD) | Separate raw incidence series | Both models use log(1 + incidence) |",
  "| Dynamics | VARX with fixed p = 2 and intercept | auto.arima, nonseasonal annual series | Dynamics retained within each model |",
  "| Exogenous predictor | Same-year SDI | SDI regression with ARIMA errors | SDI retained |",
  "| Future SDI | Last observed value repeated | Last observed value repeated | Same fixed-SDI scenario |",
  "| Selection | No lag search in source code | Default AICc/stepwise search and KPSS-based differencing | ARIMAX order learned only from training data |",
  "| Back-transform | exp(log prediction) - 1, no bias adjustment | Not applicable | exp(log prediction) - 1, no bias adjustment |",
  "| Range restriction | Historical minimum to 1.5 x historical maximum | None | Zero floor only; no historical-range clipping |",
  "| Count uncertainty | Unsupported +/-15% ribbon removed | Unsupported +/-15% ribbon removed | No count intervals fabricated |", "",
  "Back-transformed log-scale values are plug-in conditional point predictions, not unbiased estimates of arithmetic means. ARIMAX can difference its response and uses separate univariate dynamics; VARX p = 2 models undifferenced joint log levels and includes cross-series lags. The two model families therefore encode different dynamic assumptions even under the common scale. The original manuscript's claimed BIC/FPE lag selection, universal stability checks and prediction intervals are not supported by the original implementation.", "",
  "## Reproduction and numerical audit", "",
  md_table(compare), "",
  "The original model code blocks were executed unchanged in separate environments on copied inputs. The model wrapper used for validation was checked against those outputs. An ASCII temporary execution folder bypassed a Windows/vroom path-encoding issue; numerical code and inputs were unchanged, and generated baseline artifacts were archived.", "",
  md_table(variants), "",
  "The second ARIMAX implementation in the legacy script applies log transformation and historical-range clipping for a separate population-weighted table. Its existence creates a version-selection ambiguity. The revision retains all candidate comparisons and never chooses the variant merely because it returns 14 or 19.", "",
  "Full-fit diagnostics:", "",
  md_table(full_diag %>% select(specification, model, n_failed, n_unstable_VARX, maximum_VARX_root, IHD_lower_clips, IHD_upper_clips, DD_lower_clips, DD_upper_clips)), "",
  sprintf("The original VARX clipping affected %s countries and %s of %s country-year-disease forecast values. Clipping can suppress explosive forecasts and change cross-country ranks. It does not repair an unstable model.", clipping$countries_affected, clipping$forecast_values_clipped, clipping$denominator_values), "",
  "## Rolling-origin evaluation", "",
  "Three predeclared expanding training windows end in 2012, 2015 and 2018. They forecast 2013-2021, 2016-2021 and 2019-2021, respectively, using only training-period observations and the last training SDI. ARIMA order selection and VARX clipping bounds are recomputed inside each window. A persistence benchmark repeats the last observed incidence. No forecast model was selected or tuned using these validation outcomes.", "",
  "Rate metrics are aggregated over 3,672 country-origin-horizon predictions per specification. Count MAE averages over 18 origin-horizon pairs. These overlapping windows are descriptive temporal backtests, not 18 independent samples. Errors compare to GBD modelled point estimates, not directly observed incidence. NA/non-finite metrics are reported without omitting failed countries or changing the denominator.", "",
  md_table(rates %>% select(specification, model, IHD_RMSE, IHD_MAE, IHD_MAPE, DD_RMSE, DD_MAE, DD_MAPE, count_MAE, count_max_absolute_error)), "",
  "Both original model families have higher IHD and DD rate RMSE than persistence in these backtests. Differences in count MAE are small and do not establish reliable prediction of incidence levels; a rank-defined count can remain similar despite appreciable country-level rate errors. No model is promoted as superior on the basis of these post-submission exploratory comparisons.", "",
  "Residual Ljung-Box values and companion roots are supplied as diagnostics only. These exploratory diagnostics were not used for multiple-testing claims or post hoc model selection. Country-level and horizon-specific validation results are saved for examination of poor performance hidden by aggregate metrics.", "",
  "## Uncertainty and limits", "",
  "No inferential confidence or prediction bands are shown. The legacy ribbon was exactly 0.85-1.15 times each count, which has no statistical 95% coverage interpretation. Replacing it with independent per-country simulations would impose unverified cross-country independence, ignore GBD posterior dependence and omitted future-SDI/parameter uncertainty, and could falsely narrow uncertainty for a threshold-and-rank count. The available matrices have no joint GBD posterior draws; a credible joint count interval has not been established. Model divergence and validation error are evidence of fragility, not substitutes for a 95% interval.", "",
  "The fixed-SDI future is a conditional scenario, not a forecast of socioeconomic change. Small annual samples, modelled and rounded incidence inputs, potential structural breaks, serial and spatial dependence, weak extrapolation support, and unquantified parameter/input/covariate uncertainty further limit policy interpretation. In particular, do not emphasize 19 countries as the expected global 2030 outcome.", "",
  "## Figure specification and acceptance", "",
  "R generated both panels and every export at 183 x 103 mm. Panel a balances original VARX and ARIMAX specifications; panel b reveals sensitivity to common scaling and removal of historical-range clipping. Both panels use the same country denominator, axes, colors and year boundary. Any unavailable complete-denominator count is visibly marked rather than interpolated or reconstructed by ranking infinities. Source data, SVG, PDF, 600-dpi TIFF and PNG preview accompany the scripts.", "",
  "Deterministic data/reporting gates pass when the input hashes, wrapper-equivalence checks, 204-country denominator and count bound checks pass. The original-code comparison uses a relative tolerance of 1e-7 to accommodate log(1+x) versus log1p floating-point differences; the maximum observed relative difference is below 3e-8 and no count changes. Statistical validity of the original VARX forecast fails because of extensive instability, and credible count intervals remain unavailable. This finding is an audit result, not a reason to relabel the original forecast as validated. The revision decision is to retain the audit figure and remove a precise 2030 headline; independent review is recorded separately in qa/independent_review.md when complete.", "",
  "## Reproduction", "",
  "Run from this analysis directory with R 4.5.0 and the package versions in package_versions.csv:", "",
  "```text", "Rscript run_forecast_revision.R", "Rscript audit_archived_arimax.R", "Rscript prepare_forecast_report.R", "```", "",
  "The first script caches model fits per model/specification/origin. Existing caches are used only to regenerate reports/exports without repeated fitting. Caches are not keyed automatically to input or code hashes: any future change in data, analytic code, package versions or protocol requires a new empty output directory and clean computation. For a clean independent reproduction, use a new empty output directory containing the scripts and contract; no original source file is overwritten. Execution logs preserve numerical warnings and implementation failures. The repairs were a Windows path workaround and preservation of the matrix dimensions when applying a zero floor; neither changes the locked scientific design.")
writeLines(report, "forecast_report.md", useBytes = TRUE)

legend <- c("Figure 4. Sensitivity of projected numbers of countries with co-high ischaemic heart disease and depressive disorder incidence.",
  sprintf("Historical counts (1992-2021; black) and conditional point forecasts (2022-2030) across 204 countries and territories. Co-high incidence denotes membership in the highest annual country rank quartile of both age-standardized incidence rates; cutoffs are recomputed each year, and the count is at most 51. a, Original specified models: VARX on log-transformed rates with fixed lag 2 and historical-minimum/1.5-times-maximum clipping, and separate raw-scale ARIMAX models selected by auto.arima. These yield %s and %s countries, respectively, in 2030. b, A companion sensitivity uses log-transformed rates in both models and removes historical-range clipping, retaining a zero floor. ARIMAX yields %s countries in 2030; the complete-denominator VARX count becomes unavailable from %s because some predictions are non-finite. Future SDI is held at its 2021 value in all scenarios. Lines show point forecasts only; no confidence or prediction intervals are available. %s of 204 original full-fit VARX models are unstable, so clipped results are shown for audit rather than as reliable policy projections. Colors and linetypes identify model families; the vertical dotted line separates historical estimates from forecasts.", n_orig_varx, n_orig_arimax, n_harm_arimax, first_bad_text, n_unstable))
writeLines(legend, "Figure4_legend.txt", useBytes = TRUE)

manuscript <- c("# Forecast replacement text for review", "",
  "## Results", "",
  sprintf("The number of countries simultaneously in the highest annual incidence quartile for IHD and DD was 14 in 1992 and 15 in 2021. Under the original fixed-SDI specifications, the reproducible VARX and ARIMAX scenarios yielded %s and %s such countries in 2030, respectively (Figure 4a). However, %s of 204 fitted VARX models were unstable, and the VARX scenario depended on historical-range clipping. In a common-log-scale sensitivity without that clipping, ARIMAX yielded %s countries in 2030, whereas non-finite VARX forecasts prevented calculation of a complete-denominator count from %s (Figure 4b). These results indicate substantial specification sensitivity and do not support a precise estimate of the number of co-high countries in 2030.", n_orig_varx, n_orig_arimax, n_unstable, n_harm_arimax, first_bad_text), "",
  "## Abstract option", "",
  "Exploratory projections were sensitive to model specification; instability in country-level VARX models and unquantified forecast uncertainty precluded a precise 2030 estimate.", "",
  "## Required reporting correction", "",
  "The former +/-15% count bands were not statistical confidence intervals and have been removed. Forecasts are conditional on constant future SDI. No joint uncertainty interval for the country count has been validated. The archived ARIMAX count of 14 is not reproduced by the raw-scale trend implementation in the recorded environment, so it should not be retained without resolving the historical version discrepancy.")
writeLines(manuscript, "manuscript_forecast_text.md", useBytes = TRUE)

# Bind the final reports, scripts, tables and exports to their current state.
out <- normalizePath(getwd(), winslash = "/")
figdir <- file.path(dirname(dirname(out)), "03_figures")
files <- c(list.files(out, recursive = TRUE, full.names = TRUE), list.files(figdir, pattern = "^Figure4_forecast_revision\\.", full.names = TRUE))
files <- files[!basename(files) %in% c("output_checksums.csv", "execution.log")]
hashes <- data.frame(file = files, bytes = suppressWarnings(file.info(files)$size),
  sha256 = vapply(files, function(f) suppressWarnings(digest::digest(file = f, algo = "sha256")), character(1)))
write.csv(hashes, "output_checksums.csv", row.names = FALSE)
cat("Reports and final checksums saved.\n")
