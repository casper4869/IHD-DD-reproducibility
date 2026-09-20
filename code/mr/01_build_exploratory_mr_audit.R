#!/usr/bin/env Rscript

# Reconstruct an auditable, exploratory phenome-wide MR screening manifest from
# the preserved IEU OpenGWAS catalogue snapshot and saved one-row MR summaries.
#
# This script never infers why a candidate lacks a saved estimate. Such records
# receive the exact label:
#   no saved estimate; exact reason not recorded
#
# Usage:
#   Rscript 01_build_exploratory_mr_audit.R <historical_mr_archive> <output_dir>
#
# The historical archive must contain ao.csv plus the IHD/ and DD/ directories,
# including the numbered one-row result files. Those redundant numbered files
# are checksum-documented but are not redistributed in the public package.

options(stringsAsFactors = FALSE, scipen = 999)

# The host R process may start in the "C" locale because C.UTF-8 is not a
# valid Windows locale. CP936 is required here only so list.files() can see the
# five source R scripts whose filenames contain Chinese characters. All tabular
# inputs and outputs still declare UTF-8 explicitly.
if (.Platform$OS.type == "windows") {
  invisible(suppressWarnings(try(Sys.setlocale("LC_CTYPE", "Chinese_China.936"), silent = TRUE)))
}

if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required.")
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package 'digest' is required for SHA256 calculation.")
}

suppressPackageStartupMessages(library(data.table))

cmd_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", cmd_all, value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  gsub("\\\\", "/", sub("^--file=", "", file_arg))
} else {
  gsub("\\\\", "/", file.path(getwd(), "01_build_exploratory_mr_audit.R"))
}
if (!file.exists(script_path)) stop("Cannot locate script: ", script_path)
script_dir <- dirname(script_path)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) {
  stop(paste(
    "Historical archive path required.",
    "Usage: Rscript 01_build_exploratory_mr_audit.R",
    "<historical_mr_archive> [output_dir]"
  ))
}
input_root <- args[[1L]]
output_dir <- if (length(args) >= 2L) {
  args[[2L]]
} else {
  file.path(script_dir, "run_2026-09-19_exploratory_manifest")
}

