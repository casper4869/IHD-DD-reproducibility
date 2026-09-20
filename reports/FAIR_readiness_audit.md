# FAIR and repository-readiness audit

Audit date: 2026-09-20  
Verdict: **not yet ready for DOI deposition as a complete manuscript reproduction package**

## Findable

- **Pass:** stable, descriptive component filenames and a top-level README are present.
- **Pass:** scripts, inputs, and package files are mapped through CSV manifests.
- **Pending:** no public landing page, release tag, persistent identifier, title/creator metadata, or searchable repository record exists.
- **Pending:** the final repository title, authors/ORCIDs, affiliations, keywords, funder metadata, and related-manuscript identifier must be added.

## Accessible

- **Pass:** a step-by-step protocol identifies the official GBD, OpenGWAS, and FinnGen/Risteys access routes.
- **Pass:** third-party files that may be restricted are distinguished from shareable author outputs.
- **Pending:** the PM2.5 and coordinate sources lack verified provider and licence metadata.
- **Pass with disclosed limitation:** the 15,703-row OpenGWAS catalogue, compact saved IHD/DD aggregate estimates, complete catalogue-to-analysis status manifest, and source hashes are included. The exact DD SNP-level run underlying the submitted table was not retained and cannot be reconstructed from the archive.
- **Pending:** FinnGen release-specific endpoint exports have not been recovered.
- **Pending:** no anonymous reviewer link or DOI has been created or tested.

## Interoperable

- **Pass:** principal derived outputs are CSV; figures are provided in PDF, TIFF, SVG where available, and PNG preview formats.
- **Pass:** country/year/sex/age dimensions and the analysis roles of major inputs are recorded.
- **Partial:** variable-level dictionaries are embedded in scripts and reports rather than consolidated into one data dictionary.
- **Pass with disclosed limitation:** the MR manifest contains all 15,703 catalogue IDs, provider metadata where present, outcome-specific technical scheduling statuses, saved-estimate status, methods, instrument counts, effects, P values, and BH q values. These statuses are automated catalogue-to-analysis accounting rather than manual phenotype inclusion/exclusion. For absent estimates, the exact historical failure stage was not logged and is explicitly recorded as `no saved estimate; exact reason not recorded` rather than inferred.

## Reusable

- **Pass:** corrected components include session information, package versions, checksums, logs, model diagnostics, and QA outputs.
- **Pass:** the package states which results are corrected, legacy-only, derived-only, or pending.
- **Pending:** no code licence or repository-level rights statement has been selected.
- **Pending:** several scripts retain absolute local paths and should be parameterised before public release.
- **Pending:** there is no complete clean-environment lockfile or continuous reproduction test.
- **Pass for aggregate MR audit:** the full 15,703-record catalogue-to-analysis status manifest, compact aggregate results, source hashes, candidate sets, final 29-candidate reporting tables, and offline code are incorporated.
- **Permanent MR limitation:** SNP-level instruments/harmonised objects and the exact submitted-table DD run are absent, so pleiotropy and sensitivity estimators cannot be reconstructed and are not claimed.
- **Pass for the completed temporal analysis:** corrected Granger scripts, independent numerical QA, the exploratory paired-specification Figure 5, calibrated manuscript interpretation, and cartographic/SIDS sensitivity artifacts are incorporated.
- **Pass for the model audit:** corrected GWR and its 45-unit cartographic/SID sensitivity, bandwidth trace, coefficient source tables, independent reconstruction, session record, and checksums are incorporated.

## Required pre-deposition actions

1. Preserve the disclosed absence of the exact historical DD SNP-level run; do not replace it silently with a current database rerun.
2. Curate raw-to-final preprocessing, Figure 1, and Figure 3 into clean parameterised entry points. The legacy artifacts are fingerprinted in `manifests/legacy_source_artifact_inventory.csv` but are not release-ready code.
3. Resolve PM2.5, coordinate, and release-specific FinnGen/Risteys provenance.
4. Parameterise remaining absolute paths and execute the offline package in a clean environment.
5. Add a code licence and a rights statement for derived outputs and third-party inputs.
6. Create and test the repository release, then replace all `[PENDING_*]` fields with the verified URL, DOI, version, and licence.
