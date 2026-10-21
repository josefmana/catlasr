#' Test learning against chance per participant and stage
#'
#' For every participant and learning stage, the function pools the scored
#' trials of the selected blocks across contingency types and tests the number
#' of correct responses against a chance performance with a one-sided exact
#' binomial test. Next to the test, it reports the cut-off: the smallest number
#' of correct responses that passes, given the number of answered trials.
#'
#' @param scores Per-participant learning scores, from [score_learning()].
#' @param blocks `NULL` (default) to test every block of every stage, or a
#'   named list of block numbers per stage, e.g.
#'   `list(stage1 = 6:10, stage2 = 5:8, stage3 = 4:6)`. Stages absent from the
#'   list are tested across all their blocks.
#' @param alpha Numeric(1). One-sided significance level of each test. Defaults
#'   to `0.10`.
#' @param chance Numeric(1). Probability of a correct response by guessing.
#'   Defaults to `0.5`, as every trial of the three-stage designs offers two
#'   outcomes.
#' @param silence Logical(1). Suppress the message about the assumptions behind
#'   the tests. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant and stage, and columns:
#'   \describe{
#'     \item{`id`, `stage`}{Participant and learning stage.}
#'     \item{`first_block`, `last_block`, `n_blocks`}{The blocks that entered
#'       the test for this participant.}
#'     \item{`n_responded`}{Answered trials across blocks.}
#'     \item{`n_correct`}{Correct responses among answers.}
#'     \item{`p_correct`}{`n_correct / n_responded`.}
#'     \item{`k_crit`}{Smallest `n_correct` that passes: the least \eqn{k}
#'       with \eqn{P(X \ge k) \le \alpha} for
#'       \eqn{X \sim Binomial(n_{responded}, chance)}.}
#'     \item{`p_crit`}{`k_crit` / `n_responded`. The proportion correct that
#'       passes the null-hypothesis significance test. It should not be
#'       confused with a p-value, compare it with `p_correct`.}
#'     \item{`p_value`}{One-sided exact binomial p-value,
#'       \eqn{P(X \ge n_{correct})}.}
#'     \item{`above_chance`}{`n_correct >= k_crit`, equivalently
#'       `p_value <= alpha`.}
#'   }
#'   A participant without any answered trial in a stage gets `NA` in the
#'   test columns, including `above_chance`.
#'
#' @details
#' ## Test assumptions
#'
#' Under the null hypothesis, a participant's responses carry no information
#' about which outcome is correct, so every answered trial is correct with
#' `chance` probability, independently of the block. The null distribution of
#' `n_correct` is therefore exactly \eqn{Binomial(n_{responded}, chance)} and
#' it does not depend on how accuracy would change across blocks for someone
#' who learns. Learning changes only the distribution under the alternative,
#' i.e., the power of the test, not its size (the rate at which participants
#' without knowledge succeed).
#'
#' Two consequences follow from Hoeffding (1956), who compares the number of
#' successes in independent trials with unequal success probabilities to the
#' binomial distribution with the same mean:
#'
#' * In the three-stage designs every block holds as many trials for one
#'   outcome as for the other. A participant who responds with a bias but
#'   without knowledge (e.g., always choosing the left option) is correct on
#'   half the tested trials on average, with less dispersion than the binomial,
#'   and so passes no more often than `alpha`. Only whole blocks enter the
#'   test, which keeps this balance.
#' * A participant whose accuracy rises across blocks passes at least as often
#'   as one with constant accuracy at the same mean, provided the expected
#'   number of correct responses exceeds `k_crit` by at least one.
#'
#' Each stage is tested on its own, with no adjustment of the significance test
#' threshold for multiple comparisons across stages. The question asked by the
#' test is whether the participant learned every stage.
#'
#' ## Default alpha
#'
#' At `alpha = 0.10` the cut-off on a 48-trial stage is 29 correct (60.4%),
#' similar to the 60% criterion that Le Pelley et al. (2005) applied to both
#' training stages of their two-stage design. On the 80- and 64-trial stages of
#' To our knowledge, no three-stage study tested Stage 3 against chance, so its
#' cut-off cannot be copied from the literature. At the default, a participant
#' who guesses throughout the three-stage replication passes each stage with
#' probability below `alpha`, and all three with probability below 0.001.
#'
#' ## Messages
#'
#' Every call states the test, the blocks per stage, and how many
#' participants failed the test in each stage, unless silenced
#' (`silence = TRUE`).
#'
#' @references
#' Le Pelley, M. E., Oakeshott, S. M., & McLaren, I. P. L. (2005).
#'   Blocking and unblocking in human causal learning. *Journal of Experimental
#'   Psychology: Animal Behavior Processes, 31*(1), 56-70.
#'   \doi{10.1037/0097-7403.31.1.56}
#'
#' Hoeffding, W. (1956). On the distribution of the number of
#'   successes in independent trials. *The Annals of Mathematical Statistics,
#'   27*(3), 713-721.
#'
#' @seealso [score_learning()], [screen_learning()]
#'
#' @export
test_learning <- function(
    scores,
    blocks = NULL,
    alpha = 0.10,
    chance = 0.5,
    silence = FALSE
) {
  .check_learning(scores)

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  .check_open_unit(alpha, "alpha")
  .check_open_unit(chance, "chance")

  selected <- .select_learning_blocks(scores, blocks)

  grid <- tidyr::expand_grid(
    id    = unique(scores$id),
    stage = unique(scores$stage)
  )

  tests <-
    selected |>
    dplyr::group_by(
      .data$id,
      .data$stage
    ) |>
    dplyr::summarise(
      first_block = min(.data$block),
      last_block = max(.data$block),
      n_blocks = dplyr::n_distinct(.data$block),
      n_responded = sum(.data$n_responded),
      n_correct = sum(.data$n_correct),
      .groups = "drop"
    )

  tests <-
    grid |>
    dplyr::left_join(
      tests,
      by = c("id", "stage")
    ) |>
    dplyr::mutate(
      n_blocks = dplyr::coalesce(.data$n_blocks, 0L),
      n_responded = dplyr::coalesce(.data$n_responded, 0L),
      n_correct = dplyr::coalesce(.data$n_correct, 0L),
      answered = .data$n_responded > 0L,
      p_correct = dplyr::if_else(
        .data$answered,
        .data$n_correct / .data$n_responded,
        NA_real_
      ),
      k_crit = dplyr::if_else(
        .data$answered,
        as.integer(stats::qbinom(1 - alpha, .data$n_responded, chance)) + 1L,
        NA_integer_
      ),
      p_crit = .data$k_crit / .data$n_responded,
      p_value = dplyr::if_else(
        .data$answered,
        stats::pbinom(.data$n_correct - 1L, .data$n_responded, chance, lower.tail = FALSE),
        NA_real_
      ),
      above_chance = .data$n_correct >= .data$k_crit
    ) |>
    dplyr::arrange(
      .data$id,
      .stage_order(.data$stage)
    ) |>
    dplyr::select(
      "id",
      "stage",
      "first_block",
      "last_block",
      "n_blocks",
      "n_responded",
      "n_correct",
      "p_correct",
      "k_crit",
      "p_crit",
      "p_value",
      "above_chance"
    )

  if (!silence) {
    .report_learning_test_caveats(tests, selected, alpha, chance)
  }

  tests
}


