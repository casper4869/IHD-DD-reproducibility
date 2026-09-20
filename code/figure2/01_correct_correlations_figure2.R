#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 1)
set.seed(20260918)

required <- c(
  "data.table", "weights", "ggplot2", "ggridges",
  "patchwork", "openxlsx", "digest", "svglite"
)
missing_packages <- setdiff(required, rownames(installed.packages()))
if (length(missing_packages) > 0L) {
  stop("Missing required R packages: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(data.table)
  library(weights)
  library(ggplot2)
  library(ggridges)
  library(patchwork)
})

analysis_workdir <- getwd()
if (basename(analysis_workdir) != "02_analysis") {
  stop("Run this script with the revision 02_analysis directory as the working directory")
}
analysis_dir <- "figure2_s1"
derived_dir <- file.path(analysis_dir, "derived_inputs")
figure_dir <- file.path("..", "03_figures", "figure2_corrected")
iteration_dir <- file.path("research-loop", "iterations", "iter-001")
dir.create(analysis_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

log_file <- file.path(analysis_dir, "01_correct_correlations_figure2.log")
log_con <- file(log_file, open = "wt", encoding = "UTF-8")
sink(log_con, type = "output", split = TRUE)
sink(log_con, type = "message")
on.exit({
  try(sink(type = "message"), silent = TRUE)
  try(sink(type = "output"), silent = TRUE)
  try(close(log_con), silent = TRUE)
}, add = TRUE)

cat("Run started:", format(Sys.time(), tz = "Asia/Shanghai"), "\n")

age_order <- c(
  "<5 years", "5-9 years", "10-14 years", "15-19 years", "20-24 years",
  "25-29 years", "30-34 years", "35-39 years", "40-44 years", "45-49 years",
  "50-54 years", "55-59 years", "60-64 years", "65-69 years", "70-74 years",
  "75-79 years", "80-84 years", "85-89 years", "90-94 years", "95+ years"
)

female_long_file <- "<LOCAL_PROJECT_ROOT>/Part2/IHD_DD_female_LONG_1992_2021.csv"
male_long_file <- "<LOCAL_PROJECT_ROOT>/Part2/IHD_DD_male_LONG_1992_2021.csv"
old_s1_file <- "<LOCAL_PROJECT_ROOT>/Part2/correlation_results_by_age_with_adjusted_pvalues.csv"
raw_ihd_location_file <- "<LOCAL_PROJECT_ROOT>/Part0/IHD_country.csv"
original_scripts <- c(
  "<LOCAL_PROJECT_ROOT>/Part2/GBD_map_4.R",
  "<LOCAL_PROJECT_ROOT>/Part2/GBD_map_4_female.R",
  "<LOCAL_PROJECT_ROOT>/Part2/GBD_map_4_male.R"
)
population_dir <- "immutable_population_source"
if (!dir.exists(population_dir)) {
  stop("Missing read-only population-source junction: ", population_dir)
}
population_files <- sort(list.files(population_dir, pattern = "\\.csv$", full.names = TRUE))
if (length(population_files) != 21L) {
  stop("Expected 21 immutable GBD population CSVs; found ", length(population_files))
}

input_files <- c(
  female_long_file, male_long_file, old_s1_file, raw_ihd_location_file,
  original_scripts, population_files
)
if (any(!file.exists(input_files))) {
  stop("Missing immutable input(s): ", paste(input_files[!file.exists(input_files)], collapse = "; "))
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

cat("Fingerprinting", length(input_files), "input files...\n")
input_checksums <- data.table(
  file = normalizePath(input_files, winslash = "/", mustWork = TRUE),
  bytes = suppressWarnings(file.info(input_files)$size),
  sha256 = vapply(input_files, sha256_file, character(1))
)
fwrite(input_checksums, file.path(analysis_dir, "input_checksums_sha256.csv"))

read_disease_long <- function(path, sex_label) {
  dt <- fread(path, showProgress = FALSE)
  required_cols <- c("location_name", "age_name", "year", "ihd_val", "dd_val")
  if (!all(required_cols %in% names(dt))) {
    stop("Unexpected columns in ", path)
  }
  dt <- dt[
    year %between% c(1992L, 2021L) & age_name %chin% age_order,
    .(location_name, sex_name = sex_label, age_name, year, ihd_val, dd_val)
  ]
  setorder(dt, location_name, age_name, year)
  dt
}

female_long <- read_disease_long(female_long_file, "Female")
male_long <- read_disease_long(male_long_file, "Male")
disease_long <- rbindlist(list(female_long, male_long), use.names = TRUE)

# Recover the immutable GBD location_id from the original country-level IHD
# extract. Joining population by location_id prevents same-name subnational
# units (for example, the US state and country both named Georgia) from being
# mixed with country estimates.
cat("Recovering target GBD location identifiers from the original IHD extract...\n")
raw_location_crosswalk <- unique(fread(
  raw_ihd_location_file,
  select = c("location_id", "location_name"),
  showProgress = FALSE
))
target_names <- unique(disease_long$location_name)
country_crosswalk <- raw_location_crosswalk[location_name %chin% target_names]
if (nrow(country_crosswalk) != 204L ||
    country_crosswalk[, uniqueN(location_id)] != 204L ||
    country_crosswalk[, uniqueN(location_name)] != 204L) {
  fwrite(country_crosswalk, file.path(analysis_dir, "country_location_crosswalk_failure.csv"))
  stop("Could not recover a unique GBD location_id for all 204 analysis units")
}
fwrite(country_crosswalk, file.path(derived_dir, "GBD_country_location_crosswalk.csv"))
disease_long <- merge(
  disease_long, country_crosswalk,
  by = "location_name", all.x = TRUE, sort = FALSE
)
target_location_ids <- country_crosswalk$location_id

expected_rows_per_sex <- 204L * length(age_order) * 30L
row_check <- disease_long[, .(
  rows = .N,
  locations = uniqueN(location_name),
  years = uniqueN(year),
  ages = uniqueN(age_name)
), by = sex_name]
print(row_check)
if (any(row_check$rows != expected_rows_per_sex) ||
    any(row_check$locations != 204L) ||
    any(row_check$years != 30L) ||
    any(row_check$ages != length(age_order))) {
  stop("Disease long-file integrity check failed")
}

group_check <- disease_long[, .(
  n = .N,
  n_year = uniqueN(year),
  missing_n = sum(!is.finite(ihd_val) | !is.finite(dd_val))
), by = .(location_name, sex_name, age_name)]
if (any(group_check$n != 30L) || any(group_check$n_year != 30L) || any(group_check$missing_n > 0L)) {
  fwrite(group_check[n != 30L | n_year != 30L | missing_n > 0L],
         file.path(analysis_dir, "disease_group_integrity_failures.csv"))
  stop("One or more disease country-sex-age groups are incomplete")
}

# Table S1: 2021 correlation across the 20 age groups within each country and sex.
# P values remain full precision until BH adjustment. The two BH families are
# all 204 country-level tests within Female and within Male, respectively.
s1 <- disease_long[year == 2021L, {
  test <- cor.test(ihd_val, dd_val, method = "pearson")
  .(
    n_age_groups = .N,
    correlation = unname(test$estimate),
    p_value = unname(test$p.value)
  )
}, by = .(location_name, sex_name)]
s1[, fdr_pvalue := p.adjust(p_value, method = "BH"), by = sex_name]
s1[, bh_family := sprintf(
  "2021 country-level Pearson correlations across 20 age groups within %s (m=%d)",
  sex_name, .N
), by = sex_name]
setorder(s1, location_name, sex_name)

if (any(s1$n_age_groups != length(age_order)) || nrow(s1) != 408L) {
  stop("Table S1 family integrity check failed")
}

s1_csv <- file.path(analysis_dir, "Supplementary_Table_S1_corrected.csv")
fwrite(s1, s1_csv)

old_s1 <- fread(old_s1_file, showProgress = FALSE)
setnames(old_s1, c("correlation", "p_value", "fdr_pvalue"),
         c("old_correlation", "old_p_value_rounded", "old_fdr_from_rounded_p"))
s1_comparison <- merge(
  s1, old_s1,
  by = c("location_name", "sex_name"),
  all.x = TRUE, sort = FALSE
)
s1_comparison[, `:=`(
  correlation_difference = correlation - old_correlation,
  old_significant = old_fdr_from_rounded_p < 0.05,
  corrected_significant = fdr_pvalue < 0.05,
  significance_changed = (old_fdr_from_rounded_p < 0.05) != (fdr_pvalue < 0.05)
)]
fwrite(s1_comparison, file.path(analysis_dir, "S1_original_vs_corrected.csv"))

s1_notes <- data.frame(
  Item = c("Estimand", "Female BH family", "Male BH family", "Precision rule", "Reporting rule"),
  Definition = c(
    "Within each country and sex, Pearson correlation between 2021 age-specific IHD and DD incidence rates across 20 five-year age groups (<5 to 95+ years).",
    "204 country/territory tests; BH applied once to the 204 unrounded female P values.",
    "204 country/territory tests; BH applied once to the 204 unrounded male P values.",
    "Correlations and P values are computed from unrounded incidence rates; rounding is applied only for display.",
    "The machine-readable sheet retains full precision. Formatted values are for presentation only."
  )
)

s1_formatted <- copy(s1)
s1_formatted[, `:=`(
  correlation = round(correlation, 2),
  p_value = signif(p_value, 4),
  fdr_pvalue = signif(fdr_pvalue, 4)
)]
wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, "S1_full_precision")
openxlsx::writeData(wb, "S1_full_precision", as.data.frame(s1))
openxlsx::addWorksheet(wb, "S1_formatted")
openxlsx::writeData(wb, "S1_formatted", as.data.frame(s1_formatted))
openxlsx::addWorksheet(wb, "Notes")
openxlsx::writeData(wb, "Notes", s1_notes)
openxlsx::freezePane(wb, "S1_full_precision", firstRow = TRUE)
openxlsx::freezePane(wb, "S1_formatted", firstRow = TRUE)
openxlsx::saveWorkbook(
  wb, file.path(analysis_dir, "Supplementary_Table_S1_corrected.xlsx"), overwrite = TRUE
)

# Build a compact, immutable-derived age/sex/year population input from the 21
# original GBD population exports. No aggregation is allowed: each key must be unique.
population_derived_file <- file.path(
  derived_dir, "GBD_population_age_sex_1992_2021.csv"
)
population_parts <- vector("list", length(population_files))
for (i in seq_along(population_files)) {
  cat(sprintf("Reading population file %d/%d: %s\n",
              i, length(population_files), basename(population_files[[i]])))
  part <- fread(
    population_files[[i]],
    select = c("location_id", "location_name", "sex_name", "age_name", "metric_name", "year", "val"),
    showProgress = FALSE
  )
  part <- part[
    location_id %in% target_location_ids &
      sex_name %chin% c("Female", "Male") &
      age_name %chin% age_order &
      metric_name == "Number" &
      year %between% c(1992L, 2021L),
    .(location_id, population_location_name = location_name, sex_name, age_name, year,
      population = val, source_file = basename(population_files[[i]]))
  ]
  population_parts[[i]] <- part
  rm(part)
  invisible(gc(FALSE))
}
population <- rbindlist(population_parts, use.names = TRUE)
rm(population_parts)

duplicate_population_keys <- population[, .(
  N = .N,
  unique_population_values = uniqueN(population),
  minimum_population = min(population),
  maximum_population = max(population),
  source_files = paste(sort(unique(source_file)), collapse = ";")
), by = .(location_id, population_location_name, sex_name, age_name, year)][N > 1L]
fwrite(duplicate_population_keys,
       file.path(analysis_dir, "population_duplicate_keys.csv"))
if (nrow(duplicate_population_keys) > 0L) {
  if (any(duplicate_population_keys$unique_population_values != 1L)) {
    stop("Population input contains conflicting duplicate country-sex-age-year keys")
  }
  cat("Removing", nrow(duplicate_population_keys),
      "exact duplicate population keys found at source-file boundaries.\n")
  setorder(population, location_id, sex_name, age_name, year, source_file)
  population <- unique(
    population,
    by = c("location_id", "sex_name", "age_name", "year")
  )
}
if (any(!is.finite(population$population) | population$population <= 0)) {
  stop("Population input contains missing, nonfinite, or nonpositive weights")
}

fwrite(population, population_derived_file)

population_for_merge <- population[, .(
  location_id, sex_name, age_name, year, population_location_name, population
)]
if (population_for_merge[, anyDuplicated(paste(location_id, sex_name, age_name, year))] != 0L) {
  stop("Duplicate population keys remain after location_id filtering")
}

weighted_input <- merge(
  disease_long,
  population_for_merge,
  by = c("location_id", "sex_name", "age_name", "year"),
  all.x = TRUE,
  sort = FALSE
)
coverage <- weighted_input[, .(
  rows = .N,
  population_missing = sum(is.na(population)),
  population_location_names = uniqueN(population_location_name)
), by = .(location_name, location_id, sex_name, age_name)]
fwrite(coverage, file.path(analysis_dir, "population_merge_coverage.csv"))
if (any(coverage$rows != 30L) || any(coverage$population_missing > 0L)) {
  fwrite(
    coverage[rows != 30L | population_missing > 0L],
    file.path(analysis_dir, "population_merge_failures.csv")
  )
  stop("Population coverage is incomplete for one or more disease groups")
}

weighted_cor <- weighted_input[, {
  if (uniqueN(ihd_val) < 2L || uniqueN(dd_val) < 2L) {
    .(
      n_years = .N, weighted_r = NA_real_, weighted_se = NA_real_,
      weighted_t = NA_real_, weighted_p = NA_real_,
      fit_status = "not_estimable_constant_series"
    )
  } else {
    result <- tryCatch(
      suppressWarnings(weights::wtd.cor(
        ihd_val, dd_val, weight = population,
        mean1 = TRUE, bootse = FALSE
      )),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      .(
        n_years = .N, weighted_r = NA_real_, weighted_se = NA_real_,
        weighted_t = NA_real_, weighted_p = NA_real_,
        fit_status = paste0("failed: ", conditionMessage(result))
      )
    } else {
      required_result_cols <- c("correlation", "std.err", "t.value", "p.value")
      if (!all(required_result_cols %in% colnames(result))) {
        stop("weights::wtd.cor returned unexpected columns")
      }
      .(
        n_years = .N,
        weighted_r = unname(result[1L, "correlation"]),
        weighted_se = unname(result[1L, "std.err"]),
        weighted_t = unname(result[1L, "t.value"]),
        weighted_p = unname(result[1L, "p.value"]),
        fit_status = "ok"
      )
    }
  }
}, by = .(location_name, location_id, sex_name, age_name)]

if (any(weighted_cor$fit_status != "ok")) {
  fwrite(weighted_cor[fit_status != "ok"],
         file.path(analysis_dir, "weighted_correlation_failures.csv"))
}
if (any(weighted_cor$weighted_r < -1 - 1e-12 |
        weighted_cor$weighted_r > 1 + 1e-12, na.rm = TRUE)) {
  stop("Corrected weighted correlation is outside [-1, 1]")
}

weighted_cor[, weighted_fdr := p.adjust(weighted_p, method = "BH"), by = sex_name]
weighted_cor[, bh_family := sprintf(
  "Descriptive weighted country-age temporal correlations within %s (m=%d); not used to filter Figure 2E-F",
  sex_name, sum(is.finite(weighted_p))
), by = sex_name]
setorder(weighted_cor, sex_name, age_name, location_name)
weighted_csv <- file.path(analysis_dir, "Figure2_EF_weighted_correlations_corrected.csv")
fwrite(weighted_cor, weighted_csv)

plot_data <- weighted_cor[fit_status == "ok" & is.finite(weighted_r)]
plot_data[, age_name := factor(age_name, levels = age_order)]
plot_group_counts <- plot_data[, .(locations = uniqueN(location_name)), by = .(sex_name, age_name)]
if (any(plot_group_counts$locations != 204L) || nrow(plot_group_counts) != 34L) {
  fwrite(plot_group_counts, file.path(analysis_dir, "figure2_plot_group_count_failure.csv"))
  stop("Corrected Figure 2E-F does not contain 204 locations for each estimable sex-age group")
}

make_ridge_plot <- function(sex_label) {
  ggplot(plot_data[sex_name == sex_label], aes(x = weighted_r, y = age_name)) +
    geom_density_ridges_gradient(
      aes(fill = after_stat(x)),
      scale = 2.45, rel_min_height = 0.01,
      color = "grey65", linewidth = 0.25, alpha = 0.90
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey35", linewidth = 0.45) +
    scale_x_continuous(limits = c(-1, 1), breaks = seq(-1, 1, by = 0.5)) +
    scale_fill_gradient2(
      low = "#377EB8", mid = "#F7F7F7", high = "#E41A1C",
      midpoint = 0, limits = c(-1, 1),
      name = "Population-weighted\ncorrelation (r)"
    ) +
    labs(
      title = sprintf(
        "Population-weighted temporal correlation between IHD and DD\nby country and age group (%s, 1992-2021)",
        sex_label
      ),
      x = "Population-weighted Pearson correlation (r)",
      y = "Age group"
    ) +
    theme_minimal(base_size = 11, base_family = "sans") +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.3),
      axis.title = element_text(face = "bold"),
      axis.text = element_text(color = "grey20"),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 12),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 9)
    )
}

