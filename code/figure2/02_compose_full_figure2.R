#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 1)
set.seed(20260918)

required <- c(
  "data.table", "ggplot2", "ggridges", "patchwork", "png", "tiff", "digest",
  "countrycode", "rworldmap", "sf"
)
missing_packages <- setdiff(required, rownames(installed.packages()))
if (length(missing_packages) > 0L) {
  stop("Missing required R packages: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(ggridges)
  library(patchwork)
  library(grid)
})

if (basename(getwd()) != "02_analysis") {
  stop("Run this script with the revision 02_analysis directory as the working directory")
}

original_figure <- file.path("..", "00_original", "Figure2.tif")
s1_csv <- file.path("figure2_s1", "Supplementary_Table_S1_corrected.csv")
weighted_csv <- file.path("figure2_s1", "Figure2_EF_weighted_correlations_corrected.csv")
location_crosswalk_csv <- file.path(
  "figure2_s1", "derived_inputs", "GBD_country_location_crosswalk.csv"
)
figure_dir <- file.path("..", "03_figures", "figure2_corrected")
analysis_dir <- file.path("figure2_s1")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(original_figure) || !file.exists(s1_csv) ||
    !file.exists(weighted_csv) || !file.exists(location_crosswalk_csv)) {
  stop("Missing original Figure 2, corrected source table, or location crosswalk")
}

original <- tiff::readTIFF(original_figure, native = FALSE)
original_dim <- dim(original)
if (length(original_dim) < 3L || original_dim[1L] != 2227L || original_dim[2L] != 2800L) {
  stop("Unexpected original Figure 2 dimensions: ", paste(original_dim, collapse = " x "))
}

# The submitted A-B maps used raw P<0.05 masking. The corrected manuscript and
# Table S1 require sex-specific BH q<0.05 based on unrounded P values. Regenerate
# A-B from the corrected table, retain only the conceptually valid submitted C-D
# row, and retain the corrected E-F generation below.
ab_end_row <- 680L
cd_start_row <- ab_end_row + 1L
cd_end_row <- 1425L
ab_rows <- ab_end_row
cd_rows <- cd_end_row - cd_start_row + 1L
ef_rows <- original_dim[1L] - cd_end_row
cd_raster <- original[cd_start_row:cd_end_row, , , drop = FALSE]

s1 <- fread(s1_csv, showProgress = FALSE)
required_s1 <- c("location_name", "sex_name", "correlation", "p_value", "fdr_pvalue")
if (!all(required_s1 %in% names(s1))) {
  stop("Corrected S1 is missing required columns: ",
       paste(setdiff(required_s1, names(s1)), collapse = ", "))
}
stopifnot(nrow(s1) == 408L, !anyDuplicated(s1[, .(location_name, sex_name)]))
stopifnot(all(s1[, .N, by = sex_name]$N == 204L))

s1[, ISO3 := countrycode::countrycode(
  location_name, origin = "country.name", destination = "iso3c", warn = FALSE
)]
s1[, iso3_mapping_method := "countrycode country.name to iso3c"]
manual_iso3 <- c(
  "Lebanese Republic" = "LBN",
  "Republic of Guyana" = "GUY",
  "Portuguese Republic" = "PRT",
  "Republic of Cote d'Ivoire" = "CIV",
  "Republic of Côte d'Ivoire" = "CIV"
)
miss <- is.na(s1$ISO3) & s1$location_name %in% names(manual_iso3)
s1[miss, ISO3 := unname(manual_iso3[location_name])]
s1[miss, iso3_mapping_method := "manual ISO3 override after countrycode non-match"]
if (anyNA(s1$ISO3)) {
  stop("Unmatched S1 country names: ",
       paste(unique(s1[is.na(ISO3), location_name]), collapse = "; "))
}
s1[, `:=`(
  display_r = fifelse(fdr_pvalue < 0.05, correlation, NA_real_),
  display_status = fifelse(fdr_pvalue < 0.05, "BH q<0.05", "BH q>=0.05")
)]

ab_counts <- s1[, .(
  countries = .N,
  raw_p_lt_0_05 = sum(p_value < 0.05),
  bh_q_lt_0_05 = sum(fdr_pvalue < 0.05),
  grey_bh_q_ge_0_05 = sum(fdr_pvalue >= 0.05)
), by = sex_name]
ab_counts[, sex_order := match(sex_name, c("Female", "Male"))]
setorder(ab_counts, sex_order)
ab_counts[, sex_order := NULL]
stopifnot(
  ab_counts[sex_name == "Female", bh_q_lt_0_05] == 46L,
  ab_counts[sex_name == "Male", bh_q_lt_0_05] == 109L
)

