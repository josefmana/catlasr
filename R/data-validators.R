# Columns that define catlas_designs()
.required_design_cols <- c(
  "design",
  "stage1_cue",
  "stage1_outcome",
  "stage2_cue",
  "stage2_outcome",
  "stage3_cue",
  "stage3_outcome",
  "test_cue",
  "test_outcome",
  "test_preference"
)

# Columns that define catlas_effects()
.required_effects_cols <- c(
  "bibtex",
  "experiment",
  "design",
  "story",
  "story_type",
  "n_subjects",
  "dv",
  "measure_formula",
  "measure_type",
  "measure_when",
  "value1",
  "null",
  "alternative",
  "test_identity",
  "test_effect",
  "test_statistic",
  "test_p",
  "es_identity",
  "es_value"
)

# Numeric columns that define catlas_effects()
.numeric_effects_cols <- c(
  "value1",
  "test_statistic",
  "test_p",
  "es_value"
)

# Experimental procedure cover stories in catlas_effects()
.allowed_story_types <- c(
  "causal",
  "diagnostic"
)

#' Validate shared constraints of any `catlas_data` object
#'
#' Performs structural checks shared across all CATLAS data
#' subclasses. Subclass validators should call this validator
#' first and then add their own domain-specific constraints.
#'
#' @param x A `catlas_data` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_data <- function(x) {
  if (!inherits(x, "catlas_data")) {
    cli::cli_abort(c(
      "`x` must inherit from {.cls catlas_data}."
    ))
  }

  if (!tibble::is_tibble(x)) {
    cli::cli_abort(c(
            "`data` must be a tibble.",
      "i" = "Provided object inherits from {.cls {class(x)}}."
    ))
  }

  if (ncol(x) == 0L) {
    cli::cli_abort("`data` must contain at least one column.")
  }

  invisible(x)
}


#' Validate constraints of any `catlas_designs` object
#'
#' Applies shared `catlas_data` checks followed by validation
#' specific to forward blocking design specifications.
#'
#' @param x A `catlas_designs` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_designs <- function(x) {
  x <- validate_catlas_data(x)

  missing_cols <- setdiff(.required_design_cols, names(x))

  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
            "`data` is missing required column(s).",
      "x" = "Missing: {missing_cols}."
    ))
  }

  non_character <- .required_design_cols[
    !vapply(
      x[.required_design_cols],
      is.character,
      logical(1)
    )
  ]

  if (length(non_character) > 0L) {
    cli::cli_abort(c(
            "Some required columns are not character vectors.",
      "x" = "Applies to: {non_character}."
    ))
  }

  invisible(x)
}


#' Validate constraints of any `catlas_effects` object
#'
#' Applies shared `catlas_data` checks followed by validation
#' specific to summarized empirical effect data.
#'
#' @param x A `catlas_effects` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_effects <- function(x) {
  x <- validate_catlas_data(x)

  missing_cols <- setdiff(.required_effects_cols, names(x))

  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
            "`data` is missing required column{?s}.",
      "x" = "Missing: {missing_cols}."
    ))
  }

  if (!is.numeric(x$n_subjects)) {
    cli::cli_abort(c(
            "`n_subjects` must be numeric.",
      "i" = "Provided column inherits from {.cls {class(x$n_subjects)}}."
    ))
  }

  if (any(x$n_subjects <= 0, na.rm = TRUE)) {
    cli::cli_abort(c(
            "`n_subjects` must contain strictly positive values.",
      "x" = "Detected non-positive sample sizes."
    ))
  }

  non_numeric <- .numeric_effects_cols[
    !vapply(
      x[.numeric_effects_cols],
      is.numeric,
      logical(1)
    )
  ]

  if (length(non_numeric) > 0L) {
    cli::cli_abort(c(
            "Some required columns are not numeric vectors.",
      "x" = "Non-numeric columns: {non_numeric}."
    ))
  }

  if (any(x$test_p < 0 | x$test_p > 1, na.rm = TRUE)) {
    cli::cli_abort(c(
            "`test_p` must lie within [0, 1].",
      "x" = "Detected invalid p-values."
    ))
  }

  invalid_story_types <- unique(
    x$story_type[
      !is.na(x$story_type) &
        !x$story_type %in% .allowed_story_types
    ]
  )

  if (length(invalid_story_types) > 0L) {
    cli::cli_abort(c(
            "`story_type` contains invalid entries.",
      "x" = "Invalid values: {invalid_story_types}",
      "i" = "Allowed values are: {(.allowed_story_types)}."
    ))
  }

  invisible(x)
}


#' Test whether an object inherits from `catlas_data`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_data"`.
#'
#' @noRd
is_catlas_data <- function(x) {
  inherits(x, "catlas_data")
}


#' Test whether an object inherits from `catlas_designs`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_designs"`.
#'
#' @noRd
is_catlas_designs <- function(x) {
  inherits(x, "catlas_designs")
}


#' Test whether an object inherits from `catlas_effects`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_effects"`.
#'
#' @noRd
is_catlas_effects <- function(x) {
  inherits(x, "catlas_effects")
}