plot_e <- make_ridge_plot("Female")
plot_f <- make_ridge_plot("Male")
combined <- plot_e + plot_f + plot_annotation(tag_levels = list(c("E", "F"))) &
  theme(plot.tag = element_text(face = "bold", size = 18))

save_plot_set <- function(plot_object, stem, width, height) {
  ggsave(file.path(figure_dir, paste0(stem, ".svg")), plot_object,
         width = width, height = height, units = "in", device = svglite::svglite)
  ggsave(file.path(figure_dir, paste0(stem, ".pdf")), plot_object,
         width = width, height = height, units = "in", device = cairo_pdf)
  grDevices::png(file.path(figure_dir, paste0(stem, ".png")),
                 width = width, height = height, units = "in", res = 600,
                 bg = "white", type = "cairo")
  print(plot_object)
  grDevices::dev.off()
  grDevices::tiff(file.path(figure_dir, paste0(stem, ".tif")),
                  width = width, height = height, units = "in", res = 600,
                  bg = "white", compression = "lzw", type = "cairo")
  print(plot_object)
  grDevices::dev.off()
}

save_plot_set(plot_e, "Figure2E_corrected", 7.2, 6.5)
save_plot_set(plot_f, "Figure2F_corrected", 7.2, 6.5)
save_plot_set(combined, "Figure2_EF_corrected", 14.4, 6.5)

