#' Check that the study belongs to the `fba` family
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
.validate_fba_study_family <- function(x, call = rlang::caller_env()) {
  prefix <- provenance(x)$prefix
  if (!identical(prefix, "fba")) {
    cli::cli_abort(c(
            "A {.cls catlas_fba_rawdata} object must carry an {.val fba} study.",
      "x" = "`provenance$study` is {.val {provenance(x)$study}}, prefix {.val {prefix}}.",
      "i" = "Construct the bundle with the subclass that matches its family."
    ), call = call)
  }
  invisible(x)
}


#' Expected trial counts for a bundle, derived from its provenance
#'
#' The number of trials a complete participant produces is a property of the
#' build that collected them, so it is read off `provenance$blocks` and
#' `provenance$trial_types` rather than hardcoded. The minimum is equivalent to
#' "finished all learning and reached the first test block".
#'
#' @param x A `catlas_fba_rawdata` object.
#'
#' @section Promotion:
#' The arithmetic is paradigm-agnostic but the floor is not: `setdiff(names(
#' blocks), "test")` assumes exactly one test stage, named `test`. Promote this
#' to a more general helper only once a design with a different stage structure
#' would call it unmodified. Until then the `.fba_` prefix is the most honest
#' about its reach.
#'
#' @returns A named integer vector, `c(min = , max = )`.
#'
#' @noRd
.fba_expected_trials <- function(x) {
  prov        <- provenance(x)
  blocks      <- prov$blocks
  trial_types <- prov$trial_types

  learning <- setdiff(names(blocks), "test")

  c(
    min = as.integer((sum(blocks[learning]) + 1L) * trial_types),
    max = as.integer(sum(blocks) * trial_types)
  )
}


#' Check whether the data contain all stages of the study design
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly on success, informative error otherwise.
#'
#' @noRd
.validate_fba_stage_coverage <- function(x, call = rlang::caller_env()) {
  expected <- .design_spec(provenance(x)$design)$stages # Lives in `R/rawdata-provenance.R`
  missing  <- setdiff(expected, unique(x$trials$stage))

  if (length(missing) > 0L) {
    cli::cli_abort(c(
            "{length(missing)} expected stage{?s} absent from `trials$stage`.",
      "x" = "Missing: {.val {missing}}.",
      "i" = "Expected for {.val {provenance(x)$design}}: {.val {expected}}."
    ), call = call)
  }
  invisible(x)
}


#' Check trial counts is within bounds of the design
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly; counts outside the range warn.
#'
#' @noRd
.validate_fba_trial_counts <- function(x, call = rlang::caller_env()) {
  expected <- .fba_expected_trials(x)
  counts   <- dplyr::count(x$trials, .data$id, name = "n")

  low  <- counts$id[counts$n < expected[["min"]]]
  high <- counts$id[counts$n > expected[["max"]]]

  if (length(low) > 0L) {
    cli::cli_warn(c(
            "{length(low)} participant{?s} {?has/have} fewer than {expected[['min']]} trials.",
      "i" = "ID{?s}: {.val {as.character(low)}}.",
      "i" = "Trial count below the minimum means the participant did not complete learning."
    ), call = call)
  }

  if (length(high) > 0L) {
    cli::cli_warn(c(
            "{length(high)} participant{?s} {?has/have} more than {expected[['max']]} trials.",
      "i" = "ID{?s}: {.val {as.character(high)}}.",
      "i" = "Trial count above the maximum suggests a duplicate submission or a merged run."
    ), call = call)
  }

  invisible(x)
}


#' Check whether all stimuli of the study design were used
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly; thin coverage warns.
#'
#' @noRd
.validate_fba_cue_coverage <- function(x, call = rlang::caller_env()) {
  spec <- .design_spec(provenance(x)$design)

  coverage <-
    x$trials |>
    dplyr::group_by(.data$id) |>
    dplyr::summarise(
      n_cues     = dplyr::n_distinct(.data$cue1),
      n_outcomes = dplyr::n_distinct(.data$response, na.rm = TRUE),
      .groups    = "drop"
    )

  low_cue <- coverage$id[coverage$n_cues < spec$min_cues]
  low_out <- coverage$id[coverage$n_outcomes < spec$min_outcomes]

  if (length(low_cue) > 0L) {
    cli::cli_warn(c(
            "{length(low_cue)} participant{?s} did not see all {spec$min_cues} distinct cues.",
      "i" = "ID{?s}: {.val {as.character(low_cue)}}."
    ), call = call)
  }

  if (length(low_out) > 0L) {
    cli::cli_warn(c(
            "{length(low_out)} participant{?s} did not use all {spec$min_outcomes} outcome options.",
      "i" = "ID{?s}: {.val {as.character(low_out)}}."
    ), call = call)
  }

  invisible(x)
}


