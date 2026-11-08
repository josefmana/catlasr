# Columns that every blocking score table contains, in this order.
.blocking_score_cols <- c(
  "id",
  "block",
  "cue1",
  "cue2",
  "blocked",
  "control",
  "expected",
  "timed_out",
  "response",
  "consistent",
  "confidence",
  "signed_confidence"
)

# Columns that every per-participant blocking index table contains, in this
# order.
.blocking_index_cols <- c(
  "id",
  "blocks",
  "first_block",
  "last_block",
  "n_blocks",
  "n_trials",
  "n_timed_out",
  "n_answered",
  "complete",
  "p_blocking_consistent",
  "bi_confidence",
  "bi_choice"
)


# Display labels of the blocking indices, by column name.
.blocking_index_labels <- c(
  bi_confidence = "Confidence-weighted choice score",
  bi_choice     = "Choice-proportion score"
)


#' Check whether a table holds per-trial blocking scores
#'
#' @param scores Object to check.
#' @param call Environment for error reporting.
#'
#' @returns `scores` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_blocking_scores <- function(scores, call = rlang::caller_env()) {
  .check_blocking_table(
    scores,
    cols  = .blocking_score_cols,
    arg   = "scores",
    maker = "score_blocking",
    call  = call
  )
}


#' Check whether a table holds per-participant blocking indices
#'
#' @param indices Object to check.
#' @param call Environment for error reporting.
#'
#' @returns `indices` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_blocking_indices <- function(indices, call = rlang::caller_env()) {
  .check_blocking_table(
    indices,
    cols  = .blocking_index_cols,
    arg   = "indices",
    maker = "index_blocking",
    call  = call
  )
}


#' Check a table for the columns a given blocking function produces
#'
#' @param x Object to check.
#' @param cols Character. Required columns.
#' @param arg Character(1). Argument name, used in messages.
#' @param maker Character(1). Function that creates the table, used in messages.
#' @param call Environment for error reporting.
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.check_blocking_table <- function(x, cols, arg, maker, call) {
  if (!is.data.frame(x)) {
    cli::cli_abort(c(
            "`{arg}` must be a data frame.",
      "i" = "Create it with {.fn {maker}}."
    ), call = call)
  }

  missing <- setdiff(cols, names(x))

  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "`{arg}` is missing {length(missing)} required column{?s}.",
      "x" = "Missing: {.val {missing}}.",
      "i" = "Create it with {.fn {maker}}."
    ), call = call)
  }

  invisible(x)
}


#' Label a set of blocks for display
#'
#' @param blocks Integer. Block numbers, sorted.
#'
#' @returns Character(1): `"1"`, a range such as `"1-6"` (with an en dash) for
#'   consecutive blocks, otherwise a comma-separated list.
#'
#' @noRd
.label_blocks <- function(blocks) {
  if (length(blocks) == 1L) {
    return(as.character(blocks))
  }

  if (all(diff(blocks) == 1L)) {
    return(paste0(min(blocks), "\u2013", max(blocks)))
  }

  paste(blocks, collapse = ", ")
}


#' Sort labels of block selections
#'
#' Orders the labels made by `.label_blocks()` by how many blocks they span,
#' then by their first block, so that single blocks come in order and pooled
#' selections follow them: `"1"`, `"2"`, ..., `"1-6"`.
#'
#' @param labels Character. Labels made by `.label_blocks()`.
#'
#' @returns Character. The unique labels, sorted.
#'
#' @noRd
.sort_block_labels <- function(labels) {
  labels <- unique(labels)
  bounds <- lapply(regmatches(labels, gregexpr("[0-9]+", labels)), as.integer)
  first <- vapply(bounds, min, integer(1))
  span <- vapply(
    seq_along(labels),
    \(i) {
      if (grepl("\u2013", labels[i])) {
        diff(range(bounds[[i]])) + 1L
      } else {
        length(bounds[[i]])
      }
    },
    integer(1)
  )
  labels[order(span, first)]
}