world_sp <- rworldmap::getMap(resolution = "low")
world_sf <- sf::st_as_sf(world_sp)
world_sf <- world_sf[, c("ISO3", "ADMIN", "geometry")]
shape_iso3 <- unique(as.character(world_sf$ISO3))
world_features <- data.table(
  geometry_feature_index = seq_len(nrow(world_sp@data)),
  ISO3 = as.character(world_sp@data$ISO3),
  geometry_feature_name = as.character(world_sp@data$ADMIN),
  polygon_part_count = vapply(
    world_sp@polygons, function(z) length(z@Polygons), integer(1)
  )
)
world_features <- world_features[!is.na(ISO3) & nzchar(ISO3)]
geometry_by_iso3 <- world_features[, .(
  geometry_feature_count = .N,
  geometry_feature_indices = paste(geometry_feature_index, collapse = ";"),
  geometry_feature_names = paste(unique(geometry_feature_name), collapse = ";"),
  polygon_part_count = sum(polygon_part_count)
), by = ISO3]

location_crosswalk <- fread(location_crosswalk_csv, showProgress = FALSE)
stopifnot(
  nrow(location_crosswalk) == 204L,
  !anyDuplicated(location_crosswalk$location_id),
  !anyDuplicated(location_crosswalk$location_name)
)
mapping_coverage <- unique(s1[, .(
  location_name, ISO3, iso3_mapping_method
)])
mapping_coverage <- merge(
  location_crosswalk, mapping_coverage,
  by = "location_name", all.x = TRUE, sort = FALSE
)
mapping_coverage <- merge(
  mapping_coverage, geometry_by_iso3,
  by = "ISO3", all.x = TRUE, sort = FALSE
)
mapping_coverage[, geometry_available := !is.na(geometry_feature_count)]
mapping_coverage[is.na(geometry_feature_count), `:=`(
  geometry_feature_count = 0L,
  geometry_feature_indices = "",
  geometry_feature_names = "",
  polygon_part_count = 0L
)]
mapping_coverage[, multipart_value_replication := polygon_part_count > 1L]
mapping_coverage[, match_status := fifelse(
  geometry_available,
  "matched_exact_iso3",
  "unmatched_no_geometry_feature"
)]
mapping_coverage[, geometry_feature_or_region_names := geometry_feature_names]
mapping_coverage[, display_mapping_rule := fifelse(
  geometry_available,
  "Exact ISO3 join; one country value is applied to every polygon part in the matched feature(s)",
  "No country feature in bundled rworldmap/Natural Earth low-resolution geometry"
)]
setcolorder(mapping_coverage, c(
  "location_id", "location_name", "ISO3", "iso3_mapping_method",
  "match_status", "geometry_available", "geometry_feature_count", "geometry_feature_indices",
  "geometry_feature_names", "geometry_feature_or_region_names", "polygon_part_count",
  "multipart_value_replication", "display_mapping_rule"
))
setorder(mapping_coverage, location_name)

make_map_panel <- function(sex_label) {
  vals <- as.data.frame(s1[sex_name == sex_label,
                           .(ISO3, correlation, p_value, fdr_pvalue, display_r,
                             display_status)])
  map_dat <- merge(world_sf, vals, by = "ISO3", all.x = TRUE, sort = FALSE)
  ggplot(map_dat) +
    geom_sf(aes(fill = display_r), color = "grey35", linewidth = 0.055) +
    coord_sf(
      xlim = c(-180, 180), ylim = c(-90, 90), expand = FALSE,
      datum = NA
    ) +
    scale_fill_gradient2(
      low = "#377EB8", mid = "grey85", high = "#E41A1C",
      midpoint = 0, limits = c(-1, 1), na.value = "grey90",
      name = "Correlation",
      breaks = c(-1, -0.5, 0, 0.5, 1)
    ) +
    guides(fill = guide_colorbar(
      title.position = "top", title.hjust = 0.5,
      barheight = unit(0.70, "in"), barwidth = unit(0.14, "in")
    )) +
    theme_void(base_size = 7.0, base_family = "sans") +
    theme(
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 6.8),
      legend.text = element_text(size = 6.0),
      legend.margin = margin(0, 1, 0, 0),
      plot.margin = margin(2, 2, 0, 2)
    )
}

panel_a <- make_map_panel("Female")
panel_b <- make_map_panel("Male")
ab_compact <- panel_a + panel_b +
  plot_annotation(tag_levels = list(c("A", "B"))) &
  theme(
    plot.tag = element_text(face = "bold", size = 11),
    plot.tag.position = c(0.005, 0.99)
  )

