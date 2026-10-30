# Recognised structural design variants
.catlas_designs <- c(
  "three-stage-replication",  # Three-stage forward blocking study design of Beesley & Le Pelley (2011)
  "three-stage-extension"     # Extension of the three-stage design suggested by Paskewitz & Jones (2020)
)

# Test pairs of the three-stage replication, with the outcome predicted by
# blocking for each. Every test pair combines a cue blocked in Stage 2
# (`blocked`) with a control cue (`control`) that was paired with the other
# outcome in Stage 3. Transcribed from Beesley & Le Pelley (2011, Table 1 and
# p. 116) and Paskewitz & Jones (2020, Table 12, column "Ctl. Asc.").
.fba_three_stage_test_pairs <- tibble::tribble(
  ~cue1, ~cue2, ~blocked, ~control, ~expected,
  "B",   "T",   "B",      "T",      "o4",
  "F",   "N",   "F",      "N",      "o4",
  "B",   "N",   "B",      "N",      "o4",
  "F",   "T",   "F",      "T",      "o4",
  "D",   "Q",   "D",      "Q",      "o3",
  "H",   "K",   "H",      "K",      "o3",
  "D",   "K",   "D",      "K",      "o3",
  "H",   "Q",   "H",      "Q",      "o3"
)

# Cue sets of the three-stage replication
# Within each pair the order is canonical: `fba_cues_map()` reads `cue1` and
# `cue2` from it and records the presented order separately in `cues_reversed`.
.fba_three_stage_cue_sets <- list(
  stage1 = list(
    "A", "C", "E", "G", # Blocking
    "I", "L", "O", "R"  # Control
  ),
  stage2 = list(
    c("A", "B"), c("C", "D"), c("E", "F"), c("G", "H"), # Blocking
    c("J", "K"), c("M", "N"), c("P", "Q"), c("S", "T")  # Control
  ),
  stage3 = list(
    c("B", "K"), c("D", "N"), c("F", "Q"), c("H", "T"),       # Blocking/critical
    c("U", "V"), c("W", "X"), c("Y", "Z"), c("alpha", "beta") # Filler
  ),
  test = unname(Map(
    c,
    .fba_three_stage_test_pairs$cue1,
    .fba_three_stage_test_pairs$cue2
  ))
)

# Design specifications.
.catlas_design_specs <- list(
  "three-stage-replication" = list(
    stages       = c("stage1", "stage2", "stage3", "test"),
    feedback     = c(stage1 = TRUE, stage2 = TRUE, stage3 = TRUE, test = FALSE),
    min_cues     = 20L,
    min_outcomes = 4L,
    cue_sets     = .fba_three_stage_cue_sets,
    test_pairs   = .fba_three_stage_test_pairs,
    confidence   = c(min = 1L, max = 10L)
  ),
  "three-stage-extension" = list(
    stages       = c("stage1", "stage2", "stage3", "test"),
    feedback     = c(stage1 = TRUE, stage2 = TRUE, stage3 = TRUE, test = FALSE),
    min_cues     = 20L,
    min_outcomes = 4L,
    cue_sets     = NULL,  # Stage 3 differs from the replication; set once the -03 build exists
    test_pairs   = NULL,  # Likewise
    confidence   = NULL   # Test stage without confidence rating; check post-02 against the real -03 build
  )
)

# Stage taxonomy.
#
# Vocabulary: a *stage* is a between-trial period of the design (Stage 1 to 3,
# Test), as in Beesley & Le Pelley (2011) and Paskewitz & Jones (2020). Much
# of the literature uses the term "phase" for the same thing; CATLAS does not,
# because `catlaslab` uses *phase* for the within-trial periods of a single test
# trial (e.g., 2AFC response, then confidence rating, timed by `rt1` and `rt2`).
.stage_taxonomy <- tibble::tribble(
  ~stage,   ~label,    ~order,
  "stage1", "Stage 1", 1L,
  "stage2", "Stage 2", 2L,
  "stage3", "Stage 3", 3L,
  "test",   "Test",    4L
)


