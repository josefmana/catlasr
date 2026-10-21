#' Screen participants on their learning tests
#'
#' Applies an exclusion criterion to the per-stage tests implemented in
#' [test_learning()]. Which stages count to the exclusion decision and whether
#' failing any or all of them excludes the participant is decided here, in
#' `stages` and `rule`, respectively. The function Returns one row per
#' participant with the decision and the reason for it, so that the excluded
#' identifiers can be passed on to [record_exclusion()].
#'
#' @param tests Per-participant, per-stage learning tests from
#'   [test_learning()].
#' @param stages Character. Stages whose test counts towards the criterion.
#'   `NULL` (default) uses every stage in `tests`.
#' @param rule Character(1). `"any"` (default) excludes a participant who fails
#'   the test in at least one of `stages`. `"all"` excludes only a participant
#'   who fails it in every one of `stages`.
#' @param silence Logical(1). Suppress the message summarising the criterion
#'   and its yield. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant, and columns:
#'   \describe{
#'     \item{`id`}{Participant identifier.}
#'     \item{`exclude`}{`TRUE` when the participant meets the exclusion
#'       criterion.}
#'     \item{`n_failed`}{Number of `stages` in which the participant did not
#'       score significantly above chance.}
#'     \item{`failed_stages`}{Failed stages, comma-separated; `NA` when none.}
#'     \item{`reason`}{For excluded participants, the failed tests in words,
#'       e.g. `"Stage 3: 27/48 correct, below the cut-off of 29 (p = 0.235)"`;
#'       `NA` for participants who are kept.}
#'   }
#'
#' @details
#' A stage counts as failed when its test did find clear evidence of
#' above-chance performance, including a stage without any answered trial.
#'
#' The function makes exclusion decision, but it does not exclude. Exclusions
#' are applied, and recorded in the provenance of the data bundle, by
#' [record_exclusion()], for instance with `ids = screen$id[screen$exclude]`.
#' Its `description` should state the test, `alpha`, the stages and the rule, so
#' that it can be reported verbatim.
#'
#' ## Messages
#'
#' Every call states the criterion, how many participants it excludes, and how
#' many failed each of `stages`, unless silenced (`silence = TRUE`).
#'
#' @seealso [test_learning()], [record_exclusion()]
#'
#' @export
screen_learning <- function(
    tests,
    stages = NULL,
    rule = c("any", "all"),
    silence = FALSE
) {
  .check_learning_tests(tests)
  rule <- rlang::arg_match(rule)

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  available <- unique(tests$stage[order(.stage_order(tests$stage))])

  if (is.null(stages)) {
    stages <- available
  }

  if (!is.character(stages) || length(stages) == 0L) {
    cli::cli_abort("`stages` must be `NULL` or a character vector of stage names.")
  }

  unknown <- setdiff(stages, available)

  if (length(unknown) > 0L) {
    cli::cli_abort(c(
            "`stages` names {length(unknown)} stage{?s} absent from `tests`.",
      "x" = "Unknown: {.val {unknown}}.",
      "i" = "Stages in `tests`: {.val {available}}."
    ))
  }

  stages <- available[available %in% stages]

  considered <-
    tests |>
    dplyr::filter(.data$stage %in% stages) |>
    dplyr::mutate(
      failed = !(.data$above_chance %in% TRUE),
      detail = dplyr::if_else(
        .data$n_responded > 0L,
        sprintf(
          "%s: %d/%d correct, below the cut-off of %d (p %s)",
          .stage_label(.data$stage),
          .data$n_correct,
          .data$n_responded,
          .data$k_crit,
          dplyr::if_else(
            .data$p_value < 0.001,
            "< 0.001",
            sprintf("= %.3f", .data$p_value)
          )
        ),
        sprintf("%s: no answered trial", .stage_label(.data$stage))
      )
    ) |>
    dplyr::arrange(
      .data$id,
      .stage_order(.data$stage)
    )

  screen <-
    considered |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      n_failed = sum(.data$failed),
      failed_stages = if (any(.data$failed)) {
        paste(.data$stage[.data$failed], collapse = ", ")
      } else {
        NA_character_
      },
      reason = if (any(.data$failed)) {
        paste(.data$detail[.data$failed], collapse = "; ")
      } else {
        NA_character_
      },
      .groups = "drop"
    ) |>
    dplyr::mutate(
      exclude = if (rule == "any") {
        .data$n_failed > 0L
      } else {
        .data$n_failed == length(stages)
      },
      reason = dplyr::if_else(.data$exclude, .data$reason, NA_character_)
    ) |>
    dplyr::select(
      "id",
      "exclude",
      "n_failed",
      "failed_stages",
      "reason"
    )

  if (!silence) {
    .report_learning_screen_caveats(screen, considered, stages, rule)
  }

  screen
}


#' Check whether a table holds per-stage learning tests
#'
#' @param tests Object to check.
#' @param call Environment for error reporting.
#'
#' @returns `tests` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_learning_tests <- function(tests, call = rlang::caller_env()) {
  required <- c(
    "id",
    "stage",
    "n_responded",
    "n_correct",
    "k_crit",
    "p_value",
    "above_chance"
  )

  if (!is.data.frame(tests)) {
    cli::cli_abort(c(
            "`tests` must be a data frame.",
      "i" = "Create it with {.fn test_learning}."
    ), call = call)
  }

  missing <- setdiff(required, names(tests))

  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "`tests` is missing {length(missing)} required column{?s}.",
      "x" = "Missing: {.val {missing}}.",
      "i" = "Create it with {.fn test_learning}."
    ), call = call)
  }

  invisible(tests)
}