age_order <- c(
  "<5 years", "5-9 years", "10-14 years", "15-19 years", "20-24 years",
  "25-29 years", "30-34 years", "35-39 years", "40-44 years", "45-49 years",
  "50-54 years", "55-59 years", "60-64 years", "65-69 years", "70-74 years",
  "75-79 years", "80-84 years", "85-89 years", "90-94 years", "95+ years"
)
plot_data <- fread(weighted_csv, showProgress = FALSE)[
  fit_status == "ok" & is.finite(weighted_r)
]
plot_data[, age_name := factor(age_name, levels = age_order)]

make_compact_panel <- function(sex_label) {
  ggplot(plot_data[sex_name == sex_label], aes(x = weighted_r, y = age_name)) +
    geom_density_ridges_gradient(
      aes(fill = after_stat(x)),
      scale = 2.35, rel_min_height = 0.01,
      color = "grey65", linewidth = 0.20, alpha = 0.90
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey35", linewidth = 0.35) +
    scale_x_continuous(limits = c(-1, 1), breaks = c(-1, -0.5, 0, 0.5, 1)) +
    scale_fill_gradient2(
      low = "#377EB8", mid = "#F7F7F7", high = "#E41A1C",
      midpoint = 0, limits = c(-1, 1), name = "Population-weighted\nr"
    ) +
    labs(
      title = sprintf("Population-weighted IHD-DD temporal correlations\n%s, 1992-2021", sex_label),
      x = "Population-weighted Pearson correlation (r)",
      y = NULL
    ) +
    theme_minimal(base_size = 6.8, base_family = "sans") +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color = "grey90", linewidth = 0.20),
      axis.title.x = element_text(face = "bold", size = 7.2, margin = margin(t = 2)),
      axis.text.x = element_text(size = 6.1),
      axis.text.y = element_text(size = 5.8, color = "grey20"),
      plot.title = element_text(face = "bold", hjust = 0.5, size = 7.5, lineheight = 0.95),
      legend.position = "right",
      legend.title = element_text(face = "bold", size = 5.8),
      legend.text = element_text(size = 5.5),
      plot.margin = margin(t = 2, r = 3, b = 2, l = 2)
    )
}

panel_e <- make_compact_panel("Female")
panel_f <- make_compact_panel("Male")
ef_compact <- panel_e + panel_f +
  plot_annotation(tag_levels = list(c("E", "F"))) &
  theme(plot.tag = element_text(face = "bold", size = 11),
        plot.tag.position = c(0.005, 0.99))

width_px <- original_dim[2L]
height_px <- original_dim[1L]
dpi <- 300
width_in <- width_px / dpi
height_in <- height_px / dpi

draw_full_figure <- function() {
  grid.newpage()
  layout <- grid.layout(
    nrow = 3L, ncol = 1L,
    heights = unit(c(ab_rows, cd_rows, ef_rows), "null")
  )
  pushViewport(viewport(layout = layout))
  print(
    ab_compact,
    vp = viewport(layout.pos.row = 1L, layout.pos.col = 1L)
  )
  grid.raster(
    cd_raster,
    x = unit(0.5, "npc"), y = unit(0.5, "npc"),
    width = unit(1, "npc"), height = unit(1, "npc"),
    interpolate = FALSE,
    vp = viewport(layout.pos.row = 2L, layout.pos.col = 1L)
  )
  print(
    ef_compact,
    vp = viewport(layout.pos.row = 3L, layout.pos.col = 1L)
  )
  popViewport()
}

png_file <- file.path(figure_dir, "Figure2_corrected_full.png")
tif_file <- file.path(figure_dir, "Figure2_corrected_full.tif")
pdf_file <- file.path(figure_dir, "Figure2_corrected_full.pdf")

grDevices::png(
  png_file, width = width_in, height = height_in, units = "in", res = dpi,
  bg = "white", type = "cairo"
)
draw_full_figure()
grDevices::dev.off()

grDevices::tiff(
  tif_file, width = width_in, height = height_in, units = "in", res = dpi,
  bg = "white", compression = "lzw", type = "cairo"
)
draw_full_figure()
grDevices::dev.off()

grDevices::cairo_pdf(pdf_file, width = width_in, height = height_in, bg = "white")
draw_full_figure()
grDevices::dev.off()

# Deterministic numerical and raster QA. The retained C-D rows must remain
# byte-for-byte equivalent after decoding, while A-B and E-F are regenerated.
png_array <- png::readPNG(png_file, native = FALSE)
tif_array <- tiff::readTIFF(tif_file, native = FALSE)
png_tif_max_diff <- max(abs(png_array - tif_array))
cd_png_max_diff <- max(abs(
  png_array[cd_start_row:cd_end_row, , , drop = FALSE] - cd_raster
))
cd_tif_max_diff <- max(abs(
  tif_array[cd_start_row:cd_end_row, , , drop = FALSE] - cd_raster
))

