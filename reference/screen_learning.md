# Screen participants on their learning tests

Applies an exclusion criterion to the per-stage tests implemented in
[`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md).
Which stages count to the exclusion decision and whether failing any or
all of them excludes the participant is decided here, in `stages` and
`rule`, respectively. The function Returns one row per participant with
the decision and the reason for it, so that the excluded identifiers can
be passed on to
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md).

## Usage

``` r
screen_learning(tests, stages = NULL, rule = c("any", "all"), silence = FALSE)
```

## Arguments

- tests:

  Per-participant, per-stage learning tests from
  [`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md).

- stages:

  Character. Stages whose test counts towards the criterion. `NULL`
  (default) uses every stage in `tests`.

- rule:

  Character(1). `"any"` (default) excludes a participant who fails the
  test in at least one of `stages`. `"all"` excludes only a participant
  who fails it in every one of `stages`.

- silence:

  Logical(1). Suppress the message summarising the criterion and its
  yield. Defaults to `FALSE` (recommended).

## Value

A tibble with one row per participant, and columns:

- `id`:

  Participant identifier.

- `exclude`:

  `TRUE` when the participant meets the exclusion criterion.

- `n_failed`:

  Number of `stages` in which the participant did not score
  significantly above chance.

- `failed_stages`:

  Failed stages, comma-separated; `NA` when none.

- `reason`:

  For excluded participants, the failed tests in words, e.g.
  `"Stage 3: 27/48 correct, below the cut-off of 29 (p = 0.235)"`; `NA`
  for participants who are kept.

## Details

A stage counts as failed when its test did find clear evidence of
above-chance performance, including a stage without any answered trial.

The function makes exclusion decision, but it does not exclude.
Exclusions are applied, and recorded in the provenance of the data
bundle, by
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md),
for instance with `ids = screen$id[screen$exclude]`. Its `description`
should state the test, `alpha`, the stages and the rule, so that it can
be reported verbatim.

### Messages

Every call states the criterion, how many participants it excludes, and
how many failed each of `stages`, unless silenced (`silence = TRUE`).

## See also

[`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md),
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
