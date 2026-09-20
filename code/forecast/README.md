# Forecast files and Figure 4

The authoritative manuscript Figure 4 is `../../figures/Figure4.tif`, with matching PDF, PNG, and SVG exports. It is an R-only minimal redraw of the archived trajectories: panel A is VARX, panel B is ARIMAX, the historical series is identical in both panels, and the archived 2030 endpoints remain 19 and 14. The graphic contains only uppercase panel labels, axes, ticks, curves, and an unlabelled historical/projection divider.

`01_build_source_data.R` documents how the locked plotting table was assembled from the archived annual counts and the archived ARIMAX 2030 classification. `02_draw_figure4_minimal.R` renders the supplied source table without refitting either model. The exact table is `../../derived_data/forecast/results/Figure4_minimal_source.csv`; QA and checksums are under `../../derived_data/forecast/qa/`.

Rebuild the four figure formats offline into a review directory:

```powershell
Rscript code/forecast/02_draw_figure4_minimal.R `
  derived_data/forecast/results/Figure4_minimal_source.csv `
  '<review-output-directory>/Figure4'
```

The source lock is deliberate. The submitted/archived ARIMAX classification and figure report 14 countries in 2030, whereas the current execution of the legacy `auto.arima` block yields 13. The retained materials do not determine why these values differ; unrecorded software or model-selection state is one possible explanation. The redraw preserves the archived manuscript trajectory and transparently discloses the current rerun value; it does not silently replace the analysis.

`run_forecast_revision.R`, `audit_archived_arimax.R`, and `prepare_forecast_report.R` remain a **post-submission internal audit and sensitivity workflow**. Their common-scale diagnostic display is stored under `../../figures/internal_audit_not_for_submission/`. Its VARX line stops after 2025 because at least one of 204 country forecasts is non-finite from 2026, so a complete-denominator count cannot be calculated. That audit panel is not the manuscript Figure 4.

The byte-identical original submitted Figure 4 is preserved for provenance under `../../figures/original_submitted_not_for_resubmission/` and must not be used for resubmission.