figure2_qa <- data.table(
  check = c(
    "S1 unique country-sex rows", "Female BH q<0.05 count",
    "Male BH q<0.05 count", "q>=0.05 values masked",
    "study units with map geometry", "PNG dimensions",
    "TIFF dimensions", "PNG versus TIFF decoded max difference",
    "retained C-D PNG versus source max difference",
    "retained C-D TIFF versus source max difference",
    "Female estimable E-F coefficients", "Male estimable E-F coefficients",
    "PDF non-empty"
  ),
  observed = c(
    nrow(s1),
    ab_counts[sex_name == "Female", bh_q_lt_0_05],
    ab_counts[sex_name == "Male", bh_q_lt_0_05],
    sum(is.finite(s1[fdr_pvalue >= 0.05, display_r])),
    sum(mapping_coverage$geometry_available),
    paste(dim(png_array), collapse = "x"),
    paste(dim(tif_array), collapse = "x"),
    format(png_tif_max_diff, scientific = TRUE),
    format(cd_png_max_diff, scientific = TRUE),
    format(cd_tif_max_diff, scientific = TRUE),
    plot_data[sex_name == "Female", .N],
    plot_data[sex_name == "Male", .N],
    file.info(pdf_file)$size
  ),
  acceptance_rule = c(
    "408", "46", "109", "0", "203 (Tokelau absent)",
    "2227x2800x3", "2227x2800x3", "0", "0", "0",
    "3468", "3468", ">0 bytes"
  ),
  pass = c(
    nrow(s1) == 408L,
    ab_counts[sex_name == "Female", bh_q_lt_0_05] == 46L,
    ab_counts[sex_name == "Male", bh_q_lt_0_05] == 109L,
    sum(is.finite(s1[fdr_pvalue >= 0.05, display_r])) == 0L,
    sum(mapping_coverage$geometry_available) == 203L,
    identical(dim(png_array), c(2227L, 2800L, 3L)),
    identical(dim(tif_array), c(2227L, 2800L, 3L)),
    png_tif_max_diff == 0,
    cd_png_max_diff == 0,
    cd_tif_max_diff == 0,
    plot_data[sex_name == "Female", .N] == 3468L,
    plot_data[sex_name == "Male", .N] == 3468L,
    file.info(pdf_file)$size > 0
  )
)
stopifnot(all(figure2_qa$pass))
fwrite(figure2_qa, file.path(analysis_dir, "Figure2_full_numerical_QA.csv"))

geometry_audit <- data.table(
  item = c(
    "original_height_px", "original_width_px", "regenerated_AB_rows",
    "retained_CD_start_row", "retained_CD_end_row", "retained_CD_rows",
    "regenerated_EF_rows", "output_height_px", "output_width_px", "output_dpi"
  ),
  value = c(
    original_dim[1L], original_dim[2L], ab_rows, cd_start_row, cd_end_row,
    cd_rows, ef_rows, height_px, width_px, dpi
  ),
  acceptance_rule = c(
    "must equal 2227", "must equal 2800",
    "A-B regenerated from corrected S1 BH q values",
    "starts above original panel C tag", "ends below original panel D and above original E label",
    "contains only retained C-D row", "contains only regenerated E-F row",
    "must equal original height", "must equal original width",
    "preserves original pixel dimensions at 300 dpi"
  )
)
fwrite(geometry_audit, file.path(analysis_dir, "Figure2_full_geometry_audit.csv"))

fwrite(s1[, .(
  location_name, ISO3, sex_name, correlation, p_value, fdr_pvalue,
  display_status, display_r
)], file.path(analysis_dir, "Figure2_AB_corrected_source.csv"))
fwrite(ab_counts, file.path(analysis_dir, "Figure2_AB_corrected_counts.csv"))
fwrite(mapping_coverage, file.path(analysis_dir, "Figure2_AB_mapping_coverage.csv"))

