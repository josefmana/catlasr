#' Draw causal assumptions
#'
#' This function serves to visualise data-generating
#' process assumptions used to derive data analysis
#' plan.
#'
#' @param nodes A data.frame containing nodes specification:
#' \describe{
#'   \item{name}{Character variable names.}
#'   \item{x}{Numeric horizontal position.}
#'   \item{y}{Numeric vertical position.}
#'   \item{node_shape}{Numeric indicating {ggplot2} shape.}
#'   \item{node_colour}{Character indicating colour (outline).}
#'   \item{node_fill}{Character indicating fill colour.}
#'   \item{text}{Character text next to nodes.}
#'   \item{text_colour}{Character colour of the text.}
#'   \item{text_nudge_x}{Numeric horizontal displacement.}
#'   \item{text_nudge_y}{Numeric vertical displacement.}
#' }
#' @param structure A data frame indicating structure of
#'   causal relations between variables:
#'   \describe{
#'     \item{y}{Character outcome name. The left side of
#'     `"dagify` formula.}
#'     \item{X}{Character causal predictors set. The right
#'     side of `"dagify"` formula. Multiple causes must be
#'     separated by `"+"`}
#'   }
#' @param arcs A data frame containing curvature of arced
#'   edges:
#'   \describe{
#'     \item{from}{Character name of the parent.}
#'     \item{to}{Character name of the child.}
#'     \item{arc}{Numeric indicating amount of arc.}
#'   }
#' @param size Named numeric vector for scaling the size
#'   of DAG's graphical elements:
#'   \describe{
#'     \item{nodes}{Numeric point size (default is 9).}
#'     \item{names}{Numeric node name size (default i 5.33).}
#'     \item{texts}{Numeric text size (default is 2).}
#'     \item{arrow}{Numeric open arrow size (default is 12 points).}
#'   }
#'
#' @returns A list containing:
#' \describe{
#'   \item{\code{equations}}{A `"tidy_daggity"` object with the model}
#'   \item{\code{plot}}{A `"ggplot"` with the graph.}
#' }
#'
#' @examples
#' \dontrun{
#'
#' }
#'
#' @export
draw_dag <- function(
    nodes,
    structure,
    arcs = NULL,
    size = NULL) {

  # Creating a DAG via `dagify()` requires correctly formatted arguments
  specs <- purrr::map2(structure$y, structure$X, function(y, x) {
    as.formula(glue::glue("{y} ~ {x}"))
  })
  specs$coords <- nodes |>
    dplyr::select(name, x, y)
  dag_nodes <- nodes |>
    dplyr::mutate(xend = NA, yend = NA)
  dag <- do.call(ggdag::dagify, specs)

  # `geom_dag_edges_arc()` requires the `arc` variable to exist in data
  if (rlang::is_empty(arcs)) {
    dag <- dag |>
      ggdag::tidy_dagitty() |>
      dplyr::mutate(arc = NA)
  } else {
    dag <- dag |>
      ggdag::tidy_dagitty() |>
      dplyr::left_join(arcs, by = join_by(name == from, to))
  }
  if (rlang::is_empty(size)) {
    size <- c(
      nodes = 9,
      names = 5.33,
      texts = 2,
      arrows = 12
    )
  }

  # Using {ggplot} directly allows greater flexibility than ggdag::ggdag()
  plt <- dag |>
    ggplot2::ggplot() +
    ggplot2::aes(
      x = x,
      y = y,
      xend = xend,
      yend = yend
    ) +
    ggdag::geom_dag_point(
      data = dag_nodes,
      ggplot2::aes(
        x = x,
        y = y,
        fill = node_fill,
        colour = node_colour,
        shape = node_shape
      ),
      size = size[["nodes"]]
    ) +
    # Nodes need specification of "inside" as well as "outside" text
    ggdag::geom_dag_text(
      color = "black",
      size = size[["names"]]
    ) +
    ggdag::geom_dag_text(
      data = dag_nodes,
      ggplot2::aes(
        x = x + text_nudge_x,
        y = y + text_nudge_y,
        label = text,
        colour = text_colour
      ),
      size = size[["texts"]]
    ) +
    # Combining direct and arced arrows requires separate specification.
    # Taken from https://github.com/r-causal/ggdag/issues/5#issuecomment-462924706.
    ggdag::geom_dag_edges_link(
      data = \(x) dplyr::filter(x, is.na(arc)),
      arrow = grid::arrow(
        length = grid::unit(size[["arrows"]], "pt"),
        type = "open"
      )
    ) +
    ggdag::geom_dag_edges_arc(
      data = \(x) dplyr::filter(x, !is.na(arc)),
      curvature = na.omit(dag$data$arc),
      arrow = grid::arrow(
        length = grid::unit(size[["arrows"]], "pt"),
        type = "open"
      )
    )  +
    # For the one-to-one mapping between inputs and `aes()`,
    # everything needs to be scaled as identity
    ggplot2::scale_fill_identity() +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_shape_identity() +
    ## Tidy it up:
    ggdag::theme_dag() +
    ggplot2::theme(legend.position = "none")

  # dagify object for further operations, ggplot for visualisation
  list(
    equations = dag,
    plot = plt
  )
}
