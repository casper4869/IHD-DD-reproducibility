# Supplementary Data S3 — targeted MR sensitivity analysis

This archive contains the complete instrument-level follow-up of the 29 Figure 7 traits against IHD and DD (58 pairs), retrieved and analysed on 21 September 2026. It supplements the historical discovery screen; it does not repeat all 11,988 scheduled exposures or replace discovery q values. All 29 traits are retained regardless of sensitivity findings. The readable result workbook is Supplementary Data S2.

## Offline reproduction

Unzip into a writable folder and set it as the R working directory, or set MR_SENSITIVITY_DIR to its absolute path. Required R packages and exact analysis versions are recorded in sessionInfo_analysis.txt. The supplied cache, pair and PRESSO RDS files contain only numerical analysis objects, not authentication or HTTP response objects.

1. Run analyse_targeted.R for IVW, MR-Egger, weighted median/mode, heterogeneity, intercept, strength, single-SNP and leave-one-out outputs.
2. Run validate_presso_fast.R, validate_presso_distortion_candidate.R and validate_real_distortion.R in that order, then run_presso.R for MR-PRESSO. Completed pairs are cached. Optional local parallel execution uses PRESSO_WORKERS and PRESSO_WORKER (1 through the worker count), with the same per-pair seeds; use distinct worker indices.
3. After all 58 pair files are present, run finalise_presso.R, summarise_targeted.R and export_presso_details.R in that order to verify completion and generate the complete tables and SNP-level outputs.

Existing pair caches are reused. For a fresh computational reproduction, copy only cache/harmonised_all.rds, cache/instruments_all.rds, locked_candidates.csv, FETCH_COMPLETE.txt and the analysis scripts into a new directory, then run the same sequence. Each script locks the input signature. Do not combine changed inputs with old output caches. No network access is needed for these offline steps.

## Optional official retrieval

acquire_targeted_inputs.R is disabled unless RUN_OPENGWAS_SENSITIVITY=YES is explicitly set. Use ieugwasr::get_opengwas_jwt() with a valid locally configured JWT. Never paste a token into source code or an output table. Read the current OpenGWAS terms and allowance documentation first: https://api.opengwas.io/api/ . Requests are sequential and at least 95 seconds apart; HTTP errors including 429 stop the run without retry. Do not bypass provider allowances or repeatedly restart after a limit response. This code is not a crawler.

The fixed 29 exposure IDs are cached in batches of up to three, with P<5e-6, European LD clumping r2=0.001 and 10,000 kb. Outcomes are acquired as two official exact-ID VCF files via gwasinfo_files, rather than thousands of per-SNP requests. Download URLs are temporary and must not be published. Once downloaded, run extract_local_vcf.py with Python 3.11 or later and harmonise_local_vcf.R with R. Both are offline. See VCF_PROVENANCE.md for the exact allele convention, ambiguous rsID exclusions and upstream StudyType conflict. Do not treat the binary endpoints as continuous for Steiger calculations.

## Interpretation and rights

All sensitivity P values are conditional on discovery selection. q_sensitivity_58 is descriptive BH adjustment across 58 pairs per method or diagnostic, never the original 11,988-test discovery q. Different exposure phenotype scales prevent direct clinical comparison of ORs. Frequent heterogeneity and low I2GX limit causal interpretation. Non-significant pleiotropy tests do not establish absence of pleiotropy. Failed, untriggered and non-estimable tests are distinct from zero effects.

The located historical DD script specifies 5e-6; the historical IHD threshold remains unverified. Offline instrument-count comparisons suggest a possible configuration difference but do not prove provenance. This follow-up deliberately uses a documented common 5e-6 threshold and is reported separately from historical discovery, not as exact reproduction of the original estimates.

Source GWAS data remain subject to their provider terms and licences; inclusion for verification is not a blanket licence to redistribute third-party data. The complete VCFs, private headers, signed URLs and credentials are excluded. See source IDs and access instructions for authorised retrieval. Raw historical SNP-level objects were not retained and are not claimed to have been recovered.
