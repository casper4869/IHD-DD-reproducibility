# Internal audit figures — not for submission

Every file in this directory is a post-submission methodological audit or sensitivity display. None is the manuscript's Figure 4 or Figure 5.

- `Figure4_forecast_revision.*` compares the original forecast specification with a common-scale diagnostic sensitivity. In its second panel, the VARX count stops after 2025 because at least one country forecast is non-finite from 2026, so a complete 204-country count cannot be calculated. This is an audit result and is not part of the revised manuscript Figure 4.
- `Figure5_corrected.*` compares alternative Newey-West and HC3 implementations developed during code audit. The large difference between them shows specification sensitivity. This two-map audit display is not a replacement for the submitted single-state Figure 5.

The authoritative manuscript artwork is one directory above: the minimally redrawn `Figure4.*` exports and the submitted `Figure5.tif`. The original submitted Figure 4 is preserved separately under `../original_submitted_not_for_resubmission/`.
