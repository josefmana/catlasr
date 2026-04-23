#' Print a CATLAS stimulus
#'
#' @param x A "catlas_stimulus" object.
#' @param ... Unused.
#'
#' @returns Invisibly returns `x`.
#'
#' @examples
#' \dontrun{
#' stim <- catlas_stimulus("Xyline", "path/to/flask.jpg", "cue")
#' print(stim)
#' }
#'
#' @family stimuli
#'
#' @export
print.catlas_stimulus <- function(x, ...) {
  validate_catlas_stimulus(x)
  cat("<catlas_stimulus>\n")
  cat("  Type : ", x$type, "\n", sep = "")
  cat("  Label: ", x$label, "\n", sep = "")
  cat("  Image: ", x$image_path, "\n", sep = "")
  invisible(x)
}

#' Render a CATLAS stimulus using magick
#'
#' @param x A "catlas_stimulus" object.
#' @param ... Currently not used.
#' @param width,height Numeric. Output dimensions in pixels.
#' @param font_size Numeric. Label font size.
#' @param font_family Character. Font family (NULL = auto-detect).
#' @param background Character. Background color.
#'
#' @returns A "magick-image" object.
#'
#' @examples
#' \dontrun{
#' stim <- catlas_stimulus("Xyline", "path/to/flask.jpg", "cue")
#' img  <- render_stimulus(stim)
#' }
#'
#' @family stimuli
#'
#' @export
render_stimulus.catlas_stimulus <- function(
    x,
    ...,
    width = 200,
    height = 200,
    font_size = 32,
    font_family = NULL,
    background = "#c8c8c8"
  ) {
  font_family <- resolve_font(font_family)

  img <- magick::image_read(x$image_path) |>
    magick::image_resize(glue::glue("{width}x{round(height * 0.75)}"))

  magick::image_blank(width, height, color = background) |>
    magick::image_composite(img, gravity = "North") |>
    magick::image_annotate(
      x$label,
      gravity  = "South",
      size     = font_size,
      font     = font_family,
      color    = "black",
      location = "+0+10"
    )
}
