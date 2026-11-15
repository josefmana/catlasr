# Participant-level metadata (one row per participant). Demographics (`sex`,
# `age`) are optional, so that shared data sets can leave them out.
.required_rawdata_meta_cols <- c(
  "id",
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

# Platform-specific columns
.platform_meta_cols <- list(
  JATOS = c("batch_id", "browser", "browser_version", "os", "vsync_rate")
)

# Column names that identify a person or contain free text that may do so
.forbidden_meta_cols <- c(
  "email",
  "emails",
  "e-mail",
  "e_mail",
  "mail",
  "email_address",
  "prolific_pid",
  "subject_id",   # the name of PROLIFIC ID stored under `catlaslab` build from 2026-06-18
  "prior_guess",  # free-text debriefing answer, present from `fba-allergy-online-02` on
  "comment"       # free-text debriefing comment
)


#' Validate the shape of a raw-data bundle
#'
#' @param x A `catlas_rawdata` object.
#' @param call Environment for error reporting.
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_components <- function(x, call = rlang::caller_env()) {
  required <- c("meta", "stimuli", "trials")
  missing  <- setdiff(required, names(x))

  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "A {.cls catlas_rawdata} object is missing {length(missing)} required component{?s}.",
      "x" = "Missing: {.val {missing}}."
    ), call = call)
  }

  purrr::walk(required, function(comp) {
    if (!tibble::is_tibble(x[[comp]])) {
      cli::cli_abort(c(
              "`{comp}` must be a tibble.",
        "x" = "Got {.cls {class(x[[comp]])}}.",
        "i" = "The constructor coerces with {.fn tibble::as_tibble}, so this means the slot was replaced after construction."
      ), call = call)
    }
    if (nrow(x[[comp]]) == 0L) {
      cli::cli_abort(c(
              "`{comp}` must contain at least one row.",
        "i" = "An exclusion rule that removed every participant produces this; see {.fn provenance}."
      ), call = call)
    }
  })

  invisible(x)
}


#' Validate that each component carries its required columns
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_component_cols <- function(x, call = rlang::caller_env()) {
  labels <- unique(c(x$trials$cue1, x$trials$cue2, x$trials$response))

  required <- list(
    meta    = .required_rawdata_meta_cols,
    trials  = .required_rawdata_trials_cols,
    stimuli = c("id", labels[!is.na(labels)])
  )

  purrr::iwalk(required, function(cols, comp) {
    missing <- setdiff(cols, names(x[[comp]]))
    if (length(missing) > 0L) {
      cli::cli_abort(c(
              "`{comp}` is missing {length(missing)} required column{?s}.",
        "x" = "Missing: {.val {missing}}."
      ), call = call)
    }
  })

  invisible(x)
}


#' Validate that participant identifiers agree across components
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly; an identifier in a component without a `meta` entry
#'   aborts, a `meta` entry without data in a component warns.
#'
#' @noRd
.validate_id_alignment <- function(x, call = rlang::caller_env()) {
  meta_ids    <- as.character(x$meta$id)
  stimuli_ids <- as.character(x$stimuli$id)
  trials_ids  <- unique(as.character(x$trials$id))

  dup_meta <- unique(meta_ids[duplicated(meta_ids)])
  if (length(dup_meta) > 0L) {
    cli::cli_abort(c(
            "`meta$id` must be unique, one row per participant.",
      "x" = "Duplicated ID{?s}: {.val {dup_meta}}.",
      "i" = "Two rows for one participant usually means two batches were bound without de-duplicating."
    ), call = call)
  }

  dup_stimuli <- unique(stimuli_ids[duplicated(stimuli_ids)])
  if (length(dup_stimuli) > 0L) {
    cli::cli_abort(c(
            "`stimuli$id` must be unique, one row per participant.",
      "x" = "Duplicated ID{?s}: {.val {dup_stimuli}}."
    ), call = call)
  }

  orphans <- list(
    trials  = setdiff(trials_ids, meta_ids),
    stimuli = setdiff(stimuli_ids, meta_ids)
  )
  orphans <- orphans[lengths(orphans) > 0L]

  if (length(orphans) > 0L) {
    bullets <- paste0(
      names(orphans), ": ",
      vapply(orphans, paste, character(1L), collapse = ", ")
    )
    cli::cli_abort(c(
      "Every participant in a component must have a `meta` entry.",
      rlang::set_names(bullets, rep("x", length(bullets))),
      "i" = "An ID in a component but not in `meta` means the components were filtered separately; use {.fn record_exclusion}."
    ), call = call)
  }

  incomplete <- list(
    trials  = setdiff(meta_ids, trials_ids),
    stimuli = setdiff(meta_ids, stimuli_ids)
  )
  incomplete <- incomplete[lengths(incomplete) > 0L]

  if (length(incomplete) > 0L) {
    bullets <- paste0(
      "no ",
      names(incomplete),
      " for ",
      vapply(incomplete, paste, character(1L), collapse = ", ")
    )
    cli::cli_warn(c(
      "{length(incomplete)} component{?s} {?is/are} missing participants that `meta` has.",
      rlang::set_names(bullets, rep("i", length(bullets))),
      "i" = "These are candidates for a structural exclusion rule."
    ), call = call)
  }

  invisible(x)
}


