# Columns that every learning summary contains, in this order.
.learning_cols <- c(
  "id",
  "stage",
  "type",
  "block",
  "n_trials",
  "n_timed_out",
  "n_responded",
  "n_correct",
  "p_correct"
)


#' Check whether a table is a per-participant learning summary
#'
#' @param learning Object to check.
#' @param call Environment for error reporting.
#'
#' @returns `learning` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_learning <- function(learning, call = rlang::caller_env()) {
  if (!is.data.frame(learning)) {
    cli::cli_abort(c(
            "`learning` must be a data frame.",
      "i" = "Create it with {.fn score_learning}."
    ), call = call)
  }

  missing <- setdiff(.learning_cols, names(learning))

  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "`learning` is missing {length(missing)} required column{?s}.",
      "x" = "Missing: {.val {missing}}.",
      "i" = "Create it with {.fn score_learning}."
    ), call = call)
  }

  invisible(learning)
}


#' Score learning per participant
#'
#' Counts the trials, responses and correct responses of every participant in
#' every block of every learning stage, separately for each contingency type.
#' The results represent the per-participant, per-type summaries on which the
#' learning checks and the learning-based exclusion rules are based.
#'
#' @param x A `catlas_rawdata` object.
#' @param silence Logical(1). Suppress the message summarising what data went
#'   into the calculations. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant, stage, contingency type and
#'   block, and columns:
#'   \describe{
#'     \item{`id`}{Participant identifier.}
#'     \item{`stage`, `type`, `block`}{As in the `trials` component.}
#'     \item{`n_trials`}{Number of trials presented.}
#'     \item{`n_timed_out`}{Number of trials that ended without a response.}
#'     \item{`n_responded`}{Number of trials with a recorded response.}
#'     \item{`n_correct`}{Number of correct responses.}
#'     \item{`p_correct`}{`n_correct / n_responded`, or `NA` when no trial
#'       was answered.}
#'   }
#'
#' @details
#' ## Stages
#'
#' Only the stages that give feedback according to the study design are used
#' during the calculations. The design can be found in the `provenance(x)`. The
#' test stage is never included, because in it, the `is_correct` column records
#' whether a response is consistent with blocking, which is a component part of
#' the outcome measure of the study, rather than a measure of learning.
#'
#' ## Timed-out trials
#'
#' Timed-out trials are left out of the denominator of `p_correct` and counted
#' in `n_timed_out` instead, so that leaving the task is not confused with
#' giving an incorrect answer.
#'
#' ## Messages
#'
#' Every call states which stages were scored and how many timed-out trials
#' were left out of the denominators, unless manually silenced
#' (`silence = TRUE`).
#'
#' @seealso [aggregate_learning()], [plot_learning()]
#'
#' @export
score_learning <- function(x, silence = FALSE) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  design <- provenance(x)$design
  stages <- .feedback_stages(design)

  scores <-
    extract_trials(x) |>
      dplyr::filter(.data$stage %in% stages) |>
      dplyr::group_by(
        .data$id,
        .data$stage,
        .data$type,
        .data$block
      ) |>
      dplyr::summarise(
        n_trials = dplyr::n(),
        n_timed_out = sum(.data$timed_out %in% TRUE),
        n_responded = sum(!is.na(.data$is_correct)),
        n_correct = sum(.data$is_correct %in% TRUE),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        id = as.character(.data$id),
        block = as.integer(.data$block),
        p_correct = dplyr::if_else(
          .data$n_responded > 0L,
          .data$n_correct / .data$n_responded,
          NA_real_
        )
      ) |>
      dplyr::arrange(
        .data$id,
        match(.data$stage, stages),
        .data$type,
        .data$block
      ) |>
      dplyr::select(tidyselect::all_of(.learning_cols))

  if (!silence) {
    .report_scoring_caveats(design, stages, sum(scores$n_timed_out))
  }

  scores
}


#' Aggregate learning across participants
#'
#' Averages the per-participant proportions of correct responses within each
#' stage, contingency type and block, and gives the standard error of that
#' mean.
#'
#' @param learning A per-participant learning summary, from
#'   [score_learning()].
#' @param silence Logical(1). Suppress the message about the assumptions behind
#'   the calculations. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per stage, contingency type and block and
#'   columns:
#'   \describe{
#'     \item{`stage`, `type`, `block`}{As in `learning`.}
#'     \item{`n_participants`}{Participants with at least one answered trial
#'       in the cell.}
#'     \item{`p_correct`}{Mean of the participants' `p_correct`.}
#'     \item{`se`}{Standard error of the `p_correct` mean,
#'       \eqn{SD / \sqrt{n_{participants}}}; `NA` in rows with fewer than two
#'       participants.}
#'   }
#'
#' @details
#' Every participant counts once per cell, no matter how many trials they
#' answered. The standard error is computed between participants, because the
#' learning check asks whether accuracy is above chance, not whether the
#' accuracy differs as a function of cue type or stage (which would ask for a
#' within-subjects SE instead). Every call states this definition of the
#' standard error and states the cells where it could not be computed, unless
#' silenced (`silence = TRUE`).
#'
#' @seealso [score_learning()], [plot_learning()]
#'
#' @export
aggregate_learning <- function(learning, silence = FALSE) {
  .check_learning(learning)

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  aggregated <-
    learning |>
      dplyr::filter(!is.na(.data$p_correct)) |>
      dplyr::group_by(
        .data$stage,
        .data$type,
        .data$block
      ) |>
      dplyr::summarise(
        n_participants = dplyr::n(),
        se = stats::sd(.data$p_correct) / sqrt(dplyr::n()),
        p_correct = mean(.data$p_correct),
        .groups = "drop"
      ) |>
      dplyr::arrange(
        .stage_order(.data$stage),
        .data$type,
        .data$block
      ) |>
      dplyr::select(
        "stage",
        "type",
        "block",
        "n_participants",
        "p_correct",
        "se"
      )

  if (!silence) {
    .report_aggregation_caveats(aggregated)
  }

  aggregated
}
