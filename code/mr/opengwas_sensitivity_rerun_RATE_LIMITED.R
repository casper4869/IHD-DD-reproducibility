#!/usr/bin/env Rscript

# Optional, deliberately slow and resumable instrument-level sensitivity rerun.
#
# IMPORTANT
# - This script is OFF by default. It makes no API request unless the environment
#   variable RUN_OPENGWAS_SENSITIVITY is set exactly to YES.
# - Read the current OpenGWAS authentication and allowance documentation before
#   enabling it: https://api.opengwas.io/api/#authentication and
#   https://api.opengwas.io/api/#allowance
# - Run sequentially. Do not parallelise, do not override HTTP 429 protection,
#   and do not use this script as a crawler.
# - Every completed exposure is cached. A later run resumes from the next item.

suppressPackageStartupMessages({
  library(TwoSampleMR)
  library(ieugwasr)
  library(data.table)
})

cmd_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", cmd_all, value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  gsub("\\\\", "/", sub("^--file=", "", file_arg))
} else {
  gsub("\\\\", "/", file.path(getwd(), "opengwas_sensitivity_rerun_RATE_LIMITED.R"))
}
package_root <- gsub("\\\\", "/", file.path(dirname(script_path), "..", ".."))

args <- commandArgs(trailingOnly = TRUE)
candidate_csv <- if (length(args) >= 1L) args[[1L]] else
  file.path(package_root, "derived_data", "mr", "alternative_sets",
            "set_B_setA_excluding_finn_b_exposures.csv")
output_dir <- if (length(args) >= 2L) args[[2L]] else
  file.path(getwd(), "optional_opengwas_rerun_output")

if (!identical(Sys.getenv("RUN_OPENGWAS_SENSITIVITY"), "YES")) {
  stop(paste(
    "No API request was made.",
    "Set RUN_OPENGWAS_SENSITIVITY=YES only after reviewing OpenGWAS allowance",
    "and after deciding that a slow, sequential rerun is necessary."
  ))
}
if (!file.exists(candidate_csv)) stop("Candidate file not found: ", candidate_csv)

jwt <- ieugwasr::get_opengwas_jwt()
if (!nzchar(jwt)) stop("OPENGWAS_JWT is not configured. No request was made.")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(output_dir, "cache"), showWarnings = FALSE)
dir.create(file.path(output_dir, "logs"), showWarnings = FALSE)

delay_seconds <- suppressWarnings(as.numeric(Sys.getenv("OPENGWAS_DELAY_SECONDS", "90")))
if (!is.finite(delay_seconds) || delay_seconds < 60) {
  stop("OPENGWAS_DELAY_SECONDS must be at least 60 seconds for this release script.")
}

candidate <- data.table::fread(candidate_csv)
if (!"id.exposure" %in% names(candidate)) stop("Candidate file lacks id.exposure")
candidate <- unique(candidate[, .(id.exposure, trait)])

outcomes <- c(IHD = "finn-b-I9_IHD", DD = "finn-b-F5_DEPRESSIO")
p1 <- 5e-6
r2 <- 0.001
kb <- 10000

log_path <- file.path(output_dir, "logs", "run_log.tsv")
append_log <- function(id, stage, status, detail = "") {
  row <- data.table::data.table(
    timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    id_exposure = id,
    stage = stage,
    status = status,
    detail = gsub("[\r\n\t]+", " ", detail)
  )
  data.table::fwrite(row, log_path, sep = "\t", append = file.exists(log_path),
                     col.names = !file.exists(log_path))
}

request_clock <- new.env(parent = emptyenv())
request_clock$last_request <- as.POSIXct(NA)

safe_request <- function(id, stage, expr) {
  # Pace every top-level API operation, including the two operations required
  # for one exposure. This avoids a burst of back-to-back requests. The API
  # client may split a very large operation internally; its allowance and 429
  # protections still apply, and any 429 stops the run without an automatic
  # retry. Increasing OPENGWAS_DELAY_SECONDS is always safe.
  if (!is.na(request_clock$last_request)) {
    elapsed <- as.numeric(difftime(Sys.time(), request_clock$last_request,
                                  units = "secs"))
    wait <- max(0, delay_seconds - elapsed) + stats::runif(1L, 0, 15)
    if (wait > 0) {
      append_log(id, stage, "WAIT_BEFORE_REQUEST", sprintf("%.1f seconds", wait))
      Sys.sleep(wait)
    }
  }
  ieugwasr::check_reset(override_429 = FALSE)
  request_clock$last_request <- Sys.time()
  tryCatch(
    force(expr),
    error = function(e) {
      msg <- conditionMessage(e)
      append_log(id, stage, "ERROR_STOP", msg)
      if (grepl("429|allowance|Too Many Requests|Retry-After", msg, ignore.case = TRUE)) {
        stop("OpenGWAS allowance/rate-limit signal received. Stopping without retry: ", msg)
      }
      stop("OpenGWAS request failed. Stopping for manual review; resume later: ", msg)
    }
  )
}