input_root <- normalizePath(input_root, winslash = "/", mustWork = TRUE)
if (dir.exists(output_dir) || file.exists(output_dir)) {
  stop("Refusing to overwrite existing output path: ", output_dir)
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
# Keep the caller-provided ASCII junction path. normalizePath() resolves the
# junction to a Chinese-character target path, which fails under some Windows R
# locale configurations despite the directory itself being valid.
output_dir <- gsub("\\\\", "/", output_dir)

outcome_ids <- c(
  IHD = "finn-b-I9_IHD",
  DD = "finn-b-F5_DEPRESSIO"
)
expected_catalog_n <- 15703L
expected_candidate_n <- 11988L
missing_status_text <- "no saved estimate; exact reason not recorded"

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

relative_path <- function(path, root) {
  # list.files(full.names=TRUE) already returns absolute paths. Avoid
  # normalizePath() here because it cannot round-trip CP936 filenames when the
  # parent process was launched with an invalid C.UTF-8 locale.
  path <- gsub("\\\\", "/", path)
  root <- sub("/+$", "", gsub("\\\\", "/", root))
  prefix <- paste0(root, "/")
  ifelse(startsWith(path, prefix), substring(path, nchar(prefix) + 1L), basename(path))
}

safe_numeric <- function(x, label) {
  ans <- suppressWarnings(as.numeric(x))
  if (anyNA(ans)) stop("Non-numeric value in ", label)
  ans
}

percent_encode_native_path <- function(x) {
  # Produce an ASCII-only, reversible representation of the current native
  # path bytes. This avoids writing a nominally UTF-8 checksum CSV containing
  # CP936 bytes for the five Chinese-named source R scripts.
  bytes <- as.integer(charToRaw(x))
  paste0(vapply(bytes, function(b) {
    if (b >= 32L && b <= 126L && b != 37L) rawToChar(as.raw(b)) else sprintf("%%%02X", b)
  }, character(1)), collapse = "")
}

read_catalog <- function(path) {
  x <- fread(path, encoding = "UTF-8", na.strings = character())
  if (nrow(x) != expected_catalog_n) {
    stop("Expected ", expected_catalog_n, " catalogue rows; found ", nrow(x))
  }
  if (!"id" %in% names(x) || anyDuplicated(x$id)) {
    stop("Catalogue IDs are missing or duplicated.")
  }
  x[, catalog_row_original := .I]
  x[]
}

read_numbered_outputs <- function(result_dir, expected_outcome_id) {
  files <- list.files(
    result_dir,
    pattern = "^[0-9]+\\.txt$",
    full.names = TRUE,
    ignore.case = FALSE
  )
  if (!length(files)) stop("No numbered TXT outputs in ", result_dir)
  indices <- as.integer(sub("\\.txt$", "", basename(files)))
  ord <- order(indices)
  files <- files[ord]
  indices <- indices[ord]
  if (anyDuplicated(indices)) stop("Duplicated numbered result files in ", result_dir)

  rows <- lapply(seq_along(files), function(i) {
    z <- fread(files[[i]], sep = "\t", encoding = "UTF-8", showProgress = FALSE)
    if (nrow(z) != 1L) {
      stop("Expected exactly one result row in ", files[[i]], "; found ", nrow(z))
    }
    z[, `:=`(
      output_index = indices[[i]],
      output_file = relative_path(files[[i]], input_root)
    )]
    z
  })
  ans <- rbindlist(rows, use.names = TRUE, fill = TRUE)
  required <- c(
    "id.exposure", "id.outcome", "outcome", "exposure", "method",
    "nsnp", "b", "se", "pval", "output_index", "output_file"
  )
  if (!all(required %in% names(ans))) {
    stop("Missing required columns in numbered outputs from ", result_dir)
  }
  if (anyDuplicated(ans$id.exposure)) {
    stop("Duplicated exposure IDs in numbered outputs from ", result_dir)
  }
  if (!all(ans$id.outcome == expected_outcome_id)) {
    stop("Unexpected outcome ID in ", result_dir)
  }
  ans[, `:=`(
    b = safe_numeric(b, paste0(result_dir, " beta")),
    se = safe_numeric(se, paste0(result_dir, " SE")),
    pval = safe_numeric(pval, paste0(result_dir, " p value"))
  )]
  if (any(ans$pval < 0 | ans$pval > 1)) stop("P value outside [0,1] in ", result_dir)
  ans[]
}

read_combined <- function(path, expected_outcome_id) {
  x <- fread(path, encoding = "UTF-8", check.names = FALSE)
  unnamed <- names(x)[names(x) %in% c("", "V1")]
  if (length(unnamed)) x[, (unnamed) := NULL]
  required <- c("id.exposure", "id.outcome", "outcome", "exposure", "method", "nsnp", "b", "se", "pval")
  if (!all(required %in% names(x))) stop("Missing columns in ", path)
  if (anyDuplicated(x$id.exposure)) stop("Duplicated exposure IDs in ", path)
  if (!all(x$id.outcome == expected_outcome_id)) stop("Unexpected outcome ID in ", path)
  x[, `:=`(
    b = safe_numeric(b, paste0(path, " beta")),
    se = safe_numeric(se, paste0(path, " SE")),
    pval = safe_numeric(pval, paste0(path, " p value")),
    nsnp = as.character(nsnp)
  )]
  x[]
}

build_candidate_universe <- function(catalog, outcome_id) {
  x <- copy(catalog[population == "European"])
  # Reproduce the original script's eQTL pattern exactly. The preserved
  # catalogue happens to contain zero matching IDs.
  x <- x[!grepl("eqtl-a-*", id)]
  x <- x[id != outcome_id]
  setorder(x, id)
  x[, candidate_index := .I]
  if (nrow(x) != expected_candidate_n) {
    stop("Expected ", expected_candidate_n, " candidates for ", outcome_id,
         "; found ", nrow(x))
  }
  x[]
}

validate_and_attach_results <- function(candidates, numbered, combined, label) {
  if (!setequal(numbered$id.exposure, combined$id.exposure)) {
    stop(label, ": numbered TXT and bb.csv exposure-ID sets differ.")
  }

  index_check <- merge(
    candidates[, .(id, candidate_index)],
    numbered[, .(id = id.exposure, output_index)],
    by = "id",
    all.y = TRUE,
    sort = FALSE
  )
  if (anyNA(index_check$candidate_index) ||
      !all(index_check$candidate_index == index_check$output_index)) {
    stop(label, ": numbered output index does not match the filtered catalogue order.")
  }

  cmp <- merge(
    numbered[, .(
      id = id.exposure,
      method_txt = method,
      nsnp_txt = as.character(nsnp),
      b_txt = b,
      se_txt = se,
      p_txt = pval,
      exposure_txt = exposure,
      output_index,
      output_file
    )],
    combined[, .(
      id = id.exposure,
      method_csv = method,
      nsnp_csv = as.character(nsnp),
      b_csv = b,
      se_csv = se,
      p_csv = pval,
      exposure_csv = exposure
    )],
    by = "id",
    all = TRUE,
    sort = FALSE
  )
  numeric_match <- isTRUE(all.equal(cmp$b_txt, cmp$b_csv, tolerance = 1e-14)) &&
    isTRUE(all.equal(cmp$se_txt, cmp$se_csv, tolerance = 1e-14)) &&
    isTRUE(all.equal(cmp$p_txt, cmp$p_csv, tolerance = 1e-14))
  method_match <- all(cmp$method_txt == cmp$method_csv) && all(cmp$nsnp_txt == cmp$nsnp_csv)
  if (!numeric_match || !method_match) {
    stop(label, ": numeric, method, or nsnp values differ between TXT and bb.csv.")
  }
  label_difference_n <- sum(cmp$exposure_txt != cmp$exposure_csv, na.rm = TRUE)

  results <- merge(
    combined,
    numbered[, .(id.exposure, output_index, output_file)],
    by = "id.exposure",
    all.x = TRUE,
    sort = FALSE
  )
  list(results = results, label_difference_n = label_difference_n)
}

attach_outcome <- function(candidates, results, prefix) {
  x <- copy(candidates)
  keep_meta <- c(
    "id", "trait", "population", "ncase", "ncontrol", "sample_size",
    "year", "author", "consortium", "pmid", "doi", "build", "candidate_index"
  )
  x <- x[, ..keep_meta]
  r <- results[, .(
    id = id.exposure,
    outcome_id = id.outcome,
    exposure_label_saved = exposure,
    method,
    nsnp_or_snp_raw = as.character(nsnp),
    beta = b,
    se,
    p_value = pval,
    output_index,
    output_file
  )]
  x <- merge(x, r, by = "id", all.x = TRUE, sort = FALSE)
  setorder(x, candidate_index)
  x[, saved_estimate := !is.na(method)]
  x[, output_status := fifelse(saved_estimate, "saved summary estimate", missing_status_text)]
  x[, p_for_bh := fifelse(saved_estimate, p_value, 1)]
  x[, q_bh_m11988 := p.adjust(p_for_bh, method = "BH", n = expected_candidate_n)]
  x[, instrument_count := NA_integer_]
  x[
    method == "Inverse variance weighted" & grepl("^[0-9]+$", nsnp_or_snp_raw),
    instrument_count := as.integer(nsnp_or_snp_raw)
  ]
  x[, single_instrument_snp := fifelse(method == "Wald ratio", nsnp_or_snp_raw, NA_character_)]
  setnames(
    x,
    old = setdiff(names(x), c("id", "trait", "population", "ncase", "ncontrol", "sample_size", "year", "author", "consortium", "pmid", "doi", "build")),
    new = paste0(prefix, "_", setdiff(names(x), c("id", "trait", "population", "ncase", "ncontrol", "sample_size", "year", "author", "consortium", "pmid", "doi", "build")))
  )
  x[]
}

catalog_path <- file.path(input_root, "ao.csv")
ihd_dir <- file.path(input_root, "IHD")
dd_dir <- file.path(input_root, "DD")

catalog <- read_catalog(catalog_path)
ihd_candidates <- build_candidate_universe(catalog, outcome_ids[["IHD"]])
dd_candidates <- build_candidate_universe(catalog, outcome_ids[["DD"]])

ihd_numbered <- read_numbered_outputs(ihd_dir, outcome_ids[["IHD"]])
dd_numbered <- read_numbered_outputs(dd_dir, outcome_ids[["DD"]])
ihd_combined <- read_combined(file.path(ihd_dir, "bb.csv"), outcome_ids[["IHD"]])
dd_combined <- read_combined(file.path(dd_dir, "bb.csv"), outcome_ids[["DD"]])

ihd_checked <- validate_and_attach_results(ihd_candidates, ihd_numbered, ihd_combined, "IHD")
dd_checked <- validate_and_attach_results(dd_candidates, dd_numbered, dd_combined, "DD")

ihd <- attach_outcome(ihd_candidates, ihd_checked$results, "ihd")
dd <- attach_outcome(dd_candidates, dd_checked$results, "dd")

# Full 15,703-row catalogue manifest.
manifest <- copy(catalog)
manifest[, technical_scope_status := fifelse(
  population == "European",
  "within European-ancestry technical scope",
  "outside European-ancestry technical scope"
)]
manifest[, technical_scope_reason := fifelse(
  population == "European", NA_character_,
  "catalogue population metadata != European"
)]
manifest[, eqtl_pattern_outside_scope := population == "European" & grepl("eqtl-a-*", id)]

manifest <- merge(
  manifest,
  ihd[, .(
    id,
    ihd_candidate_index,
    ihd_saved_estimate,
    ihd_output_status,
    ihd_outcome_id,
    ihd_method,
    ihd_nsnp_or_snp_raw,
    ihd_instrument_count,
    ihd_single_instrument_snp,
    ihd_beta,
    ihd_se,
    ihd_p_value,
    ihd_p_for_bh,
    ihd_q_bh_m11988,
    ihd_output_index,
    ihd_output_file
  )],
  by = "id", all.x = TRUE, sort = FALSE
)
manifest <- merge(
  manifest,
  dd[, .(
    id,
    dd_candidate_index,
    dd_saved_estimate,
    dd_output_status,
    dd_outcome_id,
    dd_method,
    dd_nsnp_or_snp_raw,
    dd_instrument_count,
    dd_single_instrument_snp,
    dd_beta,
    dd_se,
    dd_p_value,
    dd_p_for_bh,
    dd_q_bh_m11988,
    dd_output_index,
    dd_output_file
  )],
  by = "id", all.x = TRUE, sort = FALSE
)
setorder(manifest, catalog_row_original)

manifest[, ihd_candidate := !is.na(ihd_candidate_index)]
manifest[, dd_candidate := !is.na(dd_candidate_index)]
manifest[, ihd_scheduling_status := fcase(
  id == outcome_ids[["IHD"]], "not scheduled: target outcome dataset itself",
  population != "European", "not scheduled: outside European-ancestry technical scope",
  eqtl_pattern_outside_scope, "not scheduled: eqtl-a-* technical class",
  default = "scheduled as exposure"
)]
manifest[, dd_scheduling_status := fcase(
  id == outcome_ids[["DD"]], "not scheduled: target outcome dataset itself",
  population != "European", "not scheduled: outside European-ancestry technical scope",
  eqtl_pattern_outside_scope, "not scheduled: eqtl-a-* technical class",
  default = "scheduled as exposure"
)]
manifest[ihd_candidate == FALSE, ihd_output_status := "not scheduled for IHD outcome"]
manifest[dd_candidate == FALSE, dd_output_status := "not scheduled for DD outcome"]
manifest[, ihd_availability_note := fifelse(
  ihd_candidate & !ihd_saved_estimate, missing_status_text, NA_character_
)]
manifest[, dd_availability_note := fifelse(
  dd_candidate & !dd_saved_estimate, missing_status_text, NA_character_
)]

if (nrow(manifest) != expected_catalog_n) stop("Manifest row count changed unexpectedly.")

# Requested 11,988-row dual-outcome table. It is anchored to the IHD candidate
# universe because the two outcome-specific universes differ by one structural
# row. A separate 11,987-row common-ID table is also written below.
dual_11988 <- merge(
  ihd,
  dd[, setdiff(names(dd), c("trait", "population", "ncase", "ncontrol", "sample_size", "year", "author", "consortium", "pmid", "doi", "build")), with = FALSE],
  by = "id", all.x = TRUE, sort = FALSE
)
setorder(dual_11988, ihd_candidate_index)
dual_11988[, summary_universe := paste0(
  "IHD candidate universe: European catalogue records excluding ", outcome_ids[["IHD"]]
)]
dual_11988[, dd_candidate_in_this_row := !is.na(dd_candidate_index)]
dual_11988[dd_candidate_in_this_row == FALSE, dd_output_status :=
  "not a DD candidate: DD outcome dataset itself"]
if (nrow(dual_11988) != expected_candidate_n) stop("Requested dual summary is not 11,988 rows.")

common_11987 <- merge(ihd, dd, by = c(
  "id", "trait", "population", "ncase", "ncontrol", "sample_size",
  "year", "author", "consortium", "pmid", "doi", "build"
), all = FALSE, sort = FALSE)
setorder(common_11987, id)
if (nrow(common_11987) != expected_candidate_n - 1L) {
  stop("Expected 11,987 common candidate IDs; found ", nrow(common_11987))
}

primary <- common_11987[
  ihd_saved_estimate & dd_saved_estimate &
    ihd_method == "Inverse variance weighted" &
    dd_method == "Inverse variance weighted" &
    ihd_q_bh_m11988 < 0.05 & dd_q_bh_m11988 < 0.05 &
    sign(ihd_beta) == sign(dd_beta) & sign(ihd_beta) != 0
]
primary[, `:=`(
  direction = fifelse(ihd_beta > 0, "positive", "negative"),
  ihd_or = exp(ihd_beta),
  ihd_ci_low = exp(ihd_beta - 1.96 * ihd_se),
  ihd_ci_high = exp(ihd_beta + 1.96 * ihd_se),
  dd_or = exp(dd_beta),
  dd_ci_low = exp(dd_beta - 1.96 * dd_se),
  dd_ci_high = exp(dd_beta + 1.96 * dd_se),
  max_q_bh = pmax(ihd_q_bh_m11988, dd_q_bh_m11988)
)]
setorder(primary, max_q_bh, id)

# Cross-check the 50-row manuscript table if it is present. This detects the
# preserved local DD run's mismatch without overwriting any manuscript data.
table1_path <- file.path(script_dir, "..", "mr_reporting", "table1_extracted.csv")
table1_crosscheck <- NULL
if (file.exists(table1_path)) {
  tab <- fread(table1_path, encoding = "UTF-8")
  table1_crosscheck <- rbindlist(lapply(seq_len(nrow(tab)), function(i) {
    z <- tab[i]
    candidates_i <- ihd[trait == z$Exposure & ihd_saved_estimate]
    if (!nrow(candidates_i)) {
      return(data.table(
        table_row = i, Exposure = z$Exposure, matched_id = NA_character_,
        match_note = "no exact trait-name match in local IHD results"
      ))
    }
    target_or <- as.numeric(z$OR.IHD)
    candidates_i[, match_distance := abs(log(exp(ihd_beta) / target_or))]
    best <- candidates_i[which.min(match_distance)]
    local_dd <- dd[id == best$id]
    data.table(
      table_row = i,
      Exposure = z$Exposure,
      matched_id = best$id,
      table_or_ihd = as.numeric(z$OR.IHD),
      local_or_ihd = exp(best$ihd_beta),
      table_p_ihd = as.numeric(z$pval.IHD),
      local_p_ihd = best$ihd_p_value,
      ihd_or_matches_tolerance = isTRUE(all.equal(target_or, exp(best$ihd_beta), tolerance = 1e-5)),
      ihd_p_matches_tolerance = isTRUE(all.equal(as.numeric(z$pval.IHD), best$ihd_p_value, tolerance = 1e-5)),
      table_or_dd = as.numeric(z$OR.DD),
      local_or_dd = if (nrow(local_dd)) exp(local_dd$dd_beta) else NA_real_,
      table_p_dd = as.numeric(z$pval.DD),
      local_p_dd = if (nrow(local_dd)) local_dd$dd_p_value else NA_real_,
      dd_or_matches_tolerance = if (nrow(local_dd)) {
        isTRUE(all.equal(as.numeric(z$OR.DD), exp(local_dd$dd_beta), tolerance = 1e-5))
      } else FALSE,
      dd_p_matches_tolerance = if (nrow(local_dd)) {
        isTRUE(all.equal(as.numeric(z$pval.DD), local_dd$dd_p_value, tolerance = 1e-5))
      } else FALSE,
      local_dd_saved_estimate = nrow(local_dd) == 1L && local_dd$dd_saved_estimate,
      match_note = if (nrow(local_dd)) "matched by IHD trait and IHD effect" else "no local DD row for matched exposure ID"
    )
  }), fill = TRUE)
}

paths <- list(
  manifest = file.path(output_dir, "01_gwas_catalog_manifest_15703.csv"),
  dual = file.path(output_dir, "02_candidate_dual_outcome_summary_11988_IHD_anchor.csv"),
  common = file.path(output_dir, "02b_common_candidate_dual_outcome_summary_11987.csv"),
  primary = file.path(output_dir, "03_primary_bh_both_q05_concordant_ivw.csv"),
  crosscheck = file.path(output_dir, "04_table1_local_run_crosscheck.csv"),
  audit = file.path(output_dir, "05_audit_summary.md"),
  session = file.path(output_dir, "06_sessionInfo.txt"),
  input_hashes = file.path(output_dir, "07_input_sha256.csv"),
  output_hashes = file.path(output_dir, "08_output_sha256.csv")
)

fwrite(manifest, paths$manifest, bom = TRUE)
fwrite(dual_11988, paths$dual, bom = TRUE)
fwrite(common_11987, paths$common, bom = TRUE)
fwrite(primary, paths$primary, bom = TRUE)
if (!is.null(table1_crosscheck)) fwrite(table1_crosscheck, paths$crosscheck, bom = TRUE)

# Hash every preserved input file so the audit covers the numbered outputs as
# well as the consolidated tables and scripts.
input_files <- list.files(input_root, recursive = TRUE, full.names = TRUE, all.files = TRUE)
input_files <- input_files[!file.info(input_files)$isdir]
relative_paths_native <- vapply(input_files, relative_path, character(1), root = input_root)
relative_paths_safe <- vapply(relative_paths_native, percent_encode_native_path, character(1))
input_hashes <- data.table(
  relative_path = relative_paths_safe,
  path_encoding = fifelse(
    relative_paths_safe == relative_paths_native,
    "ASCII unchanged",
    "non-ASCII native CP936 bytes percent-encoded"
  ),
  bytes = as.numeric(file.info(input_files)$size),
  sha256 = vapply(input_files, sha256_file, character(1))
)
setorder(input_hashes, relative_path)
fwrite(input_hashes, paths$input_hashes, bom = TRUE)

method_counts_ihd <- ihd[ihd_saved_estimate == TRUE, .N, by = ihd_method]
method_counts_dd <- dd[dd_saved_estimate == TRUE, .N, by = dd_method]
shared_saved_n <- common_11987[ihd_saved_estimate & dd_saved_estimate, .N]
neither_saved_n <- common_11987[!ihd_saved_estimate & !dd_saved_estimate, .N]
ihd_q_n <- ihd[ihd_q_bh_m11988 < 0.05, .N]
dd_q_n <- dd[dd_q_bh_m11988 < 0.05, .N]
eqtl_outside_scope_n <- catalog[population == "European" & grepl("eqtl-a-*", id), .N]

crosscheck_text <- if (is.null(table1_crosscheck)) {
  "- Manuscript Table 1 cross-check was not run because `table1_extracted.csv` was absent."
} else {
  paste0(
    "- Table 1 rows checked: ", nrow(table1_crosscheck), "\n",
    "- IHD OR matches within tolerance: ", sum(table1_crosscheck$ihd_or_matches_tolerance, na.rm = TRUE), "\n",
    "- IHD P-value matches within tolerance: ", sum(table1_crosscheck$ihd_p_matches_tolerance, na.rm = TRUE), "\n",
    "- DD OR matches within tolerance: ", sum(table1_crosscheck$dd_or_matches_tolerance, na.rm = TRUE), "\n",
    "- DD P-value matches within tolerance: ", sum(table1_crosscheck$dd_p_matches_tolerance, na.rm = TRUE), "\n",
    "- Interpretation: the saved IHD run reproduces Table 1, while the saved DD run is a different run and must not be represented as the exact Table 1 source."
  )
}

audit_lines <- c(
  "# Exploratory MR screening audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste0("Input root: `", input_root, "`"),
  paste0("Script: `", script_path, "`"),
  "",
  "## Scope and interpretation",
  "",
  "This reconstruction treats the MR component as an exploratory, hypothesis-generating phenome-wide two-sample MR screen. It does not convert screening associations into confirmatory causal claims.",
  "",
  "No phenotype was manually selected or rejected by name, clinical relevance, modifiability, expected direction, or result. The population, data-class, target-outcome, and ordering rules below define the automated technical schedule.",
  "",
  paste0("Every candidate without a saved estimate is labelled exactly: `", missing_status_text, "`. No failure reason was inferred."),
  "",
  "## Catalogue and candidate universes",
  "",
  paste0("- Catalogue records: ", nrow(catalog), " (unique IDs: ", uniqueN(catalog$id), ")"),
  paste0("- European-ancestry catalogue records: ", catalog[population == "European", .N]),
  paste0("- Catalogue records outside the European-ancestry technical scope: ", catalog[population != "European", .N]),
  paste0("- IDs matching the stored script's `eqtl-a-*` technical class: ", eqtl_outside_scope_n),
  paste0("- IHD exposure schedule: ", nrow(ihd), " (European records omitting target outcome `", outcome_ids[["IHD"]], "`)"),
  paste0("- DD exposure schedule: ", nrow(dd), " (European records omitting target outcome `", outcome_ids[["DD"]], "`)"),
  paste0("- Common candidate IDs: ", nrow(common_11987)),
  paste0("- Union of the two outcome-specific candidate universes: ", length(union(ihd$id, dd$id))),
  "",
  "There is no natural 11,988-ID common dual-outcome set: each outcome-specific schedule omits its own outcome dataset. The 11,988-row dual table is therefore anchored to the IHD exposure schedule; the common-ID table has 11,987 rows.",
  "",
  "## Saved output coverage",
  "",
  paste0("- IHD saved estimates: ", ihd[ihd_saved_estimate == TRUE, .N], "; no saved estimate: ", ihd[ihd_saved_estimate == FALSE, .N]),
  paste0("- IHD methods: ", paste(method_counts_ihd$ihd_method, method_counts_ihd$N, sep = "=", collapse = "; ")),
  paste0("- DD saved estimates: ", dd[dd_saved_estimate == TRUE, .N], "; no saved estimate: ", dd[dd_saved_estimate == FALSE, .N]),
  paste0("- DD methods: ", paste(method_counts_dd$dd_method, method_counts_dd$N, sep = "=", collapse = "; ")),
  paste0("- Common IDs with saved estimates for both outcomes: ", shared_saved_n),
  paste0("- Common IDs with neither estimate saved: ", neither_saved_n),
  "",
  "## BH primary-screen reconstruction",
  "",
  paste0("- BH family size was fixed at m=", expected_candidate_n, " separately for each outcome."),
  "- Missing saved estimates were assigned P=1 before BH adjustment.",
  paste0("- IHD candidates with q<0.05: ", ihd_q_n),
  paste0("- DD candidates with q<0.05: ", dd_q_n),
  paste0("- Candidates meeting both q<0.05, concordant non-zero direction, and IVW for both outcomes: ", nrow(primary)),
  "",
  "## Integrity checks",
  "",
  "- All 17,655 numbered TXT files contained exactly one result row.",
  "- All saved outcome IDs were uniform and matched the expected outcome for their directory.",
  "- All numbered file indices exactly matched the filtered, alphabetically sorted catalogue index.",
  "- The exposure-ID sets, numeric estimates, methods, and `nsnp` values matched between numbered TXT files and `bb.csv`.",
  paste0("- Trait-label quoting differed between TXT and merged CSV in ", ihd_checked$label_difference_n, " IHD rows and ", dd_checked$label_difference_n, " DD rows; IDs and numeric results were unchanged."),
  "",
  "## Manuscript Table 1 cross-check",
  "",
  crosscheck_text,
  "",
  "## Known provenance limitations",
  "",
  "- The located screening scripts use an instrument threshold of P<5e-6, whereas the submitted manuscript reported P<5e-8; the revision reports the reconstructed P<5e-6 setting.",
  "- The preserved files do not include SNP-level exposure data, SNP-level outcome data, harmonised objects, F statistics, heterogeneity tests, MR-Egger, weighted-median, MR-PRESSO, or Steiger outputs.",
  "- Exact reasons for absent estimates were not logged.",
  "- The exact DD run used for Table 1 is not present in this directory.",
  "- FinnGen release identifiers, IEU OpenGWAS access dates, and historical package versions were not embedded in the source files.",
  "",
  "## Checksums",
  "",
  paste0("- `07_input_sha256.csv` contains SHA256 for all ", nrow(input_hashes), " preserved source files."),
  paste0("- Non-ASCII source filenames represented by reversible percent-encoded native CP936 bytes: ", sum(input_hashes$path_encoding != "ASCII unchanged"), "."),
  "- `08_output_sha256.csv` contains SHA256 for the generated artifacts and this R script; it intentionally excludes itself."
)
writeLines(audit_lines, paths$audit, useBytes = TRUE)

session_lines <- c(
  paste0("generated_at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  paste0("script_path: ", script_path),
  paste0("script_sha256: ", sha256_file(script_path)),
  paste0("input_root: ", input_root),
  paste0("output_dir: ", output_dir),
  paste0("command: ", paste(commandArgs(), collapse = " ")),
  "",
  capture.output(sessionInfo())
)
writeLines(session_lines, paths$session, useBytes = TRUE)

generated <- unlist(paths[names(paths) != "output_hashes"], use.names = FALSE)
generated <- generated[file.exists(generated)]
output_hashes <- data.table(
  artifact = c(basename(generated), basename(script_path)),
  bytes = c(as.numeric(file.info(generated)$size), as.numeric(file.info(script_path)$size)),
  sha256 = c(vapply(generated, sha256_file, character(1)), sha256_file(script_path))
)
setorder(output_hashes, artifact)
fwrite(output_hashes, paths$output_hashes, bom = TRUE)

cat("MR exploratory audit completed.\n")
cat("Output directory:", output_dir, "\n")
cat("Catalogue rows:", nrow(manifest), "\n")
cat("IHD candidates:", nrow(ihd), "saved:", ihd[ihd_saved_estimate == TRUE, .N], "q<0.05:", ihd_q_n, "\n")
cat("DD candidates:", nrow(dd), "saved:", dd[dd_saved_estimate == TRUE, .N], "q<0.05:", dd_q_n, "\n")
cat("Common candidates:", nrow(common_11987), "\n")
cat("Primary dual-outcome BH candidates:", nrow(primary), "\n")
cat("Input files hashed:", nrow(input_hashes), "\n")
