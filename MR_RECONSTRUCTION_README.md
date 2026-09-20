# Exploratory MR reconstruction and reproducibility record

## Scope

This package reconstructs the manuscript's catalogue-wide two-sample MR component from the preserved IEU OpenGWAS catalogue snapshot and saved aggregate result files. The analysis is exploratory and hypothesis-generating. Traits were not manually pre-selected or rejected according to phenotype name, clinical plausibility, expected direction, modifiability, or result. It does not turn screening associations into confirmed causal effects.

The revised Table 1 and Figure 7 use a traceable 29-candidate set derived from the retained IHD and DD aggregate runs. The former 50-row table is not retained as the primary result because the exact DD run used for those rows is unavailable and its DD estimates are not reproduced by the preserved DD aggregate run. The evidence establishes that the preserved run differs from the old-table run; it does not establish the date of either run relative to journal submission.

## What is included

### Catalogue and compact aggregate source files

- `source_data/mr/ao.csv`: 15,703 unique OpenGWAS catalogue records returned by `TwoSampleMR::available_outcomes()` and then cached locally. This is a dated catalogue snapshot, not 15,703 completed MR analyses.
- `source_data/mr/IHD/bb.csv`: 5,880 saved aggregate estimates against `finn-b-I9_IHD`.
- `source_data/mr/DD/bb.csv`: 11,775 saved aggregate estimates against `finn-b-F5_DEPRESSIO`.
- `source_data/mr/IHD/END.csv` and `source_data/mr/DD/END.csv`: companion retained result subsets from the historical workflow.

The two `bb.csv` files are exact compact concatenations of the numbered one-row result files. The offline audit verified matching exposure IDs, outcome IDs, numeric estimates, methods, and instrument-count fields. The 17,655 redundant numbered result files are therefore not copied into this package. `derived_data/mr/manifest/07_input_sha256.csv` preserves byte counts and SHA-256 values for all 17,666 source files, including every numbered result file and the historical scripts.

### Offline scripts

- `code/mr/00_catalogue_snapshot_provenance.R`: validates the included catalogue offline by default; its explicitly enabled refresh mode makes one catalogue request to a new file and never overwrites the historical snapshot.
- `code/mr/01_build_exploratory_mr_audit.R`: reconstructs the catalogue-to-analysis status manifest and cross-checks retained one-row files against the compact aggregates. The executed historical audit used the full local source directory; the generated outputs and complete source hashes are included here. The public package does not duplicate the 17,655 numbered files.
- `code/mr/alternative_sets/build_alternative_mr_sets.py`: derives Sets A-C from the packaged catalogue and saved aggregate results without a network request.
- `code/mr/02_build_final_mr_reporting.R`: verifies Set B and creates the final 29-candidate reporting tables and Figure 7 source/exports. This script is fully offline when supplied with the included Set B CSV.
- `code/mr/opengwas_sensitivity_rerun_RATE_LIMITED.R`: optional future instrument-level sensitivity workflow. It was not executed for this revision and is disabled by default.

### Generated evidence

- `derived_data/mr/manifest/01_gwas_catalog_manifest_15703.csv`: full 15,703-row catalogue-to-analysis status manifest. Its `technical_scope_status` and `*_scheduling_status` fields describe automated scheduling rather than manual phenotype inclusion/exclusion.
- `derived_data/mr/manifest/02_candidate_dual_outcome_summary_11988_IHD_anchor.csv`: IHD-anchored outcome-specific candidate universe.
- `derived_data/mr/manifest/02b_common_candidate_dual_outcome_summary_11987.csv`: common candidate IDs after excluding each outcome from its own exposure universe.
- `derived_data/mr/manifest/03_primary_bh_both_q05_concordant_ivw.csv`: 49-candidate primary aggregate screen (Set A).
- `derived_data/mr/manifest/04_table1_local_run_crosscheck.csv`: comparison with the former 50-row table.
- `derived_data/mr/manifest/05_audit_summary.md`, session information, and input/output checksum tables.
- `derived_data/mr/alternative_sets/`: definitions, membership tables, counts, old-table comparison, and hashes for Sets A-C.
- `derived_data/mr/final_reporting/`: final 29-candidate Table 1 source, Figure 7 source/QA, and session information.

## Reconstructed methods

The retained catalogue contains 11,989 European-ancestry records. Each outcome-specific run scheduled 11,988 exposures after removing its own outcome dataset from the schedule. The stored `eqtl-a-*` rule matched zero records. IDs were sorted, and every remaining exposure was scheduled. The clean intersection contains 11,987 IDs.

