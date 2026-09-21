# Data access and reconstruction protocol

This protocol distinguishes files present in `v1.1.0`, third-party data that readers must retrieve from the provider, and evidence that was not recovered. It does not grant redistribution rights for IHME, IEU OpenGWAS, FinnGen, or any other third-party resource.

## 1. GBD 2021 disease incidence estimates

**Access class:** third-party, account-based retrieval.  
**Provider:** Institute for Health Metrics and Evaluation (IHME), Global Health Data Exchange.  
**Official entry point:** https://vizhub.healthdata.org/gbd-results/  
**User guide:** https://ghdx.healthdata.org/sites/default/files/ihme_query_tool/GBD_Results_Tool_User_Guide_2019.pdf

1. Create or use an IHME/GHDx account and sign in to the GBD Results Tool.
2. Select the GBD 2021 results release.
3. Retrieve the cause results separately for `Ischaemic heart disease` and `Depressive disorders`.
4. For the age-standardised country analyses, select:
   - measure: `Incidence`;
   - metric: `Rate`;
   - age: `Age-standardized`;
   - sex: `Male` and `Female` (and `Both` only where explicitly required by a corrected script);
   - years: `1992` through `2021`;
   - locations: the 204 countries and territories represented in the analysis.
5. For the age-specific analyses, repeat the query using the 20 five-year age bands from `<5 years` through `95+ years`, retaining sex-specific estimates for 1992–2021.
6. Download CSV output rather than copying rounded values from the web display. Retain the provider-generated archive, query summary/codebook, download date, and GBD terms applying on that date.
7. Do not rename or overwrite the raw downloads. Record their SHA-256 values, then run the preprocessing that generates the long files and 204 × 30 analysis matrices.

The local project contains large combined GBD extracts (`Part0/IHD_country.csv` and `Part0/DD_country.csv`) with additional measures and metrics. Corrected downstream scripts filter the required incidence-rate records. Their local hashes are in `manifests/input_data_inventory.csv`; the files are not copied into this package because redistribution rights have not been confirmed.

The legacy-source audit did not locate a valid consolidated raw-to-final IHD/DD preprocessing script; the project file named `Part0/Data preprocessing.R` is an unrelated rheumatoid-arthritis/anxiety-disorders example. The revision therefore adds `code/preprocessing/01_build_gbd_analysis_inputs.R`, a minimal parameterised entry point that filters the retained combined extracts to Incidence/Rate, the fixed 204-location crosswalk and 1992–2021, and emits the age-standardised and sex/age-specific inputs used by the analyses. `02_compare_with_historical_inputs.R` verifies the rebuilt tables against the retained Part 2/4/5/7 inputs; the QA summary is in `reports/PREPROCESSING_QA.md`. The third-party source files themselves remain provider-controlled and are not redistributed.

## 2. GBD population estimates

**Access class:** third-party, account-based retrieval.  
**Provider:** IHME/GHDx.  
**Official entry point:** https://vizhub.healthdata.org/gbd-results/

1. In the same GBD release, select measure `Population` and metric `Number`.
2. Select the same 204 locations, male and female sex strata, the age bands required by Figure 2, and years 1992–2021.
3. Download the full-precision CSV results. The local analysis received 21 provider CSV files; their individual byte counts and SHA-256 values are preserved in `derived_data/figure2/input_checksums_sha256.csv`.
4. The Figure 2 correction joins population to disease data by immutable GBD `location_id`, sex, age, and year. It does not join on country name alone. The generated merge-coverage and duplicate-key reports are included in `derived_data/figure2/`.

## 3. Socio-demographic Index

**Access class:** third-party GBD covariate.  
**Provider:** IHME/GHDx.

Retrieve the GBD 2021 SDI series for the same 204 locations and years 1992–2021. Preserve the provider file and query metadata, then generate the 204 × 30 matrix used by the temporal analyses. The current local source and matrices are fingerprinted as `SDI-*` in the input inventory.

With the three fingerprinted IHD, DD, and SDI matrices in one local directory, run `code/granger/reproduce_archived_granger_main.R <input-directory> <output-directory> [archived-results.csv]`. This reproduces the submitted three-variable VAR and its two legacy-labelled system tests without a network request. The IHD-labelled call jointly tests lagged IHD terms in the DD and SDI equations; the DD-labelled call jointly tests lagged DD terms in the IHD and SDI equations. The included audit reproduces all 204 archived classifications and records the exact source hashes under `derived_data/granger/archived_main_reconstruction/`.

