#' Constructor for CATLAS stimulus object
#'
#' Constructs a validated `catlas_stimulus` object representing a single
#' composited stimulus: a source image (e.g., a flask or a cartoon of allergic
#' reaction icon) paired with a text label.
#'
#' @param label `character(1)`. Text label paired with the image.
#' @param image_path `character(1)`. Path to the source image file (PNG, JPEG,
#'   or any format supported by \pkg{magick}). The file must exist at
#'   construction time.
#' @param type `character(1)`. Stimulus role in the experimental paradigm. One
#'   of `"cue"` or `"outcome"`. Partial matching supported.
#' @param meta `list`. Optional named list for additional metadata (e.g., trial
#'   assignment, counterbalancing codes). Not used by the rendering pipeline.
#'
#' @details
#' `catlas_stimulus` stores only plain R scalars. No \pkg{magick} objects are
#' embedded, so the rendering backend used by [render_stimulus()] is fully
#' swappable without modifying the class.
#'
#' @seealso
#' - [render_stimulus()] to produce the composited image
#' - [write_stimulus()] to save the result to disk
#'
#' @returns An object of class `"catlas_stimulus"` (a named list with fields
#'   `label`, `image_path`, `type`, and `meta`)
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
#' }
#'
#' @family stimuli
#'
#' @export
catlas_stimulus <- function(
    label,
    image_path,
    type = c("cue", "outcome"),
    meta = list()
) {
  type <- match.arg(type)

  x <- structure(
    list(
      label      = label,
      image_path = image_path,
      type       = type,
      meta       = meta
    ),
    class = c("catlas_stimulus", "list")
  )

  validate_catlas_stimulus(x)
}
