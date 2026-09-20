# Historical MR runner provenance

`self_developed_find_exposure_DD_REFERENCE_ONLY.R.txt` is a safety-disabled reference copy of the located self-developed exposure-screen script.

- Original local SHA-256: `b9d6116b80ff6c58247423af6cc40d8640da58560b2474bc7d884ad8bb5d0fc6`
- Changes in the public reference copy: a warning header was added and two machine-specific output paths were replaced with placeholders.
- No credential was present in the original or added to the copy.
- The `.txt` suffix is intentional because the historical code performs catalogue-scale online extraction and does not implement the current release's provider-aware successful-request pacing.

The saved DD configuration fixes the outcome as `finn-b-F5_DEPRESSIO`, uses `P < 5e-6`, `r2 = 0.001`, `kb = 10000`, disables outcome proxies, and uses harmonisation action 2. Its numbered `i.txt` output convention, quoted tabular format, sorted catalogue indexing, and outcome ID are consistent with all 11,775 preserved DD result files.

The 5,880 IHD files have fingerprints consistent with the same self-developed code family and an earlier IHD outcome configuration (`finn-b-I9_IHD`), but the exact IHD-configured script text and historical execution records were not retained. In particular, the currently located DD-configured text contains an additional explicit DD removal that was not present or not active for the IHD run. The reference copy must therefore not be described as an exact IHD runner, and fingerprint agreement must not be presented as proof of the exact executable provenance.

The alternative Grok script has incompatible fingerprints for both preserved result folders: it begins at a different index, uses an `index_GWASID.txt` filename convention, requires local PLINK clumping and at least three instruments, and fixes a T2D outcome. The reverse-direction outcome-screen script also has an incompatible analysis-direction fingerprint.

The public, disabled-by-default 29-candidate sensitivity workflow is `../opengwas_sensitivity_rerun_RATE_LIMITED.R`. It contains the current no-crawling, sequential pacing, caching, resume, allowance, and JWT-handling safeguards.

`catalogue_capture_REFERENCE_ONLY.R.txt` records the historical cache-or-fetch snippet that produced `ao.csv`. It is preserved to explain the 15,703-row snapshot, but its unbounded retry loop must not be used. The replacement `../00_catalogue_snapshot_provenance.R` validates the archive offline by default and allows only a deliberate one-shot refresh to a new file.