The located scripts used the following settings:

- exposure-instrument threshold: `P < 5 × 10^-6`;
- LD clumping: `r² = 0.001`, 10,000 kb;
- outcome proxies: disabled;
- harmonisation: action 2;
- primary estimate: IVW for multiple instruments and Wald ratio for a single instrument.

The fixed Benjamini-Hochberg family size is 11,988 separately for IHD and DD. Candidates without a saved estimate are represented by `P = 1`, and their status remains exactly `no saved estimate; exact reason not recorded`; no failure reason is inferred.

Post-analysis reporting proceeds as follows:

1. **Set A (n = 49):** q < 0.05 for both outcomes, concordant non-zero beta signs, and IVW for both outcomes.
2. **Set B (n = 29; final reporting set):** Set A after excluding all `finn-b-*` exposures to reduce participant-overlap and same-biobank dependence because both outcomes are FinnGen datasets. It contains 20 concordant positive and 9 concordant negative associations. This post-screen safeguard is not a general requirement that MR exposure and outcome GWAS originate from different databases.
3. **Set C (n = 18; descriptive sensitivity):** Set B after conservative removal of 11 obvious diagnosis, medication, health-status, disease-history, or healthcare-use markers.

The final candidates are termed **shared genetically associated traits** rather than uniform upstream risk factors. Their categories distinguish potentially modifiable/intermediate phenotypes, sociodemographic/life-course phenotypes, psychological/symptom phenotypes, and clinical/healthcare markers.

## Historical limitations

The exact DD run used to generate the submitted 50-row table is not present. The retained DD aggregate run uses `finn-b-F5_DEPRESSIO`, but it does not reproduce the former DD odds ratios. For example, extreme old estimates for doxazosin and beclometasone are not supported by the retained run and have been removed from revised reporting.

Offline code/output fingerprinting indicates that the DD folder was produced by the self-developed exposure-screen code family in its saved DD configuration. The IHD folder was produced by an earlier IHD-configured version of that code family. The exact IHD-configured script text was not retained, so the current DD-configured file is not represented as an exact IHD runner. The alternative Grok script and the reverse-direction outcome-screen script do not match the preserved filename, indexing, outcome, or output fingerprints. See `MR_SCREEN_FLOW.md`.

No retained files contain SNP-level exposure data, outcome extractions, harmonised datasets, per-variant F statistics, heterogeneity statistics, MR-Egger results/intercepts, weighted-median results, leave-one-out analyses, MR-PRESSO, or Steiger directionality results. These analyses cannot be reconstructed honestly from aggregate `b`, `se`, `p`, method, and instrument-count fields. Their absence is disclosed in the manuscript and response letter.

Predominantly European and Finnish data limit transferability to the manuscript's global ecological analysis. Excluding `finn-b-*` exposures reduces a specific same-cohort overlap concern but does not create cross-ancestry evidence.

## OpenGWAS access and no-crawling rule

No online request is necessary to inspect or regenerate the included aggregate-result tables. No OpenGWAS request was made while building this release. The historical `ao.csv` was created through `available_outcomes()` when absent and reused from disk thereafter; a current catalogue refresh would not be a reproduction of that dated snapshot.

The optional script is provided only for a future, deliberately slow sensitivity rerun of the 29 candidates. It is **off by default** and makes no request unless `RUN_OPENGWAS_SENSITIVITY=YES` is set explicitly. It must not be used as a crawler or parallelised. It caches every completed exposure, resumes without repeating completed work, paces every top-level API operation at a default 90-second interval plus jitter, rejects delay settings below 60 seconds, prevents back-to-back exposure/outcome requests, calls `ieugwasr::check_reset(override_429 = FALSE)`, and stops immediately on any `429`, allowance, or `Retry-After` signal. The operator must review and follow the current OpenGWAS authentication, allowance, licensing, and access rules before enabling it. Never commit or archive `OPENGWAS_JWT`.

Current official guidance:

- OpenGWAS API authentication and allowance: https://api.opengwas.io/api/
- `ieugwasr` access guide: https://mrcieu.github.io/ieugwasr/articles/guide.html

## Public archive

Version `1.0.0` is published at https://github.com/casper4869/IHD-DD-reproducibility/releases/tag/v1.0.0 and permanently archived at https://doi.org/10.5281/zenodo.22852369. Rights and third-party provider terms are defined in `RIGHTS_AND_LICENSING.md`. The absence of the historical DD SNP-level objects remains disclosed and must not be repaired by silently substituting a current database rerun.
