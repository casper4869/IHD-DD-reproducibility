# Minimal GBD preprocessing

This entry point closes the documented path from the retained combined GBD disease extracts to the core IHD/DD analysis inputs. It does not alter historical files or rerun downstream models.

Run with R 4.5 and `data.table`, `digest`:

```powershell
$env:GBD_SOURCE_DIR = "<folder containing IHD_country.csv and DD_country.csv>"
$env:GBD_LOCATION_CROSSWALK = "<two-column location_id/location_name file defining the 204 study locations>"
$env:GBD_SDI_204_FILE = "<curated SDI_1992_2021_204countries.csv>"
$env:GBD_PREPROCESS_OUTPUT = "<new writable output folder>"
Rscript 01_build_gbd_analysis_inputs.R
```

Fixed filters are `Incidence`, `Rate`, years 1992–2021, the 204 named study locations, age-standardised series for both/male/female and 20 age groups for male/female. The script validates row counts, unique keys and missing values and writes SHA-256 inventories.

The curated 204-location SDI table is treated as an input. The historical source file contained a country and a US-state row both named Georgia; the retained 204-location table contains the country value. This minimal entry point does not repeat the fragile historical positional deletion.
