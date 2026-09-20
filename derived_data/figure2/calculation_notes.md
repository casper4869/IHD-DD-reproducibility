# Corrected Figure 2E-F and Supplementary Table S1 calculation notes

## Table S1
For each country/territory and sex, Pearson's r is calculated across the 20 age-specific 2021 incidence-rate pairs. P values remain unrounded until Benjamini-Hochberg adjustment. The female and male strata are separate BH families of 204 tests each.

## Figure 2E-F
For each country/territory, sex, and age group, a weighted Pearson correlation is calculated across the 30 annual IHD and DD incidence-rate pairs (1992-2021). The weight for year t is the matching GBD population count for that country, sex, age group, and year. The plotted density for each age group is the unweighted distribution of these 204 country-level population-weighted correlations.

The <5 years, 5-9 years, and 10-14 years groups are non-estimable for both sexes because the IHD annual series is constant in every one of the 204 locations. Panels E-F therefore display the 17 estimable age groups from 15-19 years through 95+ years; all 1,224 non-estimable country-sex-age records are retained with an explicit status in the source table.

The submitted code selected column [1,2] from weights::wtd.cor(), which is the standard error. The corrected code explicitly selects the named `correlation` column. The full weighted-correlation P values and BH values are retained for audit, but Figure 2E-F is descriptive and is not filtered by significance because annual observations are serially dependent.

## Formula
For annual values x_t (IHD), y_t (DD), and population weight w_t, weighted means are xbar_w = sum(w_t*x_t)/sum(w_t) and ybar_w = sum(w_t*y_t)/sum(w_t). The plotted coefficient is r_w = sum[w_t(x_t-xbar_w)(y_t-ybar_w)] / sqrt(sum[w_t(x_t-xbar_w)^2] * sum[w_t(y_t-ybar_w)^2]).

All source values used for calculation are unrounded. Machine-readable results retain full precision.
