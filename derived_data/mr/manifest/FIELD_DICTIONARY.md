# MR catalogue-to-analysis status manifest: field guide

`01_gwas_catalog_manifest_15703.csv` contains one row for every record in the preserved 15,703-record OpenGWAS catalogue snapshot.

## Scope and scheduling fields

| Field | Meaning |
|---|---|
| `catalog_row_original` | Row number in the preserved `ao.csv` snapshot before sorting. |
| `technical_scope_status` | Whether catalogue metadata place the record inside the European-ancestry technical scope. This is not a manual phenotype judgement. |
| `technical_scope_reason` | Recorded reason when a catalogue row is outside that technical scope. |
| `eqtl_pattern_outside_scope` | Whether the stored `eqtl-a-*` technical-class rule matched the ID. It matched zero rows in this snapshot. |
| `ihd_candidate_index`, `dd_candidate_index` | Position after technical scoping and sorting for the relevant outcome-specific schedule. |
| `ihd_candidate`, `dd_candidate` | Machine-readable indicator that the record belonged to that outcome-specific scheduled universe. |
| `ihd_scheduling_status`, `dd_scheduling_status` | `scheduled as exposure` or the structural/technical reason it was not scheduled. |

The word *candidate* in these legacy-derived field names means a scheduled exposure job. It does not mean that the trait was judged clinically plausible or selected as a positive result.

## Result-availability fields

| Field pattern | Meaning |
|---|---|
| `*_saved_estimate` | Whether a saved aggregate result exists in the preserved folder. |
| `*_output_status` | Saved-result status. For a scheduled job without a retained result, the exact text is `no saved estimate; exact reason not recorded`. |
| `*_availability_note` | Explicitly preserves the unknown reason for a missing saved estimate; it does not infer failure stage. |
| `*_method`, `*_instrument_count`, `*_beta`, `*_se`, `*_p_value` | Fields read from a retained one-row aggregate result. |
| `*_p_for_bh` | Saved p value, or 1 when no estimate was saved. |
| `*_q_bh_m11988` | BH q value using a fixed family size of 11,988 for that outcome. |
| `*_output_index`, `*_output_file` | Historical numbered-file index and relative path recorded by the offline audit. |

## Interpretation

The manifest is a complete catalogue-to-analysis **status** record. It is not a claim that all 15,703 catalogue records produced MR estimates, and it is not a retrospective manual inclusion/exclusion table. The outcome-specific accounting is 11,988 scheduled jobs, with 5,880 saved IHD estimates and 11,775 saved DD estimates.

