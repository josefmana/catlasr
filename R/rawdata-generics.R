#' Extract the metadata component from a CATLAS raw-data bundle
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns A tibble (one row per participant).
#'
#' @export
extract_meta <- function(x, ...) {
  UseMethod("extract_meta")
}


#' @rdname extract_meta
#' @export
extract_meta.default <- function(x, ...) {
  cli::cli_abort(c(
          "No {.fn extract_meta} method for objects of class {.cls {class(x)}}.",
    "i" = "Did you mean to build the bundle with {.fn build_fba_rawdata} first?"
  ))
}


#' @rdname extract_meta
#' @export
extract_meta.catlas_rawdata <- function(x, ...) {
  x$meta
}


#' Extract the stimulus-mappings component from a CATLAS raw-data bundle
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns A tibble (one row per participant).
#'
#' @export
extract_stimuli <- function(x, ...) {
  UseMethod("extract_stimuli")
}


#' @rdname extract_stimuli
#' @export
extract_stimuli.default <- function(x, ...) {
  cli::cli_abort(c(
          "No {.fn extract_stimuli} method for objects of class {.cls {class(x)}}.",
    "i" = "Did you mean to build the bundle with {.fn build_fba_rawdata} first?"
  ))
}


#' @rdname extract_stimuli
#' @export
extract_stimuli.catlas_rawdata <- function(x, ...) {
  x$stimuli
}


#' Extract the trial-responses component from a CATLAS raw-data bundle
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns A tibble (one row per trial).
#'
#' @export
extract_trials <- function(x, ...) {
  UseMethod("extract_trials")
}


#' @rdname extract_trials
#' @export
extract_trials.default <- function(x, ...) {
  cli::cli_abort(c(
          "No {.fn extract_trials} method for objects of class {.cls {class(x)}}.",
    "i" = "Did you mean to build the bundle with {.fn build_fba_rawdata} first?"
  ))
}


#' @rdname extract_trials
#' @export
extract_trials.catlas_rawdata <- function(x, ...) {
  x$trials
}
