# Public release notes — v1.0.1

Version `v1.0.1` supersedes the immutable `v1.0.0` archive for the manuscript revision. It retains the earlier reproducibility materials, adds the final QA-checked Figure 4 package, restores a public offline entry point for the submitted three-variable Granger analysis, and clarifies its system-test scope.

## Changes in v1.0.1

1. `figures/Figure4.tif`, `.pdf`, `.png`, and `.svg` now contain the minimal R redraw used in the revised manuscript. Panel A is VARX and panel B is ARIMAX; the identical 1992–2021 history and archived 2030 endpoints of 19 and 14 are unchanged.
2. Titles, model labels, prose annotations, endpoint callouts, and the unsupported ±15% visual envelopes were removed from the graphic. Their interpretation and the retained-code ARIMAX rerun value of 13 are disclosed in the manuscript caption and repository documentation.
3. The exact 78-row plotting table, source-table builder, R renderer, session information, numerical/visual QA, and output checksums were added.
4. The byte-identical originally submitted Figure 4 is preserved under `figures/original_submitted_not_for_resubmission/` for provenance only. Figure 5 remains byte-identical to the submitted artwork.
5. `code/granger/reproduce_archived_granger_main.R` and the parameterised full archival workflow reproduce the submitted three-variable VAR offline. All 204 lags, raw P values, adjusted P values, and legacy classifications match the archived table within `1e-12`.
6. The Granger documentation now states the exact null hypotheses: the IHD-labelled call jointly tests lagged IHD terms in both the DD and SDI equations, while the DD-labelled call jointly tests lagged DD terms in both the IHD and SDI equations. The submitted arrows are therefore retained only as legacy system-test labels and do not establish disease-specific temporal direction or causation.
7. A machine-readable submitted-system sensitivity excludes the prespecified 45 cartographic/SID units, retains 159 locations, and reapplies the two BH families to the archived raw P values. Its retained-set counts are 71 both labelled families, 13 IHD-labelled only, 60 DD-labelled only, and 15 neither; it does not refit the VAR.
8. MR code-family attribution is now phrased as output-fingerprint consistency. The archive does not claim that these fingerprints prove the exact historical executable snapshot.

## Release safeguards retained

1. Machine-specific workspace roots in public text/code records are replaced by `<LOCAL_PROJECT_ROOT>` or `<LOCAL_REVISION_WORKSPACE>` while private-original hashes remain auditable.
2. The exploratory MR manifest uses technical-scope and scheduling terminology because no manual phenotype-level inclusion/exclusion screen was performed.
3. Historical catalogue-wide online code remains a safety-disabled reference. The optional 29-candidate workflow is disabled by default, sequential, cached, paced, and governed by current provider requirements; it is not a crawler.
4. Figure 6 retains the submitted evidence form with a complete shared colour scale. Historical Figure 1, Figure 3, and SDI scripts remain quarantined as `REFERENCE_ONLY_NOT_CORRECTED` records with explicit limitations.
5. `manifests/package_file_manifest_sha256.csv` is the authoritative checksum inventory for this release.

Repository: https://github.com/casper4869/IHD-DD-reproducibility<br>
GitHub release: https://github.com/casper4869/IHD-DD-reproducibility/releases/tag/v1.0.1<br>
Zenodo version DOI: https://doi.org/10.5281/zenodo.22854090<br>
Zenodo concept DOI: https://doi.org/10.5281/zenodo.22852368

Creator metadata and the mixed-rights statement are recorded in `.zenodo.json`, `CITATION.cff`, and `RIGHTS_AND_LICENSING.md`. The PM2.5/coordinate provenance and release-specific FinnGen/Risteys metadata remain disclosed source limitations.
