#' Validate a CATLAS stimulus object
#'
#' Internal validator called automatically by [catlas_stimulus()]. Can also be
#' invoked explicitly to re-check an object constructed programatically.
#'
#' @param x Object to validate.
#'
#' @returns `x`, invisibly, when all checks pass. Throws an informative error
#' via [cli::cli_abort()] on the first failed check.
#'
#' @noRd
validate_catlas_stimulus <- function(x) {

  if (!is.list(x)) {
    cli::cli_abort(c(
            "Stimulus object must be a list.",
      "i" = "Provided object is of class {.cls {class(x)}}."
    ))
  }

  # ── Label ───────────────────────────────────────────────────────────────────
  if (!is.character(x$label) || length(x$label) != 1) {
    cli::cli_abort(c(
            "`label` must be a single character string.",
      "i" = "Provided `label` is a {.cls {class(x$label)}}
             of length {length(x$label)}."
    ))
  }

  if (is.na(x$label) || !nzchar(x$label)) {
    cli::cli_abort(c(
      "`label` must be a non-missing, non-empty string.",
      "i" = "Provided `label` is {.val {x$label}}."
    ))
  }

  # ── Image path ──────────────────────────────────────────────────────────────
  if (!is.character(x$image_path) || length(x$image_path) != 1) {
    cli::cli_abort(c(
            "`image_path` must be a single character string.",
      "i" = "Provided `image_path` is a {.cls {class(x$image_path)}}
             of length {length(x$image_path)}."
    ))
  }

  if (is.na(x$image_path)) {
    cli::cli_abort(c(
      "`image_path` must not be `NA`.",
      "i" = "Supply a valid file path as a character string."
    ))
  }

  if (!file.exists(x$image_path)) {
    cli::cli_abort(c(
            "`image_path` does not exist.",
      "i" = "No file was found at {.path {x$image_path}}."
    ))
  }

  if (!is.character(x$type) || length(x$type) != 1L || is.na(x$type)) {
    cli::cli_abort(c(
            "`type` must be a single, non-missing character string.",
      "i" = "Provided `type` is a {.cls {class(x$type)}}
             of length {length(x$type)}."
    ))
  }

  if (!x$type %in% c("cue", "outcome")) {
    cli::cli_abort(c(
            "`type` must be either 'cue' or 'outcome'.",
      "i" = "The following `type` was provided: {x$type}"
    ))
  }

  invisible(x)
}
