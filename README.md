# catlasr

<!-- badges: start -->
[![R-CMD-check](https://github.com/josefmana/catlasr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/josefmana/catlasr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

R infrastructure for the [CATLAS](https://github.com/josefmana/CATLAS) project:
the code engine that imports, validates and scores the data of the CATLAS
experiments, while CATLAS itself contains the manuscripts and analysis
notebooks. The experiments run on code documented in
[catlaslab](https://github.com/josefmana/catlaslab).

## Status

`v0.0.1` is a **pre-release**, tagged before data collection of
`fba-allergy-online-02`, the pre-registered replication of three-stage forward
blocking (Beesley & Le Pelley,
[2011](https://psycnet.apa.org/doi/10.1037/a0019526)). Its pre-registration
refers to the import, validation, exclusion and scoring functions by name, so
from this tag on they are frozen and any later change that could alter a
reported number is a deviation from the registered analysis and is logged as
such in `NEWS.md`.

The pre-release contains no data. The anonymised data of `fba-allergy-online-02`
will be added in a later release.

## Installation

```r
# install.packages("remotes")
remotes::install_github("josefmana/catlasr@v0.0.1")

# Only needed to download data from JATOS
remotes::install_github("visionlabels/jatosR")
```

## What it does

Every analysis step is a function called deliberately by the user and every
function states its assumptions as it runs.

- **Import from JATOS**  
  `pull_jatos_batches()` downloads study results, reading the complete jsPsych
  data from the result file when the experiment uploaded one and from the
  streamed data otherwise; `parse_jatos_results()` and `repair_jatos_json()`
  turn JATOS imports into trial tables.
- **Data bundles**  
  `build_provenance()` records where the data come from, `build_fba_rawdata()`
  builds and `validate_fba_rawdata()` validates a forward-blocking data bundle
  (participant metadata, stimulus mappings and trials), and `record_exclusion()`
  removes participants while recording the exclusion rule in the bundle's
  provenance.
- **Learning check**  
  `score_learning()`, `test_learning()`, `screen_learning()`,
  `aggregate_learning()` and `plot_learning()` run in a series.
- **Blocking indices**  
  `score_blocking()`, `index_blocking()` (the confidence-weighted choice score
  of Beesley & Le Pelley, [2011](https://psycnet.apa.org/doi/10.1037/a0019526),
  and the choice-proportion score of Paskewitz & Jones,
  [2020](https://doi.org/10.1016/j.jmp.2020.102371)), `aggregate_blocking()`
  and `plot_blocking()`, run in a series.
- **Data collection monitoring**  
  `trace_progress()` reports how far every participant got without reading any
  test response.
- **Stimuli**  
  `catlas_stimulus()`, `render_stimulus()` and `write_stimulus()` compose the
  cue and outcome images of the allergist task.

## Personal data

Personal data never enter any repository. They live in a private folder outside
every git repository, named by the environment variable `CATLAS_PRIVATE_DIR`
in `.Renviron`, with one subfolder per study.

- `write_private_rds()`, `write_private_csv()` and `read_private_rds()` ensure
  privacy by refusing any folder inside a git work tree.
- `update_id_key()` replaces platform identifiers by random participant IDs,
  keeping the key in the private folder only.
- Data bundles refuse e-mail addresses and free-text answers. The free-text
  debriefing answers are coded manually blind to the test data, with
  `write_debrief_coding()` and `read_debrief_coding()`.

## Vignettes

- [*Importing the Forward Blocking Replication Pilot from JATOS*](vignettes/import-jatos-data.Rmd):
  the import of the pilot `fba-allergy-online-01`, step by step.
- [*Generating Stimuli for the Allergist Task*](vignettes/stimuli-allergist-task.Rmd):
  the image generation code for `fba-allergy-online-01` and
  `fba-allergy-online-02` study materials.

## References

Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on overt
attention and associability in human learning. *Journal of Experimental
Psychology: Animal Behavior Processes, 37*(1), 114-120.
<https://doi.org/10.1037/a0019526>

Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. *Journal of Mathematical
Psychology, 97*, 102371. <https://doi.org/10.1016/j.jmp.2020.102371>

## Licence

MIT
