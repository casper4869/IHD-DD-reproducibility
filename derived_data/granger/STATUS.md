# Scope of the temporal-precedence files

Most files in this directory document a **post-submission internal methodological audit and sensitivity analysis**. The `archived_main_reconstruction/` subdirectory is different: it contains the offline numerical reconstruction and interpretation audit of the submitted three-variable VAR. Neither group replaces the manuscript's Figure 5.

The authoritative manuscript artwork is `../../figures/Figure5.tif`, an exact copy of the originally submitted TIFF. The two-map Newey-West/HC3 display is stored separately under `../../figures/internal_audit_not_for_submission/`.

Terms such as `primary`, `corrected`, or `Figure5_corrected` inside preserved execution outputs refer only to specifications and filenames used during that internal audit. They do not mean that the audit result is the manuscript's primary analysis or approved replacement figure. The large Newey-West/HC3 difference is retained as a sensitivity finding and should not be interpreted as a stable predominant direction.

For the submitted main analysis, the archived `IHD_to_DD` and `DD_to_IHD` column names are retained for exact numerical comparison only. Each is a joint system test across both remaining equations, as documented in `../../code/granger/README.md` and `../../reports/granger_archived_main_reconstruction.md`.

`submitted_system_test_small_island_exclusion.csv` and its counts file are the 159-location sensitivity for those submitted joint system tests. They reapply the two BH families after the prespecified 45-unit exclusion without refitting the VAR. The retained counts are 71 both labelled families, 13 IHD-labelled only, 60 DD-labelled only, and 15 neither.