#' Specification of a CATLAS study design
#'
#' @param design Character(1). A name from `.catlas_designs`.
#'
#' @returns A list with `stages`, `feedback` (named logical, `TRUE` for the
#'   stages that give trial-by-trial feedback), `min_cues`, `min_outcomes`,
#'   `cue_sets` (`NULL` while a design's cues are unspecified), `test_pairs`
#'   (`NULL` likewise) and `confidence` (the scale of test-stage confidence
#'   ratings as `c(min = , max = )`, `NULL` when the design collects none).
#'
#' @noRd
.design_spec <- function(design) {
  .catlas_design_specs[[design]]
}


#' Display label for a stage name, for plots and tables
#'
#' Falls back to the raw stage name for anything absent from
#' `.stage_taxonomy`, rather than erroring, so a design that adds a stage
#' is not blocked on this table being updated first.
#'
#' @param stage Character. Stage names as they appear in `trials$stage`.
#'
#' @returns Character of the same length, with labels where they are known.
#'
#' @noRd
.stage_label <- function(stage) {
  label <- .stage_taxonomy$label[match(stage, .stage_taxonomy$stage)]
  dplyr::coalesce(label, stage)
}


#' Order stages for display
#'
#' Known stages follow `.stage_taxonomy`; unknown ones follow in the order they
#' first appear, so a new design is not blocked on the taxonomy being updated.
#'
#' @param stage Character. Stage names.
#'
#' @returns Integer of the same length, a sort key.
#'
#' @noRd
.stage_order <- function(stage) {
  known <- .stage_taxonomy$order[match(stage, .stage_taxonomy$stage)]
  unknown <- match(stage, unique(stage)) + max(.stage_taxonomy$order)
  dplyr::coalesce(known, unknown)
}


#' Stages of a design that give trial-by-trial feedback
#'
#' Learning checks filter in these stages only. In a stage without feedback,
#' such as the test stage of the three-stage designs, `is_correct` records
#' consistency with the expected effect rather than a correct answer.
#'
#' @param design Character(1). A name from `.catlas_designs`.
#' @param call Environment for error reporting.
#'
#' @returns Character. Stage names in design order.
#'
#' @noRd
.feedback_stages <- function(design, call = rlang::caller_env()) {
  spec <- .design_spec(design)

  if (is.null(spec) || is.null(spec$feedback)) {
    cli::cli_abort(c(
            "No feedback stages are recorded for design {.val {design}}.",
      "i" = "Known designs: {.val {names(.catlas_design_specs)}}."
    ), call = call)
  }

  spec$stages[spec$feedback[spec$stages] %in% TRUE]
}


#' Stages of a design that give no feedback, i.e., test stages
#'
#' @inheritParams .feedback_stages
#'
#' @returns Character. Stage names in design order.
#'
#' @noRd
.test_stages <- function(design, call = rlang::caller_env()) {
  spec <- .design_spec(design)
  setdiff(spec$stages, .feedback_stages(design, call = call))
}


#' Test pairs of a design, with the outcome that is predicted by blocking
#'
#' @inheritParams .feedback_stages
#'
#' @returns A tibble with one row per test pair and columns `cue1`, `cue2` (in
#'   canonical order, as in the `trials` component), `blocked`, `control` and
#'   `expected` (the Stage 3 outcome associated with the control cue).
#'
#' @noRd
.test_pairs <- function(design, call = rlang::caller_env()) {
  pairs <- .design_spec(design)$test_pairs

  if (is.null(pairs)) {
    with_pairs <- names(.catlas_design_specs)[
      !vapply(.catlas_design_specs, function(s) is.null(s$test_pairs), logical(1))
    ]
    cli::cli_abort(c(
            "No test pairs with blocking expectations are recorded for design {.val {design}}.",
      "i" = "Designs with recorded test pairs: {.val {with_pairs}}."
    ), call = call)
  }

  pairs
}


#' Scale of the test-stage confidence ratings of a design
#'
#' @inheritParams .feedback_stages
#'
#' @returns Integer, `c(min = , max = )`, or `NULL` when the design collects no
#'   confidence ratings.
#'
#' @noRd
.confidence_scale <- function(design) {
  .design_spec(design)$confidence
}
