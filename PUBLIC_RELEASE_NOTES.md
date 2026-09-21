# Public release notes — v1.1.0

Version `v1.1.0` supersedes `v1.0.1` for the manuscript revision.

## Added

1. Completed instrument-level sensitivity follow-up for the locked final 29 Figure 7 traits against IHD and DD: 58 pairs and 232 estimator results covering IVW, MR-Egger, weighted median and weighted mode.
2. Heterogeneity, Egger-intercept, instrument-strength, I2GX, single-SNP, leave-one-out and MR-PRESSO outputs, together with validation records and cached analytical inputs.
3. `documents/Supplementary_Data_S2_MR_sensitivity.xlsx` and the self-contained `Supplementary_Data_S3_MR_outputs_and_code.zip`; the latter is also unpacked under `mr_sensitivity_29/` for browsing.
4. Parameterised GBD preprocessing from authorised IHD/DD Incidence-Rate downloads to the 204-location, 1992–2021 matrices and age-sex inputs used downstream. Comparison against retained analysis inputs is exact at display precision and within CSV precision at full precision.
5. Updated documentation distinguishing the historical aggregate discovery reconstruction from the current targeted sensitivity follow-up.

## Interpretation and access safeguards

The MR analysis remains exploratory. The targeted follow-up does not recreate the unavailable historical DD SNP objects behind the withdrawn table, does not redefine the discovery family, and does not remove traits on the basis of sensitivity results. Online acquisition code is disabled by default, sequential, cached, rate-limited and stops on provider allowance or HTTP 429 signals. Credentials, signed URLs and complete source VCFs are excluded. GBD and GWAS source data remain subject to provider terms.

Repository: https://github.com/casper4869/IHD-DD-reproducibility
GitHub release: https://github.com/casper4869/IHD-DD-reproducibility/releases/tag/v1.1.0
Version DOI: https://doi.org/10.5281/zenodo.22878656
Concept DOI: https://doi.org/10.5281/zenodo.22878655
