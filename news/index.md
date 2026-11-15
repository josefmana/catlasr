# Changelog

## catlasr 0.0.1

First pre-release, tagged `v0.0.1` before data collection of
`fba-allergy-online-02`, the pre-registered replication of three-stage
forward blocking (Beesley & Le Pelley, 2011). The pre-registration names
this version and its preprocessing functions, which are frozen from this
tag on. The pre-release contains no data.

### Freeze policy

The preprocessing layer is frozen at `v0.0.1`
([\#32](https://github.com/josefmana/catlasr/issues/32)). It covers
every exported function that imports, validates, excludes or scores
data:

- **import:**
  [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md),
  [`parse_jatos_results()`](https://josefmana.github.io/catlasr/reference/parse_jatos_results.md),
  [`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md);
- **data bundles:**
  [`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md),
  [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md),
  [`validate_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/validate_fba_rawdata.md),
  [`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md),
  [`provenance()`](https://josefmana.github.io/catlasr/reference/provenance.md),
  [`extract_meta()`](https://josefmana.github.io/catlasr/reference/extract_meta.md),
  [`extract_stimuli()`](https://josefmana.github.io/catlasr/reference/extract_stimuli.md),
  [`extract_trials()`](https://josefmana.github.io/catlasr/reference/extract_trials.md),
  [`fba_cues_map()`](https://josefmana.github.io/catlasr/reference/fba_cues_map.md);
- **personal data:**
  [`update_id_key()`](https://josefmana.github.io/catlasr/reference/update_id_key.md),
  [`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md),
  [`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md),
  [`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md),
  [`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md),
  [`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md);
- **learning check:**
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
  [`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md),
  [`screen_learning()`](https://josefmana.github.io/catlasr/reference/screen_learning.md),
  [`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md);
- **blocking indices:**
  [`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md),
  [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md),
  [`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md).

The plotting functions,
[`trace_progress()`](https://josefmana.github.io/catlasr/reference/trace_progress.md)
and the stimulus functions do not change any reported number and stay
outside the freeze.

The exported surface of this version, every exported function and S3
method with its arguments and defaults, is recorded in
`inst/api/v0.0.1.txt`. From this tag on:

- every change to a frozen function gets an entry in this file stating
  whether it affects the registered analysis of `fba-allergy-online-02`;
- any change that can alter a reported number, including a bug fix, is a
  deviation from the registered analysis and is labelled as such here.

### Contents

- **Import from JATOS.**  
  [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md)
  downloads the results of one or more batches. It reads the complete
  jsPsych data from the result file when the experiment uploaded one
  (`result_file`), falls back on the streamed data otherwise, records
  the source of every study result in `data_source` and reports the
  trials the file recovered
  ([\#38](https://github.com/josefmana/catlasr/issues/38)).
  [`parse_jatos_results()`](https://josefmana.github.io/catlasr/reference/parse_jatos_results.md)
  and
  [`repair_jatos_json()`](https://josefmana.github.io/catlasr/reference/repair_jatos_json.md)
  turn the results into trial tables.

- **Data bundles and provenance.**  
  [`build_provenance()`](https://josefmana.github.io/catlasr/reference/build_provenance.md)
  records where the data come from
  ([\#26](https://github.com/josefmana/catlasr/issues/26));
  [`build_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/build_fba_rawdata.md)
  builds and
  [`validate_fba_rawdata()`](https://josefmana.github.io/catlasr/reference/validate_fba_rawdata.md)
  validates a forward-blocking bundle of participant metadata, stimulus
  mappings and trials, checking the trials against the design registry
  and aborting on imbalanced complete runs. Bundles refuse identifying
  and free-text columns; `sex` and `age` are optional, so that shared
  data sets can leave them out.

- **Exclusions.**  
  [`record_exclusion()`](https://josefmana.github.io/catlasr/reference/record_exclusion.md)
  removes participants and records the exclusion rule, its description
  and the participants it removed in the provenance. A provenance can
  also carry deferred exclusions, each naming the analysis set it leads
  to, so that a shared data set can hold just one sample from which all
  analysis sets are derived. `print(provenance(x))` lists the rules by
  name and count; `exclusions = "long"` adds their descriptions.

- **Learning check.**  
  [`score_learning()`](https://josefmana.github.io/catlasr/reference/score_learning.md),
  [`test_learning()`](https://josefmana.github.io/catlasr/reference/test_learning.md)
  (one-sided exact binomial test against chance, `alpha = 0.1`),
  [`screen_learning()`](https://josefmana.github.io/catlasr/reference/screen_learning.md),
  [`aggregate_learning()`](https://josefmana.github.io/catlasr/reference/aggregate_learning.md)
  and
  [`plot_learning()`](https://josefmana.github.io/catlasr/reference/plot_learning.md).

- **Blocking indices.**  
  [`score_blocking()`](https://josefmana.github.io/catlasr/reference/score_blocking.md)
  scores the test stage, dropping the confidence rating of timed-out
  test trials;
  [`index_blocking()`](https://josefmana.github.io/catlasr/reference/index_blocking.md)
  computes the confidence-weighted choice score of Beesley and Le
  Pelley (2011) and the choice-proportion score of Paskewitz and
  Jones (2020) ([\#34](https://github.com/josefmana/catlasr/issues/34));
  [`aggregate_blocking()`](https://josefmana.github.io/catlasr/reference/aggregate_blocking.md)
  and
  [`plot_blocking()`](https://josefmana.github.io/catlasr/reference/plot_blocking.md).

- **Personal data.**  
  [`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md),
  [`write_private_csv()`](https://josefmana.github.io/catlasr/reference/write_private_csv.md)
  and
  [`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md)
  keep personal data in a private folder outside every repository
  ([\#16](https://github.com/josefmana/catlasr/issues/16)), with one
  subfolder per study and a guard against subfolders that link
  elsewhere.
  [`update_id_key()`](https://josefmana.github.io/catlasr/reference/update_id_key.md)
  replaces platform identifiers with random six-digit participant IDs,
  keeping the key in the private folder.
  [`write_debrief_coding()`](https://josefmana.github.io/catlasr/reference/write_debrief_coding.md)
  and
  [`read_debrief_coding()`](https://josefmana.github.io/catlasr/reference/read_debrief_coding.md)
  code the free-text debriefing answers blind to the test data
  ([\#40](https://github.com/josefmana/catlasr/issues/40)).

- **Monitoring.**  
  [`trace_progress()`](https://josefmana.github.io/catlasr/reference/trace_progress.md)
  reports how far every participant got, without reading any test
  response.

- **Stimuli.**  
  [`catlas_stimulus()`](https://josefmana.github.io/catlasr/reference/catlas_stimulus.md),
  [`render_stimulus()`](https://josefmana.github.io/catlasr/reference/render_stimulus.md)
  and
  [`write_stimulus()`](https://josefmana.github.io/catlasr/reference/write_stimulus.md)
  compose the cue and outcome images of the allergist task.

- **Data scripts.**  
  `data-raw/` holds the import of `fba-allergy-online-02`, which builds
  the shared data set `fba_allergy_online_02` (the Full sample, with the
  learning and prior-knowledge rules deferred;
  [\#39](https://github.com/josefmana/catlasr/issues/39)), and the
  e-mail exports of both studies. They are not part of the installed
  package.
