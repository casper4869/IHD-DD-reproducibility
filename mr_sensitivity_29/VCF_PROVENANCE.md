# Official outcome VCF provenance

The exact outcome IDs finn-b-I9_IHD and finn-b-F5_DEPRESSIO were resolved once through ieugwasr::gwasinfo_files, authenticated using ieugwasr::get_opengwas_jwt(). Two official compressed VCFs were downloaded sequentially with at least 95 seconds between request starts. No web scraping or SNP-by-SNP network enumeration was used. Signed access URLs, JWTs and original downloaded files are excluded from the publication bundle.

The VCF headers specify ALT as the effect allele for ES and AF, and REF as the other allele. LP is minus log10(P); the local extractor restores P as 10^(-LP). ES and SE were used without transformation. Both distributed VCFs use HG19/GRCh37. Matching used rsID, followed by TwoSampleMR allele harmonisation with action=2; no proxy substitution was requested. Of 6,875 requested unique SNPs, each outcome matched 6,570 rsIDs. Fourteen rsIDs mapped to more than one VCF record and were excluded in full rather than selecting an arbitrary record; 6,556 unambiguous records remained per outcome. The 305 unmatched rsIDs and all ambiguous records are separately logged. Variant-specific SS fields were absent and were left missing, rather than replaced by a guessed sample size.

The official VCF SAMPLE header incorrectly or inconsistently describes StudyType=Continuous, whereas the API metadata labels both endpoints Binary and reports case/control counts (IHD 31,640/187,152; DD 23,424/192,220). The disease endpoints are treated as binary. FinnGen R5 describes its GWAS as mixed-model logistic regression using SAIGE and its beta as the alternative-allele effect estimate; this supports the log-odds interpretation rather than the VCF StudyType label. Original FinnGen coordinates are GRCh38; the files used here are the OpenGWAS-distributed GRCh37 conversions, whose headers and checksums have been preserved privately. This metadata conflict is a further reason not to use an automatic continuous-trait fallback for Steiger tests. Validated population-prevalence inputs were not established, so Steiger results are not claimed.

Official documentation checked on 2026-09-21:

- https://mrcieu.github.io/ieugwasr/reference/gwasinfo_files.html
- https://github.com/MRCIEU/gwas-vcf-specification
- https://finngen.gitbook.io/documentation/r5/data-description
- https://finngen.gitbook.io/documentation/r5/methods/phewas

Full-file SHA-256, sizes and scanned record counts are in vcf_extraction_audit.json. Headers contain upstream filesystem paths and are retained only in PRIVATE_NOT_FOR_ARCHIVE. Neither the older historical SNP objects nor the historical database state is claimed to have been reconstructed.
