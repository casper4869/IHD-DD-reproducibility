#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(ggrepel)
  library(stringr)
})

args <- commandArgs(trailingOnly = TRUE)
input_csv <- if (length(args) >= 1L) args[[1L]] else
  file.path("02_analysis", "mr_recovery", "alternative_sets",
            "set_B_setA_excluding_finn_b_exposures.csv")
output_dir <- if (length(args) >= 2L) args[[2L]] else
  file.path("02_analysis", "mr_recovery", "final_reporting")

if (!file.exists(input_csv)) stop("Input candidate file not found: ", input_csv)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

dat <- fread(input_csv)
stopifnot(nrow(dat) == 29L)
stopifnot(all(dat$`IHD.method` == "Inverse variance weighted"))
stopifnot(all(dat$`DD.method` == "Inverse variance weighted"))
stopifnot(all(dat$`IHD.q_BH_m11988` < 0.05))
stopifnot(all(dat$`DD.q_BH_m11988` < 0.05))
stopifnot(all(sign(dat$`IHD.b`) == sign(dat$`DD.b`)))
stopifnot(!any(grepl("^finn-b-", dat$`id.exposure`)))

dat[, trait_group := fcase(
  grepl("Age first had sexual intercourse|Years of schooling|Age at first live birth|Qualifications:|Age completed full time education|household income",
        trait, ignore.case = TRUE),
  "Sociodemographic or life-course phenotype",
  grepl("Mood swings|tiredness|Major depression|Miserableness|Neuroticism|Fed-up feelings",
        trait, ignore.case = TRUE),
  "Psychological or symptom phenotype",
  grepl("Overall health rating|treatments/medications|illness code|Diagnoses|diagnosed by doctor|self-reported non-cancer illnesses|Illnesses of siblings|prescription medications|Blood pressure medication",
        trait, ignore.case = TRUE),
  "Clinical or healthcare marker",
  default = "Potentially modifiable or intermediate phenotype"
)]

dat[, short_label := fcase(
  trait == "Age first had sexual intercourse", "Age at first sex",
  trait == "Years of schooling", "Years of schooling",
  trait == "Overall health rating", "Overall health rating",
  trait == "Mood swings", "Mood swings",
  trait == "Age at first live birth", "Age at first live birth",
  trait == "Number of treatments/medications taken", "Number of medications",
  grepl("tiredness", trait, ignore.case = TRUE), "Tiredness/lethargy",
  grepl("A levels", trait, ignore.case = TRUE), "A/AS-level qualification",
  grepl("self-reported: hypertension", trait, ignore.case = TRUE), "Self-reported hypertension",
  grepl("ICD10: I10", trait, ignore.case = TRUE), "ICD-10 I10 hypertension",
  grepl("High blood pressure$", trait), "Doctor-diagnosed high BP",
  trait == "Age completed full time education", "Age completed education",
  grepl("Number of self-reported", trait), "Number of illnesses",
  grepl("Qualifications: None", trait), "No listed qualification",
  grepl("household income", trait, ignore.case = TRUE), "Household income",
  trait == "Major depression", "Major depression",
  trait == "Miserableness", "Miserableness",
  trait == "smoking initiation", "Smoking initiation",
  grepl("Illnesses of siblings", trait), "Sibling illness history: none",
  trait == "Neuroticism score", "Neuroticism",
  grepl("Vascular/heart problems.*None", trait), "No reported vascular/heart problem",
  grepl("Leisure/social", trait), "No listed leisure/social activity",
  grepl("Taking other prescription", trait), "Other prescription medication",
  grepl("College or University", trait), "University degree",
  grepl("exogenous hormones", trait), "Blood-pressure medication code",
  trait == "Fed-up feelings", "Fed-up feelings",
  trait == "Leg fat percentage (right)", "Right-leg fat percentage",
  trait == "Leg fat mass (left)", "Left-leg fat mass",
  trait == "Leg fat mass (right)", "Right-leg fat mass",
  default = str_trunc(trait, 38)
)]

dat[, `:=`(
  plot_x = -log10(`IHD.q_BH_m11988`),
  plot_y = -log10(`DD.q_BH_m11988`),
  effect_direction = ifelse(`IHD.b` > 0, "Concordant positive", "Concordant negative")
)]
dat[, joint_support := pmin(plot_x, plot_y)]
dat[, label_for_plot := ifelse(frank(-joint_support, ties.method = "first") <= 2L,
                                short_label, NA_character_),
    by = trait_group]

setorder(dat, set_rank)
fwrite(dat, file.path(output_dir, "Table1_candidate_traits_29.csv"))