#' Select test blocks for `index_blocking()`
#'
#' @param blocks `NULL`, or whole numbers.
#' @param present Integer. Blocks present in the scores.
#' @param call Environment for error reporting.
#'
#' @returns Integer. The selected blocks, sorted and unique.
#'
#' @noRd
.select_test_blocks <- function(blocks, present, call = rlang::caller_env()) {
  if (is.null(blocks)) {
    return(present)
  }

  if (!is.numeric(blocks) || length(blocks) == 0L || anyNA(blocks) ||
      any(blocks < 1) || any(blocks != round(blocks))) {
    cli::cli_abort(c(
            "`blocks` must be `NULL` or positive whole numbers.",
      "x" = "Got {.val {blocks}}."
    ), call = call)
  }

  blocks <- sort(unique(as.integer(blocks)))
  absent <- setdiff(blocks, present)

  if (length(absent) > 0L) {
    cli::cli_abort(c(
            "No participant has trials in test block{?s} {.val {absent}}.",
      "i" = "Blocks present in `scores`: {.val {present}}."
    ), call = call)
  }

  blocks
}


#' Score the test stage for blocking
#'
#' Records, for every test trial of every participant, whether the response is
#' consistent with blocking and the confidence rating signed accordingly. The
#' result is the per-trial table from which [index_blocking()] computes the
#' blocking indices of each participant.
#'
#' @param x A `catlas_rawdata` object.
#' @param silence Logical(1). Suppress the message summarising what was scored
#'   and how. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant/test trial combination, i.e.,
#'   per participant, test block and test pair, and columns:
#'   \describe{
#'     \item{`id`}{Participant identifier.}
#'     \item{`block`}{Test block.}
#'     \item{`cue1`, `cue2`}{The test pair, in canonical order.}
#'     \item{`blocked`, `control`}{The cue of the pair blocked in Stage 2 and
#'       its control cue.}
#'     \item{`expected`}{The outcome blocking predicts: the Stage 3 outcome
#'       associated with the control as opposed to the blocked cue.}
#'     \item{`timed_out`}{Whether the trial ended without a response.}
#'     \item{`response`}{The chosen outcome, `NA` when timed out.}
#'     \item{`consistent`}{`response == expected`, i.e., whether the response
#'       is consistent with blocking; `NA` when timed out.}
#'     \item{`confidence`}{The confidence rating; `NA` when timed out, and
#'       throughout in a design that collects no confidence ratings.}
#'     \item{`signed_confidence`}{`confidence` when `consistent`,
#'       `-confidence` otherwise; `NA` when either is missing.}
#'   }
#'
#' @details
#' ## Consistency with blocking
#'
#' Every test pair combines a cue blocked in Stage 2 with a control cue that
#' was paired with the other outcome in Stage 3. If participants learned less
#' about the blocked cues than about the control cues during Stage 3, they
#' ought to choose the Stage 3 outcome of the control cue (Beesley & Le Pelley,
#' 2011). The design registry records which outcome was paired with the control
#' and which with the blocked cue for every test pair, and `consistent` is
#' derived from it and the response.
#'
#' The jsPsych column `is_correct` contains the same comparison as made by the
#' experiment build. The function aborts if any answered test trial disagrees
#' with the registry, or if a test trial presents a pair the design does not
#' list. An experiment build whose expectations differed from the registry would
#' otherwise flip the sign of the indices on the pairs concerned. Data bundles
#' built with the current version of [build_fba_rawdata()] are checked when they
#' are built as well.
#'
#' ## Blocking test
#'
#' The function scores a *compound negation test* (Don & Livesey, 2018), known
#' in older literature as a *conflict test* (Gluck & Bower, 1988). In it, every
#' test trial presents two cues that were paired with different outcomes during
#' training, here a cue blocked in Stage 2 and a control cue paired with the
#' other outcome in Stage 3, and asks which outcome follows the compound. The
#' answer is a discrete choice among the outcomes of the test, i.e., an
#' N-alternative forced choice (N-AFC, with N the number of outcomes),
#' optionally followed by a confidence rating.
#'
#' Currently, only the three-stage forward blocking designs with a context
#' change between Stages 2 and 3 record such test pairs in the design registry.
#' For any other design, the function aborts. Single-cue tests, in which the
#' association of each cue with an outcome is rated or chosen separately, are
#' not scored. Other designs and tests will be added once the need arises, e.g.,
#' when the `CATLAS` project runs a different kind of experiment.
#'
#' ## Confidence ratings
#'
#' The design registry records the scale of the confidence ratings (1 to 10 in
#' the three-stage designs, as in Beesley & Le Pelley, 2011). In a design that
#' collects no confidence ratings, `confidence` and `signed_confidence` are `NA`
#' throughout, so that the table keeps the same columns in every design, and
#' the confidence-weighted index of [index_blocking()] is `NA` too.
#'
#' ## Messages
#'
#' Every call states what was scored, how the sign is defined, the confidence
#' scale, and how many trials timed out, unless silenced (`silence = TRUE`).
#'
#' @references
#' Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on overt
#'   attention and associability in human learning. *Journal of Experimental
#'   Psychology: Animal Behavior Processes, 37*(1), 114-120.
#'   \doi{10.1037/a0019526}
#'
#' Don, H. J., & Livesey, E. J. (2018). Is the blocking effect sensitive to
#'   causal model? It depends how you ask. In *Proceedings of the 40th Annual
#'   Meeting of the Cognitive Science Society* (pp. 1633-1638).
#'
#' Gluck, M. A., & Bower, G. H. (1988). From conditioning to category learning:
#'   An adaptive network model. *Journal of Experimental Psychology: General,
#'   117*(3), 227-247. \doi{10.1037/0096-3445.117.3.227}
#'
#' @seealso [index_blocking()], [aggregate_blocking()], [plot_blocking()]
#'
#' @export
score_blocking <- function(x, silence = FALSE) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  design <- provenance(x)$design
  pairs  <- .test_pairs(design)
  stages <- .test_stages(design)
  scale  <- .confidence_scale(design)

  if (length(stages) != 1L) {
    cli::cli_abort(c(
            "{.fn score_blocking} expects a design with exactly one test stage.",
      "x" = "Stages without feedback in {.val {design}}: {.val {stages}}."
    ))
  }

  trials <- extract_trials(x)
  .check_fba_test_expectations(trials, design, call = rlang::current_env())

  scores <-
    trials |>
    dplyr::filter(.data$stage %in% stages) |>
    dplyr::inner_join(
      pairs,
      by = c("cue1", "cue2")
    ) |>
    dplyr::mutate(
      id = as.character(.data$id),
      block = as.integer(.data$block),
      timed_out = .data$timed_out %in% TRUE,
      response = dplyr::if_else(.data$timed_out, NA_character_, as.character(.data$response)),
      consistent = .data$response == .data$expected,
      confidence = if (is.null(scale)) {
        NA_real_
      } else {
        dplyr::if_else(.data$timed_out, NA_real_, as.numeric(.data$confidence))
      },
      signed_confidence = .data$confidence * (2 * .data$consistent - 1)
    ) |>
    dplyr::arrange(
      .data$id,
      .data$block,
      match(paste(.data$cue1, .data$cue2), paste(pairs$cue1, pairs$cue2))
    ) |>
    dplyr::select(tidyselect::all_of(.blocking_score_cols))

  if (!silence) {
    .report_blocking_scoring_caveats(scores, design, stages, scale)
  }

  scores
}