The package also includes an offline small-island/cartographic sensitivity for these submitted system tests. Run `python code/granger/derive_submitted_system_test_exclusion_sensitivity.py` from the package root. It checks the packaged 45-unit exclusion list against the archived flags, retains 159 locations, and reapplies Benjamini-Hochberg correction separately to the two submitted raw-P-value families. It produces `derived_data/granger/submitted_system_test_small_island_exclusion.csv` and `submitted_system_test_small_island_exclusion_counts.csv`, with counts of 71 both labelled families, 13 IHD-labelled only, 60 DD-labelled only, and 15 neither. It does not refit the VAR or change the joint-system-test interpretation. The later `03_correct_granger_sensitivity.R` script fits separate target-specific equations and is a distinct post-submission sensitivity analysis rather than the submitted primary workflow.

## 4. PM2.5 and geographic coordinates

**Access class:** processed local inputs with incomplete source metadata.

The current GWR workspace contains `Country_with_PM25_Matched.csv` and `Country_with_LatLon_Matched.csv`. They are fingerprinted in the input inventory, but the originating PM2.5 product, version, unit, extraction date, licence, and coordinate-gazetteer provenance are not recorded in the available files. `Part7/Country_with_PM25_Matched.csv` is byte-identical to `Part6/PM25_1992_2021_matrix.csv` (40,070 bytes; SHA-256 `084290b1f9c24eaf980bcb0a354d496b6f46b6594da8171c6b61a88c0bb311b0`), which verifies a local duplicate lineage only. The coordinate file has 204 `location_name,lat,lng` rows and SHA-256 `620d973717eab5f131290ef56a4be7115a3881f75f57fc9d134557de3d749055`; no upstream generation record was found. These provenance fields could not be recovered for `v1.1.0`. Any future update should add:

- the provider and stable landing page;
- dataset/release version and retrieval date;
- PM2.5 definition and unit;
- country-matching and exclusion rules;
- licence or terms of use;
- a reproducible script that reconstructs both processed files.

Until these fields are supplied, these inputs are disclosed as processed local inputs with incomplete source metadata, not as independently retrievable data.

## 5. Map boundaries and small-island display

Analytical observations remain one row per GBD location. Any polygon replication used only for display occurs after statistical estimation and does not add observations to Pearson, Granger, forecast, or GWR models. Figure 2A–B uses `rworldmap::getMap(resolution = "low")` (Natural Earth-derived geometry), maps the 204 analysis names to ISO3 using `countrycode` plus three explicit manual overrides, and applies each country value to every polygon part in the matched feature. The exact row-level mapping, feature names/indices, match status, polygon-part counts, and multipart flags are in `derived_data/figure2/Figure2_AB_mapping_coverage.csv`; the six-step procedure is in `derived_data/figure2/Figure2_AB_cartographic_procedure.md`. Geometry is available for 203/204 study units, with Tokelau explicitly unmatched.

Before inspecting outcomes, the correlation, Granger, and GWR sensitivities use the same 45-unit rule: the 44 locations marked `SID` in the bundled `rworldmap`/Natural Earth metadata plus Tokelau. The correlation sensitivity readjusts S1 within 159 tests per sex and compares the 17 estimable age-specific Figure 2E-F distributions with the full analysis. For Granger analysis, one offline transformation reapplies both submitted legacy-label BH families over the retained 159 locations, while the distinct target-specific sensitivity recomputes its two directional families over the same retained set. GWR refits both fixed-bandwidth models over 159 locations while retaining the full-sample standardisation scale. Exact exclusion lists and machine-readable results are in the component directories under `derived_data/`.

## 6. IEU OpenGWAS and exploratory two-sample MR

**Access class:** third-party GWAS summary data accessed through IEU OpenGWAS; preserved local catalogue and aggregate outputs are included where permitted.  
**Catalogue and API:** https://opengwas.io and https://api.opengwas.io/  
**Authentication and allowance guidance:** https://api.opengwas.io/api/  
**`ieugwasr` guide:** https://mrcieu.github.io/ieugwasr/articles/guide.html  
**TwoSampleMR documentation:** https://mrcieu.github.io/TwoSampleMR/

