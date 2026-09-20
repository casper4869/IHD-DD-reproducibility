# Exploratory OpenGWAS screen: scope, provenance, and reporting flow

## What was screened

This was an exploratory, catalogue-wide screen within a prespecified technical ancestry scope. The authors did **not** manually select or reject traits according to their names, clinical plausibility, expected direction, statistical result, or perceived relevance to ischaemic heart disease (IHD) or depressive disorders (DD).

The fixed outcomes were:

- IHD: `finn-b-I9_IHD`
- DD: `finn-b-F5_DEPRESSIO`

The catalogue-to-reporting flow was:

| Stage | Count | Meaning |
|---|---:|---|
| Historical OpenGWAS catalogue snapshot | 15,703 | Metadata records returned by `TwoSampleMR::available_outcomes()` and cached as `ao.csv`; this is not the number of completed MR analyses. |
| European-ancestry catalogue scope | 11,989 | Records with `population == "European"`. |
| Exposure jobs scheduled per outcome | 11,988 | The target outcome itself was not scheduled as its own exposure. The stored `eqtl-a-*` rule matched zero records in this snapshot. IDs were sorted before scheduling. |
| Saved IHD aggregate estimates | 5,880 | Results preserved against `finn-b-I9_IHD`. |
| Saved DD aggregate estimates | 11,775 | Results preserved against `finn-b-F5_DEPRESSIO`. |
| Set A | 49 | Both outcome-specific BH q values below 0.05, concordant non-zero directions, and IVW recorded for both outcomes. |
| Set B, final Table 1/Figure 7 set | 29 | Set A after removing 20 exposures with `finn-b-*` IDs to reduce participant-overlap and same-biobank dependence because both outcomes were FinnGen datasets. Set B contains 20 concordant-positive and 9 concordant-negative traits. |

The FinnGen restriction was applied **after** the exploratory screen. It is a reporting safeguard for this analysis, not a general rule that MR exposure and outcome GWAS must always come from different databases.

## Catalogue snapshot and cache behaviour

The historical code created `ao.csv` by calling `available_outcomes()` when the file was absent and then writing the complete returned catalogue. When `ao.csv` already existed, later runs loaded that cached snapshot instead of requesting the catalogue again. Therefore, the 15,703 records describe the preserved snapshot, and a current call may return a different catalogue.

`code/mr/00_catalogue_snapshot_provenance.R` validates the packaged snapshot offline by default. A refresh is neither required nor appropriate for reproducing the historical analysis. The script permits a single deliberate refresh only when explicitly enabled, writes to a new path, refuses to overwrite the historical file, does not retry automatically, and reads `OPENGWAS_JWT` only from the user's environment.

## Technical scope versus phenotype selection

The technical scheduling rules were:

1. retain catalogue records labelled `European`;
2. apply the stored `eqtl-a-*` technical-class rule;
3. do not schedule the target outcome as its own exposure;
4. sort the remaining GWAS IDs;
5. schedule each remaining ID as an exposure against the fixed outcome.

These rules define the ancestry and data-class scope. They are not a phenotype-level inclusion/exclusion review. No trait was manually screened out before analysis because it appeared implausible, non-modifiable, downstream, medication-related, or statistically inconvenient.

The complete `derived_data/mr/manifest/01_gwas_catalog_manifest_15703.csv` therefore uses the terms `technical_scope_status` and outcome-specific `*_scheduling_status`. For scheduled records without a preserved result, the status is `no saved estimate; exact reason not recorded`. The archive does not convert missing files into inferred biological or technical failure reasons.

## Candidate-set interpretation

Set A is the agnostic exploratory result set. Set B is the manuscript's primary reporting set after the post-screen `finn-b-*` safeguard. Traits are described as **shared genetically associated traits**. Medication codes, diagnoses, health-status variables, and other downstream clinical markers are not automatically interpreted as upstream modifiable causes.

Set C (18 traits) is supplied only as a descriptive sensitivity set after removing 11 obvious downstream/code-like markers from Set B. It is not a hidden pre-screening step and does not replace the 29-trait primary reporting set.

## Historical runner provenance

Offline filename, row-index, outcome-ID, method, and aggregate-value fingerprints support the following reconstruction, but do not prove the exact historical executable snapshot:

- the DD results are consistent with the self-developed `find_exposure` code family in its saved DD configuration;
- the IHD results are consistent with an earlier IHD-configured version of that same code family;
- the exact earlier IHD-configured script text was not retained, so the current DD-configured file must not be presented as an exact byte-for-byte IHD runner;
- the alternative Grok script has incompatible output fingerprints: its start index, filename convention, local-PLINK workflow, and fixed T2D outcome do not match the preserved files;
- the `find outcome` script reverses the analytical direction and likewise has incompatible fingerprints for these exposure-screen folders.

The retained DD aggregate run does not reproduce the DD values in the superseded 50-row manuscript table. It is described only as a different preserved run, without making an unsupported claim about whether it occurred before or after journal submission.

## OpenGWAS access rule

All primary reconstruction and final reporting steps in this repository are offline. The historical catalogue-wide job should not be replayed merely to inspect or verify the archived results.

The optional `code/mr/opengwas_sensitivity_rerun_RATE_LIMITED.R` is limited to the final 29 candidates, disabled by default, sequential, cached, resumable, and paced with a default 90-second interval plus jitter and a hard minimum of 60 seconds between top-level operations. It stops on allowance or HTTP 429 signals. It must not be parallelised or used as a crawler. Provider terms and current allowance documentation govern any future run. Tokens must remain in the user's environment and must never be committed, logged, archived, or pasted into an issue.
