# Alternative MR candidate sets (aggregate-result recovery)

Generated from the packaged saved aggregate results. No network request is required.

## Fixed analysis rules

- Benjamini-Hochberg adjustment was calculated separately for IHD and DD with a fixed family size of **m = 11,988**. Scheduled candidates without a saved aggregate estimate were treated as `p = 1`; the exact reason for each missing output was not recorded.
- **Set A:** both outcome-specific BH q-values `< 0.05`, effect directions agree, and both saved methods are inverse-variance weighted.
- **Set B:** Set A after excluding all `finn-b-*` exposure IDs to reduce participant-overlap and same-biobank dependence because both outcomes are FinnGen datasets. This was applied after the exploratory screen and is not a universal different-database requirement.
- **Set C:** Set B after the conservative lexical removal of obvious medication/treatment variables, diagnosis/disease-history codes, procedure/hospital-use codes, and broad health-status or multimorbidity markers. This is a descriptive sensitivity set and is not a replacement primary screen.
- `old50_overlap` indicates membership in the manuscript's previous 50-trait table, mapped to exposure IDs by exact matching of its IHD OR and p-value.
- `old50_status_against_sets.csv` lists all previous 50 traits, their current aggregate-result status, and explicit reasons for failing Set A.

## Counts

| Set | Candidates | Overlap with old 50 |
|---|---:|---:|
| A | 49 | 18 |
| B | 29 | 18 |
| C | 18 | 11 |

Set A contains 40 direction-consistent positive associations and 9 direction-consistent negative associations. Set C removes 11 downstream/code-like markers from Set B.

## Interpretation limit

These files recover candidate sets from aggregate `b`, `se`, `p`, method, and instrument-count fields. They cannot reconstruct SNP-level harmonisation, instrument strength, heterogeneity, directional pleiotropy, MR-Egger, weighted-median, leave-one-out, MR-PRESSO, or Steiger analyses.

There was no manual phenotype pre-selection before the catalogue-wide screen. Set A is the post-analysis exploratory result set; Sets B and C are explicitly labelled post-screen reporting/sensitivity sets.
