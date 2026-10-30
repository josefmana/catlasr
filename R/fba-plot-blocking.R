#' Plot blocking indices
#'
#' Draws the distribution of the participants' blocking indices as a violin
#' with the individual values on top, and their mean with error bars of one
#' standard error each way, in the style of Kelly and Ludvig (2025, Figure 3).
#' The resulting figure stacks one panel per index above each other, with one
#' violin per selection of test blocks.
#'
#' @param indices Per-participant blocking indices, resulting from
#'   [index_blocking()]. Tables for several selections of blocks can be bound by
#'   rows first. For instance, the first block results can be combined with
#'   results based on all blocks.
#' @param index Character. Indices to draw, by their column names in
#'   `indices`, i.e., any of `"bi_confidence"` and `"bi_choice"`. Defaults to
#'   both.
#' @param labels Named character, or `NULL` (default). Panel titles by index
#'   name, replacing the defaults ("Confidence-weighted choice score",
#'   "Choice-proportion score") for the indices named.
#' @param parse Logical(1). Read `labels` as plotmath expressions? `FALSE`
#'   (default) prints them as they are. `TRUE` allows subscripts that do not
#'   depend on the font having subscript characters, e.g.
#'   `c(bi_confidence = 'BI[2]*":"~"confidence-weighted choice score"')`.
#'
#' @returns A `ggplot` object.
#'
#' @details
#' The dotted horizontal line marks zero, i.e., no blocking. The labels at the
#' top and bottom of each panel name the outcome that the participants' answers
#' lean towards. Selecting the Stage 3 outcome associated with the control cue
#' yields positive values (i.e., blocking), while preference for the Stage 3
#' outcome associated with the putatively blocked cue yields negative ones. The
#' vertical axis is symmetric around zero within each panel.
#'
#' The function says that it ran [aggregate_blocking()] on your behalf and
#' that function then states how its standard errors are defined. Run
#' [aggregate_blocking()] yourself to get the numbers behind the figure.
#'
#' @references Kelly, T., & Ludvig, E. A. (2025). Blocking of associative
#'   learning by explicit descriptions. *Cognition, 256*, 106015.
#'   \doi{10.1016/j.cognition.2024.106015}
#'
#' @seealso [index_blocking()], [aggregate_blocking()]
#'
#' @export
plot_blocking <- function(
    indices,
    index = c("bi_confidence", "bi_choice"),
    labels = NULL,
    parse = FALSE
) {
  .check_blocking_indices(indices)
  known <- names(.blocking_index_labels)

  if (!is.character(index) || length(index) == 0L || !all(index %in% known)) {
    cli::cli_abort(c(
            "`index` must name one or both of {.val {known}}.",
      "x" = "Got {.val {index}}."
    ))
  }

  if (
    !is.null(labels) &&
    (!is.character(labels) || is.null(names(labels)) || !all(names(labels) %in% known))
  ) {
    cli::cli_abort(c(
            "`labels` must be a character vector named by index, any of {.val {known}}.",
      "x" = "Received {.val {labels}}."
    ))
  }

  if (!rlang::is_bool(parse)) {
    cli::cli_abort("`parse` must be `TRUE` or `FALSE`.")
  }

  index_labels <- .blocking_index_labels

  if (parse) {
    index_labels[] <- encodeString(index_labels, quote = '"')
    unparsable <- labels[vapply(labels, function(l) {
      inherits(try(str2expression(l), silent = TRUE), "try-error")
    }, logical(1))]

    if (length(unparsable) > 0L) {
      cli::cli_abort(c(
              "With `parse = TRUE`, every label must be a plotmath expression.",
        "x" = "Not parsable: {.val {unparsable}}.",
        "i" = "Quote plain text inside the expression, e.g. {.code BI[2]*\":\"~\"text\"}."
      ))
    }
  }

  index_labels[names(labels)] <- labels

  .report_blocking_plot_caveats()

  aggregated <-
    aggregate_blocking(indices) |>
    dplyr::filter(.data$index %in% .env$index)

  block_levels <- unique(aggregated$blocks)

  values <-
    indices |>
    dplyr::select(
      "id",
      "blocks",
      "bi_confidence",
      "bi_choice"
    ) |>
    tidyr::pivot_longer(
      cols = c("bi_confidence", "bi_choice"),
      names_to = "index",
      values_to = "value"
    ) |>
    dplyr::filter(
      .data$index %in% .env$index,
      !is.na(.data$value)
    )

  label_facets <- function(data) {
    dplyr::mutate(
      data,
      panel = factor(index_labels[.data$index], levels = index_labels[.env$index]),
      blocks = factor(.data$blocks, levels = block_levels)
    )
  }

  values <- label_facets(values)
  aggregated <- label_facets(aggregated)

  limits <-
    dplyr::bind_rows(
      dplyr::select(values, "panel", y = "value"),
      dplyr::mutate(aggregated, .data$panel, y = abs(.data$estimate) + dplyr::coalesce(.data$se, 0), .keep = "none")
    ) |>
    dplyr::group_by(.data$panel) |>
    dplyr::summarise(
      lim = 1.25 * max(abs(.data$y), 1),
      .groups = "drop"
    )

  bounds <- tidyr::expand_grid(limits, side = c(-1, 1)) |>
    dplyr::mutate(
      y = .data$side * .data$lim,
      blocks = factor(block_levels[1], levels = block_levels)
    )

  poles <- dplyr::mutate(
    bounds,
    y = .data$side * .data$lim * 0.96,
    label = dplyr::if_else(.data$side > 0, "Control cue's outcome", "Blocked cue's outcome")
  )

  ggplot2::ggplot(values) +
    ggplot2::aes(
      x = .data$blocks,
      y = .data$value
    ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey30",
      linewidth = 0.5,
      linetype = "dotted"
    ) +
    ggplot2::geom_blank(
      data = bounds,
      ggplot2::aes(x = .data$blocks, y = .data$y),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_violin(
      fill = "grey85",
      colour = "grey45",
      linewidth = 0.4,
      scale = "width",
      width = 0.7,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_jitter(width = 0.08, height = 0, seed = 1L),
      colour = "grey30",
      size = 1.2,
      alpha = 0.8
    ) +
    ggplot2::geom_errorbar(
      data = aggregated,
      ggplot2::aes(
        x = .data$blocks,
        ymin = .data$estimate - .data$se,
        ymax = .data$estimate + .data$se
      ),
      inherit.aes = FALSE,
      width = 0.12,
      linewidth = 0.6,
      na.rm = TRUE
    ) +
    ggplot2::geom_point(
      data = aggregated,
      ggplot2::aes(
        x = .data$blocks,
        y = .data$estimate
      ),
      inherit.aes = FALSE,
      size = 2.4
    ) +
    ggplot2::geom_text(
      data = poles,
      ggplot2::aes(
        x = 0.45,
        y = .data$y,
        label = .data$label
      ),
      inherit.aes = FALSE,
      hjust = 0,
      size = 3,
      colour = "grey30",
      fontface = "italic"
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$panel),
      ncol = 1,
      scales = "free_y",
      labeller = if (parse) ggplot2::label_parsed else ggplot2::label_value
    ) +
    ggplot2::labs(
      x = "Test blocks",
      y = "Blocking index"
    ) +
    .learning_theme()
}
