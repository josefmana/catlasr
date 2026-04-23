#' Constructor for stimulus images
#'
#' Constructs a stimulus object used in CATLAS experiments. A stimulus binds
#' an image (e.g., PNG, JPG) with a text label and metadata describing its
#' role (e.g., cue or outcome).
#'
#' @param label Character. Text label shown below the image.
#' @param image_path Character. Path to the stimulus file image.
#' @param type Character. Either `"cue"` or `"outcome"`.
#' @param meta Optional list. Additional metadata.
#'
#' @returns An object of class "catlas_stimulus".
#'
#' @examples
#' \dontrun{
#' stim <- catlas_stimulus(
#'   label = "Xyline",
#'   image_path = "path/to/flask.jpg",
#'   type = "cue"
#' )
#' }
#'
#' @family stimuli
#'
#' @export
catlas_stimulus <- function(
    label = character(),
    image_path = character(),
    type = c("cue", "outcome"),
    meta = list()
) {
  x <- list(
    label      = label,
    image_path = image_path,
    type       = type,
    meta       = meta
  )

  structure(x, class = c("catlas_stimulus", class(x)))
}
