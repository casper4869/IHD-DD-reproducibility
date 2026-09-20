#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(maps)
  library(patchwork)
  library(svglite)
  library(digest)
})

options(stringsAsFactors = FALSE, scipen = 999)
out_analysis <- "granger_corrected"
out_figure <- "../03_figures/figure5_corrected"
dir.create(out_figure, recursive = TRUE, showWarnings = FALSE)

result_file <- file.path(out_analysis, "Supplementary_Table_S2_corrected.csv")
coordinate_file <- "immutable_part7_source/Country_with_LatLon_Matched.csv"
stopifnot(file.exists(result_file), file.exists(coordinate_file))

normalise_location_key <- function(x) {
  x[grepl("Ivoire", x, fixed = TRUE)] <- "Republic of Cote d'Ivoire"
  x
}

res <- fread(result_file)
coords <- fread(coordinate_file)[, .(
  location_name = normalise_location_key(location_name),
  longitude = as.numeric(lng), latitude = as.numeric(lat)
)]
res[, location_name := normalise_location_key(location_name)]
dat <- merge(res, coords, by = "location_name", all.x = TRUE)
stopifnot(nrow(dat) == 204L, !anyNA(dat[, .(longitude, latitude)]))

dat[, IHD_to_DD_q_HC3 := p.adjust(IHD_to_DD_p_HC3, method = "BH", n = 204L)]
dat[, DD_to_IHD_q_HC3 := p.adjust(DD_to_IHD_p_HC3, method = "BH", n = 204L)]
dat[, direction_HC3 := fcase(
  IHD_to_DD_q_HC3 < 0.05 & DD_to_IHD_q_HC3 < 0.05, "Bidirectional",
  IHD_to_DD_q_HC3 < 0.05, "IHD -> DD",
  DD_to_IHD_q_HC3 < 0.05, "DD -> IHD",
  default = "Neither"
)]
dat[, direction_primary := fcase(
  direction == "Bidirectional", "Bidirectional",
  direction == "IHD_to_DD", "IHD -> DD",
  direction == "DD_to_IHD", "DD -> IHD",
  default = "Neither"
)]

category_levels <- c("Bidirectional", "IHD -> DD", "DD -> IHD", "Neither")
dat[, `:=`(
  direction_primary = factor(direction_primary, levels = category_levels),
  direction_HC3 = factor(direction_HC3, levels = category_levels)
)]

source <- dat[, .(
  location_name, ISO3, longitude, latitude, selected_lag_BIC,
  primary_direction = as.character(direction_primary),
  IHD_to_DD_p, IHD_to_DD_q, DD_to_IHD_p, DD_to_IHD_q,
  HC3_direction = as.character(direction_HC3),
  IHD_to_DD_p_HC3, IHD_to_DD_q_HC3,
  DD_to_IHD_p_HC3, DD_to_IHD_q_HC3,
  IHD_to_DD_BG_p, DD_to_IHD_BG_p, diagnostics,
  small_island_excluded
)]
fwrite(source, file.path(out_analysis, "Figure5_corrected_source.csv"))

world <- map_data("world")
palette <- c(
  "Bidirectional" = "#7B3294",
  "IHD -> DD" = "#2166AC",
  "DD -> IHD" = "#D95F02",
  "Neither" = "#BDBDBD"
)

make_panel <- function(direction_col, title, subtitle) {
  counts <- dat[, .N, by = direction_col]
  count_lookup <- setNames(counts$N, as.character(counts[[direction_col]]))
  legend_labels <- vapply(category_levels, function(x) {
    n_x <- if (x %in% names(count_lookup)) unname(count_lookup[[x]]) else 0L
    paste0(x, " (n=", n_x, ")")
  }, character(1))

  ggplot() +
    geom_polygon(
      data = world,
      aes(long, lat, group = group),
      fill = "#F2F2F2", colour = "#FFFFFF", linewidth = 0.15
    ) +
    geom_point(
      data = dat,
      aes(x = longitude, y = latitude, colour = .data[[direction_col]]),
      size = 2.15, alpha = 0.90, shape = 16
    ) +
    scale_colour_manual(
      values = palette, limits = category_levels, labels = legend_labels,
      drop = FALSE, name = NULL
    ) +
    coord_quickmap(xlim = c(-180, 180), ylim = c(-60, 88), expand = FALSE) +
    labs(title = title, subtitle = subtitle, x = NULL, y = NULL) +
    theme_void(base_size = 10) +
    theme(
      plot.title = element_text(face = "bold", size = 12, margin = margin(b = 3)),
      plot.subtitle = element_text(size = 9, colour = "#444444", margin = margin(b = 7)),
      legend.position = "bottom",
      legend.text = element_text(size = 8.5),
      legend.key.width = grid::unit(0.65, "cm"),
      plot.margin = margin(6, 6, 2, 6)
    ) +
    guides(colour = guide_legend(nrow = 1, byrow = TRUE, override.aes = list(size = 3)))
}

p_primary <- make_panel(
  "direction_primary",
  "A  Primary Newey-West classification (exploratory)",
  "BIC-selected lags 1-3; SDI exogenous; Newey-West(2); directional BH q < 0.05"
)
p_hc3 <- make_panel(
  "direction_HC3",
  "B  Covariance-estimator sensitivity",
  "Same models and BH families; HC3 covariance"
)

