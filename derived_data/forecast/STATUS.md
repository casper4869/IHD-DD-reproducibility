# Forecast and Figure 4 status

The main manuscript Figure 4 is now the minimal R redraw in `../../figures/Figure4.tif`, with matching PDF, PNG, and SVG exports. Panel A retains the archived VARX trajectory and panel B retains the archived ARIMAX trajectory. The 1992–2021 historical sequence is identical across panels, and the archived 2030 endpoints are 19 and 14.

The exact 78-row plotting table is `results/Figure4_minimal_source.csv`. `../../code/forecast/02_draw_figure4_minimal.R` renders it without model refitting. `qa/Figure4_minimal_QA_REPORT.md`, `qa/Figure4_minimal_QA_checks.csv`, and the checksum tables document the numerical and visual gates. The TIFF is 4322 × 1842 pixels, RGB/LZW, at 600 dpi; the SVG retains editable text.

The main figure contains no long title, subtitle, legend, prose annotation, endpoint callout, or uncertainty ribbon. The submitted ±15% heuristic envelope was not a model-derived 95% interval and is omitted. The caption explains the panel/model mapping, visual encodings, model assumptions, archived endpoints, and unquantified forecast uncertainty.

The original submitted Figure 4 remains under `../../figures/original_submitted_not_for_resubmission/` for provenance. The extra common-scale display remains under `../../figures/internal_audit_not_for_submission/`; its VARX count becomes unavailable from 2026 because of non-finite forecasts and is not a manuscript result.

The current raw-scale ARIMAX rerun yields 13 countries in 2030, while the archived classification and submitted figure yield 14. The main redraw transparently locks the archived trajectory; the 13-country rerun and 15-country log-scale sensitivity remain documented in the internal forecast audit.
