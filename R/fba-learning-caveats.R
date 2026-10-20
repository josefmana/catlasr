#' Report the assumptions behind `score_learning()`
#'
#' @param design Character(1). Study design recorded in the provenance.
#' @param stages Character. Feedback stages that were scored.
#' @param n_timed_out Integer(1). Timed-out trials within those stages.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_scoring_caveats <- function(design, stages, n_timed_out) {
  cli::cli_inform(c(
    "i" = "Scored {length(stages)} stage{?s} ({.val {stages}}), i.e., the stages of the {.val {design}} design that contain trial-by-trial feedback.",
    "i" = "Stages without feedback, such as the test stage, are left out, because their {.field is_correct} does not record a correct answer.",
    "i" = "{n_timed_out} timed-out trial{?s} {?is/are} left out of the {.field p_correct} denominators and counted in {.field n_timed_out} instead."
  ))
  invisible(NULL)
}


#' Report the assumptions behind `aggregate_learning()`
#'
#' @param aggregated The tibble `aggregate_learning()` is about to return.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_aggregation_caveats <- function(aggregated) {
  n_missing_se <- sum(is.na(aggregated$se))

  cli::cli_inform(c(
    "i" = "{.field se} is the between-participant standard error of the mean of participants' {.field p_correct}: SD / sqrt({.field n_participants}).",
    "i" = "Every participant counts once per cell, number of trials they answered in it notwithstanding.",
    "i" = "The SE suits comparing a cell against a constant, such as chance (50%). Comparing types or blocks within the same participants calls for a within-participant error instead.",
    if (n_missing_se > 0L) {
      c("!" = "{n_missing_se} cell{?s} {?has/have} fewer than two participants, so {?its/their} {.field se} is {.code NA}.")
    }
  ))
  invisible(NULL)
}


#' Report what `plot_learning()` computed on the user's behalf
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_plot_caveats <- function() {
  cli::cli_inform(c(
    "i" = "{.fn plot_learning} runs {.fn aggregate_learning} internally to compute the plotted means and error bars.",
    "i" = "Error bars span one standard error each way, clipped to the 0 to 100% range."
  ))
  invisible(NULL)
}
