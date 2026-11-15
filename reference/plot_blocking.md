# Plot blocking indices

Draws the distribution of the participants' blocking indices as a violin
with the individual values on top, and their mean with error bars of one
standard error each way, in the style of Kelly and Ludvig (2025, Figure
3). The resulting figure stacks one panel per index above each other,
with one violin per selection of test blocks.

## Usage

``` r
plot_blocking(
  indices,
  index = c("bi_confidence", "bi_choice"),
  labels = NULL,
  parse = FALSE
)
```

## Arguments

- indices:

  Per-participant blocking indices, resulting from
  [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md).
  Tables for several selections of blocks can be bound by rows first.
  For instance, the first block results can be combined with results
  based on all blocks.

- index:

  Character. Indices to draw, by their column names in `indices`, i.e.,
  any of `"bi_confidence"` and `"bi_choice"`. Defaults to both.

- labels:

  Named character, or `NULL` (default). Panel titles by index name,
  replacing the defaults ("Confidence-weighted choice score",
  "Choice-proportion score") for the indices named.

- parse:

  Logical(1). Read `labels` as plotmath expressions? `FALSE` (default)
  prints them as they are. `TRUE` allows subscripts that do not depend
  on the font having subscript characters, e.g.
  `c(bi_confidence = 'BI[2]*":"~"confidence-weighted choice score"')`.

## Value

A `ggplot` object.

## Details

The dotted horizontal line marks zero, i.e., no blocking. The labels at
the top and bottom of each panel name the outcome that the participants'
answers lean towards. Selecting the Stage 3 outcome associated with the
control cue yields positive values (i.e., blocking), while preference
for the Stage 3 outcome associated with the putatively blocked cue
yields negative ones. The vertical axis is symmetric around zero within
each panel.

The function says that it ran
[`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
on your behalf and that function then states how its standard errors are
defined. Run
[`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
yourself to get the numbers behind the figure.

## References

Kelly, T., & Ludvig, E. A. (2025). Blocking of associative learning by
explicit descriptions. *Cognition, 256*, 106015.
[doi:10.1016/j.cognition.2024.106015](https://doi.org/10.1016/j.cognition.2024.106015)

## See also

[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md),
[`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
