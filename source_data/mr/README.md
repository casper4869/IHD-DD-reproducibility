# Preserved MR source files

- `ao.csv`: 15,703-row OpenGWAS catalogue snapshot returned by `TwoSampleMR::available_outcomes()` and cached by the preserved workflow. The count refers to catalogue metadata, not completed MR analyses.
- `IHD/bb.csv`: exact compact concatenation of 5,880 saved one-row IHD aggregate estimates.
- `DD/bb.csv`: exact compact concatenation of 11,775 saved one-row DD aggregate estimates.
- `IHD/END.csv` and `DD/END.csv`: companion retained result subsets from the historical workflow.

The 17,655 numbered one-row TXT files are not duplicated because the audit verified that their exposure IDs, outcome IDs, numeric estimates, methods, and instrument-count fields match the corresponding compact `bb.csv` files. `../../derived_data/mr/manifest/07_input_sha256.csv` contains byte counts and SHA-256 values for every preserved source file, including all numbered TXT files.

The technical screen scheduled 11,988 exposures per outcome after European-ancestry scoping, the stored `eqtl-a-*` rule (zero matches in this snapshot), removal of the target outcome itself, and ID sorting. There was no manual phenotype selection based on trait name or result. These files contain aggregate results only. They do not include SNP-level exposure/outcome data or harmonised objects. Do not infer unrecorded failure reasons for missing estimates.
