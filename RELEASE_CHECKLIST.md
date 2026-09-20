# GitHub and Zenodo release checklist

## Before the first GitHub push

- [ ] Confirm the public repository name and description.
- [ ] Confirm the full author list, ORCIDs, affiliations, and release version.
- [ ] Select a software licence for author-written code and a separate rights statement for data/derived files; do not relicense third-party inputs without permission.
- [ ] Resolve or explicitly retain the documented PM2.5, coordinate, and FinnGen/Risteys provenance limitations.
- [ ] Confirm that the final Figure 6 files and legend correspond to the verified GWR specification.
- [ ] Run the credential scan and confirm that no JWT, password, token, cookie, private key, or `.Renviron` file is present.
- [ ] Run the absolute-path and placeholder scans; document any intentionally retained archival paths.
- [ ] Regenerate `manifests/package_file_manifest_sha256.csv` after all content changes.
- [ ] Check that every file is below GitHub's per-file limit and that repository size remains reasonable.

## GitHub release

- [ ] Create the public repository without pasting account credentials into chat or files.
- [ ] Push the reviewed staging directory.
- [ ] Create a version tag and GitHub Release only after the file list is final.
- [ ] Record the exact release URL and commit/tag in `data_access_protocol.md`.

## Zenodo archive

- [ ] Sign in to Zenodo with GitHub and connect only the intended repository.
- [ ] Verify the metadata in `ZENODO_METADATA_DRAFT.md`.
- [ ] Archive the final GitHub Release, verify the uploaded file list, then publish the Zenodo record.
- [ ] Record the version-specific DOI and, if shown, the concept DOI; cite the version-specific DOI for the exact reviewer release.
- [ ] Test the DOI and public file download while signed out.
- [ ] Replace all remaining repository/DOI/version/licence placeholders in the manuscript-facing availability text.
