#' Create APA Style Table
#'
#' Puts a {gt} table in the APA 7th styling.
#'
#' @param gtable {gt} table. A table prepared
#'   with the gt package.
#'
#' @details Taken from
#' <https://gist.github.com/pdparker/1b61b6d36d09cb295bf286a931990159>.
#'
#' @return A {gt} table that is identical to `gtable`,
#'   but formatted.
#'
#' @examples
#' \dontrun{
#' tibble::tibble(stage_1 = c("A->1", "C->2"), stage_2 = c("AB->1", "CD->2")) |>
#'   gt::gt() |>
#'   apa_style()
#' }
#'
#' @export
apa_style <- function(gtable) {
  gtable |>
    gt::opt_table_lines(extent = "none") |>
    gt::tab_options(
      heading.border.bottom.width = 2,
      heading.border.bottom.color = "black",
      heading.border.bottom.style = "solid",
      table.border.top.color = "white",
      table_body.hlines.color = "white",
      table_body.border.top.color = "black",
      table_body.border.top.style = "solid",
      table_body.border.top.width = 1,
      heading.title.font.size = 12,
      table.font.size = 12,
      heading.subtitle.font.size = 12,
      table_body.border.bottom.color = "black",
      table_body.border.bottom.width = 1,
      table_body.border.bottom.style = "solid",
      column_labels.border.bottom.color = "black",
      column_labels.border.bottom.style = "solid",
      column_labels.border.bottom.width = 1
    ) |>
    gt::opt_table_font(font = "times")
}
