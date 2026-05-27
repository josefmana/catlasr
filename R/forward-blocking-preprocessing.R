# forward-blocking-preprocessing.R
#
# Pre-processing functions for forward blocking experiments.
# Computes subject-level DVs and learning summaries from `catlas_rawdata`
# objects; produces group-level learning curve plots.
#
# Three DVs are provided:
#   1. compute_cb_blocking() — confidence-weighted score (Beesley & Le Pelley, 2011)
#   2. compute_pj_blocking() — P(o3) difference score (Paskewitz & Jones, 2020)


# --- 0. Internal constants ----------------------------------------------------

# All abstract cue and outcome values.
.fb_abstract_cue_values     <- c(LETTERS, "alpha", "beta")
.fb_abstract_outcome_values <- c("o1", "o2", "o3", "o4")

# Stage 1: contingency type is not yet stored in `type`; inferred from cue1.
.fb_stage1_blocking_cues <- c("A", "C", "E", "G")
.fb_stage1_control_cues  <- c("I", "L", "O", "R")

# All Stage 1 cues; any cue1 outside this set raises a warning.
.fb_stage1_known_cues <- c(.fb_stage1_blocking_cues, .fb_stage1_control_cues)

# Test-stage cue pairs for the Paskewitz–Jones blocking score.
.fb_minuend_test_pairs <- tibble::tibble(
  cue1 = c("D", "H", "D", "H"),
  cue2 = c("Q", "K", "K", "Q")
)

.fb_subtrahend_test_pairs <- tibble::tibble(
  cue1 = c("B", "F", "B", "F"),
  cue2 = c("T", "N", "N", "T")
)

# Stage label lookup for plots.
.fb_stage_labels <- c(
  stage1 = "Stage 1",
  stage2 = "Stage 2",
  stage3 = "Stage 3"
)


# --- 1. Internal helpers ------------------------------------------------------

#' Resolve concrete stimuli to abstract labels
#'
#' Joins the `cue1`, `cue2` and `response` columns in `trials` (abstract
#' stimulus values, as returned by jsPsych) against the abstract cue columns
#' in `stimuli` (per-participant concrete-to-abstract mappings) to produce
#' `cue1_value`, `cue2_value` and `response_value` columns containing the
#' concrete stimulus value presented to the participant/selected by the
#' participant on a given trial. Trials whose values cannot be matched
#' yield `NA`.
#'
#' @param trials  A tibble containing at minimum columns `id`, `cue1`, `cue2`
#'   and `response`.
#' @param stimuli A tibble containing columns `id` and all abstract cue and
#'   outcome labels.
#'
#' @returns `trials` with additional `cue1_value`, `cue2_value` and
#'   `response_value`columns denoting the concrete stimuli presented/selected
#'   on each trial.
#'
#' @noRd
.resolve_stimulus_values <- function(trials, stimuli) {
  cues <- stimuli |>
    dplyr::select("id", tidyselect::all_of(.fb_abstract_cue_values)) |>
    tidyr::pivot_longer(
      cols      = -"id",
      names_to  = "cue_abstract",
      values_to = "cue_value"
    )

  outcomes <- stimuli |>
    dplyr::select("id", tidyselect::all_of(.fb_abstract_outcome_values)) |>
    tidyr::pivot_longer(
      cols      = -"id",
      names_to  = "response_abstract",
      values_to = "response_value"
    )

  trials |>
    dplyr::left_join(
      cues |> dplyr::rename("cue1_value" = "cue_value"),
      by = dplyr::join_by("id", "cue1" == "cue_abstract")
    ) |>
    dplyr::left_join(
      cues |> dplyr::rename("cue2_value" = "cue_value"),
      by = dplyr::join_by("id", "cue2" == "cue_abstract")
    ) |>
    dplyr::left_join(
      outcomes,
      by = dplyr::join_by("id", "response" == "response_abstract")
    )
}