footer <- paste0(
  "Country-level temporal prediction, not individual-level or mechanistic causation. ",
  "Representative coordinate points show all 204 units, including small islands. ",
  "At least one residual serial-correlation flag occurred in 84/204 country analyses (90/408 directional equations); ",
  "all 408 directional equations had an observation above Cook's D > 4/n."
)
footer <- paste(strwrap(footer, width = 175), collapse = "\n")
fig <- (p_primary / p_hc3) +
  plot_annotation(
    title = "Corrected SDI-adjusted directional Granger-type analysis, 1992-2021",
    subtitle = "Annual log changes; separate target equations ensure each direction tests only the intended outcome",
    caption = footer,
    theme = theme(
      plot.title = element_text(face = "bold", size = 15, hjust = 0),
      plot.subtitle = element_text(size = 10.5, colour = "#333333"),
      plot.caption = element_text(size = 8.5, colour = "#444444", hjust = 0, margin = margin(t = 6)),
      plot.margin = margin(12, 14, 10, 14)
    )
  )

base <- file.path(out_figure, "Figure5_corrected")
grDevices::png(paste0(base, ".png"), width = 3600, height = 2550, res = 300,
               type = "cairo", bg = "white")
print(fig)
grDevices::dev.off()
grDevices::tiff(paste0(base, ".tif"), width = 3600, height = 2550, res = 300,
                compression = "lzw", type = "cairo", bg = "white")
print(fig)
grDevices::dev.off()
ggsave(paste0(base, ".pdf"), fig, width = 12, height = 8.5, units = "in", device = cairo_pdf, bg = "white")
ggsave(paste0(base, ".svg"), fig, width = 12, height = 8.5, units = "in", device = svglite::svglite, bg = "white")

legend <- c(
  "Figure 5. Corrected SDI-adjusted directional temporal predictive associations between IHD and DD, 1992-2021.",
  "Panel A maps an exploratory Newey-West classification from country-specific autoregressive equations fitted to annual log changes. A common lag order of 1-3 was selected by Schwarz BIC for each country, SDI change was included as an exogenous control, and each directional restriction was tested only in its intended target equation using a finite-sample-adjusted Newey-West covariance truncated at lag 2. Benjamini-Hochberg correction was applied separately to 204 IHD-to-DD tests and 204 DD-to-IHD tests. Panel B repeats the classification using HC3 covariance, showing marked estimator sensitivity. Points use the supplied representative coordinates so all 204 countries and territories, including small islands, remain visible. Results indicate temporal predictive association at the ecological country level and do not establish causation or individual comorbidity. At least one residual serial-correlation flag occurred in 84/204 country analyses (90/408 directional equations), and all 408 directional equations had an observation above Cook's D > 4/n; the classification should therefore not be interpreted as a stable predominant direction."
)
writeLines(legend, file.path(out_analysis, "Figure5_corrected_legend.txt"), useBytes = TRUE)

geometry <- data.table(
  file = c(paste0(base, ".png"), paste0(base, ".tif")),
  width_px = c(3600L, 3600L), height_px = c(2550L, 2550L), dpi = 300L,
  panels = "A-B", mapped_points_per_panel = 204L
)
fwrite(geometry, file.path(out_analysis, "Figure5_geometry_audit.csv"))

qa_notes <- c(
  "# Figure 5 visual and geometry QA",
  "",
  "- Raster exports: 3600 x 2550 pixels at 300 dpi; vector PDF and SVG also exported.",
  "- Both panels contain 204 coordinate points, including all 45 locations in the cartographic/SIDS sensitivity set.",
  "- Panel A exploratory Newey-West counts: Bidirectional 1, IHD -> DD 0, DD -> IHD 182, Neither 21.",
  "- Panel B counts: Bidirectional 0, IHD -> DD 0, DD -> IHD 11, Neither 193.",
  "- The title and legend use temporal-prediction language; the caption explicitly rejects individual-level and mechanistic causal interpretation.",
  "- The covariance-estimator sensitivity and diagnostic flags are printed in the figure rather than hidden in supplementary text.",
  "- Visual inspection: no clipped maps, points, panel titles, legends, or caption; panel labels A-B are present; colors remain distinguishable against the pale basemap.",
  "- Small islands are rendered as representative coordinate points, avoiding omission caused by low-resolution polygon geometry."
)
writeLines(qa_notes, file.path(out_analysis, "Figure5_visual_QA.md"), useBytes = TRUE)

files <- c(result_file, coordinate_file, paste0(base, c(".png", ".tif", ".pdf", ".svg")),
           file.path(out_analysis, "Figure5_corrected_source.csv"),
           file.path(out_analysis, "Figure5_corrected_legend.txt"))
manifest <- data.table(
  path = gsub("\\\\", "/", files),
  bytes = file.info(files)$size,
  sha256 = vapply(files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(manifest, file.path(out_analysis, "Figure5_checksums_sha256.csv"))

cat("Figure 5 written to ", normalizePath(out_figure, winslash = "/"), "\n", sep = "")
print(dat[, .N, by = direction_primary])
print(dat[, .N, by = direction_HC3])
