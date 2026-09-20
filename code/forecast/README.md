# Scope of the forecast files

The scripts in this directory document a **post-submission internal audit and sensitivity analysis**. They do not define or replace the manuscript's Figure 4.

The authoritative manuscript artwork is `../../figures/Figure4.tif`, an exact copy of the originally submitted TIFF. The audit display is stored separately under `../../figures/internal_audit_not_for_submission/`.

In the audit display's common-scale panel, the blue VARX trajectory stops after 2025 because at least one of the 204 country forecasts is non-finite from 2026. The audit code therefore refuses to calculate a count with an incomplete denominator. This is a diagnostic result of the additional sensitivity specification; it is not missing data in the submitted Figure 4.

Files whose names contain `Figure4_legend`, `Figure4_source`, `forecast_revision`, or `manuscript_forecast_text` are preserved execution artifacts from that audit. The last name is historical and does not make the file approved manuscript text.
