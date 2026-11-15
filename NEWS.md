# catlasr 0.0.1

First pre-release, tagged `v0.0.1` before data collection of
`fba-allergy-online-02`, the pre-registered replication of three-stage forward
blocking (Beesley & Le Pelley, 2011). The pre-registration names this version
and its preprocessing functions, which are frozen from this tag on. The
pre-release contains no data.

## Freeze policy

The preprocessing layer is frozen at `v0.0.1` (#32). It covers every exported
function that imports, validates, excludes or scores data:

* **import:** `pull_jatos_batches()`, `parse_jatos_results()`,
  `repair_jatos_json()`;
* **data bundles:** `build_provenance()`, `build_fba_rawdata()`,
  `validate_fba_rawdata()`, `record_exclusion()`, `provenance()`,
  `extract_meta()`, `extract_stimuli()`, `extract_trials()`, `fba_cues_map()`;
* **personal data:** `update_id_key()`, `write_debrief_coding()`,
  `read_debrief_coding()`, `write_private_rds()`, `write_private_csv()`,
  `read_private_rds()`;
* **learning check:** `score_learning()`, `test_learning()`,
  `screen_learning()`, `aggregate_learning()`;
* **blocking indices:** `score_blocking()`, `index_blocking()`,
  `aggregate_blocking()`.

The plotting functions, `trace_progress()` and the stimulus functions do not
change any reported number and stay outside the freeze.

The exported surface of this version, every exported function and S3 method
with its arguments and defaults, is recorded in `inst/api/v0.0.1.txt`. From
this tag on:

* every change to a frozen function gets an entry in this file stating whether
  it affects the registered analysis of `fba-allergy-online-02`;
* any change that can alter a reported number, including a bug fix, is a
  deviation from the registered analysis and is labelled as such here.

## Contents

* **Import from JATOS.**  
  `pull_jatos_batches()` downloads the results of one or more batches. It reads
  the complete jsPsych data from the result file when the experiment uploaded
  one (`result_file`), falls back on the streamed data otherwise, records the
  source of every study result in `data_source` and reports the trials the file
  recovered (#38). `parse_jatos_results()` and `repair_jatos_json()` turn the
  results into trial tables.

* **Data bundles and provenance.**  
  `build_provenance()` records where the data come from (#26);
  `build_fba_rawdata()` builds and `validate_fba_rawdata()` validates a
  forward-blocking bundle of participant metadata, stimulus mappings and trials,
  checking the trials against the design registry and aborting on imbalanced
  complete runs. Bundles refuse identifying and free-text columns; `sex` and
  `age` are optional, so that shared data sets can leave them out.

* **Exclusions.**  
  `record_exclusion()` removes participants and records the exclusion rule, its
  description and the participants it removed in the provenance. A provenance
  can also carry deferred exclusions, each naming the analysis set it leads to,
  so that a shared data set can hold just one sample from which all analysis
  sets are derived. `print(provenance(x))` lists the rules by name and count;
  `exclusions = "long"` adds their descriptions.

* **Learning check.**  
  `score_learning()`, `test_learning()` (one-sided exact binomial test against
  chance, `alpha = 0.1`), `screen_learning()`, `aggregate_learning()` and
  `plot_learning()`.

* **Blocking indices.**  
  `score_blocking()` scores the test stage, dropping the confidence rating of
  timed-out test trials; `index_blocking()` computes the confidence-weighted
  choice score of Beesley and Le Pelley (2011) and the choice-proportion score
  of Paskewitz and Jones (2020) (#34); `aggregate_blocking()` and
  `plot_blocking()`.

* **Personal data.**  
  `write_private_rds()`, `write_private_csv()` and `read_private_rds()` keep
  personal data in a private folder outside every repository (#16), with one
  subfolder per study and a guard against subfolders that link elsewhere.
  `update_id_key()` replaces platform identifiers with random six-digit
  participant IDs, keeping the key in the private folder.
  `write_debrief_coding()` and `read_debrief_coding()` code the free-text
  debriefing answers blind to the test data (#40).

* **Monitoring.**  
  `trace_progress()` reports how far every participant got, without reading any
  test response.

* **Stimuli.**  
  `catlas_stimulus()`, `render_stimulus()` and `write_stimulus()` compose the
  cue and outcome images of the allergist task.

* **Data scripts.**  
  `data-raw/` holds the import of `fba-allergy-online-02`, which builds the
  shared data set `fba_allergy_online_02` (the Full sample, with the learning
  and prior-knowledge rules deferred; #39), and the e-mail exports of both
  studies. They are not part of the installed package.
