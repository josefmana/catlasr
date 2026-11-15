# Parse pulled JATOS results into jsPsych trial data

Repairs and parses the `data_raw` column of
[`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md),
one study result at a time, so that one damaged result cannot stop the
others.

## Usage

``` r
parse_jatos_results(x)
```

## Arguments

- x:

  A tibble from
  [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md),
  or any data frame with the columns `id_sr` and `data_raw`.

## Value

`x` without `data_raw`, with three columns added in front:

- `id`:

  The JATOS study result ID as character; represents the participant
  identifier used by
  [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md).

- `jspsych`:

  A list of tibbles, one row per jsPsych trial, or `NULL` for a result
  without parseable data.

- `has_data`:

  Logical, `FALSE` on rows where `jspsych` is `NULL`.

Attributes of `x`, such as `"retrieved_at"`, are kept.

## Details

A `response` column is coerced to character for every result. jsPsych
records a button press as its index and a choice as text, so a
participant whose run holds only button presses, such as one who
declined consent, would, without the coercion, get a numeric `response`
column that does not stack with everyone else's.

## See also

[`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md),
[`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md)
