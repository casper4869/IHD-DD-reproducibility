# Figure 5 visual and geometry QA

- Raster exports: 3600 x 2550 pixels at 300 dpi; vector PDF and SVG also exported.
- Both panels contain 204 coordinate points, including all 45 locations in the cartographic/SIDS sensitivity set.
- Panel A exploratory Newey-West counts: Bidirectional 1, IHD -> DD 0, DD -> IHD 182, Neither 21.
- Panel B counts: Bidirectional 0, IHD -> DD 0, DD -> IHD 11, Neither 193.
- The title and legend use temporal-prediction language; the caption explicitly rejects individual-level and mechanistic causal interpretation.
- The covariance-estimator sensitivity and diagnostic flags are printed in the figure rather than hidden in supplementary text.
- Visual inspection: no clipped maps, points, panel titles, legends, or caption; panel labels A-B are present; colors remain distinguishable against the pale basemap.
- Small islands are rendered as representative coordinate points, avoiding omission caused by low-resolution polygon geometry.
