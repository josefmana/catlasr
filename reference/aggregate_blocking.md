# Aggregate blocking indices across participants

Averages the per-participant blocking indices from
[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
and gives the standard error of each mean, i.e., an estimate with its
standard error, the form that power and design analyses take.

## Usage

``` r
aggregate_blocking(indices, silence = FALSE)
```

## Arguments

- indices:

  Per-participant blocking indices, resulting from
  [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md).
  Tables for several selections of blocks can be bound by rows first.

- silence:

  Logical(1). Suppress the message about the assumptions behind the
  calculations. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per index and selection of blocks, and columns:

- `index`:

  The index, according to its column name in `indices`:
  `"bi_confidence"` or `"bi_choice"`.

- `blocks`:

  As in `indices`.

- `n_participants`:

  Participants with a non-missing index.

- `estimate`:

  Mean of the participants' indices.

- `sd`:

  Standard deviation of the participants' indices.

- `se`:

  Standard error of the mean, \\SD / \sqrt{n}\\; `NA` in cases with
  fewer than two participants.

## Details

During the aggregation, every participant counts once, no matter how
many trials they answered. Beware thus uneven trial counts across the
dataset. In such a case, you can, for instance, filter the input for
`complete %in% TRUE` as a sensitivity analysis, or even better analyse
the data with a bespoke model that considers such imbalances, e.g., via
partial pooling.

The standard error is computed between participants, which suits
comparing a mean against zero (i.e., no blocking). Comparing an index
between selections of blocks, such as the first block against all
blocks, concerns the same participants and calls for the per-participant
differences or hierarchical modelling instead. Per participant
differences can be taken directly from `indices`.

Every call states these caveats, unless silenced (`silence = TRUE`,
e.g., when a developer wishes to debug the code).

## See also

[`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md),
[`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md)
