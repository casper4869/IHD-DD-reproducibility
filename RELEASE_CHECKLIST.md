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
- [ ] Push the approved release metadata and refreshed checksum manifest.
- [ ] Create a version tag and GitHub Release only after the file list is final.
- [ ] Record the exact release URL and commit/tag in `data_access_protocol.md`.

## Zenodo archive

- [x] Sign in to Zenodo through the authorised GitHub account.
- [ ] Enable only `casper4869/IHD-DD-reproducibility` for Zenodo archiving.
- [x] Verify the metadata in `ZENODO_METADATA.md` and `.zenodo.json`.
- [ ] Archive the final GitHub Release, verify the uploaded file list, then publish the Zenodo record.
- [ ] Record the version-specific DOI and, if shown, the concept DOI; cite the version-specific DOI for the exact reviewer release.
- [ ] Test the DOI and public file download while signed out.
- [ ] Replace all remaining repository/DOI/version/licence placeholders in the manuscript-facing availability text.
