#' Trace how far every participant got through the experiment
#'
#' For every participant in the bundle, counts the experiment trials recorded
#' and reports the furthest stage and block reached and how long the participant
#' spent responding. If run on a bundle before exclusions, it shows the
#' attrition funnel; if run during data collection, it monitors data quality
#' without reading any test response.
#'
#' @param x A `catlas_rawdata` object.
#' @param silence Logical(1). Suppress the message summarising the progress
#'   and what the time columns measure. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant in `meta`, and columns:
#'   \describe{
#'     \item{`id`}{Participant identifier.}
#'     \item{`n_trials`}{Experiment trials recorded, timed-out ones included.}
#'     \item{`last_stage`, `last_block`}{The furthest stage reached, in design
#'       order, and the last block recorded in it; `NA` if there is no trial.}
#'     \item{`learning_complete`}{`TRUE` iff every trial of every learning stage
#'       was recorded.}
#'     \item{`n_test_blocks`}{Number of test blocks recorded in full.}
#'     \item{`test_complete`}{`TRUE` iff every test block was recorded in
#'       full.}
#'     \item{`duration_min`}{Wall-clock duration of the run, taken from
#'       `meta$duration_min` when the import recorded it, otherwise `NA`.}
#'     \item{`task_min`}{Minutes spent responding: the sum of `rt1` and `rt2`
#'       over all experiment trials.}
#'     \item{`task_min_<stage>`}{The same as above, per stage.}
#'   }
#'
#' @details
#' Expected trial counts come from `provenance(x)$blocks` and
#' `provenance(x)$trial_types`. The learning stages are the stages that the
#' study design marks as giving feedback, while all other stages count as test.
#'
#' `task_min` measures response times only. Feedback, inter-trial intervals,
#' instructions and breaks are not part of it, so it is shorter than
#' `duration_min`, which spans the whole run.
#'
#' A bundle after exclusions holds only the participants who were kept. Trace
#' the bundle as imported, before any `record_exclusion()` was applied, to see
#' where the excluded participants stopped.
#'
#' ## Messages
#'
#' Every call summarises the progress and states what the time columns
#' measure, unless silenced (`silence = TRUE`).
#'
#' @seealso [record_exclusion()], [score_learning()]
#'
#' @export
trace_progress <- function(x, silence = FALSE) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  prov <- provenance(x)
  stages <- .design_spec(prov$design)$stages
  learning <- .feedback_stages(prov$design)
  testing <- setdiff(stages, learning)
  expected <- prov$blocks[stages] * prov$trial_types

  meta <- extract_meta(x)
  ids <- as.character(meta$id)

  trials <-
    extract_trials(x) |>
    dplyr::mutate(
      id = as.character(.data$id),
      seconds = (dplyr::coalesce(.data$rt1, 0) + dplyr::coalesce(.data$rt2, 0)) / 1000
    )

  per_stage <-
    trials |>
    dplyr::group_by(
      .data$id,
      .data$stage
    ) |>
    dplyr::summarise(
      n = dplyr::n(),
      last_block = max(.data$block),
      task_min = sum(.data$seconds) / 60,
      .groups = "drop"
    ) |>
    dplyr::mutate(order = match(.data$stage, stages))

  furthest <-
    per_stage |>
    dplyr::group_by(.data$id) |>
    dplyr::slice_max(
      .data$order,
      n = 1L,
      with_ties = FALSE
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      "id",
      last_stage = "stage",
      "last_block"
    )

  learning_done <-
    per_stage |>
    dplyr::filter(.data$stage %in% learning) |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      learning_complete = dplyr::n() == length(learning) &&
        all(.data$n == expected[.data$stage]),
      .groups = "drop"
    )

  test_blocks <-
    trials |>
    dplyr::filter(.data$stage %in% testing) |>
    dplyr::count(
      .data$id,
      .data$stage,
      .data$block,
      name = "n"
    ) |>
    dplyr::filter(.data$n == prov$trial_types) |>
    dplyr::count(.data$id, name = "n_test_blocks")

  task <-
    per_stage |>
    dplyr::select("id", "stage", "task_min") |>
    tidyr::pivot_wider(
      names_from   = "stage",
      values_from  = "task_min",
      names_prefix = "task_min_",
      values_fill  = 0
    )

  stage_cols <- paste0("task_min_", stages)
  for (col in setdiff(stage_cols, names(task))) {
    task[[col]] <- 0
  }

  progress <-
    tibble::tibble(id = ids) |>
    dplyr::left_join(dplyr::count(trials, .data$id, name = "n_trials"), by = "id") |>
    dplyr::left_join(furthest, by = "id") |>
    dplyr::left_join(learning_done, by = "id") |>
    dplyr::left_join(test_blocks, by = "id") |>
    dplyr::left_join(task, by = "id") |>
    dplyr::mutate(
      n_trials = dplyr::coalesce(.data$n_trials, 0L),
      learning_complete = dplyr::coalesce(.data$learning_complete, FALSE),
      n_test_blocks = dplyr::coalesce(.data$n_test_blocks, 0L),
      test_complete = .data$n_test_blocks == sum(prov$blocks[testing]),
      duration_min = if ("duration_min" %in% names(meta)) {
        as.numeric(meta$duration_min)
      } else {
        NA_real_
      },
      dplyr::across(tidyselect::all_of(stage_cols), \(m) dplyr::coalesce(m, 0))
    )

  progress$task_min <- rowSums(progress[stage_cols])

  progress <- dplyr::select(
    progress,
    "id",
    "n_trials",
    "last_stage",
    "last_block",
    "learning_complete",
    "n_test_blocks",
    "test_complete",
    "duration_min",
    "task_min",
    tidyselect::all_of(stage_cols)
  )

  if (!silence) {
    .report_progress_caveats(progress, has_duration = "duration_min" %in% names(meta))
  }

  progress
}


#' Report what `trace_progress()` found and what its time columns measure
#'
#' @param progress The tibble `trace_progress()` is about to return.
#' @param has_duration Logical(1). Whether `meta` held `duration_min`.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_progress_caveats <- function(progress, has_duration) {
  n <- nrow(progress)
  no_trials <- sum(progress$n_trials == 0L)
  learned <- sum(progress$learning_complete)
  one_block <- sum(progress$n_test_blocks > 0L)
  tested <- sum(progress$test_complete)

  cli::cli_inform(c(
    "i" = "Traced {n} participant{?s}:",
    "*" = "  {no_trials} without any experiment trial",
    "*" = "  {learned} with complete learning stages,",
    "*" = "  {one_block} with at least one complete test block,",
    "*" = "  {tested} with the complete test.",
    "i" = "{.field task_min} sums response times ({.field rt1} + {.field rt2}) only; feedback, inter-trial intervals and instructions are not included.",
    if (has_duration) {
      c("i" = "{.field duration_min} is the wall-clock duration recorded at import and spans the whole visit.")
    } else {
      c("!" = "{.field meta} holds no {.field duration_min}, so the column is {.code NA}.")
    },
    "i" = "Excluded participants are no longer in a data bundle after {.fn record_exclusion}; trace the bundle as imported to see where they stopped."
  ))
  invisible(NULL)
}
