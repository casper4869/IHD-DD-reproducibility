# Figure 4 minimal redraw — QA report

Date: 2026-09-20  
Status: **PASS — packaged as the revised Figure 4 in release v1.0.1.**

## Figure contract

- Core conclusion: the archived VARX and ARIMAX analyses give different projected trajectories after the same 1992–2021 historical series.
- Evidence structure: panel **A** shows the archived VARX trajectory; panel **B** shows the archived ARIMAX trajectory.
- Archetype: two-panel quantitative comparison.
- Backend: R only for drawing, previewing, and all raster/vector exports.
- Export size: 183 × 78 mm; TIFF at 600 dpi; PNG preview at 300 dpi; editable SVG and PDF supplied.

## Original materials located

The archived analysis folder contains the original model/plot scripts `GBD_7_1.R` (VARX) and `GBD_7_2.R` (ARIMAX), plus the IHD, DD, and SDI 1992–2021 country matrices. File identities are recorded in `Figure4_minimal_source_provenance_checksums.csv`.

## Source-data lock

`Figure4_minimal_source.csv` contains the exact plotted annual counts. The historical sequence is identical in both panels for every year from 1992 through 2021.

- VARX projections for 2022–2030: **17, 16, 21, 19, 20, 18, 19, 20, 19**.
- ARIMAX projections for 2022–2030: **15, 14, 14, 14, 15, 14, 14, 14, 14**.
- Archived endpoints retained: **VARX = 19** and **ARIMAX = 14** in 2030.

The archived ARIMAX classification file contains 14 high–high countries in 2030 and the submitted panel labels the endpoint as 14, whereas the current rerun gives 13. The retained materials do not determine the cause of this difference; unrecorded software or model-selection state is one possible explanation. This redraw therefore locks the submitted/archived value of 14, transparently discloses the current rerun value of 13, and does not refit or replace the submitted result.

## Visual simplification

The redraw removes the long title, subtitle, duplicate legend, baseline text, trend arrow, “Forecast Period” label, “95% Confidence Interval” label, endpoint circles/numbers, and the heuristic ±15% ribbon. The ribbon was not a model-derived confidence or prediction interval. Its removal and the visual encodings are explained in `../Figure4_minimal_caption.txt`.

The only text inside the SVG is:

`A`, `B`, `Year`, `High-high countries (n)`, and the axis tick labels `10`, `15`, `20`, `1992`, `2000`, `2010`, `2021`, `2030`.

The unlabelled grey dashed line at 2021.5 separates the historical and projection periods. Historical values use cyan solid lines/circles; projected values use red dashed lines/triangles. Both panels use the same x and y ranges.

## Automated checks

All checks in `Figure4_minimal_QA_checks.csv` passed:

- R-only rendering.
- Uppercase A/B panel labels.
- Identical historical series in A and B.
- 2030 endpoints equal 19 and 14.
- No model name, title, subtitle, legend, or prose annotation inside the panel.
- Divider contains no text.
- Common axis ranges.
- Editable SVG text.
- Complete TIFF/PNG/PDF/SVG export bundle.

## Export validation

- TIFF: **4322 × 1842 px**, RGB, LZW compression, **600 × 600 dpi**.
- PNG: **2161 × 921 px**, 300 dpi preview dimensions.
- SVG: text remains text; the exact text whitelist above was verified.
- Visual inspection: no clipping, overlap, missing line segment, or illegible tick label was found.

SHA-256 values and byte sizes for the original inputs are in `Figure4_minimal_source_provenance_checksums.csv`; package-path hashes for the scripts, source table, QA, four main exports, and preserved original artwork are in `Figure4_minimal_release_checksums.csv`.
