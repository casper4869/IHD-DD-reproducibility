# Independent audit of the alternative temporal-precedence analysis and sensitivity display

> **Scope:** Post-submission internal audit/sensitivity only. This file does not describe or replace the manuscript Figure 5.


**Audit date:** 2026-09-18
**Reviewer role:** independent checker; no authorship of the audited scripts or outputs
**Files audited:** `03_correct_granger_sensitivity.R`, `06_create_figure5_corrected.R`, immutable Part 4/Part 7 inputs, all files under `granger_corrected`, and all Figure 5 exports under `figure5_corrected`.

## Decision

**REVISE for inferential use; computational implementation passes.**

I found no direction-reversal, SDI-endogeneity, stale-source, multiplicity, or figure-binding implementation error. An independent recomputation from the three raw 1992–2021 matrices reproduced every selected lag, Newey–West and HC3 P value, BH q value, coefficient, Breusch–Godfrey result, Cook's-distance result, SID flag, and final classification to numerical precision. The current analysis nevertheless fails the statistical-validity and robustness gates if Panel A is treated as evidence of a stable directional pattern: 182/204 countries are classified as DD-to-IHD with Newey–West(2), but only 11/204 remain DD-to-IHD with HC3 using the same fitted equations and multiplicity families. All 408 directional equation fits exceed the predeclared Cook's-distance threshold for at least one observation, and 84/204 countries have a residual serial-correlation flag in at least one direction. The paired map is retained only as an explicitly exploratory internal specification-sensitivity display and is not the manuscript Figure 5; the audit conclusion is lack of robustness rather than the 182-country Panel A count.

## Disqualifying defects and required revisions