#' Validate left-right counterbalancing of compound cues
#'
#' Every compound cue should appear equally often in each left-right
#' orientation within a participant. The experiments balance the orientations
#' within every stage that has an even number of blocks, so a complete run of
#' such a build is balanced by construction, and an imbalance in such a run
#' means that the build or the import went wrong. An incomplete run ends in the
#' middle of a stage and is imbalanced as a matter of course.
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly on success. An imbalance aborts for complete runs of
#'   a design whose stages all have an even number of blocks, and warns for
#'   incomplete runs or designs with an odd number of blocks in any stage. The
#'   offending rows of complete runs are printed.
#'
#' @noRd
.validate_fba_counterbalancing <- function(x, call = rlang::caller_env()) {
  counts <-
    x$trials |>
    dplyr::filter(!is.na(.data$cue2)) |>
    tidyr::drop_na("cues_reversed") |>
    dplyr::count(
      .data$id,
      .data$cue1,
      .data$cue2,
      .data$cues_reversed,
      name = "n_presentations"
    ) |>
    tidyr::pivot_wider(
      names_from   = "cues_reversed",
      values_from  = "n_presentations",
      names_prefix = "order_",
      values_fill  = 0L
    )

  for (col in c("order_FALSE", "order_TRUE")) {
    if (!col %in% names(counts)) counts[[col]] <- 0L
  }

  imbalanced <- dplyr::filter(counts, .data$order_FALSE != .data$order_TRUE)

  if (nrow(imbalanced) == 0L) {
    return(invisible(x))
  }

  blocks <- provenance(x)$blocks
  balanced_by_design <- all(blocks %% 2L == 0L)

  n_complete <- .fba_expected_trials(x)[["max"]]

  complete_ids <-
    x$trials |>
    dplyr::count(.data$id, name = "n") |>
    dplyr::filter(.data$n == n_complete) |>
    dplyr::pull("id") |>
    as.character()

  ids <- unique(as.character(imbalanced$id))
  ids_complete <- if (balanced_by_design) {
    intersect(ids, complete_ids)
  } else {
    character()
  }
  ids_other <- setdiff(ids, ids_complete)

  if (length(ids_other) > 0L) {
    reason <- if (balanced_by_design) {
      "An incomplete run ends in the middle of a stage, so this is expected."
    } else {
      paste(
        "Some stage has an odd number of blocks",
        "({.val {names(blocks)[blocks %% 2L != 0L]}}),",
        "so the cue orientations cannot balance exactly."
      )
    }
    cli::cli_warn(c(
      paste(
        "{length(ids_other)} participant{?s} with cue compounds that were",
        "not counterbalanced."
      ),
      "i" = "ID{?s}: {.val {ids_other}}.",
      "i" = reason
    ), call = call)
  }

  if (length(ids_complete) > 0L) {
    offending <- dplyr::filter(
      imbalanced,
      as.character(.data$id) %in% ids_complete
    )
    print(offending)
    cli::cli_abort(c(
      paste(
        "{nrow(offending)} cue compound{?s} {?was/were} not",
        "counterbalanced in complete runs."
      ),
      "x" = "Participant{?s}: {.val {ids_complete}}.",
      "i" = paste(
        "Every stage has an even number of blocks, so a complete run presents",
        "each compound equally often in both orientations."
      ),
      "i" = paste(
        "Check the experiment build and the import.",
        "Offending rows printed above."
      )
    ), call = call)
  }

  invisible(x)
}