analyse_one <- function(id, trait) {
  cache_rds <- file.path(output_dir, "cache", paste0(id, ".rds"))
  result_csv <- file.path(output_dir, "cache", paste0(id, "_summary.csv"))
  if (file.exists(cache_rds) && file.exists(result_csv)) {
    append_log(id, "all", "SKIPPED_CACHED", trait)
    return(invisible(NULL))
  }

  append_log(id, "start", "STARTED", trait)
  instruments <- safe_request(id, "extract_instruments",
    TwoSampleMR::extract_instruments(
      outcomes = id,
      p1 = p1,
      clump = TRUE,
      r2 = r2,
      kb = kb,
      opengwas_jwt = jwt
    )
  )
  if (is.null(instruments) || nrow(instruments) == 0L) {
    append_log(id, "extract_instruments", "NO_INSTRUMENTS", trait)
    saveRDS(list(id = id, trait = trait, instruments = instruments), cache_rds)
    return(invisible(NULL))
  }

  outcome_dat <- safe_request(id, "extract_outcome_data",
    TwoSampleMR::extract_outcome_data(
      snps = instruments$SNP,
      outcomes = unname(outcomes),
      proxies = FALSE,
      opengwas_jwt = jwt
    )
  )
  if (is.null(outcome_dat) || nrow(outcome_dat) == 0L) {
    append_log(id, "extract_outcome_data", "NO_OUTCOME_ASSOCIATIONS", trait)
    saveRDS(list(id = id, trait = trait, instruments = instruments,
                 outcome_data = outcome_dat), cache_rds)
    return(invisible(NULL))
  }

  harmonised <- TwoSampleMR::harmonise_data(instruments, outcome_dat, action = 2)
  harmonised <- harmonised[harmonised$mr_keep %in% TRUE, , drop = FALSE]
  if (nrow(harmonised) == 0L) {
    append_log(id, "harmonise", "NO_RETAINED_SNPS", trait)
    saveRDS(list(id = id, trait = trait, instruments = instruments,
                 outcome_data = outcome_dat, harmonised = harmonised), cache_rds)
    return(invisible(NULL))
  }

  split_dat <- split(harmonised, harmonised$id.outcome)
  summaries <- lapply(names(split_dat), function(outcome_id) {
    dat <- split_dat[[outcome_id]]
    n_snp <- nrow(dat)
    methods <- "mr_ivw"
    if (n_snp >= 3L) methods <- c(methods, "mr_weighted_median", "mr_egger_regression")

    estimates <- TwoSampleMR::mr(dat, method_list = methods)
    heterogeneity <- if (n_snp >= 3L) {
      tryCatch(TwoSampleMR::mr_heterogeneity(dat, method_list = c("mr_ivw", "mr_egger_regression")),
               error = function(e) data.frame(error = conditionMessage(e)))
    } else data.frame(note = "Not estimated: fewer than 3 retained SNPs")
    pleiotropy <- if (n_snp >= 3L) {
      tryCatch(TwoSampleMR::mr_pleiotropy_test(dat),
               error = function(e) data.frame(error = conditionMessage(e)))
    } else data.frame(note = "Not estimated: fewer than 3 retained SNPs")
    single <- tryCatch(TwoSampleMR::mr_singlesnp(dat),
                       error = function(e) data.frame(error = conditionMessage(e)))
    loo <- if (n_snp >= 3L) {
      tryCatch(TwoSampleMR::mr_leaveoneout(dat),
               error = function(e) data.frame(error = conditionMessage(e)))
    } else data.frame(note = "Not estimated: fewer than 3 retained SNPs")

    f_values <- (dat$beta.exposure / dat$se.exposure)^2
    strength <- data.frame(
      id.exposure = id,
      id.outcome = outcome_id,
      nsnp = n_snp,
      mean_F = mean(f_values, na.rm = TRUE),
      median_F = stats::median(f_values, na.rm = TRUE),
      min_F = min(f_values, na.rm = TRUE)
    )
    list(estimates = estimates, heterogeneity = heterogeneity,
         pleiotropy = pleiotropy, single_snp = single,
         leave_one_out = loo, strength = strength)
  })
  names(summaries) <- names(split_dat)

  object <- list(
    id = id,
    trait = trait,
    parameters = list(p1 = p1, r2 = r2, kb = kb, proxies = FALSE,
                      harmonise_action = 2),
    instruments = instruments,
    outcome_data = outcome_dat,
    harmonised = harmonised,
    analyses = summaries,
    session_info = capture.output(sessionInfo())
  )
  saveRDS(object, cache_rds)

  flat <- data.table::rbindlist(lapply(summaries, function(z) {
    e <- data.table::as.data.table(z$estimates)
    s <- data.table::as.data.table(z$strength)
    e[, `:=`(mean_F = s$mean_F[1L], median_F = s$median_F[1L], min_F = s$min_F[1L])]
    e
  }), fill = TRUE)
  data.table::fwrite(flat, result_csv)
  append_log(id, "all", "COMPLETED", paste0(trait, "; retained rows=", nrow(harmonised)))
  invisible(NULL)
}

# A zero-cost authentication check is made once before the first data query.
safe_request("__AUTH__", "user", ieugwasr::user(opengwas_jwt = jwt))

for (i in seq_len(nrow(candidate))) {
  analyse_one(candidate$id.exposure[[i]], candidate$trait[[i]])
}

writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
message("Completed sequential, cached rerun for ", nrow(candidate), " candidate exposures.")