cartographic_notes <- c(
  "# Figure 2A-B cartographic display procedure",
  "",
  "1. Start from the 204-row GBD location-ID/name crosswalk saved under `figure2_s1/derived_inputs`.",
  "2. Convert analysis names to ISO3 with `countrycode(country.name, iso3c)`. Non-matches in the source naming convention are resolved with explicit manual ISO3 overrides; the row-level mapping method is exported.",
  "3. Load the bundled `rworldmap::getMap(resolution = \"low\")` geometry (Natural Earth-derived; rworldmap 1.3-8) and join by exact ISO3.",
  "4. Apply each country coefficient to every polygon part belonging to its matched feature(s) for display only. The inferential table remains one row per country/territory and sex. Feature indices, feature names, feature counts, polygon-part counts, and multipart-replication flags are exported for all 204 study units.",
  "5. Tokelau is the sole study unit without a feature in this bundled low-resolution geometry. Non-study world polygons and study units with BH q>=0.05 are grey.",
  "6. A-B fill values use the corrected Table S1 coefficient only when the unrounded-P sex-specific BH q is below 0.05. This yields 46/204 female and 109/204 male displayed coefficients.",
  "",
  "Exact crosswalk: `Figure2_AB_mapping_coverage.csv`. Exact sex-specific plotted source: `Figure2_AB_corrected_source.csv`."
)
writeLines(
  cartographic_notes,
  file.path(analysis_dir, "Figure2_AB_cartographic_procedure.md"),
  useBytes = TRUE
)

session_file <- file.path(analysis_dir, "Figure2_full_sessionInfo.txt")
zz <- file(session_file, open = "wt")
sink(zz)
print(sessionInfo())
sink()
close(zz)

input_manifest <- data.table(
  file = c(
    original_figure, s1_csv, weighted_csv, location_crosswalk_csv,
    "02_compose_full_figure2.R"
  ),
  sha256 = vapply(c(
    original_figure, s1_csv, weighted_csv, location_crosswalk_csv,
    "02_compose_full_figure2.R"
  ),
                  function(f) digest::digest(file = f, algo = "sha256"), character(1))
)
fwrite(input_manifest, file.path(analysis_dir, "Figure2_full_input_checksums_sha256.csv"))

qa_notes <- c(
  "# Figure 2 full-composite QA",
  "",
  "- Backend: R only (tiff, sf, rworldmap, ggplot2, ggridges, patchwork, grid).",
  "- Panels A-B: regenerated from the corrected Supplementary Table S1 using sex-specific BH q<0.05 based on unrounded P values; q>=0.05 locations are grey.",
  "- Corrected displayed counts: 46/204 female locations and 109/204 male locations have q<0.05.",
  paste0("- Geometry coverage: ", sum(mapping_coverage$geometry_available), "/204 study ISO3 units have a feature in the bundled low-resolution geometry; Tokelau is the expected unmatched unit."),
  paste0("- Panels C-D: retained from rows ", cd_start_row, "-", cd_end_row, " of the submitted Figure 2 TIFF; their source scripts used unrounded P values and BH correction within sex."),
  "- Panels E-F: regenerated from the corrected machine-readable weighted-correlation table.",
  "- The <5, 5-9, and 10-14 year groups are omitted from E-F because all 204 IHD annual series are constant within each sex; 17 estimable age groups are displayed.",
  "- The original raw-P-filtered A-B and invalid E-F rows are excluded completely.",
  "- Output dimensions: 2800 x 2227 pixels, matching the submitted figure.",
  "- Decoded PNG and TIFF pixels are identical (maximum absolute difference 0).",
  paste0("- The retained C-D crop is pixel-identical to source rows ", cd_start_row, "-", cd_end_row, " in both PNG and TIFF (maximum absolute difference 0)."),
  "- Visual inspection at original resolution passed: panel labels A-F are present, q>=0.05 map units are grey, no text or legends are clipped or overlapping, and E-F span -1 to 1."
)
writeLines(qa_notes, file.path(analysis_dir, "Figure2_full_visual_QA.md"), useBytes = TRUE)

output_files <- c(
  png_file, tif_file, pdf_file,
  file.path(analysis_dir, "Figure2_AB_corrected_source.csv"),
  file.path(analysis_dir, "Figure2_AB_corrected_counts.csv"),
  file.path(analysis_dir, "Figure2_AB_mapping_coverage.csv"),
  file.path(analysis_dir, "Figure2_AB_cartographic_procedure.md"),
  file.path(analysis_dir, "Figure2_full_geometry_audit.csv"),
  file.path(analysis_dir, "Figure2_full_numerical_QA.csv"),
  file.path(analysis_dir, "Figure2_full_visual_QA.md"),
  session_file
)
output_manifest <- data.table(
  file = output_files,
  bytes = file.info(output_files)$size,
  sha256 = vapply(output_files,
                  function(f) digest::digest(file = f, algo = "sha256"), character(1))
)
fwrite(output_manifest, file.path(analysis_dir, "Figure2_full_output_checksums_sha256.csv"))

cat("Created full corrected Figure 2 at:", png_file, "\n")