#' Check test trials against the blocking expectations of the design
#'
#' Every test trial must present one of the pairs listed in the design, and on
#' every answered test trial jsPsych's `is_correct` must equal the comparison
#' of the response with the outcome the design registry expects. In the test
#' stage, `is_correct` records what the experiment build expected, so a
#' disagreement means the build and the registry are out of sync. Left
#' unchecked, that would flip the sign of the blocking indices on the pairs
#' concerned.
#'
#' Shared by `.validate_fba_test_expectations()`, which runs whenever a bundle
#' is built, and `score_blocking()`, which also covers bundles saved before
#' the check existed.
#'
#' @param trials The `trials` component of a `catlas_fba_rawdata` object.
#' @param design Character(1). A design with recorded `test_pairs`.
#' @param call Environment for error reporting.
#'
#' @returns The number of answered test trials checked, invisibly; an error
#'   on any unknown pair or disagreement.
#'
#' @noRd
.check_fba_test_expectations <- function(trials, design, call = rlang::caller_env()) {
  pairs <- .test_pairs(design, call = call)
  test <-
    trials |>
    dplyr::filter(.data$stage %in% .test_stages(design, call = call))

  unknown <- dplyr::anti_join(test, pairs, by = c("cue1", "cue2"))

  if (nrow(unknown) > 0L) {
    cli::cli_abort(c(
            "Test trials that present a cue pair the design does not list: {nrow(unknown)}.",
      "x" = "Unknown pair{?s}: {.val {unique(paste0(unknown$cue1, unknown$cue2))}}.",
      "i" = "Test pairs of {.val {design}}: {.val {paste0(pairs$cue1, pairs$cue2)}}."
    ), call = call)
  }

  checked <-
    test |>
    dplyr::filter(
      !is.na(.data$is_correct),
      !is.na(.data$response)
    ) |>
    dplyr::inner_join(
      pairs,
      by = c("cue1", "cue2")
    )

  mismatch <-
    checked |>
    dplyr::filter((.data$response == .data$expected) != .data$is_correct)

  if (nrow(mismatch) > 0L) {
    cli::cli_abort(c(
            "Answered test trials whose {.field is_correct} disagrees with the blocking expectations of {.val {design}}: {nrow(mismatch)} of {nrow(checked)}.",
      "x" = "Pair{?s} concerned: {.val {unique(paste0(mismatch$cue1, mismatch$cue2))}}.",
      "x" = "Participant{?s} concerned: {.val {unique(as.character(mismatch$id))}}.",
      "i" = "In the test stage, {.field is_correct} records the outcome the experiment build expected; the registry expects the Stage 3 outcome associated with the control cue. Check the experiment build against the registry before computing any blocking index."
    ), call = call)
  }

  invisible(nrow(checked))
}


#' Validate the test trials against the blocking expectations of the design
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly on success, otherwise an informative error. Designs
#'   without recorded test pairs pass unchecked.
#'
#' @noRd
.validate_fba_test_expectations <- function(x, call = rlang::caller_env()) {
  design <- provenance(x)$design

  if (is.null(.design_spec(design)$test_pairs)) {
    return(invisible(x))
  }

  .check_fba_test_expectations(x$trials, design, call = call)
  invisible(x)
}


#' Validate test-stage confidence ratings against the scale of the design
#'
#' Ratings outside the scale recorded in the design registry, or not whole
#' numbers, abort. Answered test trials without a rating warn, as do ratings in
#' a design that records no confidence scale.
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly on success, otherwise an informative error or warning.
#'
#' @noRd
.validate_fba_confidence <- function(x, call = rlang::caller_env()) {
  design <- provenance(x)$design
  scale <- .confidence_scale(design)

  test <-
    x$trials |>
    dplyr::filter(.data$stage %in% .test_stages(design, call = call))

  rated <- !is.na(test$confidence)

  if (is.null(scale)) {
    if (any(rated)) {
      cli::cli_warn(c(
              "The design {.val {design}} records no confidence scale, but {sum(rated)} test trial{?s} contain{?s/} a rating.",
        "i" = "Participant{?s}: {.val {unique(as.character(test$id[rated]))}}.",
        "i" = "Record the scale in the design registry if the build collects confidence ratings."
      ), call = call)
    }
    return(invisible(x))
  }

  outside <- rated &
    (test$confidence < scale[["min"]] |
       test$confidence > scale[["max"]] |
       test$confidence != round(test$confidence))

  if (any(outside)) {
    cli::cli_abort(c(
            "Test-stage confidence ratings outside the {scale[['min']]} to {scale[['max']]} scale of {.val {design}}: {sum(outside)}.",
      "x" = "Values: {.val {sort(unique(test$confidence[outside]))}}.",
      "x" = "Participant{?s} concerned: {.val {unique(as.character(test$id[outside]))}}."
    ), call = call)
  }

  unrated <- !is.na(test$response) & !(test$timed_out %in% TRUE) & !rated

  if (any(unrated)) {
    cli::cli_warn(c(
            "{sum(unrated)} answered test trial{?s} {?has/have} no confidence rating.",
      "i" = "Participant{?s}: {.val {unique(as.character(test$id[unrated]))}}."
    ), call = call)
  }

  invisible(x)
}


