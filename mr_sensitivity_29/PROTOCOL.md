# Locked targeted sensitivity protocol — 2026-09-21

Author authorised instrument-level follow-up of the 29 Figure 7 candidates (58 exposure–outcome pairs), without repeating the catalogue-wide screen. Scope is fixed by the archived final 29-trait CSV. Selection occurred using the historical screen; new results must not be used to silently drop traits or redefine that screen. This is a current-data sensitivity follow-up, not independent replication or exact recreation of the lost historical SNP objects.

## Acquisition and matching

- Official OpenGWAS API through locally configured JWT; no scraping, credential printing or redistribution. Cache every completed batch; sequential HTTP operations spaced by at least 95 seconds. Respect allowance headers and stop on 429 or any other HTTP error without automatic retries.
- Exposure P < 5e-6, LD r² 0.001, 10,000 kb; European LD reference; outcomes finn-b-I9_IHD and finn-b-F5_DEPRESSIO. No proxies, harmonisation action 2. Preserve all harmonised rows including excluded rows and reasons.
- Archive current metadata, parameters, timestamps, raw extracted tables, hashes and software versions. Compare new IVW SNP counts, beta, SE, OR and P with the corresponding historical pair; retain differences explicitly.

## Offline analyses

1. IVW, MR-Egger, weighted median and weighted mode, with 95% CI, nominal P and SNP counts. Use fixed random seeds and 1,000 bootstrap draws for weighted median/mode. Estimators lacking sufficient instruments are labelled not estimable, never zero or negative.
2. IVW and Egger Cochran Q; Egger intercept with SE and P; per-SNP F=(beta_exposure/SE_exposure)², min/median/mean and count below 10; I²GX using absolute exposure beta aligned to Egger orientation. Low I²GX limits Egger interpretation.
3. Single-SNP and leave-one-out IVW estimates, sign changes and maximal shifts. Retain every pair, not only robust or significant pairs.
4. MR-PRESSO global/outlier/distortion, where identifiable (at least 4 SNPs), with fixed seed and NbDistribution=max(10000,100×nsnp). Run as a separate cached offline queue; report Monte Carlo resolution and failures. Use a documented single-exposure algebraic optimisation of MRPRESSO 1.0: cache invariant observed-data LOO predictions and compute random-data LOO residuals from exact sufficient statistics. All other official tests and distortion logic remain unchanged. Five signed/heteroskedastic fixtures (n=4,5,8,20; no/single/multiple outliers) match every official output within 1e-10 and preserve identical final RNG states. Near-singular LOO denominators fall back to the original helper. This is an implementation optimisation, not an approximation or a new statistical estimator.
5. Steiger only if effect scales, sample sizes, allele frequencies and appropriate population prevalences can be established for binary outcomes and exposures. Never apply the continuous-trait fallback to IHD or DD, and never invent prevalence. Missing required metadata means not estimable, documented as such.

## Interpretation and multiplicity

The discovery BH families remain 11,988 candidates per outcome, as reported in the historical screen. No redefinition of discovery FDR on 29 selected hits. Sensitivity P values are descriptive conditional on selection. Optionally provide BH across all 58 planned pairs within each sensitivity method/diagnostic, clearly labelled sensitivity-only, with missing tests assigned P=1 for that descriptive adjustment. Do not claim independent confirmation or absence of pleiotropy from non-significant tests. Direction agreement, uncertainty, influence and assumption failures take precedence over counting nominal significance.

No changes to Figure 7/Table 1 discovery values until current-data comparisons are reviewed. Archive/public release is deferred by the author.

## Implementation-only amendment

Historical instrument-count comparison (offline, without changing the follow-up): IHD historical counts were closer to the P<5e-8 subset of currently retained instruments (21/29 within one SNP), whereas DD counts closely matched the full current extraction at the 5e-6 threshold (25/29 within one SNP). This is a configuration clue, not proof of the historical threshold or exact executable provenance. Only the located DD script verifies a 5e-6 threshold. The current follow-up uses the locked common threshold of 5e-6 for both outcomes and remains separately reported. API-returned rounded p values exactly equal to 5e-6 are retained as returned; no extra result-dependent boundary filter was imposed.

The distortion calculation additionally caches the invariant non-outlier sampling pool and uses the exact weighted no-intercept coefficient from the sampled sufficient statistics, with an original-lm fallback for near-singular denominators. The original repeated sample(pool)[1] calls, sampled indices, random-number order, draw count and statistical tests are unchanged. All five official-output fixtures pass tolerance 1e-10 with identical RNG state for this v2 implementation. A further check on the real 508-SNP schooling–IHD dataset over 200 distortion draws also agrees at tolerance 1e-10 with identical RNG state. Completed v1 pairs are retained because they implement the same estimator, settings and seeds. Each cached result records which computational implementation was used. This amendment changes computational work only, not analytical scope, multiplicity or sensitivity criteria.
