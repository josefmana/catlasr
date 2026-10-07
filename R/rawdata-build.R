#' Build a forward-blocking-attention raw-data bundle
#'
#' User-facing constructor for the `catlas_fba_rawdata` class. Takes the three
#' components produced by import plus the provenance of the pull, constructs
#' the object and validates it.
#'
#' @param meta Data frame. One row per participant.
#' @param stimuli Data frame. One row per participant, concrete-to-abstract
#'   stimulus mappings.
#' @param trials Data frame. One row per trial.
#' @param provenance A `catlas_provenance` object, from [build_provenance()].
#'
#' @returns A validated object of class
#'   `c("catlas_fba_rawdata", "catlas_rawdata")`.
#'
#' @seealso [build_provenance()], [provenance()], [record_exclusion()]
#'
#' @export
build_fba_rawdata <- function(meta, stimuli, trials, provenance) {
  obj <- catlas_fba_rawdata(
    meta       = meta,
    stimuli    = stimuli,
    trials     = trials,
    provenance = provenance
  )
  validate_catlas_fba_rawdata(obj)
}
