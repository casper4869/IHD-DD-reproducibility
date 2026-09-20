# Figure roles

`Figure4.tif`, `Figure4.pdf`, `Figure4.png`, and `Figure4.svg` are the revised manuscript Figure 4. They are a minimal R redraw of the archived trajectories: panel A is VARX and panel B is ARIMAX; both retain the identical 1992–2021 historical series and the archived 2030 endpoints of 19 and 14. Titles, subtitles, legends, prose annotations, endpoint callouts, and the unsupported ±15% band have been removed from the graphic and explained in the manuscript legend. The source table, rendering script, QA report, and checksums are under `../derived_data/forecast/` and `../code/forecast/`.

`Figure5.tif` remains the byte-identical figure supplied with the original manuscript and is the manuscript Figure 5.

`original_submitted_not_for_resubmission/` preserves the original submitted Figure 4 for provenance only. It contains dense annotations and an ±15% heuristic band labelled as a 95% confidence interval; it must not be resubmitted as the revised figure.

`internal_audit_not_for_submission/` contains post-submission forecast and temporal-precedence sensitivity displays. These document revision checks, including the forecast sensitivity panel whose VARX line stops after 2025 when complete-denominator counts become unavailable. They are not manuscript figures and must not be submitted as Figure 4 or Figure 5.

`../manifests/figure4_figure5_roles_and_checksums.csv` records the role, byte count, and SHA-256 checksum of every Figure 4/5 artifact in this package.