summary_metrics <- rbindlist(list(
  s1[, .(
    analysis = "Table S1 corrected",
    stratum = sex_name,
    n_estimates = .N,
    min_estimate = min(correlation),
    median_estimate = median(correlation),
    max_estimate = max(correlation),
    q_lt_0_05 = sum(fdr_pvalue < 0.05),
    changed_vs_submitted = NA_integer_
  ), by = sex_name],
  s1_comparison[, .(
    analysis = "Table S1 significance comparison",
    stratum = sex_name,
    n_estimates = .N,
    min_estimate = NA_real_,
    median_estimate = NA_real_,
    max_estimate = NA_real_,
    q_lt_0_05 = sum(corrected_significant),
    changed_vs_submitted = sum(significance_changed, na.rm = TRUE)
  ), by = sex_name],
  weighted_cor[, .(
    analysis = "Figure 2E-F corrected",
    stratum = sex_name,
    n_estimates = sum(fit_status == "ok"),
    min_estimate = min(weighted_r, na.rm = TRUE),
    median_estimate = median(weighted_r, na.rm = TRUE),
    max_estimate = max(weighted_r, na.rm = TRUE),
    q_lt_0_05 = sum(weighted_fdr < 0.05, na.rm = TRUE),
    changed_vs_submitted = NA_integer_
  ), by = sex_name]
), use.names = TRUE, fill = TRUE)
fwrite(summary_metrics, file.path(analysis_dir, "correlation_correction_summary.csv"))
print(summary_metrics)