table_export <- dat[, .(
  `OpenGWAS ID` = `id.exposure`,
  Trait = trait,
  `Trait group` = trait_group,
  Direction = effect_direction,
  `IHD SNPs` = as.integer(`IHD.nsnp`),
  `IHD OR` = `IHD.OR`,
  `IHD CI lower` = `IHD.CI95_lower`,
  `IHD CI upper` = `IHD.CI95_upper`,
  `IHD P` = `IHD.p`,
  `IHD q` = `IHD.q_BH_m11988`,
  `DD SNPs` = as.integer(`DD.nsnp`),
  `DD OR` = `DD.OR`,
  `DD CI lower` = `DD.CI95_lower`,
  `DD CI upper` = `DD.CI95_upper`,
  `DD P` = `DD.p`,
  `DD q` = `DD.q_BH_m11988`
)]
fwrite(table_export, file.path(output_dir, "Table1_display_source_29.csv"))

colours <- c(
  "Potentially modifiable or intermediate phenotype" = "#0072B2",
  "Sociodemographic or life-course phenotype" = "#009E73",
  "Psychological or symptom phenotype" = "#CC79A7",
  "Clinical or healthcare marker" = "#D55E00"
)
shapes <- c("Concordant positive" = 16, "Concordant negative" = 17)
threshold <- -log10(0.05)

p <- ggplot(dat, aes(plot_x, plot_y)) +
  geom_hline(yintercept = threshold, linetype = "dashed", colour = "grey55", linewidth = 0.45) +
  geom_vline(xintercept = threshold, linetype = "dashed", colour = "grey55", linewidth = 0.45) +
  geom_point(aes(colour = trait_group, shape = effect_direction), size = 3.3, alpha = 0.90) +
  geom_text_repel(
    data = dat[!is.na(label_for_plot)],
    aes(label = label_for_plot),
    size = 2.75,
    colour = "grey12",
    box.padding = 0.38,
    point.padding = 0.25,
    min.segment.length = 0,
    segment.size = 0.25,
    seed = 20260920,
    max.overlaps = Inf,
    show.legend = FALSE
  ) +
  scale_colour_manual(values = colours, name = "Trait group") +
  scale_shape_manual(values = shapes, name = "Direction") +
  scale_x_continuous(expand = expansion(mult = c(0.04, 0.12))) +
  scale_y_continuous(expand = expansion(mult = c(0.04, 0.10))) +
  labs(
    title = "Exploratory candidate signals for IHD and depressive disorders",
    subtitle = "29 non-FinnGen exposure datasets passing outcome-specific BH q < 0.05 in both screens",
    x = expression("IHD statistical support, " * -log[10](italic(q))),
    y = expression("DD statistical support, " * -log[10](italic(q))),
    caption = paste0(
      "Uniform point size. Dashed lines: q = 0.05. ",
      "Colours describe phenotype type; shapes show concordant effect direction. ",
      "Labels identify the two strongest joint signals in each group; all 29 traits are listed in Table 1."
    )
  ) +
  guides(
    colour = guide_legend(override.aes = list(size = 4, alpha = 1)),
    shape = guide_legend(override.aes = list(size = 4, alpha = 1))
  ) +
  theme_classic(base_size = 11.5) +
  theme(
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 10.2, colour = "grey25", margin = margin(b = 8)),
    plot.caption = element_text(size = 8.7, hjust = 0, colour = "grey30", margin = margin(t = 8)),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold"),
    legend.position = "right",
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.5)
  )

ggsave(file.path(output_dir, "Figure7_revised.pdf"), p, width = 12.5, height = 9.0,
       units = "in", device = cairo_pdf, bg = "white")
grDevices::png(file.path(output_dir, "Figure7_revised.png"),
               width = 12.5, height = 9.0, units = "in", res = 180,
               type = "cairo", bg = "white")
print(p)
grDevices::dev.off()
grDevices::tiff(file.path(output_dir, "Figure7_revised.tif"),
                width = 12.5, height = 9.0, units = "in", res = 600,
                compression = "lzw", type = "cairo", bg = "white")
print(p)
grDevices::dev.off()

qa <- data.table(
  check = c(
    "candidate_count", "finn_b_exposures", "non_ivw_IHD", "non_ivw_DD",
    "IHD_q_ge_0.05", "DD_q_ge_0.05", "discordant_direction",
    "positive_direction", "negative_direction", "trait_group_count"
  ),
  value = c(
    nrow(dat), sum(grepl("^finn-b-", dat$`id.exposure`)),
    sum(dat$`IHD.method` != "Inverse variance weighted"),
    sum(dat$`DD.method` != "Inverse variance weighted"),
    sum(dat$`IHD.q_BH_m11988` >= 0.05), sum(dat$`DD.q_BH_m11988` >= 0.05),
    sum(sign(dat$`IHD.b`) != sign(dat$`DD.b`)),
    sum(dat$effect_direction == "Concordant positive"),
    sum(dat$effect_direction == "Concordant negative"),
    uniqueN(dat$trait_group)
  )
)
fwrite(qa, file.path(output_dir, "Figure7_Table1_QA.csv"))
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))

message("Created final reporting source and Figure 7 for ", nrow(dat), " candidate traits.")
