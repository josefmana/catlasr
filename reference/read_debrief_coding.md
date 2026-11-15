# Read the codes of the free-text debriefing answers

Reads the coding file written by
[`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md)
once `blocking_naive` is filled in, and returns the participants whose
answer was coded as indicating they either recognised blocking or did
not answer (in which case them recognising blocking cannot be ruled
out), ready for
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md).

## Usage

``` r
read_debrief_coding(file, ids = NULL, dir = Sys.getenv("CATLAS_PRIVATE_DIR"))
```

## Arguments

- file:

  Character(1). Path of the coding file (`.csv`) within the private
  folder, e.g. `"fba-allergy-online-02/debrief-coding.csv"`.

- ids:

  Character or `NULL`. Participants whose codes are needed, e.g. those
  of the data bundle the rule is applied to. Every one of them must have
  a coded row. `NULL` (default) uses every row of the file.

- dir:

  Character(1). The private folder. Defaults to the environment variable
  `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.

## Value

A character vector of the participant IDs coded `FALSE`, i.e., not naive
to blocking, among `ids` when given.

## Details

The call aborts if any row asked for has no code, if a code is anything
other than `TRUE` or `FALSE` (case does not matter) or if any
participant from `ids` is missing from the file. Codes are thus never
guessed: an uncoded answer stops the import until it gets its code.

## See also

[`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md),
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
