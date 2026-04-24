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

  switch(sysname,
     Windows = "Arial",
     Darwin = "Helvetica",
     Linux = "Liberation Sans",
     "sans"
  )
}

#' Write a rendered stimulus to disk
#'
#' A thin wrapper of [magick::image_write()] function.
#'
#' @param image A magick image object.
#' @param path Output file path.
#' @param ... Additional parameters passed to [magick::image_write()].
#'
#' @returns Invisibly returns `path`.
#'
#' @examples
#' \dontrun{
#' # A minimal white PNG to satisfy the file-existence check
#' tmp <- tempfile(fileext = ".png")
#' magick::image_write(magick::image_blank(1L, 1L, "white"), tmp)
#'
#' stim <- catlas_stimulus(
#'   label      = "Xyline",
#'   image_path = tmp,
#'   type       = "cue"
#' )
#' print(stim)
#' write_stimulus(img, "output.png")
#' }
#'
#' @family stimuli

#' @export
write_stimulus <- function(image, path, ...) {
  magick::image_write(image, path, ...)
  invisible(path)
}
