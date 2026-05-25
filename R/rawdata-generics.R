#' Extract the metadata component from a CATLAS raw-data bundle
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns A tibble (one row per participant).
#'
#' @noRd
extract_meta <- function(x, ...) {
  UseMethod("extract_meta")
}

#' @noRd
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
#' @noRd
extract_stimuli <- function(x, ...) {
  UseMethod("extract_stimuli")
}

#' @noRd
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
#' @noRd
extract_trials <- function(x, ...) {
  UseMethod("extract_trials")
}

#' @noRd
extract_trials.catlas_rawdata <- function(x, ...) {
  x$trials
}
