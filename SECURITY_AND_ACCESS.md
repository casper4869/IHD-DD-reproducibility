# Credentials and external-access safety

- No password, GitHub credential, Zenodo credential, OpenGWAS JWT, browser cookie, or private key belongs in this repository.
- Configure `OPENGWAS_JWT` only in the local user environment. Do not place it in R scripts, `.Renviron` files committed to Git, logs, issues, screenshots, or release archives.
- Primary MR reconstruction in this repository is offline. Do not rerun the historical catalogue-wide screen simply to verify the included aggregate results.
- The optional 29-candidate OpenGWAS sensitivity script is disabled by default. If a future rerun is scientifically necessary, first review the provider's current authentication, allowance, licensing, and access rules. Run sequentially, retain the built-in delay and cache, and stop on rate-limit signals.
- The historical catalogue snapshot is already included. `00_catalogue_snapshot_provenance.R` validates it offline by default and never refreshes silently.
- Third-party GBD, OpenGWAS, and FinnGen/Risteys materials remain subject to their providers' terms. See `data_access_protocol.md` for retrieval routes and redistribution boundaries.

