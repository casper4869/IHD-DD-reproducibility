# Figure 6 visual and numerical QA

- Core conclusion: adjusted local country-level IHD-DD associations vary geographically and include positive and negative coefficients.
- Archetype: two vertically stacked coordinate-based point maps, retaining the submitted figure's evidence form.
- Backend: R only (ggplot2, maps, patchwork, svglite, cairo_pdf, ragg).
- Source rows: 408 (204 countries/territories in each direction).
- Every study unit is displayed once at its recorded representative coordinate; multipart polygons do not duplicate analytical observations.
- Shared symmetric colour limit: ±1.7; observed range -1.607 to 1.045.
- Submitted ±1 scale would truncate 1 estimates in panel A and 11 estimates in panel B; the revised figure truncates none.
- Panel A beta range: -0.382 to 1.045; median 0.073.
- Panel B beta range: -1.607 to 0.757; median 0.177.
- TIFF dimensions: 4322 x 3685 pixels at 600 dpi target.
- PDF and SVG retain vector geometry and editable text.
- Direction is encoded redundantly by blue/negative and red/positive labels around a neutral zero midpoint.
- Interpretation guardrail: these are adjusted 2021 cross-sectional GWR coefficients, not causal estimates.
