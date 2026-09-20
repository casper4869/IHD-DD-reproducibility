#!/usr/bin/env Rscript

# Reproducible 2021 GWR and small-island sensitivity.
# This reproduces the submitted specification with explicit scaling, joins,
# distance units, kernel, bandwidth criterion, diagnostics, and exclusions.

suppressPackageStartupMessages({
  library(data.table)
  library(sp)
  library(spgwr)
  library(car)
  library(openxlsx)
  library(digest)
  library(countrycode)
  library(rworldmap)
})

options(stringsAsFactors = FALSE, scipen = 999)
set.seed(20260918)

out_dir <- "gwr_sensitivity"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

input_files <- c(
  IHD = "immutable_part7_source/IHD_1992_2021_matrix.csv",
  DD = "immutable_part7_source/DD_1992_2021_matrix.csv",
  SDI = "immutable_part7_source/SDI_1992_2021_matrix.csv",
  PM25 = "immutable_part7_source/Country_with_PM25_Matched.csv",
  coordinates = "immutable_part7_source/Country_with_LatLon_Matched.csv"
)
stopifnot(all(file.exists(input_files)))

input_manifest <- data.table(
  input = names(input_files),
  path = normalizePath(input_files, winslash = "/", mustWork = TRUE),
  bytes = file.info(input_files)$size,
  sha256 = vapply(input_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(input_manifest, file.path(out_dir, "input_checksums_sha256.csv"))

normalise_location_key <- function(x) {
  # The CSV exports use different encodings for the same Côte d'Ivoire label.
  x[grepl("Ivoire", x, fixed = TRUE)] <- "Republic of Cote d'Ivoire"
  x
}

read_2021 <- function(path, new_name) {
  z <- fread(path, check.names = FALSE)
  stopifnot(all(c("location_name", "val_2021") %in% names(z)))
  z[, location_name := normalise_location_key(location_name)]
  z <- z[, .(location_name, value = as.numeric(val_2021))]
  setnames(z, "value", new_name)
  if (anyDuplicated(z$location_name)) stop("Duplicate country key in ", path)
  z
}

dat <- Reduce(
  function(x, y) merge(x, y, by = "location_name", all = TRUE),
  list(
    read_2021(input_files[["IHD"]], "IHD"),
    read_2021(input_files[["DD"]], "DD"),
    read_2021(input_files[["SDI"]], "SDI"),
    read_2021(input_files[["PM25"]], "PM25"),
    fread(input_files[["coordinates"]])[, .(
      location_name = normalise_location_key(location_name),
      lat = as.numeric(lat), lng = as.numeric(lng)
    )]
  )
)

stopifnot(nrow(dat) == 204L, !anyDuplicated(dat$location_name))
if (anyNA(dat)) stop("Incomplete 2021 GWR join; see source files")
if (any(!is.finite(unlist(dat[, .(IHD, DD, SDI, PM25, lat, lng)])))) stop("Non-finite GWR input")

# The submitted analysis standardized each annual column across countries.
# Scaling the four 2021 columns here is exactly equivalent for the 2021 GWR.
for (v in c("IHD", "DD", "SDI", "PM25")) {
  dat[, paste0(v, "_z") := as.numeric(scale(get(v)))]
}

iso3 <- countrycode(dat$location_name, "country.name", "iso3c", warn = FALSE)
manual_iso3 <- c(
  "Lebanese Republic" = "LBN", "Republic of Guyana" = "GUY",
  "Portuguese Republic" = "PRT", "Republic of Cote d'Ivoire" = "CIV"
)
miss <- is.na(iso3) & dat$location_name %in% names(manual_iso3)
iso3[miss] <- unname(manual_iso3[dat$location_name[miss]])
if (anyNA(iso3)) stop("Unmatched ISO3: ", paste(dat$location_name[is.na(iso3)], collapse = "; "))
world <- rworldmap::getMap(resolution = "low")
sid_iso3 <- sort(unique(world@data$ISO3[world@data$SID == "SID" & !is.na(world@data$SID)]))
dat[, `:=`(ISO3 = iso3, small_island_excluded = iso3 %in% sid_iso3 | location_name == "Tokelau")]
sid_list <- dat[small_island_excluded == TRUE, .(location_name, ISO3)]
stopifnot(nrow(sid_list) == 45L)
sid_list[, exclusion_rule := fifelse(
  location_name == "Tokelau",
  "Tokelau: no country feature in the bundled rworldmap/Natural Earth geometry",
  "rworldmap/Natural Earth SID attribute equals 'SID'"
)]
fwrite(sid_list, file.path(out_dir, "small_island_exclusion_list.csv"))

run_gwr <- function(d, outcome, exposure, analysis_id) {
  vars_needed <- c("location_name", "lng", "lat", outcome, exposure, "SDI_z", "PM25_z")
  z <- copy(d[, ..vars_needed])
  setorder(z, location_name)
  coords <- as.matrix(z[, .(lng, lat)])
  spdf <- SpatialPointsDataFrame(
    coords = coords,
    data = as.data.frame(z[, setdiff(names(z), c("lng", "lat")), with = FALSE]),
    proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs")
  )
  form <- as.formula(paste(outcome, "~", paste(c(exposure, "SDI_z", "PM25_z"), collapse = " + ")))

  trace <- capture.output({
    bw <- spgwr::gwr.sel(
      form, data = spdf, gweight = spgwr::gwr.Gauss,
      method = "cv", longlat = TRUE, verbose = FALSE
    )
  })
  fit <- spgwr::gwr(
    form, data = spdf, bandwidth = bw,
    gweight = spgwr::gwr.Gauss, hatmatrix = TRUE,
    se.fit = TRUE, longlat = TRUE
  )
  local <- as.data.table(as.data.frame(fit$SDF))
  local[, `:=`(
    location_name = z$location_name,
    analysis = analysis_id,
    n = nrow(z),
    bandwidth_km = as.numeric(bw)
  )]
  if (!exposure %in% names(local)) stop("Exposure coefficient missing from GWR SDF: ", exposure)

  se_candidates <- c(paste0(exposure, "_se"), paste0(exposure, ".se"))
  se_col <- se_candidates[se_candidates %in% names(local)][1]
  if (length(se_col) == 0L || is.na(se_col)) {
    local[, exposure_local_se := NA_real_]
  } else {
    local[, exposure_local_se := get(se_col)]
  }
  local[, `:=`(
    exposure_name = exposure,
    exposure_local_beta = get(exposure)
  )]
  local[, exposure_local_t := exposure_local_beta / exposure_local_se]

  ols <- lm(form, data = as.data.frame(z))
  vif_values <- car::vif(ols)
  result_names <- names(fit$results)
  get_result <- function(nm) if (nm %in% result_names) unname(fit$results[[nm]]) else NA_real_

  summary <- data.table(
    analysis = analysis_id,
    n = nrow(z),
    outcome = outcome,
    exposure = exposure,
    kernel = "Gaussian fixed bandwidth",
    bandwidth_selection = "leave-one-out cross-validation",
    bandwidth_km = as.numeric(bw),
    local_beta_min = min(local$exposure_local_beta),
    local_beta_q1 = quantile(local$exposure_local_beta, 0.25, names = FALSE),
    local_beta_median = median(local$exposure_local_beta),
    local_beta_q3 = quantile(local$exposure_local_beta, 0.75, names = FALSE),
    local_beta_max = max(local$exposure_local_beta),
    local_beta_negative_n = sum(local$exposure_local_beta < 0),
    local_beta_positive_n = sum(local$exposure_local_beta > 0),
    local_abs_t_gt_1_96_n = sum(abs(local$exposure_local_t) > 1.96, na.rm = TRUE),
    local_se_available_n = sum(is.finite(local$exposure_local_se)),
    global_OLS_beta = unname(coef(ols)[exposure]),
    global_OLS_p = unname(summary(ols)$coefficients[exposure, "Pr(>|t|)"]),
    global_OLS_adjusted_R2 = summary(ols)$adj.r.squared,
    global_OLS_max_VIF = max(vif_values),
    gwr_AIC = get_result("AIC"),
    gwr_AICc = get_result("AICc"),
    gwr_effective_df = get_result("edf")
  )
  list(local = local, summary = summary, fit = fit, bandwidth_trace = trace)
}

full_dd_to_ihd <- run_gwr(dat, "IHD_z", "DD_z", "Full 204: DD association with IHD")
full_ihd_to_dd <- run_gwr(dat, "DD_z", "IHD_z", "Full 204: IHD association with DD")
retained_dat <- dat[small_island_excluded == FALSE]
excluded_label <- paste0("Cartographic/SIDS-excluded ", nrow(retained_dat))
sid_dd_to_ihd <- run_gwr(retained_dat, "IHD_z", "DD_z", paste0(excluded_label, ": DD association with IHD"))
sid_ihd_to_dd <- run_gwr(retained_dat, "DD_z", "IHD_z", paste0(excluded_label, ": IHD association with DD"))

all_local <- rbindlist(list(
  full_dd_to_ihd$local, full_ihd_to_dd$local,
  sid_dd_to_ihd$local, sid_ihd_to_dd$local
), fill = TRUE)
all_summary <- rbindlist(list(
  full_dd_to_ihd$summary, full_ihd_to_dd$summary,
  sid_dd_to_ihd$summary, sid_ihd_to_dd$summary
), fill = TRUE)

compare_pair <- function(full_obj, sid_obj, direction) {
  a <- full_obj$local[, .(location_name, beta_full = exposure_local_beta)]
  b <- sid_obj$local[, .(location_name, beta_SID_excluded = exposure_local_beta)]
  m <- merge(a, b, by = "location_name")
  data.table(
    direction = direction,
    retained_n = nrow(m),
    full_bandwidth_km = full_obj$summary$bandwidth_km,
    SID_excluded_bandwidth_km = sid_obj$summary$bandwidth_km,
    bandwidth_percent_change = 100 * (sid_obj$summary$bandwidth_km / full_obj$summary$bandwidth_km - 1),
    local_beta_Pearson_r = cor(m$beta_full, m$beta_SID_excluded),
    median_absolute_beta_change = median(abs(m$beta_SID_excluded - m$beta_full)),
    max_absolute_beta_change = max(abs(m$beta_SID_excluded - m$beta_full)),
    sign_agreement_n = sum(sign(m$beta_full) == sign(m$beta_SID_excluded)),
    sign_agreement_percent = 100 * mean(sign(m$beta_full) == sign(m$beta_SID_excluded))
  )
}

sensitivity_comparison <- rbindlist(list(
  compare_pair(full_dd_to_ihd, sid_dd_to_ihd, "DD association with IHD"),
  compare_pair(full_ihd_to_dd, sid_ihd_to_dd, "IHD association with DD")
))

# Independent coefficient reconstruction using great-circle distances and
# weighted least squares at every observed coordinate.
manual_verify <- function(d, outcome, exposure, obj) {
  z <- copy(d[, c("location_name", "lng", "lat", outcome, exposure, "SDI_z", "PM25_z"), with = FALSE])
  setorder(z, location_name)
  coords <- as.matrix(z[, .(lng, lat)])
  distances_km <- sp::spDists(coords, longlat = TRUE)
  X <- cbind(`(Intercept)` = 1, as.matrix(z[, c(exposure, "SDI_z", "PM25_z"), with = FALSE]))
  y <- z[[outcome]]
  manual_beta <- vapply(seq_len(nrow(z)), function(j) {
    w <- spgwr::gwr.Gauss(distances_km[, j]^2, obj$summary$bandwidth_km)
    unname(lm.wfit(X, y, w)$coefficients[exposure])
  }, numeric(1))
  reported <- obj$local$exposure_local_beta
  data.table(
    analysis = obj$summary$analysis,
    n = nrow(z),
    max_absolute_difference = max(abs(manual_beta - reported)),
    mean_absolute_difference = mean(abs(manual_beta - reported)),
    tolerance = 1e-8,
    pass = max(abs(manual_beta - reported)) < 1e-8
  )
}

independent_check <- rbindlist(list(
  manual_verify(dat, "IHD_z", "DD_z", full_dd_to_ihd),
  manual_verify(dat, "DD_z", "IHD_z", full_ihd_to_dd),
  manual_verify(retained_dat, "IHD_z", "DD_z", sid_dd_to_ihd),
  manual_verify(retained_dat, "DD_z", "IHD_z", sid_ihd_to_dd)
))
print(independent_check)
stopifnot(all(independent_check$pass))

fwrite(dat, file.path(out_dir, "GWR_2021_analysis_input.csv"))
fwrite(all_local, file.path(out_dir, "GWR_local_coefficients_full_and_SID_excluded.csv"))
fwrite(all_summary, file.path(out_dir, "GWR_model_summary.csv"))
fwrite(sensitivity_comparison, file.path(out_dir, "GWR_small_island_sensitivity_comparison.csv"))
fwrite(independent_check, file.path(out_dir, "GWR_independent_coefficient_check.csv"))

trace_lines <- c(
  "# spgwr::gwr.sel bandwidth traces",
  "", "## Full 204: DD association with IHD", full_dd_to_ihd$bandwidth_trace,
  "", "## Full 204: IHD association with DD", full_ihd_to_dd$bandwidth_trace,
  "", paste0("## ", excluded_label, ": DD association with IHD"), sid_dd_to_ihd$bandwidth_trace,
  "", paste0("## ", excluded_label, ": IHD association with DD"), sid_ihd_to_dd$bandwidth_trace
)
writeLines(trace_lines, file.path(out_dir, "bandwidth_selection_trace.txt"), useBytes = TRUE)

method_notes <- c(
  "# GWR verification and small-island sensitivity",
  "",
  "The 2021 cross-section contained all 204 study locations with complete IHD, DD, SDI, PM2.5, latitude, and longitude data. Each 2021 variable was z-standardised across the included locations. Two Gaussian fixed-bandwidth GWRs were fitted with great-circle distances (spgwr, longlat=TRUE): IHD ~ DD + SDI + PM2.5 and DD ~ IHD + SDI + PM2.5. Bandwidths were selected separately by leave-one-out cross-validation. Coordinates are country/territory representative points supplied in the original analysis, so coefficients describe local ecological associations, not individual effects.",
  "",
  paste0("The sensitivity analysis removed ", nrow(sid_list), " locations, leaving ", nrow(retained_dat), ": locations classified by the bundled rworldmap/Natural Earth SID attribute plus Tokelau, which has no country feature in that geometry. SID is a Small Island Developing States metadata classification, not a polygon-area or land-size threshold, and includes several coastal states. The exclusion list was determined before examining GWR coefficients. All variables were re-standardised only once in the full 204-country input, matching the submitted analysis; the sensitivity therefore isolates geographic-unit removal rather than changing the measurement scale."),
  "",
  "Local t ratios are exported only as descriptive diagnostics. They are not interpreted as multiplicity-corrected country-level significance tests."
)
writeLines(method_notes, file.path(out_dir, "method_and_reporting_notes.md"), useBytes = TRUE)

wb <- createWorkbook()
addWorksheet(wb, "Model_summary"); writeDataTable(wb, "Model_summary", all_summary)
addWorksheet(wb, "SID_sensitivity"); writeDataTable(wb, "SID_sensitivity", sensitivity_comparison)
addWorksheet(wb, "Independent_check"); writeDataTable(wb, "Independent_check", independent_check)
addWorksheet(wb, "Local_coefficients"); writeDataTable(wb, "Local_coefficients", all_local)
addWorksheet(wb, "SID_exclusion_list"); writeDataTable(wb, "SID_exclusion_list", sid_list)
saveWorkbook(wb, file.path(out_dir, "GWR_verified_results.xlsx"), overwrite = TRUE)

saveRDS(list(
  full_dd_to_ihd = full_dd_to_ihd$fit,
  full_ihd_to_dd = full_ihd_to_dd$fit,
  sid_dd_to_ihd = sid_dd_to_ihd$fit,
  sid_ihd_to_dd = sid_ihd_to_dd$fit
), file.path(out_dir, "GWR_fitted_models.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

output_files <- list.files(out_dir, full.names = TRUE, recursive = FALSE)
output_files <- output_files[!grepl("output_checksums_sha256\\.csv$", output_files)]
output_manifest <- data.table(
  path = gsub("\\\\", "/", output_files),
  bytes = file.info(output_files)$size,
  sha256 = vapply(output_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(output_manifest, file.path(out_dir, "output_checksums_sha256.csv"))

cat("\nGWR model summaries:\n")
print(all_summary)
cat("\nSmall-island sensitivity comparison:\n")
print(sensitivity_comparison)
cat("\nIndependent coefficient reconstruction:\n")
print(independent_check)
