#' Validate a CATLAS stimulus object
#'
#' Internal validator for [catlas_stimulus()].
#'
#' @param x Object to validate.
#'
#' @returns A validated "catlas_stimulus" object.
#'
#' @noRd
validate_catlas_stimulus <- function(x) {
  if (!is.list(x)) {
    cli::cli_abort(c(
            "Stimulus object must be a list.",
      "i" = "Provided object is of class {.cls {class(x)}}."
    ))
  }

  if (!is.character(x$label) || length(x$label) != 1) {
    cli::cli_abort(c(
            "`label` must be a single character string.",
      "i" = "Provided `label` is a {.cls {class(x$label)}} of length {length(x$label)}."
    ))
  }

  if (!is.character(x$image_path) || length(x$image_path) != 1) {
    cli::cli_abort(c(
            "`image_path` must be a single character string.",
      "i" = "Provided `label` is a {.cls {class(x$label)}} of length {length(x$label)}."
    ))
  }

  if (!file.exists(x$image_path)) {
    cli::cli_abort(c(
            "`image_path` does not exist.",
      "i" = "No file was found at {.path {x$image_path}}."
    ))
  }

  if (!x$type %in% c("cue", "outcome")) {
    cli::cli_abort(c(
            "`type` must be either 'cue' or 'outcome'.",
      "i" = "The following `type` was provided: {x$type}"
    ))
  }

  x
}
