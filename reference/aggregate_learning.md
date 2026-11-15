# Aggregate learning across participants

Averages the per-participant proportions of correct responses within
each stage, contingency type and block, and gives the standard error of
that mean.

## Usage

``` r
aggregate_learning(learning, silence = FALSE)
```

## Arguments

- learning:

  A per-participant learning summary, from
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md).

- silence:

  Logical(1). Suppress the message about the assumptions behind the
  calculations. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per stage, contingency type and block and columns:

- `stage`, `type`, `block`:

  As in `learning`.

- `n_participants`:

  Participants with at least one answered trial in the cell.

- `p_correct`:

  Mean of the participants' `p_correct`.

- `se`:

  Standard error of the `p_correct` mean, \\SD /
  \sqrt{n\_{participants}}\\; `NA` in rows with fewer than two
  participants.

## Details

Every participant counts once per cell, no matter how many trials they
answered. The standard error is computed between participants, because
the learning check asks whether accuracy is above chance, not whether
the accuracy differs as a function of cue type or stage (which would ask
for a within-subjects SE instead). Every call states this definition of
the standard error and states the cells where it could not be computed,
unless silenced (`silence = TRUE`).

## See also

[`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
[`plot_learning()`](https://josefmana.github.io/catlasr/reference/plot_learning.md)
