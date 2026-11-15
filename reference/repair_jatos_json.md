# Repair trial-by-trial JATOS result data into a valid JSON

CATLAS experiments stream every jsPsych trial to JATOS as it finishes,
via `jatos.appendResultData(JSON.stringify(data))`. JATOS stores the
appended strings back to back, so a study result arrives as a sequence
of JSON objects, `{...}{...}{...}`, with neither the enclosing brackets
nor the separating commas that would make it one JSON array.
`repair_jatos_json()` supplies both missing components, so the result
can be parsed with
[`jsonlite::fromJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

## Usage

``` r
repair_jatos_json(x)
```

## Arguments

- x:

  Character. One element per JATOS study result, typically the
  `data_raw` column of `jatosR::process_results()$data`. A logical
  vector of `NA`s is accepted too and will be returned unchanged.

## Value

A character vector of the same length as `x`. Each element is a JSON
array of trial records. `NA` stays `NA`, an empty string becomes `"[]"`,
and an element that already is a JSON array is returned unchanged.

## Details

The repair inserts a comma wherever a closing brace is followed,
possibly after whitespace, by an opening brace. It does not parse the
JSON, so a string *value* containing `}{` would be split as well.
jsPsych escapes quotes but not braces, so this can only happen when a
participant types `}{` into a free-text field. The record would then
fail to parse, which shows up as an invalid result.

## Examples

``` r
raw <- c(
  '{"trial_type":"consent","response":1}{"trial_type":"stimuli-map"}',
  NA,
  ""
)
repair_jatos_json(raw)
#> [1] "[{\"trial_type\":\"consent\",\"response\":1},{\"trial_type\":\"stimuli-map\"}]"
#> [2] NA                                                                              
#> [3] "[]"                                                                            
```
