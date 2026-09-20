#!/usr/bin/env Rscript

# INTERNAL POST-SUBMISSION TEMPORAL-PRECEDENCE AUDIT; does not replace the manuscript Figure 5.
#
# Primary estimand:
#   Does the previous annual change in IHD (DD) improve prediction of the
#   current annual change in DD (IHD), conditional on the target's own lag
#   and the contemporaneous annual change in SDI?
#
# The two outcome equations are fitted separately. This is deliberate: it
# guarantees that IHD -> DD tests the DD equation only and DD -> IHD tests
# the IHD equation only. SDI is an exogenous control, never an endogenous
# response. With only 30 annual observations, the primary lag is selected
# by Schwarz BIC from 1-3 jointly for the two endogenous series. Estimates
# use a finite-sample-adjusted Newey-West covariance with lag 2 for residual
# autocorrelation; HC3 estimates are retained as a sensitivity check,
# and raw, unrounded P values are adjusted by BH in two pre-specified
# direction-specific families of 204 countries each.

suppressPackageStartupMessages({
  library(data.table)
  library(sandwich)
  library(car)
  library(lmtest)
  library(tseries)
  library(vars)
  library(openxlsx)
  library(digest)
  library(countrycode)
  library(rworldmap)
})

options(stringsAsFactors = FALSE, scipen = 999)
set.seed(20260918)

stopifnot(
  file.exists("immutable_part4_source/IHD_1992_2021_matrix.csv"),
  file.exists("immutable_part4_source/DD_1992_2021_matrix.csv"),
  file.exists("immutable_part4_source/SDI_1992_2021_matrix.csv")
)

out_dir <- "granger_corrected"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

input_files <- c(
  IHD = "immutable_part4_source/IHD_1992_2021_matrix.csv",
  DD = "immutable_part4_source/DD_1992_2021_matrix.csv",
  SDI = "immutable_part4_source/SDI_1992_2021_matrix.csv",
  submitted_results = "immutable_part4_source/IHD_DD_SDI_VAR_Granger_Results_NoSex.csv"
)

