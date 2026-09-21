# GitHub and Zenodo release checklist

## Completed repository preparation

- [x] Confirm the public repository name and description.
- [x] Record the full author list, affiliations, and release version; omit unverified ORCIDs rather than guessing them.
- [x] Prepare a conservative mixed-rights statement: public access for verification, no repository-wide reuse licence, and original provider terms for third-party material.
- [x] Explicitly retain the documented PM2.5, coordinate, and FinnGen/Risteys provenance limitations.
- [x] Confirm that the final Figure 6 files and legend correspond to the verified GWR specification.
- [x] Run the credential scan and confirm that no JWT, password, token, cookie, private key, or `.Renviron` file is present.
- [x] Run the absolute-path scan; document intentionally retained redacted archival references.
- [x] Check that every file is below GitHub's per-file limit and that repository size remains reasonable.
- [x] Regenerate `manifests/package_file_manifest_sha256.csv` after the final metadata files are prepared.

## GitHub release

- [x] Create the public repository without pasting account credentials into chat or files.
- [x] Push and independently verify the reviewed analysis package.
- [x] Push the approved release metadata and refreshed checksum manifest.
- [x] Create version tag `v1.0.1` and the GitHub Release from the final metadata and manifest snapshot.
- [x] Record the exact release URL and commit/tag in `data_access_protocol.md`.

## Zenodo archive

- [x] Sign in to Zenodo through the authorised GitHub account.
- [x] Enable only `casper4869/IHD-DD-reproducibility` for Zenodo archiving.
- [x] Verify the metadata in `ZENODO_METADATA.md` and `.zenodo.json`.
- [x] Archive the final GitHub Release and verify the published 82,648,552-byte source archive.
- [x] Record version DOI `10.5281/zenodo.22878656` and concept DOI `10.5281/zenodo.22878656`; cite the version DOI for the exact reviewer release.
- [x] Test the DOI metadata endpoint and public file response without depositor credentials.
- [x] Provide the final repository, version DOI, release version, and rights wording in `data_access_protocol.md` for use in the manuscript-facing availability text.
- [x] Verify that `figures/Figure4.*` is the QA-checked minimal redraw with archived 19/14 endpoints, `figures/Figure5.tif` is the byte-identical submitted Figure 5, the original Figure 4 is isolated under `figures/original_submitted_not_for_resubmission/`, and all additional sensitivity displays remain under `figures/internal_audit_not_for_submission/`.
- [x] Include the machine-readable submitted-system 45-unit exclusion sensitivity, with 159 retained rows and independently verified 71/13/60/15 category counts.
