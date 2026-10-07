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
#' blocks), "test")` assumes exactly one test phase, named `test`. Promote this
#' to a more general helper only once a design with a different phase structure
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
      n_outcomes = dplyr::n_distinct(.data$response),
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
#' orientation within a participant.
#'
#' @inheritParams validate_catlas_fba_rawdata
#'
#' @returns `x` invisibly; imbalance warns and the offending rows are printed.
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

  if (nrow(imbalanced) > 0L) {
    cli::cli_warn(c(
            "{nrow(imbalanced)} cue compound{?s} {?was/were} not counterbalanced.",
      "i" = "Affected participant{?s}: {.val {unique(as.character(imbalanced$id))}}.",
      "i" = "Offending rows printed below."
    ), call = call)
    print(imbalanced)
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

  invisible(x)
}