input_manifest <- data.table(
  input = names(input_files),
  path = normalizePath(input_files, winslash = "/", mustWork = TRUE),
  bytes = file.info(input_files)$size,
  sha256 = vapply(input_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(input_manifest, file.path(out_dir, "input_checksums_sha256.csv"))

ihd <- fread(input_files[["IHD"]], check.names = FALSE)
dd  <- fread(input_files[["DD"]], check.names = FALSE)
sdi <- fread(input_files[["SDI"]], check.names = FALSE)

years <- 1992:2021
value_cols <- paste0("val_", years)
stopifnot(nrow(ihd) == 204L, nrow(dd) == 204L, nrow(sdi) == 204L)
stopifnot(all(value_cols %in% names(ihd)), all(value_cols %in% names(dd)), all(value_cols %in% names(sdi)))
stopifnot(setequal(ihd$location_name, dd$location_name), setequal(ihd$location_name, sdi$location_name))
stopifnot(!anyDuplicated(ihd$location_name), !anyDuplicated(dd$location_name), !anyDuplicated(sdi$location_name))

setkey(ihd, location_name)
setkey(dd, location_name)
setkey(sdi, location_name)
locations <- sort(ihd$location_name)

safe_adf <- function(x) {
  if (length(unique(x[is.finite(x)])) < 4L) return(NA_real_)
  tryCatch(
    suppressWarnings(tseries::adf.test(x, k = 1)$p.value),
    error = function(e) NA_real_
  )
}

fit_direction <- function(target, cause, dsdi, lag_order = 1L) {
  stopifnot(length(target) == 29L, length(cause) == 29L, length(dsdi) == 29L)
  idx <- (lag_order + 1L):length(target)
  dat <- data.frame(
    target = target[idx],
    SDI_exogenous = dsdi[idx]
  )
  for (j in seq_len(lag_order)) {
    dat[[paste0("target_L", j)]] <- target[idx - j]
    dat[[paste0("cause_L", j)]] <- cause[idx - j]
  }
  dat <- dat[, c("target", paste0("target_L", seq_len(lag_order)),
                 paste0("cause_L", seq_len(lag_order)), "SDI_exogenous")]

  ans <- list(
    status = "fit_failed", n = nrow(dat), residual_df = NA_integer_,
    f_statistic = NA_real_, df_num = NA_real_, df_den = NA_real_,
    p_hac = NA_real_, p_hc3 = NA_real_, coefficient_cause_L1 = NA_real_,
    se_hac_cause_L1 = NA_real_, se_hc3_cause_L1 = NA_real_,
    bg_p_lag2 = NA_real_, bp_p = NA_real_, shapiro_p = NA_real_,
    max_cooks_d = NA_real_, condition_number = NA_real_, error = NA_character_
  )

  tryCatch({
    fit <- lm(target ~ ., data = dat)
    X <- model.matrix(fit)
    if (qr(X)$rank < ncol(X)) stop("rank-deficient design matrix")
    V <- sandwich::vcovHC(fit, type = "HC3")
    V_hac <- sandwich::NeweyWest(fit, lag = 2L, prewhite = FALSE, adjust = TRUE)
    tested <- paste0("cause_L", seq_len(lag_order))
    hyp <- paste0(tested, " = 0")
    lh <- car::linearHypothesis(fit, hyp, vcov. = V, test = "F")
    lh_hac <- car::linearHypothesis(fit, hyp, vcov. = V_hac, test = "F")
    row_test <- nrow(lh)
    ctest <- lmtest::coeftest(fit, vcov. = V)
    ctest_hac <- lmtest::coeftest(fit, vcov. = V_hac)
    ans$status <- "fit_ok"
    ans$residual_df <- df.residual(fit)
    ans$f_statistic <- unname(lh_hac[row_test, "F"])
    ans$df_num <- unname(lh[row_test, "Df"])
    ans$df_den <- df.residual(fit)
    ans$p_hac <- unname(lh_hac[row_test, "Pr(>F)"])
    ans$p_hc3 <- unname(lh[row_test, "Pr(>F)"])
    ans$coefficient_cause_L1 <- unname(coef(fit)["cause_L1"])
    ans$se_hac_cause_L1 <- unname(ctest_hac["cause_L1", "Std. Error"])
    ans$se_hc3_cause_L1 <- unname(ctest["cause_L1", "Std. Error"])
    ans$bg_p_lag2 <- tryCatch(
      unname(lmtest::bgtest(fit, order = 2, type = "Chisq")$p.value),
      error = function(e) NA_real_
    )
    ans$bp_p <- tryCatch(unname(lmtest::bptest(fit)$p.value), error = function(e) NA_real_)
    ans$shapiro_p <- tryCatch(unname(shapiro.test(residuals(fit))$p.value), error = function(e) NA_real_)
    ans$max_cooks_d <- max(cooks.distance(fit), na.rm = TRUE)
    ans$condition_number <- kappa(X, exact = TRUE)
    ans
  }, error = function(e) {
    ans$error <- conditionMessage(e)
    ans
  })
}

extract_series <- function(dt, location) {
  as.numeric(dt[J(location), ..value_cols])
}

select_joint_lag_bic <- function(dI, dD, dS, max_lag = 3L) {
  Y <- scale(cbind(IHD = dI, DD = dD))
  X <- scale(matrix(dS, ncol = 1L, dimnames = list(NULL, "SDI_exogenous")))
  captured_warning <- character()
  ans <- tryCatch(
    withCallingHandlers(
      vars::VARselect(Y, lag.max = max_lag, type = "const", exogen = X),
      warning = function(w) {
        captured_warning <<- c(captured_warning, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  if (inherits(ans, "error")) {
    return(list(lag = NA_integer_, warning = NA_character_, error = conditionMessage(ans)))
  }
  list(
    lag = as.integer(ans$selection[["SC(n)"]]),
    warning = if (length(captured_warning)) paste(unique(captured_warning), collapse = " | ") else NA_character_,
    error = NA_character_
  )
}

rows <- vector("list", length(locations))
lag1_rows <- vector("list", length(locations))
lag2_rows <- vector("list", length(locations))

for (i in seq_along(locations)) {
  loc <- locations[[i]]
  I <- extract_series(ihd, loc)
  D <- extract_series(dd, loc)
  S <- extract_series(sdi, loc)

  if (any(!is.finite(c(I, D, S))) || any(I <= 0) || any(D <= 0)) {
    stop("Non-finite or non-positive disease series for ", loc)
  }

  dI <- diff(log(I))
  dD <- diff(log(D))
  dS <- diff(S)

  lag_selection <- select_joint_lag_bic(dI, dD, dS, max_lag = 3L)
  if (is.na(lag_selection$lag)) {
    ihd_to_dd <- fit_direction(target = dD, cause = dI, dsdi = dS, lag_order = 1L)
    dd_to_ihd <- fit_direction(target = dI, cause = dD, dsdi = dS, lag_order = 1L)
    ihd_to_dd$status <- "lag_selection_failed"
    dd_to_ihd$status <- "lag_selection_failed"
    ihd_to_dd$error <- lag_selection$error
    dd_to_ihd$error <- lag_selection$error
  } else {
    ihd_to_dd <- fit_direction(target = dD, cause = dI, dsdi = dS, lag_order = lag_selection$lag)
    dd_to_ihd <- fit_direction(target = dI, cause = dD, dsdi = dS, lag_order = lag_selection$lag)
  }
  ihd_to_dd_l1 <- fit_direction(target = dD, cause = dI, dsdi = dS, lag_order = 1L)
  dd_to_ihd_l1 <- fit_direction(target = dI, cause = dD, dsdi = dS, lag_order = 1L)
  ihd_to_dd_l2 <- fit_direction(target = dD, cause = dI, dsdi = dS, lag_order = 2L)
  dd_to_ihd_l2 <- fit_direction(target = dI, cause = dD, dsdi = dS, lag_order = 2L)

  rows[[i]] <- data.table(
    location_name = loc,
    n_years_levels = 30L,
    n_annual_changes = 29L,
    selected_lag_BIC = lag_selection$lag,
    lag_selection_warning = lag_selection$warning,
    lag_selection_error = lag_selection$error,
    adf_IHD_level_p = safe_adf(log(I)),
    adf_DD_level_p = safe_adf(log(D)),
    adf_IHD_log_change_p = safe_adf(dI),
    adf_DD_log_change_p = safe_adf(dD),
    IHD_to_DD_status = ihd_to_dd$status,
    IHD_to_DD_n = ihd_to_dd$n,
    IHD_to_DD_residual_df = ihd_to_dd$residual_df,
    IHD_to_DD_F = ihd_to_dd$f_statistic,
    IHD_to_DD_df_num = ihd_to_dd$df_num,
    IHD_to_DD_df_den = ihd_to_dd$df_den,
    IHD_to_DD_p = ihd_to_dd$p_hac,
    IHD_to_DD_p_HC3 = ihd_to_dd$p_hc3,
    IHD_to_DD_beta_lag1 = ihd_to_dd$coefficient_cause_L1,
    IHD_to_DD_HAC_SE_lag1 = ihd_to_dd$se_hac_cause_L1,
    IHD_to_DD_HC3_SE_lag1 = ihd_to_dd$se_hc3_cause_L1,
    IHD_to_DD_BG_p = ihd_to_dd$bg_p_lag2,
    IHD_to_DD_BP_p = ihd_to_dd$bp_p,
    IHD_to_DD_Shapiro_p = ihd_to_dd$shapiro_p,
    IHD_to_DD_max_CooksD = ihd_to_dd$max_cooks_d,
    IHD_to_DD_condition_number = ihd_to_dd$condition_number,
    IHD_to_DD_error = ihd_to_dd$error,
    DD_to_IHD_status = dd_to_ihd$status,
    DD_to_IHD_n = dd_to_ihd$n,
    DD_to_IHD_residual_df = dd_to_ihd$residual_df,
    DD_to_IHD_F = dd_to_ihd$f_statistic,
    DD_to_IHD_df_num = dd_to_ihd$df_num,
    DD_to_IHD_df_den = dd_to_ihd$df_den,
    DD_to_IHD_p = dd_to_ihd$p_hac,
    DD_to_IHD_p_HC3 = dd_to_ihd$p_hc3,
    DD_to_IHD_beta_lag1 = dd_to_ihd$coefficient_cause_L1,
    DD_to_IHD_HAC_SE_lag1 = dd_to_ihd$se_hac_cause_L1,
    DD_to_IHD_HC3_SE_lag1 = dd_to_ihd$se_hc3_cause_L1,
    DD_to_IHD_BG_p = dd_to_ihd$bg_p_lag2,
    DD_to_IHD_BP_p = dd_to_ihd$bp_p,
    DD_to_IHD_Shapiro_p = dd_to_ihd$shapiro_p,
    DD_to_IHD_max_CooksD = dd_to_ihd$max_cooks_d,
    DD_to_IHD_condition_number = dd_to_ihd$condition_number,
    DD_to_IHD_error = dd_to_ihd$error
  )

  lag1_rows[[i]] <- data.table(
    location_name = loc,
    IHD_to_DD_status = ihd_to_dd_l1$status,
    IHD_to_DD_p = ihd_to_dd_l1$p_hac,
    IHD_to_DD_BG_p = ihd_to_dd_l1$bg_p_lag2,
    IHD_to_DD_error = ihd_to_dd_l1$error,
    DD_to_IHD_status = dd_to_ihd_l1$status,
    DD_to_IHD_p = dd_to_ihd_l1$p_hac,
    DD_to_IHD_BG_p = dd_to_ihd_l1$bg_p_lag2,
    DD_to_IHD_error = dd_to_ihd_l1$error
  )

  lag2_rows[[i]] <- data.table(
    location_name = loc,
    IHD_to_DD_status = ihd_to_dd_l2$status,
    IHD_to_DD_p = ihd_to_dd_l2$p_hac,
    IHD_to_DD_BG_p = ihd_to_dd_l2$bg_p_lag2,
    IHD_to_DD_error = ihd_to_dd_l2$error,
    DD_to_IHD_status = dd_to_ihd_l2$status,
    DD_to_IHD_p = dd_to_ihd_l2$p_hac,
    DD_to_IHD_BG_p = dd_to_ihd_l2$bg_p_lag2,
    DD_to_IHD_error = dd_to_ihd_l2$error
  )
}

res <- rbindlist(rows, fill = TRUE)
lag1 <- rbindlist(lag1_rows, fill = TRUE)
lag2 <- rbindlist(lag2_rows, fill = TRUE)

# The planned multiplicity families contain all 204 countries. p.adjust(...,
# n=204) preserves that family size even if a fit failed and its P value is NA.
res[, IHD_to_DD_q := p.adjust(IHD_to_DD_p, method = "BH", n = 204L)]
res[, DD_to_IHD_q := p.adjust(DD_to_IHD_p, method = "BH", n = 204L)]
res[, IHD_to_DD_q_HC3 := p.adjust(IHD_to_DD_p_HC3, method = "BH", n = 204L)]
res[, DD_to_IHD_q_HC3 := p.adjust(DD_to_IHD_p_HC3, method = "BH", n = 204L)]
res[, direction := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  IHD_to_DD_q < 0.05 & DD_to_IHD_q < 0.05, "Bidirectional",
  IHD_to_DD_q < 0.05, "IHD_to_DD",
  DD_to_IHD_q < 0.05, "DD_to_IHD",
  default = "Neither"
)]
res[, direction_HC3 := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  IHD_to_DD_q_HC3 < 0.05 & DD_to_IHD_q_HC3 < 0.05, "Bidirectional",
  IHD_to_DD_q_HC3 < 0.05, "IHD_to_DD",
  DD_to_IHD_q_HC3 < 0.05, "DD_to_IHD",
  default = "Neither"
)]
res[, diagnostics := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  (!is.na(IHD_to_DD_BG_p) & IHD_to_DD_BG_p < 0.05) |
    (!is.na(DD_to_IHD_BG_p) & DD_to_IHD_BG_p < 0.05), "Residual serial correlation flag",
  (!is.na(IHD_to_DD_max_CooksD) & IHD_to_DD_max_CooksD > 4 / IHD_to_DD_n) |
    (!is.na(DD_to_IHD_max_CooksD) & DD_to_IHD_max_CooksD > 4 / DD_to_IHD_n), "Influence flag",
  default = "No pre-specified flag"
)]

lag1[, IHD_to_DD_q := p.adjust(IHD_to_DD_p, method = "BH", n = 204L)]
lag1[, DD_to_IHD_q := p.adjust(DD_to_IHD_p, method = "BH", n = 204L)]
lag1[, direction := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  IHD_to_DD_q < 0.05 & DD_to_IHD_q < 0.05, "Bidirectional",
  IHD_to_DD_q < 0.05, "IHD_to_DD",
  DD_to_IHD_q < 0.05, "DD_to_IHD",
  default = "Neither"
)]

lag2[, IHD_to_DD_q := p.adjust(IHD_to_DD_p, method = "BH", n = 204L)]
lag2[, DD_to_IHD_q := p.adjust(DD_to_IHD_p, method = "BH", n = 204L)]
lag2[, direction := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  IHD_to_DD_q < 0.05 & DD_to_IHD_q < 0.05, "Bidirectional",
  IHD_to_DD_q < 0.05, "IHD_to_DD",
  DD_to_IHD_q < 0.05, "DD_to_IHD",
  default = "Neither"
)]

# Transparent small-island sensitivity: exclude analytical units classified
# as SID in the rworldmap/Natural Earth country attribute bundled with the
# installed R package. ISO3 matching is reproducible and the exact list is
# exported; no outcome or P value is used to define exclusion.
iso3 <- countrycode(res$location_name, "country.name", "iso3c", warn = FALSE)
manual_iso3 <- c(
  "Lebanese Republic" = "LBN",
  "Republic of Guyana" = "GUY",
  "Portuguese Republic" = "PRT"
)
miss <- is.na(iso3) & res$location_name %in% names(manual_iso3)
iso3[miss] <- unname(manual_iso3[res$location_name[miss]])
if (anyNA(iso3)) stop("Unmatched ISO3: ", paste(res$location_name[is.na(iso3)], collapse = "; "))

world <- rworldmap::getMap(resolution = "low")
sid_iso3 <- sort(unique(world@data$ISO3[world@data$SID == "SID" & !is.na(world@data$SID)]))
res[, ISO3 := iso3]
res[, small_island_excluded := ISO3 %in% sid_iso3 | location_name == "Tokelau"]
small_island_list <- res[small_island_excluded == TRUE, .(location_name, ISO3)]
small_island_list[, exclusion_rule := fifelse(
  location_name == "Tokelau",
  "Tokelau: no country feature in the bundled rworldmap/Natural Earth geometry",
  "rworldmap/Natural Earth SID attribute equals 'SID'"
)]
fwrite(small_island_list, file.path(out_dir, "small_island_exclusion_list.csv"))

retained <- res[small_island_excluded == FALSE]
retained[, IHD_to_DD_q_recomputed := p.adjust(IHD_to_DD_p, method = "BH", n = .N)]
retained[, DD_to_IHD_q_recomputed := p.adjust(DD_to_IHD_p, method = "BH", n = .N)]
retained[, direction_recomputed := fcase(
  IHD_to_DD_status != "fit_ok" | DD_to_IHD_status != "fit_ok", "Fit failed",
  IHD_to_DD_q_recomputed < 0.05 & DD_to_IHD_q_recomputed < 0.05, "Bidirectional",
  IHD_to_DD_q_recomputed < 0.05, "IHD_to_DD",
  DD_to_IHD_q_recomputed < 0.05, "DD_to_IHD",
  default = "Neither"
)]

submitted <- fread(input_files[["submitted_results"]])
submitted[, submitted_direction := fifelse(is.na(direction) | direction == "NA", "Neither", direction)]
submitted[, submitted_direction := fifelse(submitted_direction == "IHD→DD", "IHD_to_DD",
                                    fifelse(submitted_direction == "DD→IHD", "DD_to_IHD", submitted_direction))]
comparison <- merge(
  res[, .(location_name, corrected_direction = direction, IHD_to_DD_p, IHD_to_DD_q,
          DD_to_IHD_p, DD_to_IHD_q, diagnostics, small_island_excluded)],
  submitted[, .(location_name, submitted_direction, submitted_IHD_to_DD_p = IHD_to_DD_p,
                submitted_IHD_to_DD_q = IHD_to_DD_padj,
                submitted_DD_to_IHD_p = DD_to_IHD_p,
                submitted_DD_to_IHD_q = DD_to_IHD_padj)],
  by = "location_name", all.x = TRUE
)
comparison[, classification_changed := corrected_direction != submitted_direction]

count_table <- function(x, col, analysis, denominator) {
  z <- x[, .N, by = col]
  setnames(z, col, "classification")
  z[, `:=`(analysis = analysis, denominator = denominator, percent = 100 * N / denominator)]
  setcolorder(z, c("analysis", "classification", "N", "denominator", "percent"))
  z[]
}

summary_counts <- rbindlist(list(
  count_table(res, "direction", "Primary: log changes, joint BIC lag 1-3, SDI exogenous, Newey-West(2), BH n=204/direction", nrow(res)),
  count_table(res, "direction_HC3", "Covariance sensitivity: same BIC models, HC3, BH n=204/direction", nrow(res)),
  count_table(lag1, "direction", "Sensitivity: log changes, fixed lag 1, SDI exogenous, Newey-West(2), BH n=204/direction", nrow(lag1)),
  count_table(lag2, "direction", "Sensitivity: log changes, fixed lag 2, SDI exogenous, Newey-West(2), BH n=204/direction", nrow(lag2)),
  count_table(retained, "direction_recomputed", paste0("Small-island sensitivity: primary after SID exclusion, BH n=", nrow(retained), "/direction"), nrow(retained)),
  count_table(submitted, "submitted_direction", "Submitted model: SDI incorrectly endogenous", nrow(submitted))
), fill = TRUE)

diagnostic_summary <- rbindlist(list(
  res[, .(metric = "Countries", value = .N)],
  res[, .(metric = "Primary fits failed in either direction", value = sum(direction == "Fit failed"))],
  res[, .(metric = "BG serial-correlation flags in either direction", value = sum(diagnostics == "Residual serial correlation flag"))],
  res[, .(metric = "Influence flags without BG flag", value = sum(diagnostics == "Influence flag"))],
  res[, .(metric = "No pre-specified diagnostic flag", value = sum(diagnostics == "No pre-specified flag"))],
  res[, .(metric = "Small-island units excluded", value = sum(small_island_excluded))],
  data.table(metric = "Primary vs submitted classification changed", value = sum(comparison$classification_changed, na.rm = TRUE))
))

fwrite(res, file.path(out_dir, "Supplementary_Table_S2_corrected.csv"))
fwrite(lag1, file.path(out_dir, "Granger_lag1_sensitivity.csv"))
fwrite(lag2, file.path(out_dir, "Granger_lag2_sensitivity.csv"))
fwrite(retained, file.path(out_dir, "Granger_small_island_excluded_sensitivity.csv"))
fwrite(comparison, file.path(out_dir, "Granger_submitted_vs_corrected.csv"))
fwrite(summary_counts, file.path(out_dir, "Granger_classification_counts.csv"))
fwrite(diagnostic_summary, file.path(out_dir, "Granger_diagnostic_summary.csv"))

wb <- createWorkbook()
addWorksheet(wb, "Corrected_S2")
writeDataTable(wb, "Corrected_S2", res)
addWorksheet(wb, "Lag1_sensitivity")
writeDataTable(wb, "Lag1_sensitivity", lag1)
addWorksheet(wb, "Lag2_sensitivity")
writeDataTable(wb, "Lag2_sensitivity", lag2)
addWorksheet(wb, "SID_excluded")
writeDataTable(wb, "SID_excluded", retained)
addWorksheet(wb, "Classification_counts")
writeDataTable(wb, "Classification_counts", summary_counts)
addWorksheet(wb, "Diagnostic_summary")
writeDataTable(wb, "Diagnostic_summary", diagnostic_summary)
addWorksheet(wb, "SID_exclusion_list")
writeDataTable(wb, "SID_exclusion_list", small_island_list)
saveWorkbook(wb, file.path(out_dir, "Supplementary_Table_S2_corrected.xlsx"), overwrite = TRUE)

method_text <- c(
  "# Internal audit: alternative directional temporal-prediction specification",
  "",
  "> **Scope:** Post-submission internal audit/sensitivity only. This file does not describe or replace the manuscript Figure 5.",
  "",
  "The primary analysis used annual log changes in age-standardised incidence (1992-2021; 29 changes per country) to reduce deterministic level trends. For each country, a common lag order for IHD and DD was selected by Schwarz BIC from 1-3 with SDI change supplied as an exogenous regressor. Two separate autoregressive equations were then fitted: current DD change was regressed on its own selected lags, selected lags of IHD change, and contemporaneous SDI change; current IHD change was analogously regressed on its own selected lags, selected lags of DD change, and contemporaneous SDI change. Thus SDI was an exogenous control and each directional test concerned only its intended target equation.",
  "",
  "The lag search was capped at three because each series contained only 30 annual observations (minimum residual df=18 in a three-lag directional equation). The joint lag restrictions used an F test with a finite-sample-adjusted Newey-West covariance truncated at lag 2; HC3 results were retained in the full table. Unrounded P values were adjusted by Benjamini-Hochberg in two separate, pre-specified families: 204 IHD-to-DD tests and 204 DD-to-IHD tests. Fixed one- and two-lag models were retained as sensitivity analyses.",
  "",
  "Diagnostics include the Breusch-Godfrey test through lag 2, Breusch-Pagan test, Shapiro-Wilk test, maximum Cook's distance, design-matrix condition number, and ADF summaries for levels and annual changes. These diagnostics are reported rather than used to select favorable results. Newey-West inference addresses residual autocorrelation and heteroskedasticity asymptotically, but the 30-year country series remain short and the analysis does not make ecological country-level associations causal.",
  "",
  paste0("The cartographic/SIDS sensitivity excluded ", nrow(small_island_list), " study units: locations whose ISO3 code has rworldmap/Natural Earth's bundled SID attribute equal to 'SID', plus Tokelau because the same bundled geometry contains no Tokelau country feature. The exact list and reason per location are exported. SID is a Small Island Developing States metadata classification, not a polygon-area or land-size threshold, and includes several coastal states. The definition was fixed from geographic metadata and did not use outcomes, effect estimates, or P values. BH adjustment was recomputed within the retained ", nrow(retained), "-country set separately for each direction.")
)
writeLines(method_text, file.path(out_dir, "method_and_reporting_notes.md"), useBytes = TRUE)

capture.output(sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

output_files <- file.path(out_dir, c(
  "input_checksums_sha256.csv",
  "Supplementary_Table_S2_corrected.csv",
  "Supplementary_Table_S2_corrected.xlsx",
  "Granger_lag1_sensitivity.csv",
  "Granger_lag2_sensitivity.csv",
  "Granger_small_island_excluded_sensitivity.csv",
  "Granger_submitted_vs_corrected.csv",
  "Granger_classification_counts.csv",
  "Granger_diagnostic_summary.csv",
  "small_island_exclusion_list.csv",
  "method_and_reporting_notes.md",
  "sessionInfo.txt"
))
stopifnot(all(file.exists(output_files)))
output_manifest <- data.table(
  path = gsub("\\\\", "/", output_files),
  bytes = file.info(output_files)$size,
  sha256 = vapply(output_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(output_manifest, file.path(out_dir, "output_checksums_sha256.csv"))

cat("\nCorrected Granger classification counts:\n")
print(summary_counts)
cat("\nDiagnostics:\n")
print(diagnostic_summary)
cat("\nSmall-island exclusions (", nrow(small_island_list), "):\n", sep = "")
print(small_island_list)
