# Reproducible forecast audit and balanced Figure 4; R-only workflow.
options(stringsAsFactors = FALSE, width = 120)
Sys.setenv(LANGUAGE = "en")
if (.Platform$OS.type == "windows") suppressWarnings(Sys.setlocale("LC_CTYPE", "English_United States.UTF-8"))
set.seed(20260918)
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(forecast); library(MTS)
  library(ggplot2); library(patchwork)
})

args <- commandArgs(trailingOnly = TRUE)
input_dir <- if (length(args) >= 1) args[1] else "<LOCAL_PROJECT_ROOT>/Part5"
out_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
revision_dir <- dirname(dirname(out_dir))
figure_dir <- file.path(revision_dir, "03_figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
for (sub in c("baseline", "results", "qa")) dir.create(file.path(out_dir, sub), showWarnings = FALSE)

write_csv <- function(x, name) write.csv(x, file.path(out_dir, name), row.names = FALSE, na = "")
emit <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
required <- c("MTS", "forecast", "vroom", "dplyr", "tidyr", "ggplot2", "patchwork", "svglite", "ragg", "jsonlite", "digest")
stopifnot(all(vapply(required, requireNamespace, logical(1), quietly = TRUE)))
capture.output(sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))
write_csv(data.frame(package = required, version = vapply(required, function(p) as.character(packageVersion(p)), character(1))), "package_versions.csv")

input_names <- paste0(c("IHD", "DD", "SDI"), "_1992_2021_matrix.csv")
fingerprint <- function(files) data.frame(file = files, bytes = file.info(files)$size,
  sha256 = vapply(files, digest::digest, character(1), file = TRUE, algo = "sha256"))
input_hash_before <- fingerprint(file.path(input_dir, input_names))
write_csv(input_hash_before, "input_checksums.csv")
raw <- lapply(input_names, function(f) read.csv(file.path(input_dir, f), check.names = FALSE))
names(raw) <- c("IHD", "DD", "SDI")
years <- 1992:2021
stopifnot(all(vapply(raw, nrow, integer(1)) == 204L))
stopifnot(all(vapply(raw, function(z) identical(names(z), c("location_name", paste0("val_", years))), logical(1))))
stopifnot(all(vapply(raw, function(z) !anyDuplicated(z$location_name) && !anyNA(z), logical(1))))
countries <- sort(raw$IHD$location_name)
stopifnot(all(vapply(raw, function(z) setequal(z$location_name, countries), logical(1))))
raw <- lapply(raw, function(z) z[match(countries, z$location_name), ])
mat <- lapply(raw, function(z) { a <- as.matrix(z[, -1]); storage.mode(a) <- "double"; a })
stopifnot(all(mat$IHD > 0), all(mat$DD > 0), all(mat$SDI > 0 & mat$SDI < 1))
write_csv(data.frame(input = names(raw), countries = 204, years = 30, missing = 0,
                     minimum = vapply(mat, min, numeric(1)), maximum = vapply(mat, max, numeric(1))), "qa/input_audit.csv")

# dplyr::ntile is retained; alphabetic country order deterministically resolves ties.
rank_pair <- function(ihd, dd) {
  if (any(!is.finite(ihd)) || any(!is.finite(dd)) || length(ihd) != 204) return(rep(NA, length(ihd)))
  dplyr::ntile(ihd, 4) == 4L & dplyr::ntile(dd, 4) == 4L
}
actual <- bind_rows(lapply(seq_along(years), function(j) data.frame(
  location_name = countries, year = years[j], IHD = mat$IHD[, j], DD = mat$DD[, j],
  high_high = rank_pair(mat$IHD[, j], mat$DD[, j]))))
actual_counts <- actual %>% group_by(year) %>% summarise(n_high = sum(high_high), .groups = "drop")
stopifnot(all(actual_counts$n_high <= 51), !anyNA(actual$high_high))
write_csv(actual, "results/historical_country_source.csv")
write_csv(actual_counts, "results/historical_counts.csv")

