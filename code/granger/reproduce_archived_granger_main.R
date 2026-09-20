# Reproduce the archived country-level three-variable VAR screening.
# This script performs local file reads only; it does not access any website.
# Usage: Rscript reproduce_archived_granger_main.R INPUT_DIR OUTPUT_DIR
# Optional third argument: archived results CSV to compare against.
# Optional fourth argument: archived CSV encoding (default UTF-8; some original
# Windows exports require GB18030). This changes decoding, not any numbers.
# Required packages are installed separately: dplyr, tidyr, vars, vroom.
#
# IMPORTANT INTERPRETATION:
# In the three-variable model, causality(model, cause = "IHD_val") tests
# lagged IHD coefficients JOINTLY in BOTH the DD AND SDI equations.
# Conversely, cause = "DD_val" tests DD lags in BOTH IHD AND SDI equations.
# These are system-level block-exogeneity tests. The archived column and
# category names are retained only for exact provenance/reproduction. They
# must not be interpreted as equation-specific IHD-to-DD or DD-to-IHD tests,
# or as evidence of individual-level/biological causation.
# No detrending, differencing, stationarity restriction, or alternative test
# is added here, because those changes would define a different analysis.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Provide INPUT_DIR OUTPUT_DIR [ARCHIVED_RESULTS_CSV].")
input_dir <- normalizePath(args[1], mustWork = TRUE)
output_dir <- args[2]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
for (pkg in c("dplyr", "tidyr", "vars", "vroom")) {
  if (!requireNamespace(pkg, quietly = TRUE)) stop("Missing package: ", pkg)
}
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(vars)})
read_matrix <- function(filename, value_name) {
  x <- vroom::vroom(file.path(input_dir, filename), show_col_types = FALSE,
                    progress = FALSE)
  required <- c("location_name", paste0("val_", 1992:2021))
  if (!all(required %in% names(x))) stop("Missing required columns in ", filename)
  if (anyDuplicated(x$location_name)) stop("Duplicated countries in ", filename)
  x %>% pivot_longer(cols = starts_with("val_"), names_to = "year",
                     names_prefix = "val_", values_to = value_name) %>%
    mutate(year = as.integer(year))
}
ihd_long <- read_matrix("IHD_1992_2021_matrix.csv", "IHD_val")
dd_long <- read_matrix("DD_1992_2021_matrix.csv", "DD_val")
sdi_long <- read_matrix("SDI_1992_2021_matrix.csv", "SDI_val")
df_all <- ihd_long %>% left_join(dd_long, by = c("location_name", "year")) %>%
  left_join(sdi_long, by = c("location_name", "year"))

granger_var_by_country <- function(df, max_p = 2) {
  df <- df %>% arrange(year)
  if (any(is.na(df$IHD_val)) | any(is.na(df$DD_val)) |
      any(is.na(df$SDI_val)) | nrow(df) < (max_p + 1)) {
    return(tibble(IHD_to_DD_p = NA_real_, DD_to_IHD_p = NA_real_, lag = NA_real_))
  }
  p_sel <- min(VARselect(df[, c("IHD_val", "DD_val", "SDI_val")],
                        lag.max = max_p)$selection["AIC(n)"], max_p)
  tryCatch({
    model <- VAR(df[, c("IHD_val", "DD_val", "SDI_val")], p = p_sel, type = "const")
    ihd2dd <- causality(model, cause = "IHD_val")$Granger$p.value
    dd2ihd <- causality(model, cause = "DD_val")$Granger$p.value
    tibble(IHD_to_DD_p = ihd2dd, DD_to_IHD_p = dd2ihd, lag = p_sel)
  }, error = function(e) tibble(IHD_to_DD_p = NA_real_, DD_to_IHD_p = NA_real_, lag = p_sel))
}

results <- df_all %>% group_by(location_name) %>%
  group_modify(~ granger_var_by_country(.x, max_p = 2)) %>% ungroup() %>%
  mutate(IHD_to_DD_padj = p.adjust(IHD_to_DD_p, method = "BH"),
         DD_to_IHD_padj = p.adjust(DD_to_IHD_p, method = "BH"),
         direction = case_when(
           IHD_to_DD_padj < 0.05 & DD_to_IHD_padj < 0.05 ~ "Bidirectional",
           IHD_to_DD_padj < 0.05 ~ "IHD\u2192DD",
           DD_to_IHD_padj < 0.05 ~ "DD\u2192IHD",
           TRUE ~ NA_character_))
write.csv(results, file.path(output_dir, "IHD_DD_SDI_VAR_Granger_Results_NoSex.csv"), row.names = FALSE)

# Supply accurately named supplementary output, without replacing legacy files.
audited <- results %>% mutate(
  IHD_block_targets = "DD and SDI jointly",
  DD_block_targets = "IHD and SDI jointly",
  system_test_category = case_when(
    IHD_to_DD_padj < 0.05 & DD_to_IHD_padj < 0.05 ~ "Both source blocks significant",
    IHD_to_DD_padj < 0.05 ~ "IHD source block only",
    DD_to_IHD_padj < 0.05 ~ "DD source block only",
    is.na(IHD_to_DD_padj) | is.na(DD_to_IHD_padj) ~ "Test unavailable",
    TRUE ~ "Neither source block significant"))
write.csv(audited, file.path(output_dir, "system_block_test_interpretation.csv"), row.names = FALSE)
counts <- as.data.frame(table(audited$system_test_category), stringsAsFactors = FALSE)
names(counts) <- c("system_test_category", "n")
write.csv(counts, file.path(output_dir, "category_counts.csv"), row.names = FALSE)
print(counts)

if (length(args) >= 3L) {
  archive_encoding <- if (length(args) >= 4L) args[4] else "UTF-8"
  old <- as.data.frame(vroom::vroom(args[3], show_col_types = FALSE, progress = FALSE,
                                   locale = vroom::locale(encoding = archive_encoding)))
  old <- old[match(results$location_name, old$location_name), ]
  if (anyNA(old$location_name) || nrow(old) != nrow(results)) stop("Country mismatch")
  cols <- c("IHD_to_DD_p", "DD_to_IHD_p", "lag", "IHD_to_DD_padj", "DD_to_IHD_padj")
  comparison <- do.call(rbind, lapply(cols, function(nm) {
    data.frame(field = nm, max_absolute_difference = max(abs(results[[nm]] - old[[nm]]), na.rm = TRUE),
               new_missing = sum(is.na(results[[nm]])), old_missing = sum(is.na(old[[nm]])),
               pass = identical(as.vector(is.na(results[[nm]])), as.vector(is.na(old[[nm]]))) &&
                 all(abs(results[[nm]] - old[[nm]]) <= 1e-12, na.rm = TRUE))
  }))
  categories_equal <- identical(ifelse(is.na(results$direction), "None", results$direction),
                                ifelse(is.na(old$direction), "None", old$direction))
  comparison <- rbind(comparison, data.frame(field = "all_country_categories",
                                             max_absolute_difference = NA_real_, new_missing = NA_integer_,
                                             old_missing = NA_integer_, pass = categories_equal))
  write.csv(comparison, file.path(output_dir, "archived_comparison.csv"), row.names = FALSE)
  print(comparison)
}
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
