# Figure 2A-B cartographic display procedure

1. Start from the 204-row GBD location-ID/name crosswalk saved under this component's `derived_inputs/` directory.
2. Convert analysis names to ISO3 with `countrycode(country.name, iso3c)`. Non-matches in the source naming convention are resolved with explicit manual ISO3 overrides; the row-level mapping method is exported.
3. Load the bundled `rworldmap::getMap(resolution = "low")` geometry (Natural Earth-derived; rworldmap 1.3-8) and join by exact ISO3.
4. Apply each country coefficient to every polygon part belonging to its matched feature(s) for display only. The inferential table remains one row per country/territory and sex. Feature indices, feature names, feature counts, polygon-part counts, and multipart-replication flags are exported for all 204 study units.
5. Tokelau is the sole study unit without a feature in this bundled low-resolution geometry. Non-study world polygons and study units with BH q>=0.05 are grey.
6. A-B fill values use the corrected Table S1 coefficient only when the unrounded-P sex-specific BH q is below 0.05. This yields 46/204 female and 109/204 male displayed coefficients.

Exact crosswalk: `Figure2_AB_mapping_coverage.csv`. Exact sex-specific plotted source: `Figure2_AB_corrected_source.csv`.
