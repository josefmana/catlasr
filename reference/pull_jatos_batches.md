# Pull the study results of one or more JATOS batches

Downloads every study result of the listed batches through `{jatosR}`
and binds them into one table. The connection is tested first, so a
wrong token fails before any batch is requested. Batch that cannot be
pulled is named in the error.

## Usage

``` r
pull_jatos_batches(url, batch_ids, token, result_file = NULL)
```

## Arguments

- url:

  Character(1). Address of the JATOS server, e.g.
  `"https://jatos.mindprobe.eu"`.

- batch_ids:

  Integer-valued numeric vector of JATOS batch IDs, without duplicates.

- token:

  Character(1). A JATOS API token, `"jap_..."` with or without the
  `"Bearer "` prefix. Read it from `.Renviron` rather than typing it
  into a script, e.g. `Sys.getenv("mindprobe_catlas_token")`.

- result_file:

  `NULL` (default) or Character(1). Name of a JATOS result file that
  holds the complete data of a study result, e.g. `"jspsych-data.json"`
  from `fba-allergy-online-02` on. `NULL` reads the streamed data only,
  as for builds that upload no result file (e.g.
  `fba-allergy-online-01`). See details.

## Value

A tibble with one row per JATOS study result, including the columns of
`jatosR::process_results()$data` (among them `id_sr`, `id_cr`,
`batch_id`, `start_date_sr`, `study_state` and `data_raw`),
`jatos_study_id` representing the JATOS study each batch belongs to, and
`data_source`, the source of `data_raw`: `"file"` (the result file),
`"stream"` (the streamed data) or `NA` (neither exists). The time the
pull finished, in UTC, is attached as the attribute `"retrieved_at"`,
ready for
[`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md).

## Details

Batches may belong to different JATOS studies, for instance when a study
was re-deployed after a patch. `jatos_study_id` keeps this fact visible.

### Result files

CATLAS experiments stream every trial to JATOS as it finishes, and from
`fba-allergy-online-02` on they also upload the complete jsPsych data as
a result file at the end of the run. A trial whose upload failed, e.g.
during a dropped internet connection, is missing from the streamed data
but present in the file. With `result_file` given, the file of every
study result is requested from the JATOS API
(`/jatos/api/v1/results/files/`, JATOS 3.8.1 and later), and the
following rule applies:

- Where the file exists, it is read instead of the streamed data. The
  two are never combined, because the file of a finished run repeats
  every streamed trial.

- Where it does not exist (unfinished runs, failed uploads), the
  streamed data are read.

- Where it exists but does not parse, the streamed data are read, with a
  warning.

Where both exist, the file must hold every streamed trial apart from
`email-collection` records, matched on `trial_index`. A file that does
not is still read, with a warning naming the affected study result.
Every call reports how many study results were read from each source,
names those read from the streamed data, and counts the trials recovered
from the files.

## See also

[`parse_jatos_results()`](https://josefmana.github.io/catlasr/reference/parse_jatos_results.md),
[`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md)
