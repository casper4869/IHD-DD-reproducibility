# FAIR and repository-readiness audit

Audit date: 2026-09-20  
Verdict: **published as a versioned aggregate-result reproducibility release with disclosed scope limitations; not a complete raw-to-final reproduction package**

## Findable

- **Pass:** stable, descriptive component filenames and a top-level README are present.
- **Pass:** scripts, inputs, and package files are mapped through CSV manifests.
- **Pass:** the public GitHub landing page, version `1.0.1` tag, title, creators, affiliations, keywords, and Zenodo DOI are present and verified.
- **Pass with omission:** verified creator names and affiliations are supplied. ORCIDs and funding are omitted because none were verified.

## Accessible

- **Pass:** a step-by-step protocol identifies the official GBD, OpenGWAS, and FinnGen/Risteys access routes.
- **Pass:** third-party files that may be restricted are distinguished from shareable author outputs.
- **Disclosed limitation:** the PM2.5 and coordinate sources lack verified provider and licence metadata.
- **Pass with disclosed limitation:** the 15,703-row OpenGWAS catalogue, compact saved IHD/DD aggregate estimates, complete catalogue-to-analysis status manifest, and source hashes are included. The exact DD SNP-level run underlying the submitted table was not retained and cannot be reconstructed from the archive.
- **Disclosed limitation:** FinnGen release-specific endpoint exports were not recovered for `v1.0.1`.
- **Pass:** the GitHub release, Zenodo DOI, and unauthenticated public archive response were verified after archival.

## Interoperable

- **Pass:** principal derived outputs are CSV; figures are provided in PDF, TIFF, SVG where available, and PNG preview formats.
- **Pass:** country/year/sex/age dimensions and the analysis roles of major inputs are recorded.
- **Partial:** variable-level dictionaries are embedded in scripts and reports rather than consolidated into one data dictionary.
- **Pass with disclosed limitation:** the MR manifest contains all 15,703 catalogue IDs, provider metadata where present, outcome-specific technical scheduling statuses, saved-estimate status, methods, instrument counts, effects, P values, and BH q values. These statuses are automated catalogue-to-analysis accounting rather than manual phenotype inclusion/exclusion. For absent estimates, the exact historical failure stage was not logged and is explicitly recorded as `no saved estimate; exact reason not recorded` rather than inferred.

## Reusable

- **Pass:** corrected components include session information, package versions, checksums, logs, model diagnostics, and QA outputs.
- **Pass:** the package states which results are corrected, legacy-only, derived-only, or unavailable in `v1.0.1`.
- **Pass with rights retained:** `RIGHTS_AND_LICENSING.md` defines public access for verification, no repository-wide reuse licence, and original provider terms for third-party material.
- **Pass with disclosed archival limitation:** executable release scripts use relative or parameterised paths; quarantined historical `.R.txt` records contain redacted `<LOCAL_...>` placeholders and are not release entry points.
- **Disclosed limitation:** there is no complete clean-environment lockfile or continuous reproduction test.
- **Pass for aggregate MR audit:** the full 15,703-record catalogue-to-analysis status manifest, compact aggregate results, source hashes, candidate sets, final 29-candidate reporting tables, and offline code are incorporated.
- **Permanent MR limitation:** SNP-level instruments/harmonised objects and the exact submitted-table DD run are absent, so pleiotropy and sensitivity estimators cannot be reconstructed and are not claimed.
- **Pass for the submitted temporal analysis and audit:** the path-parameterised three-variable VAR reconstruction reproduces all 204 archived classifications and documents that each `vars::causality()` call is a joint system test across both remaining equations. A machine-readable submitted-system sensitivity reapplies both BH families after the prespecified 45-unit exclusion and supplies 159 row-level results plus the 71/13/60/15 category counts. The separate target-specific sensitivity scripts, numerical QA, audit-only paired-specification display, calibrated interpretation, and cartographic/SIDS artifacts are also incorporated.
- **Pass for the model audit:** corrected GWR and its 45-unit cartographic/SID sensitivity, bandwidth trace, coefficient source tables, independent reconstruction, session record, and checksums are incorporated.

## Known limitations and post-release checks

1. Preserve the disclosed absence of the exact historical DD SNP-level run; do not replace it silently with a current database rerun.
2. Curate raw-to-final preprocessing, Figure 1, and Figure 3 into clean parameterised entry points. The legacy artifacts are fingerprinted in `manifests/legacy_source_artifact_inventory.csv` but are not release-ready code.
3. Resolve PM2.5, coordinate, and release-specific FinnGen/Risteys provenance.
4. Parameterise remaining absolute paths and execute the offline package in a clean environment.
5. Preserve the rights-retained statement and provider exclusions unless the relevant rightsholders later approve explicit file-level licences.
6. Preserve the verified `v1.0.1` DOI `10.5281/zenodo.22854090` in the manuscript-facing availability statement.
