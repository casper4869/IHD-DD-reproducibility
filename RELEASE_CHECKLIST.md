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
- [x] Create version tag `v1.0.0` and the GitHub Release from commit `9885cb8671030cfa2e925fcfa25c7f264f50f457`.
- [x] Record the exact release URL and commit/tag in `data_access_protocol.md`.

## Zenodo archive

- [x] Sign in to Zenodo through the authorised GitHub account.
- [x] Enable only `casper4869/IHD-DD-reproducibility` for Zenodo archiving.
- [x] Verify the metadata in `ZENODO_METADATA.md` and `.zenodo.json`.
- [x] Archive the final GitHub Release and verify the published 82,648,552-byte source archive.
- [x] Record version DOI `10.5281/zenodo.22852369` and concept DOI `10.5281/zenodo.22852368`; cite the version DOI for the exact reviewer release.
- [x] Test the DOI metadata endpoint and public file response without depositor credentials.
- [x] Provide the final repository, version DOI, release version, and rights wording in `data_access_protocol.md` for use in the manuscript-facing availability text.
- [x] Verify that `figures/Figure4.tif` and `figures/Figure5.tif` are byte-identical submitted artifacts and that all alternative displays are isolated under `figures/internal_audit_not_for_submission/`.
