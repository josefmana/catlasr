#' Base constructor for CATLAS raw experimental data bundles
#'
#' Internal. Constructs a named-list S3 object with three aligned tibble
#' components: participant metadata (`meta`), per-participant stimulus mappings
#' (`stimuli`), and raw trial-level responses (`trials`) and the provenance
#' of the pull that last produced the data.
#'
#' @param meta A data frame of participant-level metadata.
#' @param stimuli A data frame of per-participant stimulus mappings.
#' @param trials A data frame of raw trial-level responses.
#' @param provenance A `catlas_provenance` object. Required, so that every data
#'   bundle created within CATLAS can be backtracked to its origins.
#' @param subclass Character(1). Optional platform-specific subclass
#'   label added to the class vector.
#' @param ... Additional named slots forwarded as list elements.
#'
#' @returns A named list with class `c(subclass, "catlas_rawdata")`.
#'
#' @noRd
catlas_rawdata <- function(
    meta,
    stimuli,
    trials,
    provenance,
    subclass = character(),
    ...
) {
  stopifnot(is.data.frame(meta))
  stopifnot(is.data.frame(stimuli))
  stopifnot(is.data.frame(trials))
  stopifnot(is_catlas_provenance(provenance))
  stopifnot(is.character(subclass))

  structure(
    list(
      meta       = tibble::as_tibble(meta),
      stimuli    = tibble::as_tibble(stimuli),
      trials     = tibble::as_tibble(trials),
      provenance = provenance,
      ...
    ),
    class = c(subclass, "catlas_rawdata")
  )
}


#' Constructor for CATLAS forward-blocking-attention raw data
#'
#' Internal subclass constructor of CATLAS raw data bundle containing
#' experimental data of any forward-blocking-attention type experiment. Contains
#' participant metadata, per-participant stimulus mappings, and raw trial-level
#' responses, with data provenance to differentiate between experiment runs.
#'
#' @inheritParams catlas_rawdata
#'
#' @returns A named list with class `c("catlas_fba_rawdata", "catlas_rawdata")`.
#'
#' @noRd
catlas_fba_rawdata <- function(
    meta,
    stimuli,
    trials,
    provenance
) {
  catlas_rawdata(
    meta       = meta,
    stimuli    = stimuli,
    trials     = trials,
    provenance = provenance,
    subclass   = "catlas_fba_rawdata"
  )
}
