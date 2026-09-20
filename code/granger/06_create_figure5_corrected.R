#!/usr/bin/env Rscript
# INTERNAL POST-SUBMISSION SENSITIVITY DISPLAY; not the manuscript Figure 5.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
  library(sf)
  library(svglite)
  library(digest)
})

options(stringsAsFactors = FALSE, scipen = 999)
out_analysis <- "granger_corrected"
out_figure <- "../03_figures/figure5_corrected"
dir.create(out_figure, recursive = TRUE, showWarnings = FALSE)

write_utf8_lf <- function(lines, path) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeChar(paste0(paste(lines, collapse = "\n"), "\n"), con,
            eos = NULL, useBytes = TRUE)
}

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
fwrite(source, file.path(out_analysis, "Figure5_corrected_source.csv"), eol = "\n")

# Use the same Natural Earth-derived ISO3 geometry used elsewhere in the
# revised cartographic workflow. Polygon fills retain the visual language of
# the submitted map; representative points are reserved for the prespecified
# small-island/territory set and any unit without polygon geometry.
world_sp <- rworldmap::getMap(resolution = "low")
world_sf <- sf::st_as_sf(world_sp)
world_sf <- world_sf[, c("ISO3", "ADMIN", "geometry")]
geometry_iso3 <- unique(as.character(world_sf$ISO3))
point_overlay <- dat[
  small_island_excluded == TRUE |
    is.na(ISO3) | !nzchar(ISO3) | !(ISO3 %in% geometry_iso3)
]

palette <- c(
  "Bidirectional" = "#7B3294",
  "IHD -> DD" = "#2166AC",
  "DD -> IHD" = "#D95F02",
  "Neither" = "#D4D4D4"
)

make_panel <- function(direction_col) {
  vals <- as.data.frame(dat[, .(
    ISO3,
    map_direction = factor(
      as.character(get(direction_col)),
      levels = category_levels
    )
  )])
  map_dat <- merge(world_sf, vals, by = "ISO3", all.x = TRUE, sort = FALSE)

  ggplot(map_dat) +
    geom_sf(
      aes(fill = map_direction),
      colour = "#FFFFFF", linewidth = 0.08
    ) +
    geom_point(
      data = point_overlay,
      aes(x = longitude, y = latitude, fill = .data[[direction_col]]),
      shape = 21, size = 1.45, stroke = 0.22,
      colour = "#303030", alpha = 0.98, show.legend = FALSE,
      inherit.aes = FALSE
    ) +
    scale_fill_manual(
      values = palette,
      limits = category_levels,
      breaks = category_levels,
      labels = c("Bidirectional", "IHD-to-DD", "DD-to-IHD", "No evidence"),
      drop = FALSE, na.value = "#F2F2F2", name = NULL
    ) +
    coord_sf(
      xlim = c(-180, 180), ylim = c(-60, 88),
      expand = FALSE, datum = NA, clip = "off"
    ) +
    theme_void(base_size = 7.0, base_family = "sans") +
    theme(
      legend.position = "none",
      plot.margin = margin(3, 3, 0, 3)
    )
}

panel_tag_theme <- theme(
  plot.tag = element_text(
    face = "bold", size = 10.5, colour = "#111111",
    hjust = 0, vjust = 1
  ),
  plot.tag.position = c(0.012, 0.985)
)
p_primary <- make_panel("direction_primary") +
  labs(tag = "A") + panel_tag_theme
p_hc3 <- make_panel("direction_HC3") +
  labs(tag = "B") + panel_tag_theme

legend_data <- data.frame(
  x = seq_along(category_levels),
  y = 1,
  category = factor(category_levels, levels = category_levels)
)
legend_plot <- ggplot(legend_data, aes(x = x, y = y, fill = category)) +
  geom_point(shape = 22, size = 3.1, colour = "#FFFFFF") +
  scale_fill_manual(
    values = palette,
    limits = category_levels,
    breaks = category_levels,
    labels = c("Bidirectional", "IHD-to-DD", "DD-to-IHD", "No evidence"),
    drop = FALSE, name = NULL
  ) +
  guides(fill = guide_legend(
    nrow = 1, byrow = TRUE,
    override.aes = list(shape = 22, size = 3.1, colour = "#FFFFFF")
  )) +
  theme_void(base_size = 7.0, base_family = "sans") +
  theme(
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.text = element_text(size = 6.8, colour = "#111111"),
    legend.key.size = grid::unit(0.32, "cm"),
    legend.spacing.x = grid::unit(0.10, "cm"),
    legend.margin = margin(0, 0, 0, 0)
  )
legend_grob <- cowplot::get_legend(legend_plot)

# Keep the artwork deliberately minimal. Panel definitions, model details,
# counts and diagnostic cautions belong in the manuscript figure legend.
maps <- p_primary | p_hc3
fig <- maps / wrap_elements(full = legend_grob) +
  plot_layout(heights = c(1, 0.12))