### Preserved evidence included in this package

1. `source_data/mr/ao.csv` is the 15,703-row catalogue snapshot used by the preserved workflow. It was created by `TwoSampleMR::available_outcomes()` when the cache was absent and loaded from disk on later runs. It contains 11,989 European-ancestry records. The count describes catalogue metadata, not completed MR analyses, and a current catalogue request may differ.
2. `source_data/mr/IHD/bb.csv` and `source_data/mr/DD/bb.csv` are exact compact concatenations of the saved one-row aggregate results. They contain 5,880 IHD and 11,775 DD estimates, respectively. The companion `END.csv` files are also preserved.
3. `derived_data/mr/manifest/01_gwas_catalog_manifest_15703.csv` contains one row per catalogue record, its technical ancestry scope, outcome-specific scheduling position/status, saved-result status, exact result fields where available, and the literal status `no saved estimate; exact reason not recorded` where no result was retained. These are automated technical statuses, not author judgements about phenotype relevance.
4. `derived_data/mr/manifest/02_candidate_dual_outcome_summary_11988_IHD_anchor.csv` represents the 11,988-record IHD exposure schedule; `02b_common_candidate_dual_outcome_summary_11987.csv` is the common-ID set. Each outcome-specific run omits its own outcome from the exposure schedule, so there is no natural 11,988-ID common set.
5. `derived_data/mr/manifest/07_input_sha256.csv` fingerprints all 17,666 preserved source files, including the 17,655 numbered one-row result files. Those redundant numbered files are not duplicated in this package because `bb.csv` preserves their exact concatenated aggregate estimates; the audit verified matching exposure IDs, numeric estimates, methods, and instrument-count fields.
6. The preserved scripts used an exposure-instrument threshold of `P < 5 × 10^-6`, LD clumping at `r² = 0.001` within 10,000 kb, no outcome proxies, and harmonisation action 2. These are the reconstructed historical settings reported in the revision. The submitted manuscript's former `P < 5 × 10^-8` description was inconsistent with the located scripts and has been corrected.
7. IHD outcome `finn-b-I9_IHD` had 31,640 cases and 187,152 controls; DD outcome `finn-b-F5_DEPRESSIO` had 23,424 cases and 192,220 controls in the retained catalogue metadata.

### Exploratory scope and post-analysis reporting

No phenotype was manually included or excluded before analysis according to its name, clinical relevance, modifiability, expected direction, or result. The automated technical scope retained records labelled European, applied the stored `eqtl-a-*` data-class rule (zero matches in this snapshot), omitted the target outcome itself, sorted IDs, and scheduled every remaining exposure.

Benjamini-Hochberg adjustment was performed separately for IHD and DD with a fixed family size of 11,988 per outcome; missing saved estimates were represented by `P = 1`. Set A required q < 0.05 for both outcomes, concordant non-zero effect direction, and IVW for both outcomes (49 candidates). Set B additionally excluded all `finn-b-*` exposures after the exploratory screen to reduce participant-overlap and same-biobank dependence because both outcomes were FinnGen datasets (29 candidates; 20 positive and 9 negative directions). Set B is the final Table 1/Figure 7 reporting set. This safeguard is not a claim that MR exposure and outcome GWAS must always originate from separate databases. Set C further excluded 11 obvious downstream clinical, diagnosis, medication, health-status, or healthcare-use markers and is supplied only as a descriptive sensitivity set (18 candidates), not as an unreported pre-screen.

These files reconstruct the aggregate discovery screen but do not recover the exact historical DD SNP-level run underlying the withdrawn 50-row table. The revised 29-candidate set replaces that table. A separately labelled targeted current-data follow-up was completed for all 29 traits against both outcomes (58 pairs) and is archived under `mr_sensitivity_29/` and `documents/Supplementary_Data_S3_MR_outputs_and_code.zip`. It supplies harmonised instruments, F statistics, IVW, MR-Egger, weighted-median and weighted-mode estimates, heterogeneity, Egger intercepts, single-SNP, leave-one-out and MR-PRESSO outputs. It does not retroactively recreate the lost historical run or change discovery q values.

