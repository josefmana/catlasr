# Write the free-text debriefing answers to a private coding file

The free-text answers to the debriefing question asking whether the
participant knew or guessed what the study tested must be coded before
any blocking index is computed, from a file that holds nothing but
participant identifiers and debriefing answers, so that the coding is
blind to the test data. `write_debrief_coding()` writes such a file to
the private folder as a CSV with an empty column `blocking_naive` for
the codes indicating whether, based on the debriefing answer, the
participant appears to be naive to the study's purpose to investigate
blocking. Fill it in manually with `TRUE` or `FALSE`, then read the
codes back with
[`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md).

## Usage

``` r
write_debrief_coding(
  debrief,
  file,
  rule = NULL,
  dir = Sys.getenv("CATLAS_PRIVATE_DIR")
)
```

## Arguments

- debrief:

  A data frame with one row per participant and the columns `id`,
  `prior_knowledge` (the yes/no answer) and `prior_guess` (the free
  text), taken from the debriefing records of the parsed jsPsych data.

- file:

  Character(1). Path of the coding file (`.csv`) within the private
  folder, e.g. `"fba-allergy-online-02/debrief-coding.csv"`.

- rule:

  Character(1) or `NULL`. The coding rule, printed in the message as a
  reminder. Defaults to `NULL`.

- dir:

  Character(1). The private folder. Defaults to the environment variable
  `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.

## Value

The path of the coding file, invisibly.

## Details

### Repeated calls

The debriefing file grows with the data. When it exists, codes already
entered are kept, participants new to `debrief` are added with an empty
code, and participants absent from `debrief` keep their rows. A
participant whose answer differs from the one in the file aborts the
call, as answers cannot change between pulls, so a difference means that
participant identifiers no longer match.

### Answers that need no coding

A missing answer (for which `is.na(prior_guess)`, e.g. after a timed-out
debriefing screen) cannot show that the participant was naive to
blocking, so it is coded `FALSE` automatically and the participant does
not reach the naive set (i.e., data set of participants naive to the
experimental design).

### The file

UTF-8, comma-separated, sorted by `id`, with empty cells for missing
values. Spreadsheet programs may change the separator or translate
`TRUE` and `FALSE` (e.g. into `PRAVDA` and `NEPRAVDA`) when saving;
[`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md)
accepts semicolons, but aborts on any code other than `TRUE` or `FALSE`.

## See also

[`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md)
