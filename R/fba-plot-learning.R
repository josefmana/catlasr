# Display colours per contingency type (Okabe-Ito). Interim, until
# `theme_catlas()` (#22) supplies the CATLAS palette.
.learning_palette <- c(
  blocking = "#D55E00",
  control  = "#0072B2",
  legit    = "#CC79A7",
  filler   = "#009E73"
)


#' Integer axis breaks within the limits of a panel
#'
#' @param limits Numeric(2). Panel limits, as passed by ggplot2.
#'
#' @returns Integer breaks.
#'
#' @noRd
.integer_breaks <- function(limits) {
  seq(ceiling(limits[1]), floor(limits[2]))
}


#' Interim theme for learning-curve figures
#'
#' Replaced by `theme_catlas()` once #22 lands.
#'
#' @returns A ggplot2 theme.
#'
#' @noRd
.learning_theme <- function() {
  ggplot2::theme_classic(base_size = 11) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_line(colour = "grey90", linewidth = 0.3),
      strip.background   = ggplot2::element_blank(),
      strip.text         = ggplot2::element_text(face = "bold"),
      legend.position    = "bottom"
    )
}


#' Plot learning curves
#'
#' Draws the proportion of correct responses over the blocks of each learning
#' stage, one line per contingency type, in the form of Beesley and Le Pelley
#' (2011, Figure 1). The group figure adds error bars counting one standard
#' error each way. The participant figure draws every participant in a row of
#' their own.
#'
#' @param learning A per-participant learning summary, from
#'   [score_learning()].
#' @param level Character(1). `"group"` (default) for the mean across
#'   participants, from [aggregate_learning()], or `"participant"` for one row
#'   of panels per participant.
#'
#' @returns A `ggplot` object.
#'
#' @details
#' The dashed line marks chance, i.e., 50% correct. Error bars are clipped to
#' the 0 to 100% range.
#'
#' With `level = "group"`, the function says that it ran [aggregate_learning()]
#' on your behalf and that function then states how its standard errors are
#' defined. Run [aggregate_learning()] yourself to get the numbers behind the
#' figure.
#'
#' @references Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking
#'   on overt attention and associability in human learning. *Journal of
#'   Experimental Psychology: Animal Behavior Processes, 37*(1), 114-120.
#'   \doi{10.1037/a0019526}
#'
#' @seealso [score_learning()], [aggregate_learning()]
#'
#' @export
plot_learning <- function(learning, level = c("group", "participant")) {
  .check_learning(learning)
  level <- rlang::arg_match(level)

  data <- if (level == "group") {
    .report_plot_caveats()
    aggregate_learning(learning)
  } else {
    learning
  }

  stages <- unique(data$stage[order(.stage_order(data$stage))])
  data$stage_label <- factor(
    .stage_label(data$stage),
    levels = .stage_label(stages)
  )

  types <- unique(data$type)
  palette <- .learning_palette[types]
  palette[is.na(palette)] <- "grey40"
  names(palette) <- types

  plot <-
    ggplot2::ggplot(data) +
    ggplot2::aes(
      x      = .data$block,
      y      = .data$p_correct,
      colour = .data$type,
      group  = .data$type
    ) +
    ggplot2::geom_hline(
      yintercept = 0.5,
      colour     = "grey55",
      linewidth  = 0.5,
      linetype   = "dashed"
    )

  if (level == "group") {
    plot <- plot +
      ggplot2::geom_errorbar(
        ggplot2::aes(
          ymin = pmax(0, .data$p_correct - .data$se),
          ymax = pmin(1, .data$p_correct + .data$se)
        ),
        width     = 0.15,
        linewidth = 0.5,
        na.rm     = TRUE
      )
  }

  plot <- plot +
    ggplot2::geom_line(
      linewidth = 0.8,
      na.rm     = TRUE
    ) +
    ggplot2::geom_point(
      size  = 2,
      na.rm = TRUE
    ) +
    ggplot2::scale_x_continuous(breaks = .integer_breaks) +
    ggplot2::scale_y_continuous(
      breaks = if (level == "group") seq(0, 1, 0.25) else c(0, 0.5, 1),
      labels = function(b) paste0(round(100 * b), "%")
    ) +
    ggplot2::scale_colour_manual(
      values = palette,
      name   = NULL
    ) +
    ggplot2::coord_cartesian(ylim = c(0, 1)) +
    ggplot2::labs(
      x = "Block",
      y = "Accuracy"
    ) +
    .learning_theme()

  if (level == "group") {
    plot +
      ggplot2::facet_grid(
        cols   = ggplot2::vars(.data$stage_label),
        scales = "free_x",
        space  = "free_x"
      )
  } else {
    plot +
      ggplot2::facet_grid(
        rows   = ggplot2::vars(.data$id),
        cols   = ggplot2::vars(.data$stage_label),
        scales = "free_x",
        space  = "free_x"
      )
  }
}
