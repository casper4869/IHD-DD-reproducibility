options(stringsAsFactors = FALSE)
if (.Platform$OS.type == "windows") suppressWarnings(Sys.setlocale("LC_CTYPE", "English_United States.UTF-8"))
suppressPackageStartupMessages({library(dplyr); library(tidyr)})
input_dir <- "<LOCAL_PROJECT_ROOT>/Part5"
cache <- "results/fits_2021_Harmonized_ARIMAX.rds"
stopifnot(file.exists(cache))
pred <- bind_rows(lapply(readRDS(cache), `[[`, "pred")) %>% filter(year == 2030) %>% arrange(location_name)
saved <- read.csv(file.path(input_dir, "Future_Risk_Quartile_2030_ARIMAX.csv")) %>% arrange(location_name)
ihd <- read.csv(file.path(input_dir, "IHD_1992_2021_matrix.csv")) %>% arrange(location_name)
dd <- read.csv(file.path(input_dir, "DD_1992_2021_matrix.csv")) %>% arrange(location_name)
clipped <- pred
clipped$IHD_pred <- pmin(pmax(pred$IHD_pred, apply(ihd[, -1], 1, min)), 1.5 * apply(ihd[, -1], 1, max))
clipped$DD_pred <- pmin(pmax(pred$DD_pred, apply(dd[, -1], 1, min)), 1.5 * apply(dd[, -1], 1, max))
ans <- bind_rows(lapply(list(log1p_unclipped = pred, log1p_clipped = clipped), function(z) data.frame(
  count_2030 = sum(ntile(z$IHD_pred, 4) == 4 & ntile(z$DD_pred, 4) == 4),
  max_IHD_abs_difference_from_archive = max(abs(z$IHD_pred - saved$IHD_pred)),
  max_DD_abs_difference_from_archive = max(abs(z$DD_pred - saved$DD_pred)),
  root_mean_square_IHD_difference = sqrt(mean((z$IHD_pred - saved$IHD_pred)^2)),
  root_mean_square_DD_difference = sqrt(mean((z$DD_pred - saved$DD_pred)^2))
)), .id = "specification")
write.csv(ans, "qa/archived_arimax_variant_comparison.csv", row.names = FALSE)
write.csv(clipped, "qa/archived_arimax_logclipped_reconstruction.csv", row.names = FALSE)
print(ans)
