#' Add APA 7th formattin to a gt table
#'
#' Applies American Psychological Association (APA) 7th edition table
#' formatting to a [gt::gt()] object.
#'
#' @param x `gt_tbl` object produced by [gt::gt()].
#' @param title Character string. The table title, rendered as italic HTML
#'   above the table. Defaults to a single space (no visible title).
#'
#' @returns A `gt_tbl` object with APA 7 formatting applied. The object
#'   remains pipeable, i.e., further [gt::gt()] calls can be chained after
#'   `apa_style()`.
#'
#' @details
#' The code was adapted from:
#' <https://www.anthonyschmidt.co/post/2020-06-03-making-apa-tables-with-gt/>.
#' It follows the three-line border convention: borders appear at the top of
#' the column header, the bottom of the column header, and the bottom of the
#' table body. All internal cell borders and the outer frame are suppressed.
#' The table title is rendered in italics, flush left.
#'
#' @family formatting
#'
#' @seealso [gt::gt()], [gt::tab_options()], [gt::tab_style()]
#'
#' @export
apa_style <- function(x, title = " ") {
  x |>
    gt::tab_options(
      table.border.top.color = "white",
      heading.title.font.size = gt::px(16),
      column_labels.border.top.width = 3,
      column_labels.border.top.color = "black",
      column_labels.border.bottom.width = 3,
      column_labels.border.bottom.color = "black",
      table_body.border.bottom.color = "black",
      table.border.bottom.color = "white",
      table.width = gt::pct(100),
      table.background.color = "white"
    ) |>
    gt::cols_align(align="center") |>
    gt::tab_style(
      style = list(
        gt::cell_borders(
          sides = c("top", "bottom"),
          color = "white",
          weight = gt::px(1)
        ),
        gt::cell_text(
          align="center"
        ),
        gt::cell_fill(color = "white", alpha = NULL)
      ),
      locations = gt::cells_body(
        columns = tidyselect::everything(),
        rows = tidyselect::everything()
      )
    ) |>
    gt::tab_header(
      title = gt::html("<i>", title, "</i>")
    ) |>
    gt::opt_align_table_header(align = "left")
}
