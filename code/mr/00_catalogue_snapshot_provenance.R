#!/usr/bin/env Rscript

# Provenance and safety wrapper for the historical OpenGWAS catalogue snapshot.
#
# The archived ao.csv was created with TwoSampleMR::available_outcomes() and was
# then reused from disk whenever it already existed. The 15,703 rows therefore
# describe that dated snapshot; they are not a claim about the current catalogue.
#
# Default behaviour is offline validation only. A fresh catalogue request is
# made only when REFRESH_OPENGWAS_CATALOGUE is set exactly to YES. Refreshing is
# unnecessary for reproducing the archived analysis and will not reproduce the
# historical snapshot if the provider catalogue has changed.

options(stringsAsFactors = FALSE)

cmd_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", cmd_all, value = TRUE)
script_path <- if (length(file_arg) == 1L) {
  gsub("\\\\", "/", sub("^--file=", "", file_arg))
} else {
  gsub("\\\\", "/", file.path(getwd(), "00_catalogue_snapshot_provenance.R"))
}
package_root <- gsub("\\\\", "/", file.path(dirname(script_path), "..", ".."))

args <- commandArgs(trailingOnly = TRUE)
catalogue_path <- if (length(args) >= 1L) args[[1L]] else
  file.path(package_root, "source_data", "mr", "ao.csv")

validate_snapshot <- function(path) {
  x <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot("id" %in% names(x), !anyDuplicated(x$id))
  message("Catalogue snapshot: ", gsub("\\\\", "/", path))
  message("Rows: ", nrow(x), "; unique IDs: ", length(unique(x$id)))
  invisible(x)
}

if (!identical(Sys.getenv("REFRESH_OPENGWAS_CATALOGUE"), "YES")) {
  if (!file.exists(catalogue_path)) {
    stop("Archived catalogue not found: ", catalogue_path,
         ". No network request was made.")
  }
  validate_snapshot(catalogue_path)
  message("Offline validation complete. No OpenGWAS request was made.")
  quit(save = "no", status = 0L)
}

if (file.exists(catalogue_path)) {
  stop("Refusing to overwrite an existing catalogue snapshot. Choose a new dated path.")
}
if (!requireNamespace("TwoSampleMR", quietly = TRUE)) {
  stop("Package 'TwoSampleMR' is required. No request was made.")
}
if (!nzchar(Sys.getenv("OPENGWAS_JWT"))) {
  stop("OPENGWAS_JWT must be configured in the user's environment, never in this script.")
}

message("Review the current OpenGWAS authentication, allowance, and access terms before continuing.")
message("This operation requests the catalogue once; it is not a per-study crawler.")
catalogue <- tryCatch(
  TwoSampleMR::available_outcomes(),
  error = function(e) {
    stop("Catalogue request failed and will not be retried automatically: ",
         conditionMessage(e))
  }
)
dir.create(dirname(catalogue_path), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(catalogue, catalogue_path, row.names = FALSE)
validate_snapshot(catalogue_path)
