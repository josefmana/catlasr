# Recognised structural design variants
.catlas_designs <- c(
  "three-stage-replication", # Three-stage forward blocking study design of Beesley & Le Pelley (2011)
  "three-stage-extension"    # Extension of the three-stage design suggested by Paskewitz & Jones (2020)
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
  test = list(
    c("B", "T"), c("F", "N"), c("B", "N"), c("F", "T"),  # Blocking expects preference for `"o4"` (subtrahend of PJ score)
    c("D", "Q"), c("H", "K"), c("D", "K"), c("H", "Q")   # Blocking expects preference for `"o3"` (minuend of PJ score)
  )
)

# Design specifications.
.catlas_design_specs <- list(
  "three-stage-replication" = list(
    stages       = c("stage1", "stage2", "stage3", "test"),
    feedback     = c(stage1 = TRUE, stage2 = TRUE, stage3 = TRUE, test = FALSE),
    min_cues     = 20L,
    min_outcomes = 4L,
    cue_sets     = .fba_three_stage_cue_sets
  ),
  "three-stage-extension" = list(
    stages       = c("stage1", "stage2", "stage3", "test"),
    feedback     = c(stage1 = TRUE, stage2 = TRUE, stage3 = TRUE, test = FALSE),
    min_cues     = 20L,
    min_outcomes = 4L,
    cue_sets     = NULL # Stage 3 differs from the replication; set once the -03 build exists
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
#'   stages that give trial-by-trial feedback), `min_cues`, `min_outcomes`, and
#'   `cue_sets` (`NULL` while a design's cues are unspecified).
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
