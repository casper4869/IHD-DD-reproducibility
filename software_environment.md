# Software environment

## Corrected analyses executed during revision

- Operating system: Windows 11 x64, build 26100.
- R: 4.5.0 (2025-04-11 ucrt), x86_64-w64-mingw32/x64.
- Time zone: Asia/Shanghai.
- Random seed used by Figure 2 and forecast scripts: `20260918`.

### Figure 2 / Supplementary Table S1

Primary attached packages: `data.table 1.18.0`, `weights 1.1.2`, `ggplot2 4.0.2`, `ggridges 0.5.7`, and `patchwork 1.3.2`. The correction also checks `openxlsx`, `digest`, and `svglite`; the full compositor uses `tiff`, `countrycode`, `rworldmap`, and `sf` to regenerate A–B and audit the display mapping. Complete records are in `derived_data/figure2/sessionInfo.txt` and `derived_data/figure2/Figure2_full_sessionInfo.txt`.

The Figure 2/S1 small-island sensitivity used `data.table 1.18.0`, `openxlsx 4.2.8`, and `digest 0.6.39`; its complete record is in `environment/sessionInfo_correlation_SID_sensitivity.txt`.

### Forecast audit / Figure 4

Recorded direct package versions:

- `MTS 1.2.1`
- `forecast 8.24.0`
- `vroom 1.6.5`
- `dplyr 1.1.4`
- `tidyr 1.3.2`
- `ggplot2 4.0.2`
- `patchwork 1.3.2`
- `svglite 2.2.2`
- `ragg 1.4.0`
- `jsonlite 2.0.0`
- `digest 0.6.39`

The complete loaded-package record is in `derived_data/forecast/sessionInfo.txt`; the concise list is in `derived_data/forecast/package_versions.csv`.

### Directional temporal-precedence analysis / Supplementary Table S2

Primary attached packages: `data.table 1.18.0`, `sandwich 3.1-1`, `car 3.1-3`, `lmtest 0.9-40`, `tseries 0.10-58`, `vars 1.6-1`, `openxlsx 4.2.8`, `digest 0.6.39`, `countrycode 1.6.1`, `sp 2.2-0`, and `rworldmap 1.3-8`. The complete record is in `environment/sessionInfo_granger.txt`.

The internal Figure 5 specification-sensitivity renderer (not the manuscript figure) additionally uses `ggplot2 4.0.2`, `patchwork 1.3.2`, `sf 1.0-21`, `rworldmap 1.3-8`, `cowplot 1.2.0`, and `svglite 2.2.2`. Its execution log is included in `derived_data/granger/`.

### GWR verification and small-island sensitivity

Primary attached packages: `data.table 1.18.0`, `sp 2.2-0`, `spgwr 0.6-37`, `spData 2.3.4`, `car 3.1-3`, `openxlsx 4.2.8`, `digest 0.6.39`, `countrycode 1.6.1`, and `rworldmap 1.3-8`. The complete record is in `environment/sessionInfo_gwr.txt`.

The revised Figure 6 renderer uses `ggplot2 4.0.2`, `dplyr 1.1.4`, `readr 2.2.0`, `maps 3.4.3`, `patchwork 1.3.2`, `svglite 2.2.2`, `ragg 1.4.0`, and `tiff 0.1-12`. Its complete record is in `derived_data/figure6/sessionInfo.txt`. The renderer reads the included audited 408-row coefficient table and makes no network request.

### Final 29-candidate Figure 7

Primary attached packages: `data.table 1.18.0`, `ggplot2 4.0.2`, `ggrepel 0.9.6`, and `stringr 1.6.0`. The complete record is in `derived_data/figure7/sessionInfo.txt` and `environment/sessionInfo_figure7.txt`.

`code/mr/02_build_final_mr_reporting.R` rebuilds Figure 7 directly from the included 29-candidate Set B CSV. It makes no network request and does not require Microsoft Word.

### Supplementary DOCX build and validation

The supplementary builder and validator use Python 3 and `python-docx`. The builder reads corrected S1/S2 CSV files and writes fixed-grid Word tables; the validator imports the builder's formatting functions and compares every displayed cell with the source data. The checked report is `reports/supplement_validation.md`.

## Historical environment caveat

The submitted manuscript stated R 4.3.2 for the original analysis. No complete lockfile or session record for that historical environment was found. Corrected revision outputs were generated and recorded in R 4.5.0. The release should report the environment actually used for each output rather than presenting the manuscript's historical R version as a verified global environment.

## Environment reconstruction

No `renv.lock` is included in `v1.0.0`. Reproducibility relies on the archived `sessionInfo()` records, package-version tables, source tables, independent reruns, and checksums. This is a disclosed environment limitation. A future release may add a clean-environment lockfile and document any package substitutions after numerical comparison with the archived outputs.
