options(stringsAsFactors = FALSE)

# Rebuild the locked plotting table from archived analysis artifacts.
# Optional command-line arguments:
#   1 historical_counts.csv
#   2 VARX_annual_count.csv
#   3 ARIMAX_annual_count.csv
#   4 archived 2030 ARIMAX classification CSV
#   5 output Figure4_minimal_source.csv

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 5L)

historical <- read.csv(args[1], check.names = FALSE)
varx_all <- read.csv(args[2], check.names = FALSE)
arimax_all <- read.csv(args[3], check.names = FALSE)
arimax_2030 <- read.csv(args[4], check.names = FALSE)

stopifnot(identical(historical$year, 1992:2021))
stopifnot(identical(historical$n_high, varx_all$n_high[varx_all$year <= 2021]))
stopifnot(identical(historical$n_high, arimax_all$n_high[arimax_all$year <= 2021]))

archived_arimax_2030 <- sum(arimax_2030$High_Burden == "High-High", na.rm = TRUE)
stopifnot(archived_arimax_2030 == 14L)

make_panel <- function(panel, model, projected) {
  rbind(
    data.frame(panel = panel, model = model, period = "Historical",
               year = historical$year, n_high = historical$n_high,
               value_basis = "archived historical count"),
    data.frame(panel = panel, model = model, period = "Projection",
               year = projected$year, n_high = projected$n_high,
               value_basis = "archived plotted trajectory")
  )
}

varx_future <- subset(varx_all, year >= 2022, select = c(year, n_high))
arimax_future <- subset(arimax_all, year >= 2022, select = c(year, n_high))
# The archived original panel and archived 2030 classification both report 14.
# Current package execution gives 13, so the redraw locks the submitted value.
arimax_future$n_high[arimax_future$year == 2030] <- archived_arimax_2030

source_data <- rbind(
  make_panel("A", "VARX", varx_future),
  make_panel("B", "ARIMAX", arimax_future)
)

stopifnot(nrow(source_data) == 78L)
stopifnot(source_data$n_high[source_data$panel == "A" & source_data$year == 2030] == 19L)
stopifnot(source_data$n_high[source_data$panel == "B" & source_data$year == 2030] == 14L)

write.csv(source_data, args[5], row.names = FALSE, na = "")

