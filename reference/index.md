# Package index

## Import from JATOS

Download study results from JATOS and turn them into trial tables.

- [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md)
  : Pull the study results of one or more JATOS batches
- [`parse_jatos_results()`](https://josefmana.github.io/catlasr/reference/parse_jatos_results.md)
  : Parse pulled JATOS results into jsPsych trial data
- [`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md)
  : Repair trial-by-trial JATOS result data into a valid JSON

## Data bundles and provenance

Build, validate and inspect forward-blocking data bundles, and record
where the data come from and which participants were excluded.

- [`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md)
  : Record where a CATLAS raw-data bundle came from

- [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md)
  : Build a forward-blocking-attention raw-data bundle

- [`validate_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/validate_fba_rawdata.md)
  : Validate a forward-blocking-attention raw-data bundle

- [`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
  : Drop participants and record why

- [`provenance()`](https://josefmana.github.io/catlasr/reference/provenance.md)
  : Extract the provenance record of a CATLAS object

- [`extract_meta()`](https://josefmana.github.io/catlasr/reference/extract_meta.md)
  : Extract the metadata component from a CATLAS raw-data bundle

- [`extract_stimuli()`](https://josefmana.github.io/catlasr/reference/extract_stimuli.md)
  : Extract the stimulus-mappings component from a CATLAS raw-data
  bundle

- [`extract_trials()`](https://josefmana.github.io/catlasr/reference/extract_trials.md)
  : Extract the trial-responses component from a CATLAS raw-data bundle

- [`fba_cues_map()`](https://josefmana.github.io/catlasr/reference/fba_cues_map.md)
  : Map recorded cue labels to canonical cue pairs

- [`format(`*`<catlas_rawdata>`*`)`](https://josefmana.github.io/catlasr/reference/format.catlas_rawdata.md)
  :

  Format a `catlas_rawdata` object

- [`print(`*`<catlas_rawdata>`*`)`](https://josefmana.github.io/catlasr/reference/print.catlas_rawdata.md)
  :

  Print a `catlas_rawdata` object

- [`format(`*`<catlas_provenance>`*`)`](https://josefmana.github.io/catlasr/reference/format.catlas_provenance.md)
  :

  Format a `catlas_provenance` record

- [`print(`*`<catlas_provenance>`*`)`](https://josefmana.github.io/catlasr/reference/print.catlas_provenance.md)
  :

  Print a `catlas_provenance` record

## Personal data

Keep personal data in a private folder outside every repository, replace
platform identifiers with random IDs, and code free-text answers.

- [`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md)
  : Write a data bundle with personal data outside all repositories
- [`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md)
  : Write a table of personal data outside all repositories
- [`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md)
  : Read a data bundle from the private folder
- [`update_id_key()`](https://josefmana.github.io/catlasr/reference/update_id_key.md)
  : Keep a private key mapping platform identifiers to random
  participant IDs
- [`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md)
  : Write the free-text debriefing answers to a private coding file
- [`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md)
  : Read the codes of the free-text debriefing answers

## Learning check

- [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md)
  : Score learning per participant
- [`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md)
  : Test learning against chance per participant and stage
- [`screen_learning()`](https://josefmana.github.io/catlasr/reference/screen_learning.md)
  : Screen participants on their learning tests
- [`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
  : Aggregate learning across participants
- [`plot_learning()`](https://josefmana.github.io/catlasr/reference/plot_learning.md)
  : Plot learning curves

## Blocking indices

- [`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md)
  : Score the test stage for blocking
- [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
  : Compute blocking indices per participant
- [`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
  : Aggregate blocking indices across participants
- [`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md)
  : Plot blocking indices

## Data collection monitoring

- [`trace_progress()`](https://josefmana.github.io/catlasr/reference/trace_progress.md)
  : Trace how far every participant got through the experiment

## Stimuli

Compose the cue and outcome images of the allergist task.

- [`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md)
  : Constructor for CATLAS stimulus object
- [`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md)
  : Render a CATLAS stimulus
- [`render_stimulus(`*`<catlas_stimulus>`*`)`](https://josefmana.github.io/catlasr/reference/render_stimulus.catlas_stimulus.md)
  : Render a CATLAS stimulus using magick
- [`print(`*`<catlas_stimulus>`*`)`](https://josefmana.github.io/catlasr/reference/print.catlas_stimulus.md)
  : Print a CATLAS stimulus
- [`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)
  : Write a rendered stimulus to disk