#' Tag Stage 1 trials with blocking vs. control contingency type
#'
#' The raw `type` column does not yet encode blocking/control for Stage 1.
#' This helper adds `contingency_type` by mapping `cue1`:
#' A, C, E, G to `"blocking"`; I, L, O, R to `"control"`.
#' Unrecognised `cue1` values produce `NA` and trigger a warning.
#'
#' @param trials A tibble of Stage 1 trials with a `cue1` column.
#'
#' @returns `trials` with the `type` column re-coded.
#'
#' @noRd
.tag_stage1_type <- function(trials) {
  stage1_cues  <- unique(subset(trials, .data$stage == "stage1")$cue1)
  unknown_cues <- setdiff(stage1_cues, .fb_stage1_known_cues)

  if (length(unknown_cues) > 0L) {
    cli::cli_warn(c(
            "Some Stage 1 `cue1` values are not in the expected blocking or control set.",
      "i" = "Unrecognised cues: {unknown_cues}. They will receive `type = NA`."
    ))
  }

  dplyr::mutate(
    trials,
    type = dplyr::case_when(
      .data$cue1 %in% .fb_stage1_blocking_cues ~ "blocking",
      .data$cue1 %in% .fb_stage1_control_cues  ~ "control",
      .data$cue1 %in% unknown_cues ~ NA_character_,
      .default = .data$type
    )
  )
}


# --- 2. Confidence-weighted blocking score (Beesley & Le Pelley, 2011) --------

#' Compute confidence-weighted forward blocking scores
#'
#' Computes a per-participant confidence-weighted performance score from
#' the **first block of the test stage**.
#'
#' @param x A `catlas_rawdata` object.
#'
#' @returns A tibble with columns:
#' \describe{
#'   \item{`id`}{Participant ID}
#'   \item{`cb_m`}{Mean signed-confidence score}
#'   \item{`cb_sd`}{SD of signed-confidence values}
#'   \item{`n_trials`}{Number of trials contributing to the score.}
#' }
#'
#' @details
#' For each trial, the computation is:
#'
#' \deqn{ \text{signed\_conf}_i = (+1 \text{ if correct, else } -1) \times
#'   \text{confidence}_i }
#'
#' The per-participant score is the mean of these values (`cw_score`).
#' `cw_sd` is the standard deviation across trials **within** the participant.
#'
#' Timed-out trials and trials with `NA` confidence are excluded before
#' aggregation.
#'
#' @references Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking
#'   on overt attention and associability in human learning. *Journal of
#'   Experimental Psychology: Animal Behavior Processes, 37*(1), 114–120.
#'   \doi{10.1037/a0019526}
#'
#' @noRd
compute_cw_blocking <- function(x) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }

  trials <- extract_trials(x)

  test_b1 <- trials |>
    dplyr::filter(
      .data$stage     == "test",
      .data$block     == 1L,
      !.data$timed_out
    ) |>
    tidyr::drop_na(
      "confidence",
      "is_correct"
    )

  if (nrow(test_b1) == 0L) {
    cli::cli_abort(c(
            "No usable test-stage block-1 trials found.",
      "i" = "Requires `stage == 'test'`, `block == 1L`, and non-NA confidence."
    ))
  }

  test_b1 |>
    dplyr::mutate(
      sign        = 2 * .data$is_correct - 1,
      signed_conf = .data$sign * .data$confidence
    ) |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      cw_score = mean(.data$signed_conf, na.rm = TRUE),
      cw_sd    = stats::sd(.data$signed_conf,   na.rm = TRUE),
      n_trials = dplyr::n(),
      .groups  = "drop"
    )
}


# --- 3. DV 2: Blocking score (Paskewitz & Jones, 2020) ------------------------

