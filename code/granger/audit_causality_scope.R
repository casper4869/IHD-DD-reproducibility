# Offline introspection: verify which equations vars::causality tests.
# Usage: Rscript audit_causality_scope.R INPUT_DIR OUTPUT_DIR
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
dir.create(args[2], recursive = TRUE, showWarnings = FALSE)
infiles <- c("IHD_1992_2021_matrix.csv", "DD_1992_2021_matrix.csv", "SDI_1992_2021_matrix.csv")
tables <- lapply(infiles, function(nm) vroom::vroom(file.path(args[1], nm),
                                                show_col_types = FALSE, progress = FALSE))
countries <- c("American Samoa", "People's Republic of China", "United States of America")
rows <- list()
for (country in countries) {
  y <- sapply(tables, function(x) as.numeric(x[x$location_name == country, paste0("val_", 1992:2021)]))
  colnames(y) <- c("IHD_val", "DD_val", "SDI_val")
  p <- unname(vars::VARselect(y, lag.max = 2)$selection["AIC(n)"])
  model <- vars::VAR(y, p = p, type = "const")
  for (cause in c("IHD_val", "DD_val")) {
    test <- vars::causality(model, cause = cause)$Granger
    targets <- setdiff(colnames(y), cause)
    rows[[length(rows) + 1L]] <- data.frame(
      country = country, cause = cause, joint_target_equations = paste(targets, collapse = "; "),
      lag = p, expected_joint_restrictions = p * length(targets),
      actual_numerator_df = unname(test$parameter[1]),
      F_statistic = unname(test$statistic), p_value = test$p.value)
  }
}
out <- do.call(rbind, rows)
stopifnot(all(out$actual_numerator_df == out$expected_joint_restrictions))
write.csv(out, file.path(args[2], "causality_scope_examples.csv"), row.names = FALSE)
writeLines(capture.output(vars::causality), file.path(args[2], "installed_vars_causality_source.txt"))
print(out)
