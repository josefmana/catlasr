#' Resolve font family safely across platforms
#'
#' @param font_family Character or NULL.
#'
#' @returns A font family string.
#'
#' @noRd
resolve_font <- function(font_family = NULL) {
  if (!is.null(font_family)) {
    return(font_family)
  }

  sysname <- Sys.info()[["sysname"]]

  if (sysname == "Windows") {
    "Arial"
  } else if (sysname == "Darwin") {
    "Helvetica"
  } else {
    "sans"
  }
}

#' Write a rendered stimulus to disk
#'
#' @param image A magick image object.
#' @param path Output file path.
#'
#' @returns Invisibly returns `path`.
#'
#' @examples
#' \dontrun{
#' stim <- catlas_stimulus("Xyline", "path/to/flask.jpg", "cue")
#' img  <- render_stimulus(stim)
#' write_stimulus(img, tempfile(fileext = ".png"))
#' }
#'
#' @family stimuli
#' @export
write_stimulus <- function(image, path) {
  if (!requireNamespace("magick", quietly = TRUE)) {
    stop(
      "Package magick is required.",
      call. = FALSE
    )
  }

  magick::image_write(image, path)
  invisible(path)
}