#' Validate the metadata columns a data collection platform contributes
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_platform_meta <- function(x, call = rlang::caller_env()) {
  platform <- provenance(x)$origin$platform
  required <- .platform_meta_cols[[platform]]

  if (is.null(required)) {
    return(invisible(x))
  }

  missing <- setdiff(required, names(x$meta))
  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "`meta` is missing {length(missing)} column{?s} that {platform} records.",
      "x" = "Missing: {.val {missing}}.",
      "i" = "Either the import dropped them or `provenance$origin$platform` is wrong."
    ), call = call)
  }

  invisible(x)
}


#' Validate that a data bundle's batches are the same its provenance names
#'
#' Applies only when `meta` carries `batch_id`. A participant from an unlisted
#' batch aborts, because the provenance record would then misstate where the
#' data came from. A listed batch that contributed nobody warns.
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly; unlisted batches abort, empty batches warn.
#'
#' @noRd
.validate_batch_alignment <- function(x, call = rlang::caller_env()) {
  if (!"batch_id" %in% names(x$meta)) {
    return(invisible(x))
  }

  expected <- as.character(provenance(x)$origin$batch_ids)
  observed <- unique(as.character(x$meta$batch_id))

  unlisted <- setdiff(observed, expected)
  if (length(unlisted) > 0L) {
    cli::cli_abort(c(
            "Every `meta$batch_id` must be listed in `provenance$origin$batch_ids`.",
      "x" = "Not listed: {.val {unlisted}}.",
      "i" = "Either the provenance record is incomplete or the data come from a different pull."
    ), call = call)
  }

  empty <- setdiff(expected, observed)
  if (length(empty) > 0L) {
    cli::cli_warn(c(
            "{length(empty)} batch{?es} named in provenance contributed no participant.",
      "i" = "Batch{?es}: {.val {empty}}.",
      "i" = "Check the batch IDs: a mistyped batch silently shrinks the sample."
    ), call = call)
  }

  invisible(x)
}


#' Refuse a data bundle that carries participant-identifying columns
#'
#' Free-text answers count as such too, because a participant may type anything
#' into them, including contact details.
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_anonymity <- function(x, call = rlang::caller_env()) {
  components <- c("meta", "stimuli", "trials")

  offending <- purrr::map(
    rlang::set_names(components),
    \(comp) intersect(tolower(names(x[[comp]])), .forbidden_meta_cols)
  )
  offending <- offending[lengths(offending) > 0L]

  if (length(offending) > 0L) {
    bullets <- paste0(
      names(offending), ": ",
      vapply(offending, paste, character(1L), collapse = ", ")
    )
    cli::cli_abort(c(
      paste(
        "A data bundle must not carry participant-identifying or free-text",
        "columns."
      ),
      "x" = "Found such column{?s} in {length(offending)} component{?s}.",
      rlang::set_names(bullets, rep("x", length(bullets))),
      "i" = paste(
        "Keep identifying data such as e-mail addresses and free-text",
        "answers outside the bundle and outside the repository."
      )
    ), call = call)
  }

  invisible(x)
}


#' Validate participant-level metadata
#'
#' @inheritParams .validate_components
#'
#' Applies only when `meta` carries `age`, which shared data sets leave out.
#'
#' @returns `x` invisibly; out-of-range ages warn rather than abort, because a
#'   genuine 17-year-old in a student sample is a consent question rather than
#'   a corrupt file.
#'
#' @noRd
.validate_participant_meta <- function(x, call = rlang::caller_env()) {
  if (!"age" %in% names(x$meta)) {
    return(invisible(x))
  }

  if (!is.numeric(x$meta$age)) {
    cli::cli_abort(c(
            "`meta$age` must be numeric.",
      "x" = "Got {.cls {class(x$meta$age)}}.",
      "i" = "The import coerces with {.fn as.numeric}; a character column means that step was skipped."
    ), call = call)
  }

  out_of_range <- which(x$meta$age < 18 | x$meta$age > 100)
  if (length(out_of_range) > 0L) {
    cli::cli_warn(c(
            "{length(out_of_range)} participant{?s} {?has/have} an age outside [18, 100].",
      "i" = "ID{?s}: {.val {as.character(x$meta$id[out_of_range])}}.",
      "i" = "Verify the age coding before this reaches an exclusion rule."
    ), call = call)
  }

  invisible(x)
}


