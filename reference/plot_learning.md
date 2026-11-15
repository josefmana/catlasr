# Plot learning curves

Draws the proportion of correct responses over the blocks of each
learning stage, one line per contingency type, in the form of Beesley
and Le Pelley (2011, Figure 1). The group figure adds error bars
counting one standard error each way. The participant figure draws every
participant in a row of their own.

## Usage

``` r
plot_learning(learning, level = c("group", "participant"))
```

## Arguments

- learning:

  A per-participant learning summary, from
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md).

- level:

  Character(1). `"group"` (default) for the mean across participants,
  from
  [`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md),
  or `"participant"` for one row of panels per participant.

## Value

A `ggplot` object.

## Details

The dashed line marks chance, i.e., 50% correct. Error bars are clipped
to the 0 to 100% range.

With `level = "group"`, the function says that it ran
[`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
on your behalf and that function then states how its standard errors are
defined. Run
[`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
yourself to get the numbers behind the figure.

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on
overt attention and associability in human learning. *Journal of
Experimental Psychology: Animal Behavior Processes, 37*(1), 114-120.
[doi:10.1037/a0019526](https://doi.org/10.1037/a0019526)

## See also

[`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
[`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
