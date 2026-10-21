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


#' Report the assumptions behind `test_learning()`
#'
#' @param tests The tibble `test_learning()` is about to return.
#' @param selected The learning scores restricted to the tested blocks.
#' @param alpha,chance As passed to `test_learning()`.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_learning_test_caveats <- function(tests, selected, alpha, chance) {
  stages <- unique(tests$stage[order(.stage_order(tests$stage))])

  tested_blocks <- vapply(stages, function(stage) {
    b <- sort(unique(selected$block[selected$stage == stage]))
    if (length(b) == 0L) {
      return(sprintf("%s: none", .stage_label(stage)))
    }
    span <- if (length(b) == max(b) - min(b) + 1L) {
      sprintf("%d to %d", min(b), max(b))
    } else {
      paste(b, collapse = ", ")
    }
    sprintf("%s: blocks %s", .stage_label(stage), span)
  }, character(1))

  failing <- vapply(stages, function(stage) {
    sum(tests$above_chance[tests$stage == stage] %in% FALSE)
  }, integer(1))

  not_tested <- sum(is.na(tests$above_chance))

  cli::cli_inform(c(
    "i" = "One-sided exact binomial test of {.field n_correct} against chance ({chance}) at alpha = {alpha}, per participant and stage, with no correction across stages, was conducted.",
    "i" = "Trials are pooled across contingency types within whole blocks.",
    "i" = "Timed-out trials are left out of {.field n_responded}.",
    "i" = "{.field k_crit} is the smallest {.field n_correct} that passes for the {.field n_responded} observed, and {.field p_crit} represents the same cut-off as a proportion.",
    "i" = "Tested: {paste(tested_blocks, collapse = '; ')}.",
    rlang::set_names(
      sprintf("%s: %d participant%s did not score above chance.", .stage_label(stages), failing, ifelse(failing == 1L, "", "s")),
      rep("*", length(stages))
    ),
    if (not_tested > 0L) {
      c("!" = "{not_tested} participant-stage combination{?s} did not include any answered trial. {.field above_chance} is {.code NA} in these cases.")
    }
  ))
  invisible(NULL)
}


#' Report the criterion applied by `screen_learning()` and its yield
#'
#' @param screen The tibble `screen_learning()` is about to return.
#' @param considered The tests of the stages that count, with a `failed` flag.
#' @param stages Character. Stages that count.
#' @param rule Character(1). `"any"` or `"all"`.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.report_learning_screen_caveats <- function(screen, considered, stages, rule) {
  labels <- .stage_label(stages)

  failing <- vapply(stages, function(stage) {
    sum(considered$failed[considered$stage == stage])
  }, integer(1))

  n_excluded <- sum(screen$exclude)
  n_total <- nrow(screen)

  criterion <- if (length(stages) == 1L) {
    sprintf("not above chance in %s", labels)
  } else if (rule == "any") {
    sprintf("not above chance in at least one of %s", paste(labels, collapse = ", "))
  } else {
    sprintf("not above chance in every one of %s", paste(labels, collapse = ", "))
  }

  cli::cli_inform(c(
    "i" = "Exclusion criterion: {criterion}. A stage without any answered trial counts as failed.",
    rlang::set_names(
      sprintf("%s: %d participant%s not above chance.", labels, failing, ifelse(failing == 1L, "", "s")),
      rep("*", length(stages))
    ),
    "i" = "{n_excluded} of {n_total} participant{?s} meet{?s/} the exclusion criterion. See {.field reason} for the failed tests.",
    "i" = "Nobody has been excluded yet: pass {.code id[exclude]} to {.fn record_exclusion}, with a {.arg description} that states the test, alpha, the stages and the rule to do so."
  ))
  invisible(NULL)
}

