# catlasr

R infrastructure for the [CATLAS](https://github.com/josefmana/CATLAS)
project: the code engine that imports, validates and scores the data of
the CATLAS experiments, while CATLAS itself contains the manuscripts and
analysis notebooks. The experiments run on code documented in
[catlaslab](https://github.com/josefmana/catlaslab).

## Status

`v0.0.1` is a **pre-release**, tagged before data collection of
`fba-allergy-online-02`, the pre-registered replication of three-stage
forward blocking (Beesley & Le Pelley,
[2011](https://psycnet.apa.org/doi/10.1037/a0019526)). Its
pre-registration refers to the import, validation, exclusion and scoring
functions by name, so from this tag on they are frozen and any later
change that could alter a reported number is a deviation from the
registered analysis and is logged as such in `NEWS.md`.

The pre-release contains no data. The anonymised data of
`fba-allergy-online-02` will be added in a later release.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("josefmana/catlasr@v0.0.1")

# Only needed to download data from JATOS
remotes::install_github("visionlabels/jatosR")
```

## What it does

Every analysis step is a function called deliberately by the user and
every function states its assumptions as it runs.

- **Import from JATOS**  
  [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md)
  downloads study results, reading the complete jsPsych data from the
  result file when the experiment uploaded one and from the streamed
  data otherwise;
  [`parse_jatos_results()`](https://josefmana.github.io/catlasr/reference/parse_jatos_results.md)
  and
  [`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md)
  turn JATOS imports into trial tables.
- **Data bundles**  
  [`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md)
  records where the data come from,
  [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md)
  builds and
  [`validate_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/validate_fba_rawdata.md)
  validates a forward-blocking data bundle (participant metadata,
  stimulus mappings and trials), and
  [`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
  removes participants while recording the exclusion rule in the
  bundle’s provenance.
- **Learning check**  
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
  [`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md),
  [`screen_learning()`](https://josefmana.github.io/catlasr/reference/screen_learning.md),
  [`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
  and
  [`plot_learning()`](https://josefmana.github.io/catlasr/reference/plot_learning.md)
  run in a series.
- **Blocking indices**  
  [`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md),
  [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
  (the confidence-weighted choice score of Beesley & Le Pelley,
  [2011](https://psycnet.apa.org/doi/10.1037/a0019526), and the
  choice-proportion score of Paskewitz & Jones,
  [2020](https://doi.org/10.1016/j.jmp.2020.102371)),
  [`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
  and
  [`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md),
  run in a series.
- **Data collection monitoring**  
  [`trace_progress()`](https://josefmana.github.io/catlasr/reference/trace_progress.md)
  reports how far every participant got without reading any test
  response.
- **Stimuli**  
  [`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
  [`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md)
  and
  [`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)
  compose the cue and outcome images of the allergist task.

## Personal data

Personal data never enter any repository. They live in a private folder
outside every git repository, named by the environment variable
`CATLAS_PRIVATE_DIR` in `.Renviron`, with one subfolder per study.

- [`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md),
  [`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md)
  and
  [`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md)
  ensure privacy by refusing any folder inside a git work tree.
- [`update_id_key()`](https://josefmana.github.io/catlasr/reference/update_id_key.md)
  replaces platform identifiers by random participant IDs, keeping the
  key in the private folder only.
- Data bundles refuse e-mail addresses and free-text answers. The
  free-text debriefing answers are coded manually blind to the test
  data, with
  [`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md)
  and
  [`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md).

## Vignettes

- [*Importing the Forward Blocking Replication Pilot from
  JATOS*](https://josefmana.github.io/catlasr/articles/import-jatos-data.html):
  the import of the pilot `fba-allergy-online-01`, step by step.
- [*Generating Stimuli for the Allergist
  Task*](https://josefmana.github.io/catlasr/articles/stimuli-allergist-task.html):
  the image generation code for `fba-allergy-online-01` and
  `fba-allergy-online-02` study materials.

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on
overt attention and associability in human learning. *Journal of
Experimental Psychology: Animal Behavior Processes, 37*(1), 114-120.
<https://doi.org/10.1037/a0019526>

Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. *Journal of
Mathematical Psychology, 97*, 102371.
<https://doi.org/10.1016/j.jmp.2020.102371>

## Licence

MIT