#' Validate forward-blocking-attention constraints on a raw-data bundle
#'
#' Calls [validate_catlas_rawdata()] for every check shared across CATLAS
#' bundles, then enforces the constraints that follow from the three-stage
#' forward-blocking design itself.
#'
#' @param x A `catlas_fba_rawdata` object.
#' @param call Environment for error reporting.
#'
#' @returns `x` invisibly on success, otherwise an informative error or warning.
#'
#' @noRd
validate_catlas_fba_rawdata <- function(x, call = rlang::caller_env()) {
  x <- validate_catlas_rawdata(x, call = call)

  .validate_fba_study_family(x, call = call)
  .validate_fba_stage_coverage(x, call = call)
  .validate_fba_trial_counts(x, call = call)
  .validate_fba_cue_coverage(x, call = call)
  .validate_fba_counterbalancing(x, call = call)
  .validate_fba_test_expectations(x, call = call)
  .validate_fba_confidence(x, call = call)

  invisible(x)
}


#' Validate a forward-blocking-attention raw-data bundle
#'
#' Runs every check that [build_fba_rawdata()] runs when it builds a bundle,
#' so that a bundle can be validated again, e.g. after it was read from disk,
#' after exclusions were recorded or before any analysis.
#'
#' @param x A `catlas_fba_rawdata` object, from [build_fba_rawdata()].
#' @param silence Logical(1). Suppress the message confirming that the bundle
#'   passed. Defaults to `FALSE` (recommended).
#'
#' @returns `x` invisibly if no check aborts, otherwise an informative error.
#'
#' @details
#' ## Checks shared by every `catlas_rawdata` bundle
#'
#' The provenance record, the three components (`meta`, `stimuli`, `trials`)
#' and their required columns, identifiers aligned across the components,
#' no participant-identifying columns such as e-mail addresses, platform
#' metadata, batches aligned with the provenance, participant metadata,
#' response times and the uniqueness of stimulus mappings.
#'
#' ## Checks of the forward-blocking-attention design
#'
#' * The study belongs to the `fba` family and every stage of the design is
#'   present (abort).
#' * Trial counts lie within the bounds derived from the provenance (warn).
#' * Every participant saw every cue and used every outcome option (warn).
#' * Compound cues are counterbalanced left and right (abort for complete runs
#'   of a design whose stages all have an even number of blocks, warn
#'   otherwise).
#' * Test trials present only the test pairs of the design, and `is_correct`
#'   agrees with the blocking expectations recorded in the design registry
#'   (abort).
#' * Confidence ratings lie on the scale of the design (abort), and every
#'   answered test trial carries one (warn).
#'
#' Warnings do not stop the validation, so read them. The message confirming
#' that the bundle passed refers to the checks that abort only.
#'
#' @seealso [build_fba_rawdata()], [record_exclusion()]
#'
#' @export
validate_fba_rawdata <- function(x, silence = FALSE) {
  if (!inherits(x, "catlas_fba_rawdata")) {
    cli::cli_abort(c(
            "`x` must be a {.cls catlas_fba_rawdata} object.",
      "i" = "Build it with {.fn build_fba_rawdata}."
    ))
  }

  if (!rlang::is_bool(silence)) {
    cli::cli_abort("`silence` must be `TRUE` or `FALSE`.")
  }

  validate_catlas_fba_rawdata(x, call = rlang::current_env())

  if (!silence) {
    cli::cli_alert_success(paste(
      "The {.val {provenance(x)$study}} bundle passed every check that",
      "aborts. Read any warnings printed below."
    ))
  }

  invisible(x)
}
