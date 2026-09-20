# Public-release staging notes

This staging tree differs from the internal revision workspace in the following deliberate ways:

1. Machine-specific workspace roots in public text/code records are replaced by `<LOCAL_PROJECT_ROOT>` or `<LOCAL_REVISION_WORKSPACE>`. Source-file SHA-256 values are retained so the private originals remain auditable.
2. The MR manifest uses technical-scope and scheduling terminology rather than `inclusion_decision`/`exclusion_decision`, because the exploratory screen did not apply manual phenotype-level inclusion/exclusion.
3. Historical catalogue-wide online code is supplied only as a safety-disabled text reference. Current public scripts validate the catalogue offline and keep the optional 29-candidate sensitivity workflow disabled by default, sequential, cached, paced, and provider-governed.
4. Figure 6 retains the submitted two-panel coordinate-point layout but uses a shared ±1.7 colour scale, which covers all observed coefficients and removes the submitted display's 12 saturated values. Its source table, parameterised offline renderer, numerical audit, and publication outputs are included.
5. Sanitised historical Figure 1, Figure 3, and SDI scripts are quarantined as `REFERENCE_ONLY_NOT_CORRECTED` records, with their original hashes and limitations. Derived Figure 1/3 source tables are included for audit. Historical TIFF and Illustrator assets are omitted because their embedded metadata retains machine-specific source paths. None of these records is described as a corrected clean-run output.
6. The top-level `manifests/package_file_manifest_sha256.csv` is the authoritative checksum inventory for the public release. Older component checksum tables are retained as execution-time provenance records and may contain hashes from the pre-sanitised internal workspace.

The repository URL, DOI, version, creator metadata, licences, PM2.5/coordinate provenance, and release-specific FinnGen/Risteys metadata remain author-confirmation fields. See `RELEASE_CHECKLIST.md`.
