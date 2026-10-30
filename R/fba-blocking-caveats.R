#' Report what `score_blocking()` scored and how
#'
#' @param scores The tibble `score_blocking()` is about to return.
#' @param design Character(1). Study design recorded in the provenance.
#' @param stages Character. The test stage that was scored.
#' @param scale Integer, `c(min = , max = )`, or `NULL`. The confidence scale
#'   of the design.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_blocking_scoring_caveats <- function(scores, design, stages, scale) {
  n_participants <- dplyr::n_distinct(scores$id)
  n_timed_out <- sum(scores$timed_out)
  n_no_confidence <- sum(!is.na(scores$consistent) & is.na(scores$confidence))
  timed_out_ids <- unique(scores$id[scores$timed_out])

  cli::cli_inform(c(
    "i" = "Scored {nrow(scores)} trial{?s} of the {.val {stages}} stage of the {.val {design}} design, from {n_participants} participant{?s}.",
    "i" = "{.field consistent} compares each response with the outcome expected if blocking took place, i.e., the Stage 3 outcome associated with the control cue, recorded for every test pair in the design.",
    "i" = "{.field signed_confidence} is the confidence rating, positive for a response consistent with blocking and negative otherwise.",
    "i" = if (is.null(scale)) {
      "The design collects no confidence ratings, so {.field confidence} and {.field signed_confidence} contain only {.code NA}s throughout."
    } else {
      "Confidence ratings use the {scale[['min']]} to {scale[['max']]} scale."
    },
    "i" = "{n_timed_out} timed-out trial{?s} {?has/have} no response and will not enter the indices.",
    if (n_timed_out > 0L) {
      c("*" = "Participant{?s} with timed-out trials: {.val {timed_out_ids}}.")
    },
    if (!is.null(scale) && n_no_confidence > 0L) {
      c("!" = "{n_no_confidence} answered trial{?s} {?has/have} no confidence rating, so {?its/their} {.field signed_confidence} is {.code NA}.")
    }
  ))
  invisible(NULL)
}


#' Report the definitions behind `index_blocking()` and what data entered the
#' calculations
#'
#' @param indices The tibble `index_blocking()` is about to return.
#' @param selection Integer. The selected blocks.
#' @param by_block Logical(1). As passed to `index_blocking()`.
#' @param n_pairs Integer(1). Test pairs per block.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_blocking_index_caveats <- function(
    indices,
    selection,
    by_block,
    n_pairs
) {
  label <- .label_blocks(selection)
  word <- if (length(selection) == 1L) "block" else "blocks"

  incomplete <- unique(indices$id[!indices$complete])
  no_trials <- unique(indices$id[indices$n_trials == 0L])
  no_choice <- unique(indices$id[is.na(indices$bi_choice) & indices$n_trials > 0L])

  cli::cli_inform(c(
    "i" = if (by_block) {
      "Indices computed per participant and test block, for {word} {label}, each of {n_pairs} test pairs."
    } else {
      "Indices computed per participant over test {word} {label}, each of {n_pairs} test pairs."
    },
    "i" = "{.field bi_confidence}, the confidence-weighted choice score, is the mean {.field signed_confidence} over answered trials (on block 1, the blocking index of Beesley & Le Pelley, 2011); positive values indicate blocking.",
    "i" = "{.field bi_choice}, the choice-proportion score, is the sum over test pairs of the proportion of answers consistent with blocking minus 0.5 (Paskewitz & Jones, 2020, Eq. 24; -{n_pairs / 2} to {n_pairs / 2}); positive values indicate blocking.",
    "i" = "Timed-out trials do not enter either index.",
    if (length(incomplete) > 0L) {
      c("!" = "Participant{?s} with timed-out trials or missing blocks ({.field complete} is {.code FALSE}): {.val {incomplete}}.")
    },
    if (length(no_choice) > 0L) {
      c("!" = "Participant{?s} without an answered trial for every test pair, so {.field bi_choice} is {.code NA}: {.val {no_choice}}.")
    },
    if (length(no_trials) > 0L) {
      c("!" = paste0(
        "Participant{?s} without any trial in ",
        if (by_block) "some of " else "",
        "the selected blocks, with zero counts and {.code NA} indices in ",
        if (by_block) "those rows" else "their row",
        ": {.val {no_trials}}."
      ))
    }
  ))
  invisible(NULL)
}


#' Report the assumptions behind `aggregate_blocking()`
#'
#' @param aggregated The tibble `aggregate_blocking()` is about to return.
#' @param indices The per-participant indices it was computed from.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_blocking_aggregation_caveats <- function(aggregated, indices) {
  n_missing_se <- sum(is.na(aggregated$se))
  n_missing <- sum(is.na(indices$bi_confidence)) + sum(is.na(indices$bi_choice))

  cli::cli_inform(c(
    "i" = "{.field se} is the between-participant standard error of the mean: SD / sqrt({.field n_participants}). Every participant counts once, however many trials they answered.",
    "i" = "This SE suits comparing a mean against zero (i.e., no blocking). Comparing the same participants across blocks or indices calls for their per-participant differences instead.",
    if (n_missing > 0L) {
      c("!" = "{n_missing} missing per-participant ind{?ex/ices} left out of the means.")
    },
    if (n_missing_se > 0L) {
      c("!" = "{n_missing_se} row{?s} {?has/have} fewer than two participants, so {?its/their} {.field se} is {.code NA}.")
    }
  ))
  invisible(NULL)
}


#' Report what `plot_blocking()` computed on the user's behalf
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_blocking_plot_caveats <- function() {
  cli::cli_inform(c(
    "i" = "{.fn plot_blocking} runs {.fn aggregate_blocking} internally to compute the plotted means and error bars.",
    "i" = "Violins and points show the participant-level indices; the black point and bars show the mean and one standard error each way."
  ))
  invisible(NULL)
}
