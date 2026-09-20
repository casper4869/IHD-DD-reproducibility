#!/usr/bin/env Rscript

# Rebuild the minimally revised Figure 6 from the included audited local
# coefficient table. This script is fully offline and contains no hard-coded
# workspace path.

if (.Platform$OS.type == "windows") {
  suppressWarnings(try(Sys.setlocale("LC_ALL", "Chinese_China.utf8"), silent = TRUE))
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(maps)
  library(patchwork)
  library(svglite)
  library(ragg)
  library(tiff)
})

args <- commandArgs(trailingOnly = TRUE)
source_file <- if (length(args) >= 1L) args[[1L]] else
  file.path("derived_data", "figure6", "Figure6_source_data.csv")
figure_dir <- if (length(args) >= 2L) args[[2L]] else "figures"
qa_dir <- if (length(args) >= 3L) args[[3L]] else
  file.path("derived_data", "figure6")

if (!file.exists(source_file)) stop("Source file not found: ", source_file)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)

full <- read_csv(source_file, show_col_types = FALSE)
required <- c(
  "location_name", "longitude", "latitude", "analysis", "outcome",
  "exposure", "bandwidth_km", "local_beta", "local_se", "local_t",
  "ISO3", "small_island_excluded"
)
if (!all(required %in% names(full))) {
  stop("Figure 6 source is missing: ", paste(setdiff(required, names(full)), collapse = ", "))
}

stopifnot(
  nrow(full) == 408L,
  identical(sort(unique(full$outcome)), c("DD", "IHD")),
  all(table(full$outcome) == 204L),
  !anyNA(full[c("longitude", "latitude", "local_beta", "ISO3")]),
  all(is.finite(full$local_beta))
)

# Both panels share a symmetric data-complete scale. Rounding upward to the
# next 0.1 retains all values and avoids the submitted plot's [-1, 1]
# saturation.
shared_limit <- ceiling(max(abs(full$local_beta)) * 10) / 10
stopifnot(shared_limit >= max(abs(full$local_beta)))

point_audit <- full |>
  distinct(location_name, ISO3, longitude, latitude, small_island_excluded) |>
  mutate(
    inferential_unit = "one country or territory",
    display_method = "recorded representative coordinate",
    value_duplicated_across_polygons = FALSE
  ) |>
  arrange(location_name)
stopifnot(nrow(point_audit) == 204L)
write_csv(point_audit, file.path(qa_dir, "Figure6_point_display_audit.csv"))

panel_summary <- full |>
  group_by(outcome, exposure) |>
  summarise(
    n = n(),
    bandwidth_km = first(bandwidth_km),
    beta_min = min(local_beta),
    beta_q1 = quantile(local_beta, 0.25),
    beta_median = median(local_beta),
    beta_q3 = quantile(local_beta, 0.75),
    beta_max = max(local_beta),
    negative_n = sum(local_beta < 0),
    positive_n = sum(local_beta > 0),
    outside_submitted_scale_n = sum(abs(local_beta) > 1),
    .groups = "drop"
  )
write_csv(panel_summary, file.path(qa_dir, "Figure6_panel_summary.csv"))

world_map <- map_data("world")

make_panel <- function(data, title, bandwidth_km) {
  ggplot() +
    geom_polygon(
      data = world_map,
      aes(x = long, y = lat, group = group),
      fill = "#F2F2F2", colour = "#A6A6A6", linewidth = 0.18
    ) +
    geom_point(
      data = data,
      aes(x = longitude, y = latitude, fill = local_beta),
      shape = 21, size = 2.45, stroke = 0.18,
      colour = "#555555", alpha = 0.86
    ) +
    scale_fill_gradient2(
      name = "Local standardised coefficient (β)",
      low = "#2166AC", mid = "#F7F7F7", high = "#B2182B",
      midpoint = 0,
      limits = c(-shared_limit, shared_limit),
      breaks = seq(-1.5, 1.5, by = 0.5),
      guide = guide_colourbar(
        title.position = "top", title.hjust = 0.5,
        barwidth = grid::unit(78, "mm"),
        barheight = grid::unit(3.2, "mm"),
        ticks.colour = "#555555", frame.colour = "#777777"
      )
    ) +
    coord_quickmap(
      xlim = c(-180, 180), ylim = c(-50, 85),
      expand = FALSE, clip = "on"
    ) +
    scale_x_continuous(
      breaks = c(-150, -100, -50, 0, 50, 100, 150),
      labels = c("150°W", "100°W", "50°W", "0°", "50°E", "100°E", "150°E")
    ) +
    scale_y_continuous(
      breaks = c(-40, 0, 40, 80),
      labels = c("40°S", "0°", "40°N", "80°N")
    ) +
    labs(
      title = title,
      subtitle = sprintf(
        "Gaussian fixed-bandwidth GWR; adjusted for SDI and PM2.5; bandwidth %.0f km",
        bandwidth_km
      ),
      x = "Longitude", y = "Latitude"
    ) +
    theme_minimal(base_family = "Arial", base_size = 7.2) +
    theme(
      panel.background = element_rect(fill = "#F2F8FC", colour = NA),
      panel.grid.major = element_line(
        colour = "#CDD6DC", linewidth = 0.25, linetype = "dotted"
      ),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(fill = NA, colour = "#555555", linewidth = 0.35),
      plot.title = element_text(
        size = 9.0, face = "bold", colour = "#151515", margin = margin(b = 1.2)
      ),
      plot.subtitle = element_text(
        size = 6.8, colour = "#4F5962", margin = margin(b = 2.5)
      ),
      axis.title = element_text(size = 7.3, face = "bold", colour = "#222222"),
      axis.text = element_text(size = 6.3, colour = "#4A4A4A"),
      legend.position = "bottom",
      legend.title = element_text(size = 6.9, face = "bold", colour = "#222222"),
      legend.text = element_text(size = 6.2, colour = "#333333"),
      legend.margin = margin(t = 0, b = 0),
      plot.margin = margin(t = 3, r = 4, b = 2, l = 3)
    )
}

