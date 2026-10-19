#' Map recorded cue labels to canonical cue pairs
#'
#' The experiment records the cues of each trial as one string, `cues`, made by
#' concatenating the cue labels in the order they were shown, left to right.
#' This function returns the table that turns that string into the canonical
#' pair `cue1`, `cue2`, plus `cues_reversed` variable, which records whether
#' the pair was shown in the reverse of its canonical order.
#'
#' The table is derived from the cue sets defined by the design in the internal
#' `.catlas_design_specs` list.
#'
#' @param design Character(1). A recognised study design, as stored in
#'   `provenance(x)$design`.
#'
#' @returns A tibble with columns `label`, `cue1`, `cue2` and `cues_reversed`,
#'   containing one row per single cue and two rows per cue pair, one for each
#'   counterbalancing order.
#'
#' @section The canonicalisation invariant:
#' `cue1` and `cue2` are always in the canonical order the design defines,
#' whichever side of the screen each cue appeared on. `"DQ"` and `"QD"` both
#' resolve to `cue1 = "D", cue2 = "Q"`, with only `cues_reversed` telling them
#' apart. Any join on `c("cue1", "cue2")` therefore matches both presentation
#' orders. Single-cue trials have `cue2 = NA` and `cues_reversed = NA`.
#'
#' @examples
#' fba_cues_map("three-stage-replication")
#'
#' @export
fba_cues_map <- function(design = "three-stage-replication") {
  if (!is.character(design) || length(design) != 1L || !design %in% .catlas_designs) {
    cli::cli_abort(c(
            "`design` must be one recognised study design.",
      "x" = "Received {.val {design}}.",
      "i" = "Recognised design{?s}: {.val {(.catlas_designs)}}."
    ))
  }

  cue_sets <- .design_spec(design)$cue_sets
  if (is.null(cue_sets)) {
    cli::cli_abort(c(
            "No cue sets are specified for {.val {design}} yet.",
      "i" = "Cue sets are added to {.code .catlas_design_specs} once an experiment build for the design exists."
    ))
  }

  map <- .build_cues_map(cue_sets)
  .validate_cues_map(map, design)
}


#' Build the cue-label map from a design's cue sets
#'
#' @param cue_sets A list, one element per stage, each a list of character
#'   vectors of length one (single cue) or two (cue pair, canonical order).
#'
#' @returns A tibble with `label`, `cue1`, `cue2` and `cues_reversed`.
#'
#' @noRd
.build_cues_map <- function(cue_sets) {
  sets <- unique(unlist(unname(cue_sets), recursive = FALSE))

  malformed <- vapply(sets, \(set) !length(set) %in% 1:2, logical(1L))
  if (any(malformed)) {
    bad <- vapply(sets[malformed], paste, character(1L), collapse = "")
    cli::cli_abort(c(
            "Every cue set must hold one or two cues.",
      "x" = "Malformed set{?s}: {.val {bad}}."
    ))
  }

  rows <- lapply(sets, function(set) {
    if (length(set) == 1L) {
      return(tibble::tibble(
        label = set,
        cue1 = set,
        cue2 = NA_character_,
        cues_reversed = NA
      ))
    }
    tibble::tibble(
      label = c(paste0(set[1L], set[2L]), paste0(set[2L], set[1L])),
      cue1 = set[1L],
      cue2 = set[2L],
      cues_reversed = c(FALSE, TRUE)
    )
  })

  dplyr::bind_rows(rows)
}


#' Check the invariants of a cue-label map
#'
#' The map is derived from a package constant, so a failure here indicates a
#' defect in `.catlas_design_specs`.
#'
#' @param map A tibble from [.build_cues_map()].
#' @param design Character(1). Used in messages.
#' @param call Environment for error reporting.
#'
#' @returns `map` on success, otherwise an informative error.
#'
#' @noRd
.validate_cues_map <- function(map, design, call = rlang::caller_env()) {
  dup_labels <- unique(map$label[duplicated(map$label)])
  if (length(dup_labels) > 0L) {
    cli::cli_abort(c(
            "Cue labels of {.val {design}} must be unique.",
      "x" = "Duplicated label{?s}: {.val {dup_labels}}.",
      "i" = "A pair listed in both orders, or two concatenations that coincide, can produce this error."
    ), call = call)
  }

  bad_flag <- map$label[is.na(map$cues_reversed) != is.na(map$cue2)]
  if (length(bad_flag) > 0L) {
    cli::cli_abort(c(
            "`cues_reversed` must be missing only for single cues.",
      "x" = "Inconsistent label{?s}: {.val {bad_flag}}."
    ), call = call)
  }

  map
}
