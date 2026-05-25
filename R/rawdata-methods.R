#' @export
print.catlas_rawdata <- function(x, ...) {
  platform <- if (inherits(x, "catlas_jatos_rawdata")) {
    "JATOS"
  } else {
    "unknown platform"
  }

  n_p <- nrow(x$meta)
  n_t <- nrow(x$trials)

  cli::cli_rule(
    left = "catlas_rawdata",
    right = platform
  )
  cli::cli_text(
    "{n_p} participant{?s} \u00b7 {n_t} trial{?s} in total"
  )
  cli::cli_text("")

  .summarise_component <- function(label, tbl) {
    nr  <- nrow(tbl)
    nc  <- ncol(tbl)
    cols <- utils::head(names(tbl), 6L)
    tail_str <- if (nc > 6L) paste0(", \u2026 +", nc - 6L) else ""
    cli::cli_text(
      "  {.field {format(label, width = 8)}}  {nr} \u00d7 {nc}:  {paste(cols, collapse = ', ')}{tail_str}"
    )
  }

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


#' Test whether an object inherits from `catlas_jatos_rawdata`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_jatos_rawdata"`.
#'
#' @noRd
is_catlas_jatos_rawdata <- function(x) {
  inherits(x, "catlas_jatos_rawdata")
}
