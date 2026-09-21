# Final MR recheck of the formal resubmission package

Scope: read-only inspection of the formal files in
`F:/GBD/1/_IHD&DD/10_返修文件_MR敏感性完成_2026-09-21/01_正式上传`.
No network access or new MR estimation was performed. Only this review report
was written. The agreed targeted scope is 29 traits × two outcomes = 58 pairs
(not 59).

## Independent checks on the actual delivered artifacts

- S1 Catalogue decisions contains 15,703 records. Recomputed BH directly from
  its p_for_bh values separately for all 11,988 scheduled IHD and 11,988 scheduled
  DD rows; every stored discovery q agrees to numerical tolerance.
- S1 Selected candidates contains exactly 29 non-finn-b exposure IDs. All selected
  OR, nominal P and discovery q values agree with S3 locked_candidates.csv.
- S2 contains 232 MR-estimator rows, 58 diagnostic rows and 58 historical
  comparison rows. Every sheet uses the same 29 locked exposure IDs.
- Table 1 has a header plus 29 rows, and every locked exposure ID is present.
- S3 contains exactly 58 numerical pair RDS files and 58 PRESSO RDS files.
  The previously completed independent full-output audit verified all 58 PRESSO
  results against their summary. No sensitivity-based removal/reselection of
  candidates or replacement of discovery q values was found.
- Figure 7's delivered caption explicitly distinguishes historical discovery
  -log10(q) from the current targeted sensitivity results. It describes all 29
  traits and the same Set A/Set B rules. This check validates data lineage and
  labeling; it does not infer numerical coordinates by reading raster pixels.

## Reviewer requirements: completed versus outstanding

### Completed substantive MR analyses for the agreed final-result scope

Reviewer 2's MR-Egger and weighted-median request has been implemented for all
58 final-trait pairs, including retained extreme-estimate phenotypes. Weighted
mode, Q, Egger intercept, F statistics, I2GX, single-SNP, leave-one-out, and PRESSO
global/outlier/distortion results are additionally supplied. There is no missing
estimator in this 58-pair set requiring a further catalogue-wide run merely to
complete the agreed sensitivity exercise.

Reviewer 1's extreme-OR concern is explicitly addressed. Doxazosin and
beclometasone failed the reconstructed shared-signal criteria and were removed;
this is explained using their recovered DD estimates. Sensitivity analysis is
provided for the extreme estimates that remain in the final 29 traits. The
response does not pretend the two removed drugs received new sensitivity runs.
No literal reviewer request requires them to remain in a withdrawn table.

### Explicit limitations, not missing mandatory targeted tests

- Steiger was not explicitly requested by either reviewer and is not claimed as
  completed. Missing validated prevalence/effect-scale inputs and conflicting
  upstream metadata justify the documented non-estimation. It does not warrant
  applying an inappropriate continuous-trait fallback.
- Restricting sensitivity to selected final traits is transparent. This is not
  independent replication or validation of all screened results. Reviewers may
  judge the scope, but there is no stated requirement to run every sensitivity
  estimator across the entire 15,703-record catalogue.
- All I2GX values are below 0.90, heterogeneity is frequent, and weighted-mode
  support is limited. These limit causal conclusions despite complete execution;
  additional methods such as SIMEX are not explicitly demanded by the reviews.
- Removing FinnGen exposure records reduces the most obvious same-biobank
  overlap; it does not prove all remaining exposure-outcome samples independent.
  The manuscript and response explicitly acknowledge this distinction.
- The historical IHD threshold is unverified; the P<5e-8 count resemblance is a
  clue, not proof. Current common-threshold 5e-6 analyses are separated from
  historical discovery values and should remain so.

### Reproducibility requirement is not made fully recoverable by publication

Reviewer 1's request for complete historical inputs/code and independent
verification remains only partially achievable. Historical IHD executable
configuration and SNP objects, original missing-output reasons, and the earlier
DD run underlying the withdrawn submitted table remain unavailable. Their
absence is disclosed rather than fabricated. Publishing an archive does not
recover them. The available reconstructed discovery and current targeted
analyses can be audited, but that is not identical to full reproduction of the
original submitted screen.

Public GitHub/Zenodo release with a verified permanent DOI remains an actual
pending deliverable. Whether the documented historical limitations sufficiently
address the broader reviewer demand is an editorial judgement, not something
that a successful deposit alone establishes.

## S3 offline reproduction prerequisites

- Use the documented R/package versions and a writable unpacked directory (or
  MR_SENSITIVITY_DIR). Bundled input and pair/PRESSO caches support offline output
  reconstruction; use a fresh directory for fresh computation as documented.
- Run the core analysis, all three validation scripts, PRESSO, finalisation,
  summary and SNP export in the README order. Existing pair results are cached.
- The earlier portable-helper/signature mismatch was corrected and independently
  rechecked. Current signatures bind the stored harmonised input, candidate set,
  parameters and implementation files. The ZIP and manifest checks passed.
- Python >=3.11 is required only for the supplied optional VCF extraction code.
  Optional online retrieval is disabled by default, sequential, cached, at least
  95 seconds apart, and persists HTTP 429 Retry-After blocking across restarts.
  No credentials, temporary signed URLs or full source VCFs are in S3.

## Heading check

Plain-text extraction appeared to join the exploratory-screen heading and body.
Inspection of the actual OOXML confirmed an explicit w:br line break after the
bold heading. The apparent concatenation was an extraction artifact, not a
document defect. No correction is requested.

## Conclusion

Within the agreed final-29-trait scope, the requested substantive sensitivity
analyses are complete and internally consistent. No additional mandatory MR
run was identified. The honest next-step description is: finalize
publication/DOI, while retaining explicit irrecoverable historical
reproducibility limitations. Do not describe those limitations as solved by
archiving, or promise that every reviewer requirement is unconditionally met.