#' Compute blocking indices per participant
#'
#' Turns the per-trial blocking scores from [score_blocking()] into two
#' blocking indices per participant over the test blocks selected: the
#' confidence-weighted choice score of Beesley and Le Pelley (2011) and the
#' choice-proportion score of Paskewitz and Jones (2020). See details for their
#' definitions.
#'
#' @param scores Per-trial blocking scores; the result from [score_blocking()].
#' @param blocks Integer. Test blocks that enter the indices. Defaults to `1L`,
#'   the first test block. `NULL` selects every block present in `scores`.
#' @param by_block Logical(1). `FALSE` (default) pools the selected blocks into
#'   one row per participant; `TRUE` gives one row per participant and selected
#'   block, which allows following the indices across the test stage.
#' @param silence Logical(1). Suppress the message about the definitions and
#'   the data that entered. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per participant (and selected block, with
#'   `by_block = TRUE`) and columns:
#'   \describe{
#'     \item{`id`}{Participant identifier.}
#'     \item{`blocks`}{The selected blocks as a label, e.g. `"1"` or
#'       `"1-6"`; with `by_block = TRUE`, the block of the row.}
#'     \item{`first_block`, `last_block`, `n_blocks`}{The selected blocks the
#'       participant has trials in.}
#'     \item{`n_trials`}{Number of test trials in selected blocks.}
#'     \item{`n_timed_out`}{Number of trials that ended without a response.}
#'     \item{`n_answered`}{Number of trials with a response.}
#'     \item{`complete`}{Logical `TRUE` iff every selected block is present and
#'       every trial in it answered.}
#'     \item{`p_blocking_consistent`}{Proportion of answered trials consistent
#'       with blocking.}
#'     \item{`bi_confidence`}{Confidence-weighted choice score: mean signed
#'       confidence over answered trials. `NA` in a design without confidence
#'       ratings.}
#'     \item{`bi_choice`}{Choice-proportion score: sum over test pairs of the
#'       proportion of answers consistent with blocking, minus one half per
#'       pair. `NA` when a pair has no answered trial in the selected blocks.}
#'   }
#'   Participants without any trial in the selected blocks keep a row, with
#'   zero counts and `NA` indices.
#'
#' @details
#' ## Confidence-weighted choice score (`bi_confidence`)
#'
#' \deqn{\mathbb{E}[Conf \times (I_{\{o_c\}} - I_{\{o_b\}})]}
#'
#' where \eqn{o_c} is the Stage 3 outcome paired with the control cue, \eqn{o_b}
#' outcome paired with the blocked cue, and `Conf` is the confidence rating. The
#' index is thus essentially the mean of `signed_confidence`. Positive values
#' indicate blocking. The confidence scale bounds the index (-10 to 10 on the
#' 1-to-10 scale of Beesley & Le Pelley, 2011). On the first test block
#' (`blocks = 1L`), it is the index that Beesley and Le Pelley (2011) reported.
#'
#' ## Choice-proportion score (`bi_choice`)
#'
#' Paskewitz and Jones (2020, Eq. 24) defined
#'
#' \deqn{\sum_{p \in P_3} P(o_3 | p) - \sum_{p \in P_4} P(o_3 | p)}
#'
#' where \eqn{P_3} are the test pairs on which blocking predicts \eqn{o_3} and
#' \eqn{P_4} those on which it predicts \eqn{o_4}. In other words, \eqn{P_3}
#' contains those cue compounds, in which the putatively blocked cue was
#' associated with `o4` during Stage 3 (i.e., blocking-consistent response on
#' those trials is `o3`) and vice versa for \eqn{P_4}.
#'
#' Since \eqn{P(o_3|p)} is the proportion of consistent answers on the pairs of
#' \eqn{P_3} and one minus it on the pairs of \eqn{P_4}, and the two sets are
#' equally large, the index equals the sum over all pairs of the proportion of
#' consistent answers minus one half, which is what is computed here. It ranges
#' from -4 to 4 with eight pairs; positive values indicating blocking. Every
#' pair weighs the same, however many of its trials were answered.
#'
#' ## Dropped trials
#'
#' Timed-out trials have no response and do not enter either index; they are
#' counted in `n_timed_out`. Both indices therefore average over the answered
#' trials only, and a participant with timed-out trials can have more answers
#' expecting one outcome than the other. `complete` marks the participants
#' without such an imbalance.
#'
#' ## Messages
#'
#' Every call states the blocks that entered, the definitions and sign of the
#' indices, and the participants with timed-out trials or missing blocks, unless
#' silenced (`silence = TRUE`).
#'
#' @references
#' Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on overt
#'   attention and associability in human learning. *Journal of Experimental
#'   Psychology: Animal Behavior Processes, 37*(1), 114-120.
#'   \doi{10.1037/a0019526}
#'
#' Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. *Journal of
#'   Mathematical Psychology, 97*, 102371. \doi{10.1016/j.jmp.2020.102371}
#'
#' @seealso [score_blocking()], [aggregate_blocking()], [plot_blocking()]
#'
#' @export
index_blocking <- function(
    scores,
    blocks = 1L,
    by_block = FALSE,
    silence = FALSE
) {
  .check_blocking_scores(scores)

  if (!rlang::is_bool(by_block)) {
    cli::cli_abort("`by_block` must be `TRUE` or `FALSE`.")
  }

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  present <- sort(unique(scores$block))
  selection <- .select_test_blocks(blocks, present)

  pair_counts <- table(dplyr::distinct(scores, .data$cue1, .data$cue2, .data$expected)$expected)

  if (length(unique(pair_counts)) != 1L) {
    cli::cli_abort(c(
            "The choice-proportion score needs an equal number of test pairs expecting each outcome.",
      "x" = "Test pairs per expected outcome: {paste(names(pair_counts), pair_counts, sep = ' = ', collapse = ', ')}."
    ))
  }

  n_pairs <- sum(pair_counts)

  groups <- if (by_block) {
    tibble::tibble(
      block = selection,
      blocks = as.character(selection)
    )
  } else {
    tibble::tibble(
      block = selection,
      blocks = .label_blocks(selection)
    )
  }

  n_requested <- if (by_block) 1L else length(selection)

  selected <- dplyr::inner_join(scores, groups, by = "block")

  choice <-
    selected |>
    dplyr::group_by(
      .data$id,
      .data$blocks,
      .data$cue1,
      .data$cue2
    ) |>
    dplyr::summarise(
      n_pair_answered = sum(!is.na(.data$consistent)),
      p_pair = mean(.data$consistent, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::group_by(
      .data$id,
      .data$blocks
    ) |>
    dplyr::summarise(
      bi_choice = if (sum(.data$n_pair_answered > 0L) == n_pairs) {
        sum(.data$p_pair[.data$n_pair_answered > 0L] - 0.5)
      } else {
        NA_real_
      },
      .groups = "drop"
    )

  pooled <-
    selected |>
    dplyr::group_by(
      .data$id,
      .data$blocks
    ) |>
    dplyr::summarise(
      first_block = min(.data$block),
      last_block = max(.data$block),
      n_blocks = dplyr::n_distinct(.data$block),
      n_trials = dplyr::n(),
      n_timed_out = sum(.data$timed_out),
      n_answered = sum(!is.na(.data$consistent)),
      n_consistent = sum(.data$consistent %in% TRUE),
      n_signed = sum(!is.na(.data$signed_confidence)),
      sum_signed = sum(.data$signed_confidence, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::left_join(
      choice,
      by = c("id", "blocks")
    )

  grid <- tidyr::expand_grid(
    id = unique(scores$id),
    blocks = unique(groups$blocks)
  )

  indices <-
    grid |>
    dplyr::left_join(
      pooled,
      by = c("id", "blocks")
    ) |>
    dplyr::mutate(
      n_blocks = dplyr::coalesce(.data$n_blocks, 0L),
      n_trials = dplyr::coalesce(.data$n_trials, 0L),
      n_timed_out = dplyr::coalesce(.data$n_timed_out, 0L),
      n_answered = dplyr::coalesce(.data$n_answered, 0L),
      complete = .data$n_blocks == n_requested &
        .data$n_trials == n_requested * n_pairs &
        .data$n_answered == .data$n_trials,
      p_blocking_consistent = dplyr::if_else(
        .data$n_answered > 0L,
        .data$n_consistent / .data$n_answered,
        NA_real_
      ),
      bi_confidence = dplyr::if_else(
        dplyr::coalesce(.data$n_signed, 0L) > 0L,
        .data$sum_signed / .data$n_signed,
        NA_real_
      )
    ) |>
    dplyr::arrange(
      .data$id,
      match(.data$blocks, groups$blocks)
    ) |>
    dplyr::select(tidyselect::all_of(.blocking_index_cols))

  if (!silence) {
    .report_blocking_index_caveats(indices, selection, by_block, n_pairs)
  }

  indices
}


#' Aggregate blocking indices across participants
#'
#' Averages the per-participant blocking indices from [index_blocking()] and
#' gives the standard error of each mean, i.e., an estimate with its standard
#' error, the form that power and design analyses take.
#'
#' @param indices Per-participant blocking indices, resulting from
#'   [index_blocking()]. Tables for several selections of blocks can be bound by
#'   rows first.
#' @param silence Logical(1). Suppress the message about the assumptions behind
#'   the calculations. Defaults to `FALSE` (recommended).
#'
#' @returns A tibble with one row per index and selection of blocks, and
#'   columns:
#'   \describe{
#'     \item{`index`}{The index, according to its column name in `indices`:
#'       `"bi_confidence"` or `"bi_choice"`.}
#'     \item{`blocks`}{As in `indices`.}
#'     \item{`n_participants`}{Participants with a non-missing index.}
#'     \item{`estimate`}{Mean of the participants' indices.}
#'     \item{`sd`}{Standard deviation of the participants' indices.}
#'     \item{`se`}{Standard error of the mean, \eqn{SD / \sqrt{n}}; `NA` in
#'       cases with fewer than two participants.}
#'   }
#'
#' @details
#' During the aggregation, every participant counts once, no matter how many
#' trials they answered. Beware thus uneven trial counts across the dataset. In
#' such a case, you can, for instance, filter the input for `complete %in% TRUE`
#' as a sensitivity analysis, or even better analyse the data with a bespoke
#' model that considers such imbalances, e.g., via partial pooling.
#'
#' The standard error is computed between participants, which suits comparing a
#' mean against zero (i.e., no blocking). Comparing an index between selections
#' of blocks, such as the first block against all blocks, concerns the same
#' participants and calls for the per-participant differences or hierarchical
#' modelling instead. Per participant differences can be taken directly from
#' `indices`.
#'
#' Every call states these caveats, unless silenced (`silence = TRUE`, e.g.,
#' when a developer wishes to debug the code).
#'
#' @seealso [index_blocking()], [plot_blocking()]
#'
#' @export
aggregate_blocking <- function(indices, silence = FALSE) {
  .check_blocking_indices(indices)

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  block_order <- .sort_block_labels(indices$blocks)

  aggregated <-
    indices |>
    dplyr::select(
      "id",
      "blocks",
      "bi_confidence",
      "bi_choice"
    ) |>
    tidyr::pivot_longer(
      cols = c("bi_confidence", "bi_choice"),
      names_to = "index",
      values_to = "value"
    ) |>
    dplyr::filter(!is.na(.data$value)) |>
    dplyr::group_by(
      .data$index,
      .data$blocks
    ) |>
    dplyr::summarise(
      n_participants = dplyr::n(),
      estimate = mean(.data$value),
      sd = stats::sd(.data$value),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      se = .data$sd / sqrt(.data$n_participants)
    ) |>
    dplyr::arrange(
      match(.data$index, names(.blocking_index_labels)),
      match(.data$blocks, block_order)
    ) |>
    dplyr::select(
      "index",
      "blocks",
      "n_participants",
      "estimate",
      "sd",
      "se"
    )

  if (!silence) {
    .report_blocking_aggregation_caveats(aggregated, indices)
  }

  aggregated
}
