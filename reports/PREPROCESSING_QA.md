# Minimal GBD preprocessing QA

The retained raw IHD and DD GBD extracts were filtered to Incidence/Rate, 1992-2021 and the fixed 204-location crosswalk.

- Rebuilt age-standardised full-precision matrices agree with Part 4 within CSV numeric precision (<5e-7).
- Rebuilt two-decimal matrices agree exactly with Part 5 and Part 7 after normalising one legacy text-encoding spelling of Côte d'Ivoire.
- Rebuilt female and male age-specific paired long tables each contain 122,400 rows and agree exactly with the retained Part 2 inputs.
- The comparison changes no manuscript result or figure; it documents how the retained raw disease extracts generate the existing analysis inputs.
- SDI uses the already curated 204-location matrix. Upstream PM2.5 and coordinate provenance limitations remain separately disclosed.