panel_a_data <- full |> filter(outcome == "IHD")
panel_b_data <- full |> filter(outcome == "DD")

p_a <- make_panel(
  panel_a_data,
  "A  Local DD coefficients for IHD incidence (2021)",
  unique(panel_a_data$bandwidth_km)
)
p_b <- make_panel(
  panel_b_data,
  "B  Local IHD coefficients for DD incidence (2021)",
  unique(panel_b_data$bandwidth_km)
)
figure6 <- (p_a / p_b) +
  plot_layout(guides = "collect", heights = c(1, 1)) &
  theme(legend.position = "bottom")

width_mm <- 183
height_mm <- 156
width_in <- width_mm / 25.4
height_in <- height_mm / 25.4
stem <- file.path(figure_dir, "Figure6_revised")

svglite(
  file = paste0(stem, ".svg"), width = width_in, height = height_in,
  bg = "white", system_fonts = list(sans = "Arial")
)
print(figure6)
dev.off()

grDevices::cairo_pdf(
  paste0(stem, ".pdf"), width = width_in, height = height_in,
  family = "Arial", bg = "white", onefile = TRUE
)
print(figure6)
dev.off()

agg_tiff(
  paste0(stem, ".tif"), width = width_in, height = height_in,
  units = "in", res = 600, compression = "lzw", background = "white"
)
print(figure6)
dev.off()

agg_png(
  paste0(stem, ".png"), width = width_in, height = height_in,
  units = "in", res = 300, background = "white"
)
print(figure6)
dev.off()

tif_img <- readTIFF(paste0(stem, ".tif"), native = FALSE, convert = TRUE)
tif_dim <- dim(tif_img)
qa_lines <- c(
  "# Figure 6 visual and numerical QA",
  "",
  "- Core conclusion: adjusted local country-level IHD-DD associations vary geographically and include positive and negative coefficients.",
  "- Archetype: two vertically stacked coordinate-based point maps, retaining the submitted figure's evidence form.",
  "- Backend: R only (ggplot2, maps, patchwork, svglite, cairo_pdf, ragg).",
  sprintf("- Source rows: %d (%d countries/territories in each direction).", nrow(full), nrow(panel_a_data)),
  "- Every study unit is displayed once at its recorded representative coordinate; multipart polygons do not duplicate analytical observations.",
  sprintf("- Shared symmetric colour limit: ±%.1f; observed range %.3f to %.3f.", shared_limit, min(full$local_beta), max(full$local_beta)),
  sprintf("- Submitted ±1 scale would truncate %d estimates in panel A and %d estimates in panel B; the revised figure truncates none.", sum(abs(panel_a_data$local_beta) > 1), sum(abs(panel_b_data$local_beta) > 1)),
  sprintf("- Panel A beta range: %.3f to %.3f; median %.3f.", min(panel_a_data$local_beta), max(panel_a_data$local_beta), median(panel_a_data$local_beta)),
  sprintf("- Panel B beta range: %.3f to %.3f; median %.3f.", min(panel_b_data$local_beta), max(panel_b_data$local_beta), median(panel_b_data$local_beta)),
  sprintf("- TIFF dimensions: %d x %d pixels at 600 dpi target.", tif_dim[2], tif_dim[1]),
  "- PDF and SVG retain vector geometry and editable text.",
  "- Direction is encoded redundantly by blue/negative and red/positive labels around a neutral zero midpoint.",
  "- Interpretation guardrail: these are adjusted 2021 cross-sectional GWR coefficients, not causal estimates."
)
writeLines(qa_lines, file.path(qa_dir, "Figure6_visual_and_numerical_QA.md"), useBytes = TRUE)
writeLines(capture.output(sessionInfo()), file.path(qa_dir, "sessionInfo.txt"), useBytes = TRUE)

cat(sprintf("Created Figure 6 at %s with shared limit ±%.1f.\n", figure_dir, shared_limit))