#' Validate response times
#'
#' Scans every `rt`-prefixed column for non-numeric or negative values.
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_response_times <- function(x, call = rlang::caller_env()) {
  rt_cols <- grep("^rt[0-9]*$", names(x$trials), value = TRUE)

  negative <- rt_cols[vapply(
    rt_cols,
    \(col) any(x$trials[[col]] < 0, na.rm = TRUE),
    logical(1L)
  )]

  if (length(negative) > 0L) {
    cli::cli_abort(c(
            "{length(negative)} response-time column{?s} {?contains/contain} negative values.",
      "x" = "Affected: {.val {negative}}."
    ), call = call)
  }

  invisible(x)
}


#' Validate that each participant's stimulus mapping is injective
#'
#' Every abstract label must map to a distinct concrete stimulus within a
#' participant. A collision means two cues were rendered identically, which
#' makes that participant's data uninterpretable.
#'
#' @inheritParams .validate_components
#'
#' @returns `x` invisibly; collisions warn, so a whole import is not blocked by
#'   one participant who will be excluded anyway. Use the warning message as
#'   means to guide data exclusion via [record_exclusion()].
#'
#' @noRd
.validate_stimulus_uniqueness <- function(x, call = rlang::caller_env()) {
  collisions <-
    x$stimuli |>
    dplyr::select(!tidyselect::ends_with("context")) |>
    tidyr::pivot_longer(
      -"id",
      names_to  = "label",
      values_to = "stimulus"
    ) |>
    tidyr::drop_na("stimulus") |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      n_duplicated = sum(duplicated(.data$stimulus)),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$n_duplicated > 0L)

  if (nrow(collisions) > 0L) {
    cli::cli_warn(c(
            "{nrow(collisions)} participant{?s} {?has/have} a stimulus assigned to more than one label.",
      "i" = "ID{?s}: {.val {as.character(collisions$id)}}."
    ), call = call)
  }

  invisible(x)
}


#' Validate shared constraints of any `catlas_rawdata` object
#'
#' Checks that the object is a properly formed three-component bundle
#' and that participant IDs are consistent across all three components.
#' Platform-specific validators should call this function first.
#'
#' @param x A `catlas_rawdata` object.
#' @param call Environment for error reporting.
#'
#' @details
#' Rules:
#' * All three data bundle components (`meta`, `stimuli`, `trials`) and
#'   `provenance` must exist and be non-empty.
#' * Each component must contain its required columns.
#' * `meta$id` and `stimuli$id` must each be unique (one row per participant).
#' * Every ID in `trials` must exist in `meta`.
#' * Every ID in `stimuli` must exist in `meta`.
#' * IDs present in `meta` but absent from `trials` or `stimuli` raise a
#'   warning, not a structural error.
#'
#' @returns `x` invisibly on success, otherwise throws an informative error.
#'
#' @noRd
validate_catlas_rawdata <- function(x, call = rlang::caller_env()) {
  if (!inherits(x, "catlas_rawdata")) {
    cli::cli_abort("`x` must inherit from {.cls catlas_rawdata}.", call = call)
  }

  # Provenance first to check data bundle origin
  if (is.null(x$provenance)) {
    cli::cli_abort(c(
            "`x` carries no provenance record.",
      "i" = "Objects are expected to come from {.fn build_fba_rawdata}, which requires one."
    ), call = call)
  }
  validate_catlas_provenance(x$provenance, call = call)

  # Shape, columns and identifier alignment
  .validate_components(x, call = call)
  .validate_component_cols(x, call = call)
  .validate_id_alignment(x, call = call)

  # Checks that hold for any CATLAS bundle, no matter the experimental paradigm
  .validate_anonymity(x, call = call)
  .validate_platform_meta(x, call = call)
  .validate_batch_alignment(x, call = call)
  .validate_participant_meta(x, call = call)
  .validate_response_times(x, call = call)
  .validate_stimulus_uniqueness(x, call = call)

  invisible(x)
}