# Iteration 0 executes the original model block without editing its calculations.
baseline_file <- file.path(out_dir, "baseline", "baseline_reproduced.rds")
if (!file.exists(baseline_file)) {
  baseline <- list()
  for (model in c("VARX", "ARIMAX")) {
    emit("Executing original baseline", model)
    bdir <- file.path(out_dir, "baseline", model)
    dir.create(bdir, showWarnings = FALSE)
    invisible(file.copy(file.path(input_dir, input_names), bdir, overwrite = FALSE))
    # An ASCII temporary execution directory avoids a vroom Windows path-encoding defect.
    # Inputs and every generated baseline artifact are archived in the revision directory.
    stage_dir <- file.path(tempdir(), paste0("forecast_original_", model))
    dir.create(stage_dir, showWarnings = FALSE)
    invisible(file.copy(file.path(input_dir, input_names), stage_dir, overwrite = TRUE))
    source_name <- if (model == "VARX") "GBD_7_1.R" else "GBD_7_2.R"
    source_lines <- readLines(file.path(input_dir, source_name), warn = FALSE, encoding = "UTF-8")
    first_plot <- which(grepl("^library\\(ggplot2\\)", source_lines))[1]
    code <- source_lines[seq_len(first_plot - 1L)]
    writeLines(code, file.path(bdir, "original_model_block.R"), useBytes = TRUE)
    e <- new.env(parent = globalenv())
    warning_text <- character()
    old <- getwd(); setwd(stage_dir)
    zz <- file("baseline_execution.log", "wt", encoding = "UTF-8")
    sink(zz)
    baseline_error <- tryCatch(withCallingHandlers(eval(parse(text = code), envir = e),
      warning = function(w) { warning_text <<- c(warning_text, conditionMessage(w)); invokeRestart("muffleWarning") }),
      error = function(e) conditionMessage(e))
    sink(); close(zz); setwd(old)
    invisible(file.copy(list.files(stage_dir, full.names = TRUE), bdir, overwrite = TRUE))
    writeLines(unique(warning_text), file.path(bdir, "warnings.log"), useBytes = TRUE)
    if (is.character(baseline_error) && length(baseline_error) == 1L) stop(baseline_error)
    baseline[[model]] <- list(prediction = as.data.frame(e$future_pred), count = as.data.frame(e$burden_trend))
    write_csv(baseline[[model]]$prediction, paste0("baseline/", model, "_future_prediction.csv"))
    write_csv(baseline[[model]]$count, paste0("baseline/", model, "_annual_count.csv"))
  }
  saveRDS(baseline, baseline_file)
} else baseline <- readRDS(baseline_file)

baseline_checks <- bind_rows(lapply(names(baseline), function(model) {
  pred <- baseline[[model]]$prediction %>% filter(year == 2030) %>% arrange(location_name)
  saved <- read.csv(file.path(input_dir, paste0("Future_Risk_Quartile_2030_", model, ".csv"))) %>% arrange(location_name)
  count_2030 <- sum(rank_pair(pred$IHD_pred, pred$DD_pred))
  data.frame(model = model, reproduced_2030_count = count_2030,
    saved_2030_count = sum(saved$High_Burden == "High-High"),
    max_IHD_abs_difference = max(abs(pred$IHD_pred - saved$IHD_pred)),
    max_DD_abs_difference = max(abs(pred$DD_pred - saved$DD_pred)),
    country_set_equal = identical(pred$location_name, saved$location_name))
}))
write_csv(baseline_checks, "qa/baseline_saved_output_comparison.csv")
emit("Baseline comparison:"); print(baseline_checks)