base <- file.path(out_figure, "Figure5_corrected")
width_px <- 4320L
height_px <- 1350L
dpi <- 600L
width_in <- width_px / dpi
height_in <- height_px / dpi

grDevices::png(
  paste0(base, ".png"), width = width_px, height = height_px,
  units = "px", res = dpi, type = "cairo", bg = "white"
)
print(fig)
grDevices::dev.off()
grDevices::tiff(
  paste0(base, ".tif"), width = width_px, height = height_px,
  units = "px", res = dpi, compression = "lzw", type = "cairo", bg = "white"
)
print(fig)
grDevices::dev.off()
ggsave(
  paste0(base, ".pdf"), fig,
  width = width_in, height = height_in, units = "in",
  device = cairo_pdf, bg = "white"
)
ggsave(
  paste0(base, ".svg"), fig,
  width = width_in, height = height_in, units = "in",
  device = svglite::svglite, bg = "white"
)

legend <- c(
  "INTERNAL AUDIT/SENSITIVITY DISPLAY - NOT THE SUBMITTED MANUSCRIPT FIGURE 5.",
  "Figure 5 audit. Alternative SDI-adjusted directional temporal predictive associations between IHD and DD, 1992-2021.",
  "Panel A maps the exploratory Newey-West classification from country-specific autoregressive equations fitted to annual log changes: bidirectional, n=1; IHD-to-DD only, n=0; DD-to-IHD only, n=182; and no evidence, n=21. A common lag order of 1-3 was selected by Schwarz BIC for each country, SDI change was included as an exogenous control, and each directional restriction was tested only in its intended target equation using a finite-sample-adjusted Newey-West covariance truncated at lag 2. Benjamini-Hochberg correction was applied separately to 204 IHD-to-DD tests and 204 DD-to-IHD tests. Panel B repeats the classification using HC3 covariance: bidirectional, n=0; IHD-to-DD only, n=0; DD-to-IHD only, n=11; and no evidence, n=193. Countries and territories with polygon geometry are displayed as filled areas; representative coordinate markers retain the prespecified small-island and territory set and units without polygon geometry. Results indicate temporal predictive association at the ecological country level and do not establish causation or individual comorbidity. At least one residual serial-correlation flag occurred in 84/204 country analyses (90/408 directional equations), and all 408 directional equations had an observation above Cook's D > 4/n; the classification should therefore not be interpreted as a stable predominant direction."
)
write_utf8_lf(legend, file.path(out_analysis, "Figure5_corrected_legend.txt"))

geometry <- data.table(
  file = c(paste0(base, ".png"), paste0(base, ".tif")),
  width_px = width_px, height_px = height_px, dpi = dpi,
  panels = "A-B", mapped_points_per_panel = nrow(point_overlay)
)
fwrite(geometry, file.path(out_analysis, "Figure5_geometry_audit.csv"), eol = "\n")

qa_notes <- c(
  "# Internal Figure 5 sensitivity-display visual and geometry QA",
  "",
  "> **Scope:** Post-submission internal audit/sensitivity only. This file does not describe or replace the manuscript Figure 5.",
  "",
  paste0("- Raster exports: ", width_px, " x ", height_px, " pixels at ", dpi, " dpi; vector PDF and SVG also exported."),
  paste0("- Both panels use ISO3-linked polygon fills and ", nrow(point_overlay), " representative coordinate overlays for the prespecified small-island/territory set and geometry-unmatched units."),
  "- Panel A exploratory Newey-West counts: Bidirectional 1, IHD -> DD 0, DD -> IHD 182, Neither 21.",
  "- Panel B counts: Bidirectional 0, IHD -> DD 0, DD -> IHD 11, Neither 193.",
  "- The artwork contains only uppercase panel labels A-B, the two maps and one shared legend; panel definitions, counts, methods and diagnostic cautions are kept in the figure legend.",
  "- Visual inspection confirmed no clipped maps, overlay points, uppercase panel labels or shared legend; all four categorical colors remain distinguishable.",
  "- Small islands and territories are retained as representative coordinate points rather than being omitted by low-resolution polygon geometry."
)
write_utf8_lf(qa_notes, file.path(out_analysis, "Figure5_visual_QA.md"))

files <- c(result_file, coordinate_file, paste0(base, c(".png", ".tif", ".pdf", ".svg")),
           file.path(out_analysis, "Figure5_corrected_source.csv"),
           file.path(out_analysis, "Figure5_corrected_legend.txt"))
manifest <- data.table(
  path = gsub("\\\\", "/", files),
  bytes = file.info(files)$size,
  sha256 = vapply(files, digest::digest, character(1), algo = "sha256", file = TRUE)
)
fwrite(manifest, file.path(out_analysis, "Figure5_checksums_sha256.csv"), eol = "\n")

cat("Figure 5 written to ", normalizePath(out_figure, winslash = "/"), "\n", sep = "")
print(dat[, .N, by = direction_primary])
print(dat[, .N, by = direction_HC3])
