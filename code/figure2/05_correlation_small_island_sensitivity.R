#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(openxlsx)
  library(digest)
})

options(stringsAsFactors = FALSE, scipen = 999)
out_dir <- "correlation_small_island_sensitivity"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

input_files <- c(
  S1 = "figure2_s1/Supplementary_Table_S1_corrected.csv",
  weighted = "figure2_s1/Figure2_EF_weighted_correlations_corrected.csv",
  SID_list = "gwr_sensitivity/small_island_exclusion_list.csv"
)
stopifnot(all(file.exists(input_files)))
input_manifest <- data.table(
  input = names(input_files),
  path = normalizePath(input_files, winslash = "/", mustWork = TRUE),
  bytes = file.info(input_files)$size,
  sha256 = vapply(input_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(input_manifest, file.path(out_dir, "input_checksums_sha256.csv"))

s1 <- fread(input_files[["S1"]])
w <- fread(input_files[["weighted"]])
sid <- fread(input_files[["SID_list"]])
stopifnot(nrow(sid) == 45L, uniqueN(s1$location_name) == 204L, uniqueN(w$location_name) == 204L)

s1[, small_island_excluded := location_name %in% sid$location_name]
w[, small_island_excluded := location_name %in% sid$location_name]
stopifnot(sum(unique(s1[, .(location_name, small_island_excluded)])$small_island_excluded) == 45L)

s1_retained <- s1[small_island_excluded == FALSE]
s1_retained[, fdr_pvalue_SID_excluded := p.adjust(p_value, method = "BH"), by = sex_name]
s1_retained[, significant_full_BH := fdr_pvalue < 0.05]
s1_retained[, significant_SID_excluded_BH := fdr_pvalue_SID_excluded < 0.05]
s1_retained[, bh_family_SID_excluded := paste0(
  "2021 country-level Pearson correlations across 20 age groups within ",
  sex_name, " after cartographic/SIDS exclusion (m=", .N, ")"
), by = sex_name]

s1_summary <- s1_retained[, .(
  retained_n = .N,
  correlation_min = min(correlation),
  correlation_q1 = quantile(correlation, 0.25),
  correlation_median = median(correlation),
  correlation_q3 = quantile(correlation, 0.75),
  correlation_max = max(correlation),
  BH_q_lt_0_05_n = sum(significant_SID_excluded_BH),
  BH_q_lt_0_05_percent = 100 * mean(significant_SID_excluded_BH),
  significance_changes_vs_full_family = sum(significant_full_BH != significant_SID_excluded_BH)
), by = sex_name]

w_retained <- w[small_island_excluded == FALSE]
w_estimable <- w_retained[fit_status == "ok" & is.finite(weighted_r)]
weighted_summary <- w_estimable[, .(
  retained_countries = uniqueN(location_name),
  estimable_country_age_correlations = .N,
  correlation_min = min(weighted_r),
  correlation_q1 = quantile(weighted_r, 0.25),
  correlation_median = median(weighted_r),
  correlation_q3 = quantile(weighted_r, 0.75),
  correlation_max = max(weighted_r)
), by = sex_name]

age_summary_full <- w[fit_status == "ok" & is.finite(weighted_r), .(
  full_country_n = .N,
  full_median = median(weighted_r),
  full_q1 = quantile(weighted_r, 0.25),
  full_q3 = quantile(weighted_r, 0.75)
), by = .(sex_name, age_name)]
age_summary_sid <- w_estimable[, .(
  retained_country_n = .N,
  SID_excluded_median = median(weighted_r),
  SID_excluded_q1 = quantile(weighted_r, 0.25),
  SID_excluded_q3 = quantile(weighted_r, 0.75)
), by = .(sex_name, age_name)]
age_comparison <- merge(age_summary_full, age_summary_sid, by = c("sex_name", "age_name"))
age_comparison[, median_change := SID_excluded_median - full_median]

age_robustness <- age_comparison[, .(
  estimable_age_groups = .N,
  Pearson_r_of_age_specific_medians = cor(full_median, SID_excluded_median),
  median_absolute_change_in_age_median = median(abs(median_change)),
  max_absolute_change_in_age_median = max(abs(median_change)),
  sign_agreement_age_medians_n = sum(sign(full_median) == sign(SID_excluded_median)),
  sign_agreement_age_medians_percent = 100 * mean(sign(full_median) == sign(SID_excluded_median))
), by = sex_name]

fwrite(s1_retained, file.path(out_dir, "S1_SID_excluded_results.csv"))
fwrite(s1_summary, file.path(out_dir, "S1_SID_excluded_summary.csv"))
fwrite(w_retained, file.path(out_dir, "Figure2_EF_SID_excluded_weighted_correlations.csv"))
fwrite(weighted_summary, file.path(out_dir, "Figure2_EF_SID_excluded_summary.csv"))
fwrite(age_comparison, file.path(out_dir, "Figure2_EF_age_median_full_vs_SID_excluded.csv"))
fwrite(age_robustness, file.path(out_dir, "Figure2_EF_SID_excluded_robustness.csv"))

wb <- createWorkbook()
addWorksheet(wb, "S1_retained"); writeDataTable(wb, "S1_retained", s1_retained)
addWorksheet(wb, "S1_summary"); writeDataTable(wb, "S1_summary", s1_summary)
addWorksheet(wb, "Weighted_summary"); writeDataTable(wb, "Weighted_summary", weighted_summary)
addWorksheet(wb, "Age_comparison"); writeDataTable(wb, "Age_comparison", age_comparison)
addWorksheet(wb, "Age_robustness"); writeDataTable(wb, "Age_robustness", age_robustness)
saveWorkbook(wb, file.path(out_dir, "correlation_SID_excluded_sensitivity.xlsx"), overwrite = TRUE)

notes <- c(
  "# Correlation small-island sensitivity",
  "",
  paste0("The same ", nrow(sid), " study units defined a priori for the cartographic/SIDS sensitivity were removed, leaving ", uniqueN(s1_retained$location_name), " countries/territories: units with the rworldmap/Natural Earth SID attribute plus Tokelau, which has no country feature in that bundled geometry. SID is a Small Island Developing States metadata classification, not a polygon-area or land-size threshold, and includes several coastal states. For Supplementary Table S1, the original unrounded 2021 P values were re-adjusted by BH separately within each sex (m=", uniqueN(s1_retained$location_name), "). For Figure 2E-F, descriptive population-weighted country-age temporal correlations were not significance-filtered; their distributions and age-specific medians were compared with the full 204-country analysis."),
  "",
  "The three younger groups (<5, 5-9, and 10-14 years) remain non-estimable because their IHD annual series are constant in every country and sex. Seventeen age groups are therefore included in the Figure 2E-F sensitivity summaries."
)
writeLines(notes, file.path(out_dir, "method_and_reporting_notes.md"), useBytes = TRUE)
capture.output(sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

output_files <- list.files(out_dir, full.names = TRUE, recursive = FALSE)
output_files <- output_files[!grepl("output_checksums_sha256\\.csv$", output_files)]
output_manifest <- data.table(
  path = gsub("\\\\", "/", output_files),
  bytes = file.info(output_files)$size,
  sha256 = vapply(output_files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(output_manifest, file.path(out_dir, "output_checksums_sha256.csv"))

cat("\nS1 after SID exclusion:\n"); print(s1_summary)
cat("\nWeighted temporal correlations after SID exclusion:\n"); print(weighted_summary)
cat("\nAge-profile robustness:\n"); print(age_robustness)