#' Keep the blocks selected for the learning test
#'
#' @param scores Per-participant learning scores.
#' @param blocks `NULL` or a named list of block numbers per stage.
#' @param call Environment for error reporting.
#'
#' @returns `scores`, restricted to the selected blocks.
#'
#' @noRd
.select_learning_blocks <- function(scores, blocks, call = rlang::caller_env()) {
  if (is.null(blocks)) {
    return(scores)
  }

  if (!is.list(blocks) || !rlang::is_named(blocks)) {
    cli::cli_abort(c(
            "`blocks` must be `NULL` or a named list of block numbers per stage.",
      "i" = "For instance, {.code list(stage1 = 6:10, stage2 = 5:8, stage3 = 4:6)}."
    ), call = call)
  }

  unknown <- setdiff(names(blocks), unique(scores$stage))

  if (length(unknown) > 0L) {
    cli::cli_abort(c(
            "`blocks` names {length(unknown)} stage{?s} absent from `scores`.",
      "x" = "Unknown: {.val {unknown}}.",
      "i" = "Stages in `scores`: {.val {unique(scores$stage)}}."
    ), call = call)
  }

  keep <- rep(TRUE, nrow(scores))

  for (stage in names(blocks)) {
    in_stage <- scores$stage == stage
    keep[in_stage] <- scores$block[in_stage] %in% blocks[[stage]]
  }

  scores[keep, , drop = FALSE]
}


#' Check that an argument is a single number strictly between 0 and 1
#'
#' @param value Value to check.
#' @param arg Character(1). Argument name, for the message.
#' @param call Environment for error reporting.
#'
#' @returns `value` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_open_unit <- function(value, arg, call = rlang::caller_env()) {
  if (!rlang::is_scalar_double(value) || is.na(value) || value <= 0 || value >= 1) {
    cli::cli_abort("`{arg}` must be a single number strictly between 0 and 1.", call = call)
  }
  invisible(value)
}
