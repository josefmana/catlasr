#' Summarise one component of a raw-data bundle in one line
#'
#' @param label Character(1). Component name, padded so the three lines align.
#' @param tbl A tibble.
#'
#' @returns `NULL` invisibly, called for its side effect.
#'
#' @noRd
.summarise_component <- function(label, tbl) {
  nr   <- nrow(tbl)
  nc   <- ncol(tbl)
  cols <- utils::head(names(tbl), 6L)

  tail_str <- if (nc > 6L) paste0(", \u2026 +", nc - 6L) else ""

  cli::cli_verbatim(sprintf(
    "  %-8s  %d \u00d7 %d:  %s%s",
    label,
    nr,
    nc,
    paste(cols, collapse = ", "),
    tail_str
  ))

  invisible(NULL)
}


#' Format a `catlas_rawdata` object
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns A character vector, one element per header line.
#'
#' @export
format.catlas_rawdata <- function(x, ...) {
  prov   <- provenance(x)
  blocks <- prov$blocks[.design_spec(prov$design)$stages]

  c(
    sprintf("<%s>", class(x)[1L]),
    sprintf("  study      : %s", prov$study),
    sprintf(
      "  sample     : %d participant(s), %d trial(s)",
      nrow(x$meta),
      nrow(x$trials)
    ),
    sprintf(
      "  design     : %s, %s blocks x %d types",
      prov$design,
      paste(blocks, collapse = "/"),
      prov$trial_types
    ),
    sprintf(
      "  origin     : %s, retrieved %s",
      prov$origin$platform,
      format(prov$retrieved_at, "%Y-%m-%d")
    ),
    sprintf(
      "  collected  : %s",
      if (is.null(prov$collected_between)) {
        "synthetic"
      } else {
        paste(prov$collected_between[["first"]], "to", prov$collected_between[["last"]])
      }
    ),
    sprintf(
      "  exclusions : %d rule(s) applied%s",
      length(prov$exclusions),
      if (length(prov$deferred_exclusions) > 0L) {
        sprintf(", %d deferred", length(prov$deferred_exclusions))
      } else {
        ""
      }
    )
  )
}


#' Print a `catlas_rawdata` object
#'
#' @param x A `catlas_rawdata` object.
#' @param ... Currently unused.
#'
#' @returns `x` invisibly, while printing summaries of data bundle components.
#'
#' @export
print.catlas_rawdata <- function(x, ...) {
  prov <- provenance(x)

  cli::cli_rule(left = class(x)[1L], right = prov$study)
  cat(format(x, ...)[-1L], sep = "\n")  # [-1L] drops the <class> line cli drew above
  cat("\n")

  .summarise_component("meta",    x$meta)
  .summarise_component("stimuli", x$stimuli)
  .summarise_component("trials",  x$trials)
  cli::cli_rule()

  invisible(x)
}


#' Test whether an object inherits from `catlas_rawdata`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_rawdata"`.
#'
#' @noRd
is_catlas_rawdata <- function(x) {
  inherits(x, "catlas_rawdata")
}


#' Test whether an object inherits from `catlas_fba_rawdata`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_fba_rawdata"`.
#'
#' @noRd
is_catlas_fba_rawdata <- function(x) {
  inherits(x, "catlas_fba_rawdata")
}
