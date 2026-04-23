#' Render a CATLAS stimulus
#'
#' Generic function for rendering stimuli into image objects.
#'
#' @param x A stimulus object.
#' @param ... Additional arguments passed to methods.
#'
#' @returns A rendered image object (backend-dependent).
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
render_stimulus <- function(x, ...) {
  UseMethod("render_stimulus")
}