# Fixed companion sensitivity: both models log1p, no historical-range clipping.
# All orders/transforms/bounds/covariates use training data only.
quiet_mts <- function(expr) {
  capture.output(ans <- eval.parent(substitute(expr)), file = file.path(out_dir, "model_fit_detail.log"), append = TRUE)
  ans
}
fit_country <- function(i, origin, model, specification, end_year) {
  train <- years <= origin; h <- end_year - origin
  yr <- (origin + 1L):end_year
  ihd <- mat$IHD[i, train]; dd <- mat$DD[i, train]; sdi <- mat$SDI[i, train]
  result <- list(pred = matrix(NA_real_, h, 2L), status = "ok", message = "", roots = NA_real_,
    p_IHD = NA_integer_, d_IHD = NA_integer_, q_IHD = NA_integer_,
    p_DD = NA_integer_, d_DD = NA_integer_, q_DD = NA_integer_,
    clip_low_IHD = 0L, clip_high_IHD = 0L, clip_low_DD = 0L, clip_high_DD = 0L,
    zero_floor_IHD = 0L, zero_floor_DD = 0L,
    residual_lb_IHD = NA_real_, residual_lb_DD = NA_real_)
  warnings <- character()
  result <- tryCatch(withCallingHandlers({
    if (model == "Persistence") {
      result$pred <- cbind(rep(tail(ihd, 1), h), rep(tail(dd, 1), h))
    } else if (model == "VARX") {
      Y <- log1p(cbind(ihd, dd)); X <- matrix(sdi, ncol = 1)
      fit <- quiet_mts(MTS::VARX(Y, p = 2, xt = X, include.mean = TRUE))
      companion <- rbind(fit$Phi, cbind(diag(2), matrix(0, 2, 2)))
      result$roots <- max(Mod(eigen(companion, only.values = TRUE)$values))
      pred <- quiet_mts(MTS::VARXpred(fit, newxt = matrix(rep(tail(sdi, 1), h), ncol = 1), hstep = h))$pred
      result$pred <- expm1(pred)
      if (specification == "Original") {
        result$clip_low_IHD <- sum(result$pred[, 1] < min(ihd)); result$clip_high_IHD <- sum(result$pred[, 1] > 1.5 * max(ihd))
        result$clip_low_DD <- sum(result$pred[, 2] < min(dd)); result$clip_high_DD <- sum(result$pred[, 2] > 1.5 * max(dd))
        result$pred[, 1] <- pmin(pmax(result$pred[, 1], min(ihd)), 1.5 * max(ihd))
        result$pred[, 2] <- pmin(pmax(result$pred[, 2], min(dd)), 1.5 * max(dd))
      } else {
        result$zero_floor_IHD <- sum(result$pred[, 1] < 0); result$zero_floor_DD <- sum(result$pred[, 2] < 0)
        result$pred <- pmax(result$pred, 0)
      }
      result$p_IHD <- result$p_DD <- 2L
      result$residual_lb_IHD <- Box.test(fit$residuals[, 1], lag = 5, type = "Ljung-Box")$p.value
      result$residual_lb_DD <- Box.test(fit$residuals[, 2], lag = 5, type = "Ljung-Box")$p.value
    } else {
      vals <- list(ihd, dd)
      for (j in 1:2) {
        y <- if (specification == "Harmonized") log1p(vals[[j]]) else vals[[j]]
        fit <- forecast::auto.arima(y, xreg = matrix(sdi, ncol = 1))
        pred <- as.numeric(forecast::forecast(fit, xreg = matrix(rep(tail(sdi, 1), h), ncol = 1), h = h)$mean)
        if (specification == "Harmonized") {
          pred <- expm1(pred)
          result[[paste0("zero_floor_", c("IHD", "DD")[j])]] <- sum(pred < 0)
          pred <- pmax(0, pred)
        }
        result$pred[, j] <- pred
        ord <- forecast::arimaorder(fit)
        for (nm in c("p", "d", "q")) result[[paste0(nm, "_", c("IHD", "DD")[j])]] <- unname(ord[nm])
        result[[paste0("residual_lb_", c("IHD", "DD")[j])]] <- Box.test(residuals(fit), lag = 5, type = "Ljung-Box")$p.value
      }
    }
    if (any(!is.finite(result$pred))) { result$status <- "nonfinite"; result$message <- "Nonfinite rate forecast; annual count cannot use an incomplete denominator" }
    result
  }, warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") }),
  error = function(e) { result$status <- "failed"; result$message <- conditionMessage(e); result })
  pred <- data.frame(location_name = countries[i], origin = origin, specification = specification,
    model = model, year = yr, horizon = seq_len(h), IHD_pred = result$pred[, 1], DD_pred = result$pred[, 2])
  diag <- data.frame(location_name = countries[i], origin = origin, specification = specification, model = model,
    n_train = sum(train), n_forecast = h, future_SDI = tail(sdi, 1),
    as.data.frame(result[setdiff(names(result), "pred")]), warning = paste(unique(warnings), collapse = " | "))
  list(pred = pred, diag = diag)
}

results_file <- file.path(out_dir, "results", "all_fit_results.rds")
if (!file.exists(results_file)) {
  predictions <- list(); diagnostics <- list(); k <- 0L
  for (origin in c(2021L, 2012L, 2015L, 2018L)) {
    end_year <- if (origin == 2021L) 2030L else 2021L
    for (spec in c("Original", "Harmonized")) for (model in c("VARX", "ARIMAX")) {
      cache <- file.path(out_dir, "results", paste0("fits_", origin, "_", spec, "_", model, ".rds"))
      if (file.exists(cache)) block <- readRDS(cache) else {
        emit("Fitting", origin, spec, model)
        block <- lapply(seq_along(countries), function(i) {
          if (i %% 50 == 0) emit("Progress", origin, spec, model, i, "/", length(countries))
          fit_country(i, origin, model, spec, end_year)
        })
        saveRDS(block, cache)
      }
      k <- k + 1L
      predictions[[k]] <- bind_rows(lapply(block, `[[`, "pred"))
      diagnostics[[k]] <- bind_rows(lapply(block, `[[`, "diag"))
    }
    block <- lapply(seq_along(countries), function(i) fit_country(i, origin, "Persistence", "Benchmark", end_year))
    k <- k + 1L; predictions[[k]] <- bind_rows(lapply(block, `[[`, "pred")); diagnostics[[k]] <- bind_rows(lapply(block, `[[`, "diag"))
  }
  fits <- list(predictions = bind_rows(predictions), diagnostics = bind_rows(diagnostics))
  saveRDS(fits, results_file)
} else fits <- readRDS(results_file)
predictions <- fits$predictions
diagnostics <- fits$diagnostics
write_csv(diagnostics, "results/model_diagnostics.csv")
predictions <- predictions %>% arrange(origin, specification, model, year, location_name) %>%
  group_by(origin, specification, model, year) %>% mutate(high_high_pred = rank_pair(IHD_pred, DD_pred)) %>% ungroup()
counts <- predictions %>% group_by(origin, specification, model, year, horizon) %>%
  summarise(n_countries = n(), n_valid = sum(is.finite(IHD_pred) & is.finite(DD_pred)),
    n_high = if (all(!is.na(high_high_pred))) sum(high_high_pred) else NA_integer_, .groups = "drop")
write_csv(predictions, "results/all_country_forecasts.csv")
write_csv(counts, "results/all_country_counts.csv")
write_csv(predictions %>% filter(origin == 2021, year == 2030, high_high_pred), "results/high_high_countries_2030.csv")

# Original wrapper equivalence is an implementation gate, not model validation.
wrapper_check <- bind_rows(lapply(c("VARX", "ARIMAX"), function(model) {
  orig <- baseline[[model]]$prediction %>% arrange(location_name, year)
  new <- predictions %>% filter(origin == 2021, specification == "Original", .data$model == .env$model) %>% arrange(location_name, year)
  data.frame(model = model, rows = nrow(new), max_IHD_difference = max(abs(orig$IHD_pred - new$IHD_pred)),
    max_DD_difference = max(abs(orig$DD_pred - new$DD_pred)),
    max_IHD_relative_difference = max(abs(orig$IHD_pred - new$IHD_pred) / pmax(1, abs(orig$IHD_pred))),
    max_DD_relative_difference = max(abs(orig$DD_pred - new$DD_pred) / pmax(1, abs(orig$DD_pred))))
}))
write_csv(wrapper_check, "qa/wrapper_baseline_equivalence.csv")
stopifnot(all(wrapper_check$max_IHD_relative_difference < 1e-7), all(wrapper_check$max_DD_relative_difference < 1e-7))

validation <- predictions %>% filter(origin < 2021) %>% left_join(actual, by = c("location_name", "year")) %>%
  mutate(IHD_error = IHD_pred - IHD, DD_error = DD_pred - DD)
write_csv(validation, "results/rolling_origin_predictions.csv")
rate_metrics <- validation %>% group_by(specification, model, origin, horizon) %>%
  summarise(n = n(), IHD_RMSE = sqrt(mean(IHD_error^2)), IHD_MAE = mean(abs(IHD_error)),
    IHD_MAPE = mean(abs(IHD_error) / IHD) * 100, DD_RMSE = sqrt(mean(DD_error^2)),
    DD_MAE = mean(abs(DD_error)), DD_MAPE = mean(abs(DD_error) / DD) * 100,
    high_high_agreement = mean(high_high_pred == high_high), .groups = "drop")
count_metrics <- counts %>% filter(origin < 2021) %>% left_join(actual_counts, by = "year", suffix = c("_pred", "_actual")) %>%
  mutate(count_error = n_high_pred - n_high_actual, count_absolute_error = abs(count_error))
validation_summary <- validation %>% group_by(specification, model) %>%
  summarise(n_country_origin_horizon = n(), IHD_RMSE = sqrt(mean(IHD_error^2)), IHD_MAE = mean(abs(IHD_error)),
    IHD_MAPE = mean(abs(IHD_error) / IHD) * 100, DD_RMSE = sqrt(mean(DD_error^2)), DD_MAE = mean(abs(DD_error)),
    DD_MAPE = mean(abs(DD_error) / DD) * 100, high_high_agreement = mean(high_high_pred == high_high), .groups = "drop") %>%
  left_join(count_metrics %>% group_by(specification, model) %>% summarise(count_MAE = mean(count_absolute_error),
    count_max_absolute_error = max(count_absolute_error), n_origin_horizons = n(), .groups = "drop"), by = c("specification", "model"))
write_csv(rate_metrics, "results/validation_rate_metrics_by_horizon.csv")
write_csv(count_metrics, "results/validation_count_metrics.csv")
write_csv(validation_summary, "results/validation_summary.csv")

diag_summary <- diagnostics %>% group_by(origin, specification, model) %>% summarise(
  n = n(), n_failed = sum(status != "ok"), n_unstable_VARX = sum(roots >= 1, na.rm = TRUE),
  maximum_VARX_root = if (all(is.na(roots))) NA_real_ else max(roots, na.rm = TRUE),
  IHD_lower_clips = sum(clip_low_IHD), IHD_upper_clips = sum(clip_high_IHD),
  DD_lower_clips = sum(clip_low_DD), DD_upper_clips = sum(clip_high_DD),
  IHD_zero_floors = sum(zero_floor_IHD), DD_zero_floors = sum(zero_floor_DD),
  .groups = "drop")
write_csv(diag_summary, "results/model_diagnostic_summary.csv")

# Figure derives only from saved analysis tables. No confidence or prediction ribbon.
figure_source <- counts %>% filter(origin == 2021, model != "Persistence") %>%
  select(specification, model, year, n_countries, n_valid, n_high)
write_csv(figure_source, "results/Figure4_source.csv")
endpoint <- figure_source %>% filter(year == 2030)
colours <- c(VARX = "#356A9A", ARIMAX = "#D4843C")
theme_pub <- theme_classic(base_size = 7, base_family = "Arial") + theme(
  axis.line = element_line(linewidth = .3), axis.ticks = element_line(linewidth = .3),
  axis.text = element_text(colour = "#222222", size = 6.5), axis.title = element_text(size = 7),
  plot.title = element_text(size = 8, face = "bold"), plot.subtitle = element_text(size = 6.5, colour = "#555555"),
  plot.margin = margin(5, 8, 5, 5), legend.position = "bottom", legend.title = element_blank(),
  legend.text = element_text(size = 7), panel.grid.major.y = element_line(colour = "#E9E9E9", linewidth = .2))
max_count <- max(c(actual_counts$n_high, figure_source$n_high), na.rm = TRUE)
y_top <- min(51, max_count + 4)
make_panel <- function(spec, tag, title, subtitle) {
  f <- figure_source %>% filter(specification == spec)
  anchor <- data.frame(specification = spec, model = c("VARX", "ARIMAX"), year = 2021,
    n_countries = 204, n_valid = 204, n_high = actual_counts$n_high[actual_counts$year == 2021])
  f <- bind_rows(anchor, f)
  lab <- endpoint %>% filter(specification == spec, !is.na(n_high)) %>% arrange(n_high)
  lab$label_y <- lab$n_high
  if (nrow(lab) == 2L && diff(range(lab$n_high)) < 2) lab$label_y <- lab$n_high + c(-1.2, 1.2)
  unavailable <- f %>% filter(is.na(n_high))
  unavailable_note <- if (nrow(unavailable)) paste0("VARX count unavailable from ", min(unavailable$year),
    "\n(non-finite country forecasts)") else ""
  if (spec == "Original") {
    d_orig <- diagnostics %>% filter(origin == 2021, specification == "Original", model == "VARX")
    clipped_total <- sum(d_orig$clip_low_IHD + d_orig$clip_high_IHD + d_orig$clip_low_DD + d_orig$clip_high_DD)
    unavailable_note <- paste0(sum(d_orig$roots >= 1), "/204 VARX models unstable\n",
      format(clipped_total, big.mark = ","), "/3,672 projected rates clipped")
  }
  ggplot() + geom_vline(xintercept = 2021.5, colour = "#999999", linetype = "dotted", linewidth = .35) +
    geom_line(data = actual_counts, aes(year, n_high), colour = "#414141", linewidth = .55) +
    geom_point(data = actual_counts %>% filter(year %in% c(1992, 2021)), aes(year, n_high), colour = "#414141", size = 1) +
    geom_line(data = f, aes(year, n_high, colour = model, linetype = model), linewidth = .65) +
    geom_point(data = f %>% filter(year == 2030), aes(year, n_high, colour = model, shape = model), size = 1.8) +
    geom_text(data = lab, aes(x = 2031.0, y = label_y, label = n_high, colour = model), hjust = 0, size = 2.5, fontface = "bold", show.legend = FALSE) +
    annotate("text", x = 2015.5, y = y_top - .7, label = "Historical", colour = "#555555", size = 2.2) +
    annotate("text", x = 2026.4, y = y_top - .7, label = "Conditional forecast", colour = "#555555", size = 2.2) +
    annotate("text", x = 1993, y = y_top - 5, label = unavailable_note, colour = colours["VARX"], size = 2.1, hjust = 0, vjust = 1) +
    scale_colour_manual(values = colours) + scale_linetype_manual(values = c(VARX = "longdash", ARIMAX = "dotted")) +
    scale_shape_manual(values = c(VARX = 16, ARIMAX = 17)) +
    scale_x_continuous(breaks = c(1992, 2000, 2010, 2021, 2030), limits = c(1991, 2033), expand = c(0, 0)) +
    scale_y_continuous(limits = c(0, y_top), breaks = seq(0, y_top, by = 5), expand = c(0, 0)) +
    labs(title = paste0(tag, "  ", title), subtitle = subtitle, x = "Year", y = "Countries with co-high incidence (n)") + theme_pub
}
p1 <- make_panel("Original", "a", "Original model specifications", "Different scales; VARX historical-range clipping")
p2 <- make_panel("Harmonized", "b", "Common-scale sensitivity", "Both log1p; no historical-range clipping")
fig <- (p1 | p2) + plot_layout(guides = "collect") & theme(legend.position = "bottom")
fig <- fig + plot_annotation(caption = paste(
  "204 countries/territories; high-high = highest annual rank quartile for both incidence rates.",
  "Future SDI held constant. Point forecasts only; uncertainty intervals are not available.", sep = "\n"),
  theme = theme(plot.caption = element_text(size = 6.5, hjust = 0, family = "Arial", colour = "#444444"), plot.margin = margin(2, 6, 2, 6)))
width_mm <- 183; height_mm <- 103
stem <- file.path(figure_dir, "Figure4_forecast_revision")
svglite::svglite(paste0(stem, ".svg"), width = width_mm / 25.4, height = height_mm / 25.4, system_fonts = list(sans = "Arial")); print(fig); dev.off()
grDevices::cairo_pdf(paste0(stem, ".pdf"), width = width_mm / 25.4, height = height_mm / 25.4, family = "Arial"); print(fig); dev.off()
ragg::agg_tiff(paste0(stem, ".tiff"), width = width_mm, height = height_mm, units = "mm", res = 600, compression = "lzw"); print(fig); dev.off()
ragg::agg_png(paste0(stem, ".png"), width = width_mm, height = height_mm, units = "mm", res = 300); print(fig); dev.off()
build_a <- ggplot_build(p1); build_b <- ggplot_build(p2)
stopifnot(identical(build_a$layout$panel_params[[1]]$x.range, build_b$layout$panel_params[[1]]$x.range),
          identical(build_a$layout$panel_params[[1]]$y.range, build_b$layout$panel_params[[1]]$y.range))
has_ribbon <- any(vapply(c(p1$layers, p2$layers), function(z) inherits(z$geom, "GeomRibbon"), logical(1)))
svg_text <- readLines(paste0(stem, ".svg"), warn = FALSE)
stopifnot(!has_ribbon, any(grepl("<text", svg_text, fixed = TRUE)))
write_csv(data.frame(check = c("equal_panel_x_ranges", "equal_panel_y_ranges", "no_inferential_ribbon", "editable_svg_text", "backend_R_only", "connectors_not_applicable"),
  result = c("pass", "pass", "pass", "pass", "pass", "na: no connectors")), "qa/Figure4_geometry_audit.csv")

cat("\n2030 counts:\n"); print(endpoint)
cat("\nValidation summary:\n"); print(validation_summary)
cat("\nFull-fit diagnostics:\n"); print(diag_summary %>% filter(origin == 2021))
input_hash_after <- fingerprint(file.path(input_dir, input_names))
stopifnot(identical(input_hash_before$sha256, input_hash_after$sha256))
stopifnot(all(counts$n_countries == 204), all(counts$n_high <= 51, na.rm = TRUE))
write_csv(data.frame(check = c("inputs_immutable", "204_country_denominator", "rank_count_upper_bound_51", "original_wrapper_equivalence", "no_fabricated_interval"),
  passed = TRUE), "qa/deterministic_gates.csv")
jsonlite::write_json(list(completed_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"), seed = 20260918,
  origin_years = c(2012, 2015, 2018), endpoint_counts = endpoint, uncertainty_bands = FALSE,
  figure_mm = c(width_mm, height_mm), tiff_dpi = 600, independent_review = "pending"),
  file.path(out_dir, "qa", "run_summary.json"), pretty = TRUE, auto_unbox = TRUE)
all_outputs <- c(list.files(out_dir, recursive = TRUE, full.names = TRUE), paste0(stem, c(".svg", ".pdf", ".tiff", ".png")))
all_outputs <- all_outputs[file.exists(all_outputs) & !basename(all_outputs) %in% c("output_checksums.csv", "execution.log")]
write_csv(fingerprint(all_outputs), "output_checksums.csv")
emit("DONE")
