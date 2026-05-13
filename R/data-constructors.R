#' Base constructor for CATLAS data objects
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
#' @returns An S3 object with class `c(subclass, "catlas_data")`.
#'
#' @noRd
catlas_data <- function(
    data,
    subclass = character(),
    ...
) {
  stopifnot(is.data.frame(data))
  stopifnot(is.character(subclass))

  structure(
    tibble::as_tibble(data),
    class = c(subclass, "catlas_data", class(data))
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
#' @seealso [catlas_data()]
#'
#' @returns An S3 object with class `c("catlas_designs", "catlas_data")`.
#'
#' @noRd
catlas_designs <- function(data) {
  catlas_data(
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
#' @seealso [catlas_data()]
#'
#' @returns An S3 object with class `c("catlas_effects", "catlas_data")`.
#'
#' @noRd
catlas_effects <- function(data) {
  catlas_data(
    data      = data,
    subclass  = "catlas_effects"
  )
}