#' Compute the Paskewitz–Jones blocking score
#'
#' Estimates a blocking score from **all blocks of the test stage**.
#'
#' @param x A `catlas_rawdata` object.
#'
#' @returns A tibble with columns:
#'   * `id`
#'   * One `p_o3_<pair>` column per cue-pair (e.g., `p_o3_DQ`)
#'   * `pj_score` — the final difference score (range −4 to +4)
#'
#' @details
#' For each of the four blocking and four control test cue-pairs the
#' function computes P(o3 | cue-pair) per participant, then takes the
#' difference:
#'
#' \deqn{
#'   \bigl[P(o3|DQ) + P(o3|HK) + P(o3|DK) + P(o3|HQ)\bigr] -
#'   \bigl[P(o3|BT) + P(o3|FN) + P(o3|BN) + P(o3|FT)\bigr]
#' }
#'
#' A **positive** score indicates that o3 responses are more common in cue
#' compounds where o3 outcome was correlated with the control cues (minuend),
#' than in cue compounds where o3 outcome  was correlated with blocked cues
#' (subtrahend). Consequently, positive values indicate blocking.
#'
#' Timed-out trials are excluded.
#'
#' @references Paskewitz, S., & Jones, M. (2020). Dissecting EXIT.
#'   *Journal of Mathematical Psychology*, *97*, 102371.
#'   \doi{10.1016/j.jmp.2020.102371}
#'
#' @noRd
compute_pj_blocking <- function(x) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }

  trials  <- extract_trials(x)

  test_trials <- trials |>
    dplyr::filter(
      .data$stage == "test",
      !.data$timed_out,
      !is.na(.data$response)
    )

  if (nrow(test_trials) == 0L) {
    cli::cli_abort(c(
            "No usable test-stage trials remain after filtering.",
      "i" = "Check `stage`, `timed_out`, and `response_outcome` values."
    ))
  }

  # Build a lookup table for all test pairs with their canonical labels
  all_test_cues <- dplyr::bind_rows(
    .fb_minuend_test_pairs,
    .fb_subtrahend_test_pairs
  ) |>
    dplyr::mutate(compound_cue = paste0(.data$cue1, .data$cue2))

  # Attach pair_type and pair_label to each test trial
  test_labelled <- test_trials |>
    dplyr::left_join(all_test_cues, by = c("cue1", "cue2"))

  n_total_pairs <- nrow(test_labelled)
  n_unmatched_pairs <- sum(is.na(test_labelled$compound_cue))
  if (n_unmatched_pairs > 0L) {
    cli::cli_inform(c(
            "{n_unmatched_pairs} test trial{?s} did not match any of the {n_total_pairs} expected cue-pairs.",
      "i" = "These are excluded from the blocking score calculation."
    ))
  }

  p_o3_per_compound <- test_labelled |>
    tidyr::drop_na("compound_cue") |>
    dplyr::group_by(.data$id, .data$compound_cue) |>
    dplyr::summarise(
      p_o3     = mean(.data$response == "o3", na.rm = TRUE),
      n_trials = dplyr::n(),
      .groups  = "drop"
    )

  expected_pairs <- all_test_cues$compound_cue
  missing_summary <- p_o3_per_compound |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      n_missing = length(setdiff(expected_pairs, .data$compound_cue)),
      .groups   = "drop"
    ) |>
    dplyr::filter(.data$n_missing > 0L)

  if (nrow(missing_summary) > 0L) {
    cli::cli_warn(c(
            "Some participants are missing trials for one or more of the {n_total_pairs} test cue-pairs.",
      "i" = "{nrow(missing_summary)} affected participant{?s}.",
      "i" = "`pj_score` will be `NA` for participants with any missing pair."
    ))
  }

  p_o3_wide <- p_o3_per_compound |>
    dplyr::select("id", "compound_cue", "p_o3") |>
    tidyr::pivot_wider(
      names_from   = "compound_cue",
      values_from  = "p_o3",
      names_prefix = "p_o3_"
    )

  minuend_cols     <- paste0("p_o3_", .fb_minuend_test_pairs$cue1, .fb_minuend_test_pairs$cue2)
  subtrahend_cols  <- paste0("p_o3_", .fb_subtrahend_test_pairs$cue1, .fb_subtrahend_test_pairs$cue2)

  missing_minuend    <- setdiff(minuend_cols, names(p_o3_wide))
  missing_subtrahend <- setdiff(subtrahend_cols,  names(p_o3_wide))

  if (length(missing_minuend) > 0L || length(missing_subtrahend) > 0L) {
    cli::cli_abort(c(
            "Expected P(o3) columns are entirely absent from the computed table.",
      "x" = "Missing blocking columns: {missing_blocking}.",
      "x" = "Missing control columns:  {missing_control}.",
      "i" = "Verify that the test stage contains trials for all 8 cue-pairs."
    ))
  }

  p_o3_wide |>
    dplyr::mutate(
      pj_score =
        rowSums(dplyr::across(dplyr::all_of(minuend_cols)), na.rm = FALSE) -
        rowSums(dplyr::across(dplyr::all_of(subtrahend_cols)), na.rm = FALSE)
    )
}
