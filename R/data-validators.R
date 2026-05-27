# --- catlas_literature components ---------------------------------------------

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


#' Validate shared constraints of any `catlas_literature` object
#'
#' Performs structural checks shared across all CATLAS data
#' subclasses. Subclass validators should call this validator
#' first and then add their own domain-specific constraints.
#'
#' @param x A `catlas_literature` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_literature <- function(x) {
  if (!inherits(x, "catlas_literature")) {
    cli::cli_abort(c(
      "`x` must inherit from {.cls catlas_literature}."
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
#' Applies shared `catlas_literature` checks followed by validation
#' specific to forward blocking design specifications.
#'
#' @param x A `catlas_designs` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_designs <- function(x) {
  x <- validate_catlas_literature(x)

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
#' Applies shared `catlas_literature` checks followed by validation
#' specific to summarized empirical effect data.
#'
#' @param x A `catlas_effects` object.
#'
#' @returns `x` invisibly on success, otherwise throws an
#'   informative error.
#'
#' @noRd
validate_catlas_effects <- function(x) {
  x <- validate_catlas_literature(x)

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


#' Test whether an object inherits from `catlas_literature`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_literature"`.
#'
#' @noRd
is_catlas_literature <- function(x) {
  inherits(x, "catlas_literature")
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


# --- catlas_rawdata components ------------------------------------------------

# Participant-level metadata (one row per participant)
.required_rawdata_meta_cols <- c(
  "id",
  "sex",
  "age",
  "width",
  "height",
  "os"
)

# Raw trial responses (one row per trial)
.required_rawdata_trials_cols <- c(
  "id",
  "stage",
  "block",
  "type",
  "cue1",
  "cue2",
  "cues_reversed",
  "response",
  "is_correct",
  "confidence",
  "rt1",
  "rt2",
  "timed_out"
)


#' Validate shared constraints of any `catlas_rawdata` object
#'
#' Checks that the object is a properly formed three-component bundle
#' and that participant IDs are consistent across all three components.
#' Platform-specific validators should call this function first.
#'
#' @param x A `catlas_rawdata` object.
#'
#' @details
#' Rules:
#' * All three components (`meta`, `stimuli`, `trials`) must exist and
#'   be non-empty tibbles.
#' * Each component must contain its required columns.
#' * `meta$id` and `stimuli$id` must each be unique (one row per participant).
#' * Every ID in `trials` must exist in `meta`.
#' * Every ID in `stimuli` must exist in `meta`.
#' * IDs present in `meta` but absent from `trials` or `stimuli` raise
#'   a warning, not a structural error.
#'
#' @returns `x` invisibly on success, otherwise throws an informative error.
#'
#' @noRd
validate_catlas_rawdata <- function(x) {
  if (!inherits(x, "catlas_rawdata")) {
    cli::cli_abort("`x` must inherit from {.cls catlas_rawdata}.")
  }

  # Component existence and type
  required_components <- c("meta", "stimuli", "trials")
  missing_components  <- setdiff(required_components, names(x))

  if (length(missing_components) > 0L) {
    cli::cli_abort(c(
            "`catlas_rawdata` is missing required component{?s}.",
      "x" = "Missing: {missing_components}."
    ))
  }

  purrr::walk(required_components, function(comp) {
    if (!tibble::is_tibble(x[[comp]])) {
      cli::cli_abort(c(
              "`{comp}` must be a tibble.",
        "i" = "Got {.cls {class(x[[comp]])}}."
      ))
    }
    if (nrow(x[[comp]]) == 0L) {
      cli::cli_abort("`{comp}` must contain at least one row.")
    }
  })

  # Required columns
  .assert_cols <- function(component, required) {
    missing <- setdiff(required, names(x[[component]]))
    if (length(missing) > 0L) {
      cli::cli_abort(c(
              "`{component}` is missing required column{?s}.",
        "x" = "Missing: {missing}."
      ))
    }
  }

  .required_rawdata_stimuli_cols <- c(
    "id",
    unique(x$trials$cue1),
    unique(x$trials$correct_outcome)
  )

  .assert_cols("meta",    .required_rawdata_meta_cols)
  .assert_cols("stimuli", .required_rawdata_stimuli_cols)
  .assert_cols("trials",  .required_rawdata_trials_cols)

  # ID alignment
  meta_ids    <- x$meta$id
  stimuli_ids <- x$stimuli$id
  trials_ids  <- unique(x$trials$id)

  if (anyDuplicated(meta_ids)) {
    cli::cli_abort(c(
            "`meta$id` must be unique (one row per participant).",
      "x" = "Duplicated IDs found."
    ))
  }
  if (anyDuplicated(stimuli_ids)) {
    cli::cli_abort(c(
            "`stimuli$id` must be unique (one row per participant).",
      "x" = "Duplicated ID{?s} found: {unique(stimuli_ids[duplicated(stimuli_ids)])}."
    ))
  }

  orphan_trials   <- setdiff(trials_ids, meta_ids)
  orphan_stimuli  <- setdiff(stimuli_ids, meta_ids)
  meta_no_trials  <- setdiff(meta_ids, trials_ids)
  meta_no_stimuli <- setdiff(meta_ids, stimuli_ids)

  if (length(orphan_trials) > 0L) {
    cli::cli_abort(c(
            "Some `trials` IDs have no corresponding `meta` entry.",
      "x" = "Unmatched ID{?s}: {as.character(orphan_trials)}."
    ))
  }
  if (length(orphan_stimuli) > 0L) {
    cli::cli_abort(c(
            "Some `stimuli` IDs have no corresponding `meta` entry.",
      "x" = "Unmatched ID{?s}: {as.character(orphan_stimuli)}."
    ))
  }
  if (length(meta_no_trials) > 0L) {
    cli::cli_warn(c(
            "Some participants have metadata but no trial responses.",
      "i" = "IDs: {as.character(meta_no_trials)}."
    ))
  }
  if (length(meta_no_stimuli) > 0L) {
    cli::cli_warn(c(
            "Some participants have metadata but no stimulus mappings.",
      "i" = "IDs: {as.character(meta_no_stimuli)}."
    ))
  }

  invisible(x)
}


#' Validate constraints of any `catlas_jatos_rawdata` object
#'
#' Calls [validate_catlas_rawdata()] for shared structural checks,
#' then enforces JATOS- and jsPsych-specific constraints.
#'
#' @param x A `catlas_jatos_rawdata` object.
#'
#' @returns `x` invisibly on success, otherwise throws an informative
#'   error.
#'
#' @details
#' Additional rules:
#' * Additional metadata columns must be present.
#' * Aborts if email is present in the data to ensure anonymity before saving.
#' * `meta$age` must be numeric and plausible (18–100); out-of-range
#'   values raise a warning, not an error, to accommodate edge cases.
#' * `trials$rt1` and `trials$rt2` must be non-negative.
#' * Stimulus-label columns must all be present in `stimuli`.
#'
#'
#' @noRd
validate_catlas_jatos_rawdata <- function(x) {
  x <- validate_catlas_rawdata(x)

  .jatos_required_meta_cols <- c("browser", "browser_version", "os", "vsync_rate")

  missing  <- setdiff(.jatos_required_meta_cols, names(x$meta))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "`meta` is missing column{?s} required  for `catlas_jatos_rawdata`.",
      "x" = "Missing columns: {missing}."
    ))
  }

  if ("email" %in% names(x$meta)) {
    cli::cli_abort(
            "Data must be anonymised.",
      "x" = "`meta` contains pasticipants' emails."
    )
  }

  if (!is.numeric(x$meta$age)) {
    cli::cli_abort(c(
            "`meta$age` must be numeric.",
      "i" = "Got {.cls {class(x$meta$age)}}."
    ))
  }
  if (any(x$meta$age < 18 | x$meta$age > 100, na.rm = TRUE)) {
    cli::cli_warn(c(
      "Some `meta$age` values fall outside [18, 100].",
      "i" = "Verify participant age coding."
    ))
  }

  if (any(x$trials$rt1 < 0, na.rm = TRUE) ||
      any(x$trials$rt2 < 0, na.rm = TRUE)) {
    cli::cli_abort(c(
            "Negative RT values detected in `trials`.",
      "x" = "`rt1` and `rt2` must be non-negative."
    ))
  }

  invisible(x)
}


#' Test whether an object inherits from `catlas_rawdata`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_rawdata"`.
#'
#' @noRd
is_catlas_rawdata <- function(x) {
  inherits(x, "catlas_rawdata")
}
