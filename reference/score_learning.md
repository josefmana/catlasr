# Score learning per participant

Counts the trials, responses and correct responses of every participant
in every block of every learning stage, separately for each contingency
type. The results represent the per-participant, per-type summaries on
which the learning checks and the learning-based exclusion rules are
based.

## Usage

``` r
score_learning(x, silence = FALSE)
```

## Arguments

- x:

  A `catlas_rawdata` object.

- silence:

  Logical(1). Suppress the message summarising what data went into the
  calculations. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant, stage, contingency type and
block, and columns:

- `id`:

  Participant identifier.

- `stage`, `type`, `block`:

  As in the `trials` component.

- `n_trials`:

  Number of trials presented.

- `n_timed_out`:

  Number of trials that ended without a response.

- `n_responded`:

  Number of trials with a recorded response.

- `n_correct`:

  Number of correct responses.

- `p_correct`:

  `n_correct / n_responded`, or `NA` when no trial was answered.

## Details

### Stages

Only the stages that give feedback according to the study design are
used during the calculations. The design can be found in the
`provenance(x)`. The test stage is never included, because in it, the
`is_correct` column records whether a response is consistent with
blocking, which is a component part of the outcome measure of the study,
rather than a measure of learning.

### Timed-out trials

Timed-out trials are left out of the denominator of `p_correct` and
counted in `n_timed_out` instead, so that leaving the task is not
confused with giving an incorrect answer.

### Messages

Every call states which stages were scored and how many timed-out trials
were left out of the denominators, unless manually silenced
(`silence = TRUE`).

## See also

[`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md),
[`plot_learning()`](https://josefmana.github.io/catlasr/reference/plot_learning.md)
