options(stringsAsFactors = FALSE)
Sys.setenv(LANGUAGE = "en")

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
  library(svglite)
  library(ragg)
})

argv <- commandArgs(trailingOnly = FALSE)
script_arg <- sub("^--file=", "", grep("^--file=", argv, value = TRUE)[1])
script_dir <- dirname(normalizePath(script_arg, winslash = "/", mustWork = TRUE))
args <- commandArgs(trailingOnly = TRUE)
source_file <- if (length(args) >= 1L) args[1] else file.path(script_dir, "Figure4_minimal_source.csv")
output_base <- if (length(args) >= 2L) args[2] else file.path(script_dir, "Figure4_minimal")

d <- read.csv(source_file, check.names = FALSE)
stopifnot(identical(sort(unique(d$panel)), c("A", "B")))
stopifnot(nrow(d) == 78L, !anyNA(d[c("panel", "model", "period", "year", "n_high")]))
stopifnot(all(table(d$panel) == 39L), all(table(d$panel, d$period)[, "Historical"] == 30L))
stopifnot(identical(d$n_high[d$panel == "A" & d$period == "Historical"],
                    d$n_high[d$panel == "B" & d$period == "Historical"]))
stopifnot(d$n_high[d$panel == "A" & d$year == 2030] == 19L)
stopifnot(d$n_high[d$panel == "B" & d$year == 2030] == 14L)
stopifnot(identical(d$n_high[d$panel == "A" & d$period == "Projection"],
                    c(17L, 16L, 21L, 19L, 20L, 18L, 19L, 20L, 19L)))
stopifnot(identical(d$n_high[d$panel == "B" & d$period == "Projection"],
                    c(15L, 14L, 14L, 14L, 15L, 14L, 14L, 14L, 14L)))

historical_colour <- "#3FA7C2"
projection_colour <- "#D84A35"

theme_minimal_panel <- function(show_y_title = TRUE) {
  theme_classic(base_size = 7.5, base_family = "Arial") +
    theme(
      axis.line = element_line(colour = "#202020", linewidth = 0.35),
      axis.ticks = element_line(colour = "#202020", linewidth = 0.35),
      axis.ticks.length = grid::unit(1.4, "mm"),
      axis.text = element_text(colour = "#202020", size = 7),
      axis.title.x = element_text(size = 8, margin = margin(t = 4)),
      axis.title.y = if (show_y_title) element_text(size = 8, margin = margin(r = 4)) else element_blank(),
      plot.tag = element_text(size = 10, face = "bold", colour = "#111111"),
      plot.tag.position = c(0.01, 0.99),
      plot.margin = margin(5, 6, 4, 5),
      legend.position = "none"
    )
}

make_panel <- function(panel_id, show_y_title) {
  z <- d[d$panel == panel_id, ]
  hist <- z[z$period == "Historical", ]
  forecast <- z[z$period == "Projection", ]
  forecast_line <- rbind(
    transform(hist[hist$year == 2021, ], period = "Projection"),
    forecast
  )

  ggplot() +
    geom_vline(xintercept = 2021.5, colour = "#9A9A9A", linewidth = 0.35,
               linetype = "22") +
    geom_line(data = hist, aes(year, n_high), colour = historical_colour,
              linewidth = 0.70, lineend = "round") +
    geom_point(data = hist, aes(year, n_high), colour = historical_colour,
               fill = historical_colour, shape = 21, size = 1.65, stroke = 0.25) +
    geom_line(data = forecast_line, aes(year, n_high), colour = projection_colour,
              linewidth = 0.75, linetype = "42", lineend = "round") +
    geom_point(data = forecast, aes(year, n_high), colour = projection_colour,
               fill = projection_colour, shape = 24, size = 1.95, stroke = 0.25) +
    scale_x_continuous(breaks = c(1992, 2000, 2010, 2021, 2030),
                       limits = c(1991.4, 2030.6), expand = c(0, 0)) +
    scale_y_continuous(breaks = c(10, 15, 20), limits = c(10, 22),
                       expand = c(0, 0)) +
    labs(tag = panel_id, x = "Year",
         y = if (show_y_title) "High-high countries (n)" else NULL) +
    coord_cartesian(clip = "off") +
    theme_minimal_panel(show_y_title)
}

figure <- make_panel("A", TRUE) + make_panel("B", FALSE) +
  plot_layout(ncol = 2, widths = c(1, 1))

width_mm <- 183
height_mm <- 78
width_in <- width_mm / 25.4
height_in <- height_mm / 25.4

svglite::svglite(paste0(output_base, ".svg"), width = width_in, height = height_in,
                 bg = "white", system_fonts = list(Arial = "Arial"))
print(figure)
dev.off()

grDevices::cairo_pdf(paste0(output_base, ".pdf"), width = width_in, height = height_in,
                     family = "Arial", bg = "white", onefile = TRUE)
print(figure)
dev.off()

grDevices::png(paste0(output_base, ".png"), width = width_in, height = height_in,
               units = "in", res = 300, bg = "white", type = "cairo")
print(figure)
dev.off()

grDevices::tiff(paste0(output_base, ".tif"), width = width_in, height = height_in,
                units = "in", res = 600, compression = "lzw", bg = "white", type = "cairo")
print(figure)
dev.off()

svg_text <- paste(readLines(paste0(output_base, ".svg"), warn = FALSE), collapse = "\n")
forbidden <- c("Global Burden", "Historical Trend", "Forecast Period",
               "Confidence Interval", "2021 Baseline", "Actual", "Forecast",
               "VARX", "ARIMAX")
stopifnot(!any(vapply(forbidden, grepl, logical(1), x = svg_text, fixed = TRUE)))
stopifnot(grepl("<text", svg_text, fixed = TRUE))
exports <- paste0(output_base, c(".svg", ".pdf", ".png", ".tif"))
stopifnot(all(file.exists(exports)), all(file.info(exports)$size > 0))

qa <- data.frame(
  check = c(
    "backend_R_only", "panels_uppercase_A_B", "historical_series_identical",
    "VARX_2030_equals_19", "ARIMAX_2030_equals_14",
    "no_title_subtitle_legend_or_in_panel_annotations",
    "forecast_divider_has_no_text", "common_axis_ranges",
    "svg_text_editable", "export_bundle_complete"
  ),
  result = rep("PASS", 10L),
  stringsAsFactors = FALSE
)
write.csv(qa, paste0(output_base, "_QA_checks.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = paste0(output_base, "_sessionInfo.txt"))
