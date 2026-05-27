# forward-blocking-validators.R
#
# Experiment-specific validation for forward blocking studies.
# Intentionally kept separate from core catlasr infrastructure;
# these constraints encode knowledge about the FB paradigm itself,
# not about the data container.


# Plausible trial-count bounds per participant;
# from at least one test to all test trials finished
# (raise a warning outside)
.fb_trial_count_range <- c(193L, 224L)
.fb_trial_count_range <- ceiling(.fb_trial_count_range / 2) # For pilot only, change when the real run commends! ----

# Expected experimental stages
.fb_expected_stages <- c("stage1", "stage2", "stage3", "test")

# Number of distinct cue types expected across all participants
.fb_min_cue_types     <- 20L
.fb_min_outcome_types <- 4L


#' Validate forward-blocking-specific constraints on a `catlas_rawdata` object
#'
#' Calls [validate_catlas_rawdata()] for shared checks, then enforces
#' constraints specific to forward blocking experimental designs:
#'
#' @param x A `catlas_rawdata` object (typically also a
#'   `catlas_jatos_rawdata`).
#'
#' @returns `x` invisibly on success, otherwise throws an informative
#'   error or warning.
#'
#' @details
#' * All expected stage labels (`stage1`, `stage2`, `stage3`, `test`) must be
#'   present.
#' * Each participant's trial count must fall within a plausible range (at
#'   minimum all learning plus one test trial, at maximum the full experiment).
#' * Each participant must have the minimum expected number of distinct
#'   cue and outcome types.
#' * In compound-cues stages, left-right counterbalancing is check and cases
#'   with discrepancies printed with a warning message (note these are expected
#'   in pilot round with odd number of trials per stage but should not happen
#'   during the experiment proper).
#'
#' @noRd
validate_forward_blocking_rawdata <- function(x) {
  x <- validate_catlas_rawdata(x)

  # Stage coverage
  observed_stages <- unique(x$trials$stage)
  missing_stages  <- setdiff(.fb_expected_stages, observed_stages)

  if (length(missing_stages) > 0L) {
    cli::cli_abort(c(
            "Expected experimental stage{?s} absent from `trials$stage`.",
      "x" = "Missing: {missing_stages}."
    ))
  }

  # Per-participant trial counts
  min_trials   <- .fb_trial_count_range[1L]
  max_trials   <- .fb_trial_count_range[2L]
  trial_counts <- dplyr::count(x$trials, .data$id)

  low_count  <- trial_counts[trial_counts$n < min_trials, , drop = FALSE]
  high_count <- trial_counts[trial_counts$n > max_trials, , drop = FALSE]

  if (nrow(low_count) > 0L) {
    cli::cli_warn(c(
            "Some participants have suspiciously few trials (<{min_trials}).",
      "i" = "Problematic IDs: {as.character(low_count$id)}."
    ))
  }

  if (nrow(high_count) > 0L) {
    cli::cli_warn(c(
            "Some participants have unrealistically many trials (>{max_trials}).",
      "i" = "Problematic IDs: {as.character(high_count$id)}."
    ))
  }

  # Cue-type coverage per participant
  cue_coverage <- x$trials |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(n_cue_types = dplyr::n_distinct(.data$cue1), .groups = "drop")

  low_cue <- cue_coverage[cue_coverage$n_cue_types < .fb_min_cue_types, ]

  if (nrow(low_cue) > 0L) {
    cli::cli_warn(c(
            "Some participants have fewer than {`.fb_min_cue_types`} distinct cue types.",
      "i" = "Problematic IDs: {as.character(low_cue$id)}."
    ))
  }

  # Outcome-type coverage per participant
  out_coverage <- x$trials |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(n_out_types = dplyr::n_distinct(.data$response), .groups = "drop")

  low_out <- out_coverage[out_coverage$n_out_types < .fb_min_outcome_types, ]

  if (nrow(low_out) > 0L) {
    cli::cli_warn(c(
            "Some participants utilised less than {`.fb_min_out_types`} outcome types.",
      "i" = "Problematic IDs: {as.character(low_out$id)}."
    ))
  }

  # Duplications in stimuli assignment
  duplicated_counts <- x$stimuli |>
    dplyr::select(!tidyselect::ends_with("context")) |>
    tidyr::pivot_longer(-.data$id) |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(n_duplicated = anyDuplicated(.data$value), .groups = "drop") |>
    dplyr::filter(.data$n_duplicated > 0L)

  if (nrow(duplicated_counts) > 0L) {
    cli::cli_warn(c(
            "Some participants have duplicated stimuli ty stimulus type assignments.",
      "i" = "Problematic IDs: {as.character(duplicated_counts$id)}."
    ))
  }

  # Left-right counterbalancing of compound cues
  counterimbalancing <- x$trials |>
    dplyr::group_by(.data$cue1, .data$cue2, .data$cues_reversed, .data$id) |>
    dplyr::summarise(n_presentations = dplyr::n(), .groups = "drop") |>
    tidyr::drop_na() |>
    tidyr::pivot_wider(names_from = .data$cues_reversed, values_from = .data$n_presentations) |>
    dplyr::filter(.data$`FALSE` != .data$`TRUE`) |>
    dplyr::rename("12" = "FALSE",  "21" = "TRUE")

  if (nrow(counterimbalancing) > 0L) {
    cli::cli_warn(c(
      "x" = "Some cue compounds were not properly counterbalanced for some participants.",
      "i" = "See the problematic cases below:",
      format(counterimbalancing)
    ))
  }

  invisible(x)
}