1. **The Newey–West directional classification is not robust to the covariance estimator.** The independently reproduced Newey–West classifications were 1 bidirectional, 182 DD-to-IHD, 0 IHD-to-DD, and 21 neither. The HC3 classifications from the identical equations were 0 bidirectional, 11 DD-to-IHD, 0 IHD-to-DD, and 193 neither. Of the 182 Newey–West DD-to-IHD classifications, 171 become neither under HC3; the single Newey–West bidirectional classification (People's Republic of China) also becomes neither. This is a statistical-validity/robustness limitation, not an implementation error. The manuscript must not describe the 182-country pattern as a stable or general directional finding. The internal audit legend identifies Panel A as the Newey-West specification, and the audit artwork does not present it as a stable substantive result.

2. **The short-series diagnostics do not support strong inferential language.** BIC selected lag 3 for 113 countries, lag 2 for 90, and lag 1 for only 1; the lag-3 models have 18 residual degrees of freedom. The upper lag boundary is therefore selected in 55.4% of countries. Breusch–Godfrey P < 0.05 occurred in at least one direction for 84/204 countries (90/408 directional equations). Every one of the 408 equation fits exceeded Cook's D > 4/n for at least one observation. ADF P values for the log-change series were >=0.05 for 152/204 IHD series and 204/204 DD series; given the low power of ADF with 29 changes, these do not prove nonstationarity, but they also do not provide affirmative stationarity evidence. These are limitations of the data/model and should be reported as such.

3. **The submitted figure footer and legend used an ambiguous denominator; this is resolved in the revised caption.** “Residual serial-correlation flags occurred in 84/204 models” meant that 84 of 204 country analyses had a flag in at least one of two directional equations; 90 of 408 individual directional equations were flagged. The revised artwork removes this diagnostic footer, and the accompanying caption now gives both exact denominators. It likewise states that all 408 directional equation fits exceeded the stated Cook's-distance threshold for at least one observation. This was a reporting defect, not a numerical defect.

4. **Newey–West inference is asymptotic despite the small samples.** `adjust=TRUE` applies an n/(n-k) covariance scaling and the Wald restriction is referred to an F distribution with residual degrees of freedom, but this does not make HAC inference exact for 18–24 residual degrees of freedom. The HAC/HC3 standard-error ratio had median 0.319 (range 0.00189–1.135), explaining the sharp classification instability. Model-selection uncertainty from choosing the lag on the same 29 changes is also absent from the P values. If the authors retain a “primary” directional classification, a predeclared small-sample procedure such as a suitable restricted wild/bootstrap test would be needed; otherwise the defensible response is to report specification sensitivity and avoid a definitive country classification claim.

## Implementation verification

- Raw cohort integrity passed: each matrix contained 204 unique locations and the same 30 annual columns (1992–2021); all 204 fits succeeded in both directions, with no missing primary P or q values and no lag-selection warnings/errors.
- The intended direction was implemented correctly. IHD-to-DD regresses current DD log change on DD lags, IHD lags, and contemporaneous SDI change; DD-to-IHD reverses target/cause. The joint restriction tests only the cause-lag terms in the intended target equation.
- SDI is exogenous in both the BIC lag search (`exogen`) and the separate target equations (`SDI_exogenous`); it is never included as an endogenous response.
- Independent full recomputation matched the saved output with maximum absolute differences of 5.6e-16 for P/q values, 4.8e-14 for lag-1 coefficients, 5.6e-16 for BG P values, and 3.3e-11 for Cook's distance. All selected lags matched exactly.
- BH adjustment is applied to unrounded P values in two declared 204-test direction-specific families. The independently recomputed classifications exactly matched all 204 saved primary rows and the Figure 5 source.
- Fixed-lag Newey–West sensitivities were also internally consistent: lag 1 produced 157 DD-to-IHD and 47 neither; lag 2 produced 186 DD-to-IHD and 18 neither. These analyses do not resolve covariance-estimator sensitivity.

## Small-island sensitivity

The cartographic/SIDS exclusion is computationally correct and outcome-independent. ISO3 matching was complete; the rule excluded all study units matched to the bundled `rworldmap`/Natural Earth `SID == "SID"` attribute and additionally excluded Tokelau because it has no country feature in that bundled geometry. The final exclusion set contains 45 units and retains 159. Recomputed BH correction among the retained countries reproduced 1 bidirectional, 147 DD-to-IHD, 0 IHD-to-DD, and 11 neither. The saved flags and exclusion list matched the independent derivation exactly.

Tokelau is present in the study matrix with ISO3 `TKL`, but neither its name nor `TKL` occurs in the bundled low-resolution geometry, so the additional cartographic exclusion is supported. The rule is a hybrid of Small Island Developing States metadata and explicit geometry absence; it is not a polygon-area or land-size threshold and includes several coastal states. The Methods should call it a “cartographic/SIDS sensitivity” and identify the package/geometry source.

## Internal sensitivity-display source, geometry, and visual audit

- The machine-readable figure source has 204 unique locations, 204 unique coordinate pairs, no missing/invalid coordinates, and no point outside the plotted latitude/longitude limits.
- Newey–West q values are identical to Supplementary Table S2. Independently recomputed HC3 q values matched the figure source within 5.6e-16. Panel counts and legend counts are correct.
- All input/output checksum manifests currently pass: 0 mismatches across 4 input entries, 13 analysis-output entries, and 8 Figure 5/source entries.
- PNG and TIFF are both 4320 x 1350 pixels at 600 dpi. PDF and SVG vector outputs are present and checksum-bound.
- Full-size visual inspection confirmed that the maps, representative coordinate overlays, uppercase panel labels, and shared legend are present and unclipped. The artwork contains no in-panel title, method subtitle, counts, or diagnostic footer; those items are recorded in the internal audit legend.
- ISO3-linked polygon fills restore the submitted map's visual language, while 45 representative coordinate markers retain the prespecified small-island/territory set and geometry-unmatched units. The side-by-side panels use a single four-category legend and do not label either estimator as the stable or causal result.

## Evidence-gate assessment

| Gate | Result | Evidence |
|---|---|---|
| Data provenance/cohort integrity | Pass | Immutable input hashes match; 204 complete aligned series; no fit loss. |
| Computational reproducibility | Pass | Full independent recomputation matches; current manifests have zero checksum mismatches. |
| Direction/SDI implementation | Pass | Target-specific equations and cause-lag restrictions verified; SDI remains exogenous. |
| Multiplicity | Pass, conditional on the declared two-family policy | Unrounded P values; BH n=204 separately per direction; exact reproduction. |
| Statistical validity | Revise | Very short selected-lag models, 84 country-level BG flags, all 408 fits with Cook's-D flags, and asymptotic HAC inference. |
| Robustness | Fail for a stable directional claim | 182 DD-to-IHD under Newey–West versus 11 under HC3. |
| Claim calibration | Pass with the stated qualification | The paired display is isolated as an internal audit record and is not used as the manuscript Figure 5. |
| Figure source/geometry | Pass | Correct bound source and counts; valid 4320 x 1350 exports; ISO3 polygon fills plus 45 representative small-island/territory coordinate overlays; no clipping. |

## Acceptable use after revision

The alternative audit tables and sensitivity display support only the following conclusion: the country-level directional results are highly sensitive to the covariance estimator and to short-series diagnostic limitations, so they are exploratory temporal-prediction analyses and do not establish a robust predominant direction, individual-level comorbidity, or causation. They should not support a claim that DD broadly precedes IHD across 182 countries without this qualification.

## Delta audit: corrected cartographic/SIDS exclusion

The post-review correction is accepted. All three sensitivity scripts now implement or consume the same 45-unit rule: the Granger and GWR scripts independently construct the `rworldmap`/Natural Earth SID intersection plus Tokelau, while the correlation script reads the resulting GWR exclusion list and asserts 45 exclusions. The Granger retained table has 159 unique locations, excludes Tokelau, and its recomputed direction-specific BH values match an independent recomputation within 1.8e-15, with zero classification mismatches. Final Granger counts are 1 bidirectional, 147 DD-to-IHD, 0 IHD-to-DD, and 11 neither.

The GWR model summaries and comparisons use 159 retained locations, and the correlation outputs use 159 retained locations in each sex and in the weighted-correlation summaries. Analysis IDs, bandwidth traces, and S1 BH-family labels now report `159` dynamically or explicitly as appropriate. A targeted search found no obsolete exclusion/retention labels in the three scripts or their text/CSV/Markdown outputs after this report update. All seven current checksum manifests passed with zero mismatches: Granger inputs, Granger outputs, Figure 5 artifacts, GWR inputs, GWR outputs, correlation inputs, and correlation outputs. This delta does not change the overall decision above: computational implementation passes, while inferential use still requires the stated robustness and claim-calibration revisions.