### Online-access safeguards

The targeted 29-trait follow-up used authorised OpenGWAS retrieval with sequential, cached requests and conservative pacing; it was not a catalogue crawler. The archived reconstruction itself is offline. `code/mr/00_catalogue_snapshot_provenance.R` validates `ao.csv` offline by default. Any future acquisition must remain explicitly enabled, sequential and cached, wait at least 95 seconds between top-level requests, and stop immediately on `429`, allowance or `Retry-After` signals. Operators must follow current provider authentication, licensing and access rules. Tokens, private headers and signed URLs are excluded from the repository.

See `MR_RECONSTRUCTION_README.md` for the package map and interpretation limits.

## 7. FinnGen/Risteys CodeWAS context

**Access class:** public web interface; release-specific endpoint snapshots were not retained for `v1.1.0`.<br>
**Official interface:** https://risteys.finngen.fi/

1. Select and record a fixed FinnGen/Risteys release rather than relying on the moving default interface.
2. Open endpoints `I9_IHD` and `F5_DEPRESSIO` within that release.
3. Save the endpoint definition, release number, access date, matched case/control counts, and downloadable CodeWAS table where the interface permits it.
4. Record that CodeWAS constructs a case/control cohort matched on year of birth and sex and applies code-level association testing. These results provide observational clinical context; they are not MR estimates and do not establish causation.
5. Preserve the Finnish/European ancestry limitation when interpreting transferability to the 204-location ecological analysis.

## 8. Repository release and archive

The public repository contains scripts, derived output tables, figure source data, manifests, README files, and permitted source data. Where redistribution rights were not established, it supplies provider retrieval instructions and local fingerprints instead of the third-party files. The new minimal preprocessing entry point reconstructs the core disease inputs from the retained GBD combined extracts. Sanitised historical Figure 1/Figure 3/SDI references remain quarantined and are not substituted for that entry point. PM2.5, coordinate, and release-specific FinnGen/Risteys provenance gaps remain explicitly disclosed.

- GitHub repository: https://github.com/casper4869/IHD-DD-reproducibility
- Published GitHub release: https://github.com/casper4869/IHD-DD-reproducibility/releases/tag/v1.1.0
- Archived release tag: `v1.1.0`
- Zenodo version DOI: https://doi.org/10.5281/zenodo.22878656
- Zenodo concept DOI: https://doi.org/10.5281/zenodo.22878655
- Release version: `1.1.0`
- Repository-wide reuse licence: none; author-created rights are retained unless a file states otherwise
- Zenodo rights identifier: `Other (Not Open)` with public file access
- Third-party material: original provider and dataset-owner terms; see `RIGHTS_AND_LICENSING.md`

## 9. Data and Code Availability text

> The Global Burden of Disease 2021 estimates used in this study are third-party data available through the IHME GBD Results Tool (https://vizhub.healthdata.org/gbd-results/) subject to the provider's registration and terms of use. The exact query settings, file fingerprints, preprocessing records, available analysis scripts, derived source tables, and figure-generation code are provided in release 1.1.0 at https://github.com/casper4869/IHD-DD-reproducibility and permanently archived at https://doi.org/10.5281/zenodo.22878656. IEU OpenGWAS data are accessible through https://opengwas.io subject to the applicable access terms. The archived release includes the preserved 15,703-record catalogue snapshot, the complete reconstructed catalogue-to-analysis status manifest, OpenGWAS identifiers, compact saved aggregate IHD and DD results, post-analysis candidate-set rules, source-file SHA-256 fingerprints, and final 29-candidate reporting tables. The catalogue count is not presented as the number of completed MR analyses. The historical DD SNP-level run was not retained. The archive separately supplies the completed current targeted 29-trait sensitivity follow-up, which is not claimed as an exact recreation of the lost historical run. FinnGen CodeWAS endpoint information is available through the release-specific Risteys interface (https://risteys.finngen.fi/). Third-party source files are not redistributed where the authors do not hold redistribution rights; step-by-step retrieval instructions and SHA-256 fingerprints are provided in the repository.

The disclosed absence of the historical DD SNP-level objects and the stated non-MR provenance gaps are analysis limitations, not missing release metadata.
