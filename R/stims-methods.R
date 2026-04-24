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
  cat("<catlas_stimulus>\n")
  cat("  Type : ", x$type, "\n", sep = "")
  cat("  Label: ", x$label, "\n", sep = "")
  cat("  Image: ", x$image_path, "\n", sep = "")
  invisible(x)
}

#' Render a CATLAS stimulus using magick
#'
#' Binds a text label to a source image, allowing control over layout and
#' typography.
#'
#' @param x A `catlas_stimulus` object.
#' @param ... Currently unused; reserved for future expansion.
#' @param width,height `numeric(1)`. Output dimensions in pixels.
#' @param font_size `numeric(1)`. Label font size in points.
#' @param font_family `character(1)` or `NULL`. Font family name (NULL = auto-detect
#'   by platform).
#' @param label_colour `character(1)`. Text colour.
#' @param label_position `character(1)`. Vertical label placement, `"bottom"`
#'   (default) or `"top"`. Partial matching supported.
#' @param label_shift `numeric(2)`. Horizontal and vertical offset of the label.
#' @param background `character(1)`. Background colour.
#'
#' @details
#' The label is vertically aligned to prevent overlap. When placed at the
#' bottom, the text baseline sits just above the canvas edge; when placed at
#' the top, the text top sits just below the canvas edge. Image scaling
#' preserves aspect ratio while fitting the available space.
#'
#' @returns A magick-image object (i.e., S3 class from \pkg{magick}).
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
#'
#' # Default: label below the image
#' img_bottom  <- render_stimulus(stim)
#'
#' # Label above image
#' img_top <- render_stimulus(stim, label_position = "top")
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
    label_colour = "black",
    label_position = c("bottom", "top"),
    label_shift = c(0, 0),
    background = "#c8c8c8"
  ) {
  # ── Input validation ────────────────────────────────────────────────────────
  label_position <- match.arg(label_position)

  if (!is.numeric(width) || length(width) != 1 || width <= 0) {
    cli::cli_abort("`width` must be a positive numeric scalar.")
  }
  if (!is.numeric(height) || length(height) != 1 || height <= 0) {
    cli::cli_abort("`height` must be a positive numeric scalar.")
  }
  if (!is.numeric(font_size) || length(font_size) != 1 || font_size <= 0) {
    cli::cli_abort("`font_size` must be a positive numeric scalar.")
  }
  if (!is.numeric(label_shift) || length(label_shift) != 2) {
    cli::cli_abort("`label_shift` must be a numeric vector of lengths 2.")
  }

  # ── Setup ───────────────────────────────────────────────────────────────────
  font_family <- resolve_font(font_family)
  width  <- as.integer(width)
  height <- as.integer(height)

  text_height <- ceiling(font_size * 1.4)
  available_image_height <- height - text_height - 10L

  if (available_image_height < 20L) {
    cli::cli_warn(
      "Canvas height too small for font size; text may be clipped.
       Consider increasing `height` or decreasing `font_size`."
    )
  }

  # ── Resize and composite image ──────────────────────────────────────────────
  offset <- paste0("+", paste(label_shift, collapse = "+"))

  img <- magick::image_read(x$image_path) |>
    magick::image_resize(paste0(width, "x", available_image_height))

  if (label_position == "bottom") {
    magick::image_blank(width, height, color = background) |>
      magick::image_composite(
        img,
        gravity = "North",
        offset  = "+0+0"
      ) |>
      magick::image_annotate(
        x$label,
        gravity  = "South",
        size     = font_size,
        font     = font_family,
        color    = label_colour,
        location = offset
      )
  } else {
    magick::image_blank(width, height, color = background) |>
      magick::image_annotate(
        x$label,
        gravity  = "North",
        size     = font_size,
        font     = font_family,
        color    = label_colour,
        location = offset
      ) |>
      magick::image_composite(
        img,
        gravity = "South",
        offset  = "+0+0"
      )
  }
}
