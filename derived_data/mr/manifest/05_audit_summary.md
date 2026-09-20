# Exploratory MR screening audit

Generated: 2026-09-20 00:05:26 CST
Input root: complete local historical MR archive (not redistributed as 17,655 redundant numbered files)
Script: `code/mr/01_build_exploratory_mr_audit.R`

## Scope and interpretation

This reconstruction treats the MR component as an exploratory, hypothesis-generating phenome-wide two-sample MR screen. It does not convert screening associations into confirmatory causal claims.

Every candidate without a saved estimate is labelled exactly: `no saved estimate; exact reason not recorded`. No failure reason was inferred.

## Catalogue and candidate universes

- Catalogue records: 15703 (unique IDs: 15703)
- European-ancestry catalogue records: 11989
- Catalogue records outside the European-ancestry technical scope: 3714
- IDs matching the stored script's `eqtl-a-*` technical class: 0
- IHD candidate universe: 11988 (European records excluding `finn-b-I9_IHD`)
- DD candidate universe: 11988 (European records excluding `finn-b-F5_DEPRESSIO`)
- Common candidate IDs: 11987
- Union of the two outcome-specific candidate universes: 11989

There is no natural 11,988-ID common dual-outcome set: each outcome-specific schedule omits its own outcome dataset. The 11,988-row dual table is therefore anchored to the IHD exposure schedule; the common-ID table has 11,987 rows. No phenotype was manually selected or rejected by name, relevance, modifiability, expected direction, or result.

## Saved output coverage

- IHD saved estimates: 5880; no saved estimate: 6108
- IHD methods: Inverse variance weighted=3269; Wald ratio=2611
- DD saved estimates: 11775; no saved estimate: 213
- DD methods: Inverse variance weighted=11374; Wald ratio=401
- Common IDs with saved estimates for both outcomes: 5853
- Common IDs with neither estimate saved: 187

## BH primary-screen reconstruction

- BH family size was fixed at m=11988 separately for each outcome.
- Missing saved estimates were assigned P=1 before BH adjustment.
- IHD candidates with q<0.05: 621
- DD candidates with q<0.05: 195
- Candidates meeting both q<0.05, concordant non-zero direction, and IVW for both outcomes: 49

## Integrity checks

- All 17,655 numbered TXT files contained exactly one result row.
- All saved outcome IDs were uniform and matched the expected outcome for their directory.
- All numbered file indices exactly matched the filtered, alphabetically sorted catalogue index.
- The exposure-ID sets, numeric estimates, methods, and `nsnp` values matched between numbered TXT files and `bb.csv`.
- Trait-label quoting differed between TXT and merged CSV in 29 IHD rows and 77 DD rows; IDs and numeric results were unchanged.

## Manuscript Table 1 cross-check

- Table 1 rows checked: 50
- IHD OR matches within tolerance: 50
- IHD P-value matches within tolerance: 50
- DD OR matches within tolerance: 0
- DD P-value matches within tolerance: 6
- Interpretation: the saved IHD run reproduces Table 1, while the saved DD run is a different run and must not be represented as the exact Table 1 source.

## Known provenance limitations

- The located screening scripts use an instrument threshold of P<5e-6, whereas the submitted manuscript reported P<5e-8; the revision reports the reconstructed P<5e-6 setting.
- The preserved files do not include SNP-level exposure data, SNP-level outcome data, harmonised objects, F statistics, heterogeneity tests, MR-Egger, weighted-median, MR-PRESSO, or Steiger outputs.
- Exact reasons for absent estimates were not logged.
- The exact DD run used for Table 1 is not present in this directory.
- FinnGen release identifiers, IEU OpenGWAS access dates, and historical package versions were not embedded in the source files.

## Checksums

- `07_input_sha256.csv` contains SHA256 for all 17666 preserved source files.
- Non-ASCII source filenames represented by reversible percent-encoded native CP936 bytes: 5.
- `08_output_sha256.csv` contains SHA256 for the generated artifacts and this R script; it intentionally excludes itself.