calculation_notes <- c(
  "# Corrected Figure 2E-F and Supplementary Table S1 calculation notes",
  "",
  "## Table S1",
  "For each country/territory and sex, Pearson's r is calculated across the 20 age-specific 2021 incidence-rate pairs. P values remain unrounded until Benjamini-Hochberg adjustment. The female and male strata are separate BH families of 204 tests each.",
  "",
  "## Figure 2E-F",
  "For each country/territory, sex, and age group, a weighted Pearson correlation is calculated across the 30 annual IHD and DD incidence-rate pairs (1992-2021). The weight for year t is the matching GBD population count for that country, sex, age group, and year. The plotted density for each age group is the unweighted distribution of these 204 country-level population-weighted correlations.",
  "",
  "The <5 years, 5-9 years, and 10-14 years groups are non-estimable for both sexes because the IHD annual series is constant in every one of the 204 locations. Panels E-F therefore display the 17 estimable age groups from 15-19 years through 95+ years; all 1,224 non-estimable country-sex-age records are retained with an explicit status in the source table.",
  "",
  "The submitted code selected column [1,2] from weights::wtd.cor(), which is the standard error. The corrected code explicitly selects the named `correlation` column. The full weighted-correlation P values and BH values are retained for audit, but Figure 2E-F is descriptive and is not filtered by significance because annual observations are serially dependent.",
  "",
  "## Formula",
  "For annual values x_t (IHD), y_t (DD), and population weight w_t, weighted means are xbar_w = sum(w_t*x_t)/sum(w_t) and ybar_w = sum(w_t*y_t)/sum(w_t). The plotted coefficient is r_w = sum[w_t(x_t-xbar_w)(y_t-ybar_w)] / sqrt(sum[w_t(x_t-xbar_w)^2] * sum[w_t(y_t-ybar_w)^2]).",
  "",
  "All source values used for calculation are unrounded. Machine-readable results retain full precision."
)
writeLines(calculation_notes, file.path(analysis_dir, "calculation_notes.md"), useBytes = TRUE)

capture.output(sessionInfo(), file = file.path(analysis_dir, "sessionInfo.txt"))

output_files <- c(
  s1_csv,
  file.path(analysis_dir, "Supplementary_Table_S1_corrected.xlsx"),
  file.path(analysis_dir, "S1_original_vs_corrected.csv"),
  population_derived_file,
  weighted_csv,
  file.path(analysis_dir, "correlation_correction_summary.csv"),
  file.path(analysis_dir, "calculation_notes.md"),
  file.path(analysis_dir, "population_duplicate_keys.csv"),
  list.files(
    figure_dir,
    pattern = "^Figure2(E|F|_EF)_corrected\\.(png|tif|pdf|svg)$",
    full.names = TRUE
  )
)
output_files <- output_files[file.exists(output_files)]
output_checksums <- data.table(
  file = gsub("\\\\", "/", output_files),
  bytes = file.info(output_files)$size,
  sha256 = vapply(output_files, sha256_file, character(1))
)
fwrite(output_checksums, file.path(analysis_dir, "output_checksums_sha256.csv"))

cat("Run completed:", format(Sys.time(), tz = "Asia/Shanghai"), "\n")
