# Figure 2 full-composite QA

- Backend: R only (tiff, sf, rworldmap, ggplot2, ggridges, patchwork, grid).
- Panels A-B: regenerated from the corrected Supplementary Table S1 using sex-specific BH q<0.05 based on unrounded P values; q>=0.05 locations are grey.
- Corrected displayed counts: 46/204 female locations and 109/204 male locations have q<0.05.
- Geometry coverage: 203/204 study ISO3 units have a feature in the bundled low-resolution geometry; Tokelau is the expected unmatched unit.
- Panels C-D: retained from rows 681-1425 of the submitted Figure 2 TIFF; their source scripts used unrounded P values and BH correction within sex.
- Panels E-F: regenerated from the corrected machine-readable weighted-correlation table.
- The <5, 5-9, and 10-14 year groups are omitted from E-F because all 204 IHD annual series are constant within each sex; 17 estimable age groups are displayed.
- The original raw-P-filtered A-B and invalid E-F rows are excluded completely.
- Output dimensions: 2800 x 2227 pixels, matching the submitted figure.
- Decoded PNG and TIFF pixels are identical (maximum absolute difference 0).
- The retained C-D crop is pixel-identical to source rows 681-1425 in both PNG and TIFF (maximum absolute difference 0).
- Visual inspection at original resolution passed: panel labels A-F are present, q>=0.05 map units are grey, no text or legends are clipped or overlapping, and E-F span -1 to 1.
