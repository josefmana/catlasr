#' Base constructor for CATLAS literature data objects
#'
#' Internal. Only performs lightweight structural checks (no domain-specific
#' validation).
#' Every subclass constructor should call this constructor and append
#' its own class label via the `subclass` argument.
#'
#' @param data A data frame or tibble.
#' @param subclass Character. Additional subclass appended to the
#'   class vector.
#' @param ... Additional named metadata fields (currently unused).
#'
#' @returns An S3 object with class `c(subclass, "catlas_literature")`.
#'
#' @noRd
catlas_literature <- function(
    data,
    subclass = character(),
    ...
) {
  stopifnot(is.data.frame(data))
  stopifnot(is.character(subclass))

  structure(
    tibble::as_tibble(data),
    class = c(subclass, "catlas_literature", class(data))
  )
}


#' Constructor for CATLAS experimental designs
#'
#' Constructs a CATLAS experimental design object containing
#' symbolic stage specifications of study procedures.
#'
#' @param data A data frame or tibble containing experiment
#'   design specifications.
#'
#' @seealso [catlas_literature()]
#'
#' @returns An S3 object with class `c("catlas_designs", "catlas_literature")`.
#'
#' @noRd
catlas_designs <- function(data) {
  catlas_literature(
    data      = data,
    subclass  = "catlas_designs"
  )
}


#' Constructor for CATLAS effect summaries
#'
#' Constructs a CATLAS effect-summary object containing
#' empirical results reported by previous studies.
#'
#' @param data A data frame or tibble containing summarized
#'   statistical results.
#'
#' @seealso [catlas_literature()]
#'
#' @returns An S3 object with class `c("catlas_effects", "catlas_literature")`.
#'
#' @noRd
catlas_effects <- function(data) {
  catlas_literature(
    data      = data,
    subclass  = "catlas_effects"
  )
}


#' Base constructor for CATLAS raw experimental data bundles
#'
#' Internal. Constructs a named-list S3 object with three aligned
#' tibble components: participant metadata (`meta`), per-participant
#' stimulus mappings (`stimuli`), and raw trial-level responses
#' (`trials`). Only performs lightweight structural checks; semantic
#' constraints are enforced by the corresponding validator.
#'
#' Every platform-specific subclass constructor should call this
#' constructor and supply its own label via `subclass`.
#'
#' @param meta A data frame of participant-level metadata.
#' @param stimuli A data frame of per-participant stimulus mappings.
#' @param trials A data frame of raw trial-level responses.
#' @param subclass Character. Optional platform-specific subclass
#'   label added to the class vector.
#' @param ... Reserved for future metadata fields.
#'
#' @returns A named list with class `c(subclass, "catlas_rawdata")`.
#'
#' @noRd
catlas_rawdata <- function(
    meta,
    stimuli,
    trials,
    subclass = character(),
    ...
) {
  stopifnot(is.data.frame(meta))
  stopifnot(is.data.frame(stimuli))
  stopifnot(is.data.frame(trials))
  stopifnot(is.character(subclass))

  structure(
    list(
      meta    = tibble::as_tibble(meta),
      stimuli = tibble::as_tibble(stimuli),
      trials  = tibble::as_tibble(trials)
    ),
    class = c(subclass, "catlas_rawdata")
  )
}


#' Constructor for CATLAS raw data originating from JATOS
#'
#' Constructs a CATLAS raw data bundle containing experimental data
#' collected via jsPsych and through JATOS. Contains participant metadata,
#' per-participant stimulus mappings, and raw trial-level responses.
#'
#' @param meta A data frame of participant-level metadata.
#' @param stimuli A data frame of per-participant stimulus mappings.
#' @param trials A data frame of raw trial-level responses.
#'
#' @seealso [catlas_rawdata()], [validate_catlas_jatos_rawdata()]
#'
#' @returns A named list with class `c("catlas_jatos_rawdata", "catlas_rawdata")`.
#'
#' @noRd
catlas_jatos_rawdata <- function(meta, stimuli, trials) {
  catlas_rawdata(
    meta     = meta,
    stimuli  = stimuli,
    trials   = trials,
    subclass = "catlas_jatos_rawdata"
  )
}
