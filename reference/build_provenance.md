# Record where a CATLAS raw-data bundle came from

Constructor for the `catlas_provenance` class. Each data bundle carries
a provenance record, allowing the data bundle object to answer when it
was extracted, from where, which study it comes from, and which
experiment build was used to collect the data.

## Usage

``` r
build_provenance(
  study,
  design,
  blocks,
  trial_types,
  origin,
  collected_between = NULL,
  retrieved_at = Sys.time(),
  experiment_build,
  notes = character(),
  guided = FALSE
)
```

## Arguments

- study:

  Character(1). Study identifier of the form
  `<prefix>-<task>-<mode>-0X`. Its components are parsed, so for
  instance `fba-allergy-online-01` yields `prefix = "fba"`,
  `task = "allergy"`, `mode = "online"`, `wave = 1L`. See Details for
  further explanation of the naming convention.

- design:

  Character(1). Structural variant of the procedure. Currently one of
  `"three-stage-replication"` or `"three-stage-extension"`. See Details
  for explanation of supported study designs.

- blocks:

  Named integer vector. Number of blocks per stage, named by stage
  exactly as `trials$stage` is coded. For instance, the three-stage
  allergy of the `forward-blocking-attention-01` manuscript supplies:
  `c(stage1 = 10L, stage2 = 8L, stage3 = 6L, test = 6L)`.

- trial_types:

  Integer(1). Distinct trial types presented per block, 8 for the
  three-stage allergy task. Together with `blocks`, the `trial_types`
  are used to derive the expected trial count.

- origin:

  Named list comprising of `platform` (one of `"JATOS"`, `"Prolific"`,
  `"OSF"`, `"synthetic"`), `url`, `study_id` and `batch_ids`. `study_id`
  may hold several IDs when the batches span more than one platform
  study, e.g. after a re-deployment.

- collected_between:

  Named `Date` vector or a pair of strings
  [`as.Date()`](https://rdrr.io/r/base/as.Date.html) can parse, as
  `c(first = , last = )`. Records the first and last day on which the
  experiment was run. Required unless the platform is `"synthetic"`.
  This field is **not** the same as `retrieved_at`. `collected_between`
  records when the experiment was run, `retrieved_at` when the data was
  imported.

- retrieved_at:

  POSIXct(1) or a string parseable by
  [`as.POSIXct()`](https://rdrr.io/r/base/as.POSIXlt.html). Coerced to
  UTC. Defaults to the current time.

- experiment_build:

  Named list comprising of `repo`, `release` and `commit`. At least one
  of `release` and `commit` must be given unless the platform is
  `"synthetic"` (which refers to simulated, not collected data).

- notes:

  Character. Free text.

- guided:

  Logical(1). When `TRUE`, every other argument is ignored and the
  record is collected by prompting at the console, then the equivalent
  call is printed for pasting into a script. Requires an interactive
  session.

## Value

A validated object of class `"catlas_provenance"`.

## Details

### Naming conventions (`study`)

CATLAS uses a specific study naming convention that allows it to keep
some order in the chaos that is scientific publishing. Each experiment
must be named according to this convention, and thus be of the form
`<prefix>-<task>-<mode>-0X`. In this study name, each components carries
its own specific meaning:

- `<prefix>` means study type or manuscript family. For instance, `fba`
  refers to `forward-blocking-attention` experiments aimed at
  illuminating the role attention plays in the forward blocking
  phenomenon in cue contingency learning.

- `<task>` is a broad family to which task used by the experiment falls.
  It refers to the cover story, not to the formal structure of the
  experiment. For instance, `allergy` refers to the commonly used
  allergy prediction family of tasks.

- `<mode>` refers to the data collection mode. Currently support online
  (`"online"`), behavioural on-site (`"lab"`), eye-tracking containing
  (`"eye"`), and electroencephalography containing (`"eeg"`) data.

- `0X` is the wave indicating order of this experiment in a series of
  experiments from the same study type/manuscript family (`<prefix>`),
  using the same task variant (`<task>`), and collected via the same
  data collection method (`<mode>`). The order does NOT reset with each
  new manuscript and it is thus possible to have the first experiment of
  a manuscript containing wave number of more than one. The wave
  identifier `0X` is coerced to integer via
  [`as.integer()`](https://rdrr.io/r/base/integer.html).

### Supported study designs (`design`)

Study `design` parameter provides information about above and beyond
what you put into `study`. Most importantly, while the `<task>` field of
`study` informs about the experiment's "cover story," `design` reflects
formal set-up and study procedure information. Currently, the following
designs are supported:

- `three-stage-replication` refers to a formally exact replication of
  the Beesley & Le Pelley's (2011) study which demonstrated that forward
  blocking in a three-stage cue-outcome contingency learning paradigm
  correlates with eye-tracking proxies of overt attention

- `three-stage-extension` refers to a procedure reflecting Paskewitz &
  Jones's (2020) desing suggestion for adjudicating between attentional
  shift and attentional competition accounts of forward blocking within
  associability-based associative models of cue-outcome contingency
  learning

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on
overt attention and associability in human learning. *Journal of
Experimental Psychology: Animal Behavior Processes, 37*(1), 114–120.
[doi:10.1037/a0019526](https://doi.org/10.1037/a0019526)

Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. Journal of
Mathematical Psychology\*, *97*, 102371.
[doi:10.1016/j.jmp.2020.102371](https://doi.org/10.1016/j.jmp.2020.102371)

## See also

[`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md),
[`provenance()`](https://josefmana.github.io/catlasr/reference/provenance.md),
[`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)

## Examples

``` r
build_provenance(
  study = "fba-allergy-online-01",
  design = "three-stage-replication",
  blocks = c(stage1 = 10L, stage2 = 8L, stage3 = 6L, test = 6L),
  trial_types = 8L,
  origin = list(
    platform = "JATOS",
    url = "https://jatos.mindprobe.eu",
    study_id = "catlas_01",
    batch_ids = c(30206L, 30275L, 30832L, 30829L)
  ),
  collected_between = c(
    first = as.Date("2026-06-09"),
    last  = as.Date("2026-06-26")
  ),
  retrieved_at = as.POSIXct("2026-06-26 12:00:00", tz = "UTC"),
  experiment_build = list(
    repo = "josefmana/catlaslab",
    release = "fba-allergy-online-01",
    commit = "e249e74"
  )
)

if (FALSE) { # \dontrun{
# Answer the prompts, then paste the printed call into data-raw/.
prov <- build_provenance(guided = TRUE)
} # }
```
