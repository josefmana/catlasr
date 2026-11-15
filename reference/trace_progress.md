# Trace how far every participant got through the experiment

For every participant in the bundle, counts the experiment trials
recorded and reports the furthest stage and block reached and how long
the participant spent responding. If run on a bundle before exclusions,
it shows the attrition funnel; if run during data collection, it
monitors data quality without reading any test response.

## Usage

``` r
trace_progress(x, silence = FALSE)
```

## Arguments

- x:

  A `catlas_rawdata` object.

- silence:

  Logical(1). Suppress the message summarising the progress and what the
  time columns measure. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant in `meta`, and columns:

- `id`:

  Participant identifier.

- `n_trials`:

  Experiment trials recorded, timed-out ones included.

- `last_stage`, `last_block`:

  The furthest stage reached, in design order, and the last block
  recorded in it; `NA` if there is no trial.

- `learning_complete`:

  `TRUE` iff every trial of every learning stage was recorded.

- `n_test_blocks`:

  Number of test blocks recorded in full.

- `test_complete`:

  `TRUE` iff every test block was recorded in full.

- `duration_min`:

  Wall-clock duration of the run, taken from `meta$duration_min` when
  the import recorded it, otherwise `NA`.

- `task_min`:

  Minutes spent responding: the sum of `rt1` and `rt2` over all
  experiment trials.

- `task_min_<stage>`:

  The same as above, per stage.

## Details

Expected trial counts come from `provenance(x)$blocks` and
`provenance(x)$trial_types`. The learning stages are the stages that the
study design marks as giving feedback, while all other stages count as
test.

`task_min` measures response times only. Feedback, inter-trial
intervals, instructions and breaks are not part of it, so it is shorter
than `duration_min`, which spans the whole run.

A bundle after exclusions holds only the participants who were kept.
Trace the bundle as imported, before any
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
was applied, to see where the excluded participants stopped.

### Messages

Every call summarises the progress and states what the time columns
measure, unless silenced (`silence = TRUE`).

## See also

[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md),
[`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md)
