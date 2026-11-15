# fba-allergy-online-02.R
#
# Import `fba-allergy-online-02` from JATOS, apply the registered exclusion
# rules (CATLAS appendix A1, AP1) in their registered order, save the four
# analysis bundles to the study folder in the private folder and, for the study
# proper, the anonymised Full sample, with the remaining rules deferred, as the
# package data set `fba_allergy_online_02`.
#
# The script never peeks at the test stage data: blocking indices are computed
# in the CATLAS analysis notebooks only, after the import is complete.
#
# Can run repeatedly as data arrive. The participant ID key and the debriefing
# coding file in the study folder grow with every run, so earlier IDs and
# codes stay as they were. The run stops at rule 5 until every free-text answer
# in the coding file is coded for experiment purpose guessing.
#
# Requires the JATOS token in `mindprobe_catlas_token` and the private folder
# in `CATLAS_PRIVATE_DIR` (both in `.Renviron`, accessed via
# `usethis::edit_r_environ()`).
#
# E-mail addresses are exported separately by `fba-allergy-online-02-emails.R`.

library(catlasr)
library(dplyr)
library(tidyr)
library(purrr)


# ---- Settings ----------------------------------------------------------------

# Test runs read the test batch, keep every private file in the study folder
# `fba-allergy-online-02-test/` and never write the package data set. Set to
# FALSE once the study batches are live.
test_run <- TRUE

# The study folder within the private folder
run <- if (test_run) "fba-allergy-online-02-test" else "fba-allergy-online-02"
jatos_url <- "https://jatos.mindprobe.eu"
study_id <- "fba-allergy-online-02"
batch_ids <- if (test_run) {
  33692L # Test runs of the experimenter
} else {
  integer() # The LABELS batch(es), added at release
}

# The registered exclusion rules, verbatim as in CATLAS A1 (AP1), in the order
# they are applied. The learning rule is completed from the design below.
rule_texts <- c(
  declined_consent = paste(
    "The participant declined on the informed-consent screen. Declining ends",
    "the experiment and deletes the data recorded so far, so that JATOS keeps",
    "only the study result, in the state ABORTED."
  ),
  no_jspsych_data = paste(
    "The JATOS study result holds no jsPsych data that can be parsed, for",
    "instance because the study link was opened but no trial record reached",
    "the server."
  ),
  incomplete_run = paste(
    "The run does not contain at least one complete test block of %d trials."
  ),
  learning_not_reliably_above_chance = paste(
    "The participant did not score significantly above chance in at least",
    "one of the three learning stages, as decided by a one-sided exact",
    "binomial test of the number of correct responses against 0.5 at alpha =",
    "%.2f over all answered trials of the stage (timed-out trials excluded).",
    "On complete data, fewer than %d of %d correct in Stage 1, %d of %d in",
    "Stage 2, or %d of %d in Stage 3. A stage without any answered trial",
    "counts as failed."
  ),
  prior_knowledge_reported = paste(
    "The participant answered yes to the debriefing question \"Before today,",
    "have you taken part in an experiment in which you predicted reactions",
    "from foods or medicines?\", their answer to the debriefing question",
    "\"Did you know or guess what this study tested? If so, describe it.\"",
    "was coded as describing blocking, or the debriefing screen timed out or",
    "was not reached. An answer describes blocking if it states that learning",
    "about a cue is reduced when the cue is presented together with a cue",
    "that already predicts the outcome, or if it names blocking, cue",
    "competition or learned (in)attention. Answers that describe only the",
    "surface of the task (predicting side effects, memory, attention or",
    "learning in general) do not. The answers are coded before any blocking",
    "index is computed."
  )
)

learning_alpha <- 0.10


# ---- 1. Download and parse ---------------------------------------------------

jatos_data <- pull_jatos_batches(
  url = jatos_url,
  batch_ids = batch_ids,
  token = Sys.getenv("mindprobe_catlas_token"),
  result_file = "jspsych-data.json"
)

results <- parse_jatos_results(jatos_data)


# ---- 2. Random participant IDs -----------------------------------------------

# Before anything else, the JATOS study result IDs give way to random IDs kept
# in a private key; nothing below sees a JATOS identifier.
results$id <- update_id_key(
  ids = results$id_sr,
  file = file.path(run, "id-key.rds")
)

jspsych <-
  results |>
  filter(has_data) |>
  select(id, jspsych) |>
  unnest(jspsych)

count(
  results,
  study_state,
  data_source,
  has_data
)


# ---- 3. Provenance -----------------------------------------------------------

prov <- build_provenance(
  study = "fba-allergy-online-02",
  design = "three-stage-replication",
  blocks = c(
    stage1 = 10L,
    stage2 = 8L,
    stage3 = 6L,
    test = 6L
  ),
  trial_types = 8L,
  origin = list(
    platform = "JATOS",
    url = jatos_url,
    study_id = study_id,
    batch_ids = batch_ids
  ),
  collected_between = c(
    first = as.Date(
      min(results$start_date_sr, na.rm = TRUE),
      tz = "Europe/Prague"
    ),
    last = as.Date(
      max(results$start_date_sr, na.rm = TRUE),
      tz = "Europe/Prague"
    )
  ),
  retrieved_at = attr(jatos_data, "retrieved_at"),
  experiment_build = list(
    repo = "josefmana/catlaslab",
    release = "fba-allergy-online-02",
    commit = NA_character_ # The release commit, once tagged
  ),
  notes = if (test_run) {
    "Test runs of the experimenter before release; not study data."
  } else {
    character()
  }
)


# ---- 4. Components -----------------------------------------------------------

# The debriefing contains: the yes/no answer to question (a), whether the screen
# timed out, and the free text of question (b), which goes to the coding file
# only (section 7). Taken from the debriefing records alone, since experiment
# trials carry a `timed_out` column too. The optional comment is not imported.
debrief <-
  jspsych |>
  filter(trial_type == "debrief") |>
  summarise(
    prior_knowledge = as.logical(first(prior_knowledge)),
    prior_guess = as.character(first(prior_guess)),
    debrief_timed_out = as.logical(first(timed_out)),
    .by = id
  )

meta_cols <- c(
  "sex",
  "age",
  "width",
  "height",
  "browser",
  "browser_version",
  "os",
  "vsync_rate"
)

meta <-
  results |>
  mutate(
    duration_min = if_else(
      study_state == "FINISHED",
      as.numeric(difftime(end_date_sr, start_date_sr, units = "mins")),
      NA_real_
    )
  ) |>
  select(
    id,
    batch_id,
    data_source,
    duration_min
  ) |>
  left_join(
    jspsych |>
      select(id, all_of(meta_cols)) |>
      summarise(across(everything(), \(x) first(na.omit(x))), .by = id),
    by = "id"
  ) |>
  left_join(
    select(debrief, id, prior_knowledge, debrief_timed_out),
    by = "id"
  ) |>
  mutate(age = as.numeric(age))

cue_labels <- c(LETTERS, "alpha", "beta")
outcome_labels <- paste0("o", 1:4)

stimuli <-
  jspsych |>
  filter(trial_type == "stimuli-map") |>
  mutate(map = map2(cueMap, outcomeMap, function(cues, outcomes) {
    bind_cols(
      tibble::as_tibble(jsonlite::fromJSON(cues)),
      tibble::as_tibble(jsonlite::fromJSON(outcomes))
    )
  })) |>
  select(id, map) |>
  unnest(map) |>
  select(
    id,
    all_of(cue_labels),
    all_of(outcome_labels)
  ) |>
  mutate(
    across(
      all_of(outcome_labels),
      \(x) sub("_.*$", "", x),
      .names = "{.col}_context"
    ),
    across(all_of(outcome_labels), \(x) sub("^.*_", "", x))
  )

cues_map <- fba_cues_map(prov$design)

trial_cols <- c(
  "stage",
  "block",
  "type",
  "cues",
  "response",
  "is_correct",
  "confidence",
  "rt1",
  "rt2",
  "timed_out"
)

trials <-
  jspsych |>
  filter(trial_type == "experiment-trial") |>
  select(
    id,
    all_of(trial_cols)
  ) |>
  left_join(
    cues_map,
    by = c("cues" = "label")
  ) |>
  relocate(cue1, cue2, cues_reversed, .after = type) |>
  select(-cues)

if (anyNA(trials$cue1)) {
  cli::cli_abort("Some recorded cue strings do not resolve via the design.")
}


# ---- 5. Build ----------------------------------------------------------------

# Warnings here are expected: they name the records without data and the runs
# that stopped early, which the rules below exclude.
fba <- fba_imported <- build_fba_rawdata(
  meta = meta,
  stimuli = stimuli,
  trials = trials,
  provenance = prov
)

rebuild <- function(x) {
  build_fba_rawdata(
    meta = extract_meta(x),
    stimuli = extract_stimuli(x),
    trials = extract_trials(x),
    provenance = provenance(x)
  )
}

present <- function(ids, x) {
  intersect(as.character(ids), extract_meta(x)$id)
}


# ---- 6. Rules 1 to 3 (structural) --------------------------------------------

# Rule 1: declining consent aborts the JATOS run, which deletes its data, so
# the decline is read from the study state
fba <- record_exclusion(
  fba,
  rule = "declined_consent",
  description = rule_texts[["declined_consent"]],
  ids = present(results$id[results$study_state %in% "ABORTED"], fba)
)

# Rule 2
fba <- record_exclusion(
  fba,
  rule = "no_jspsych_data",
  description = rule_texts[["no_jspsych_data"]],
  ids = present(results$id[!results$has_data], fba)
)

# Rule 3
n_types <- provenance(fba)$trial_types
test_counts <-
  extract_meta(fba) |>
  select(id) |>
  left_join(
    extract_trials(fba) |>
      summarise(
        n = sum(stage == "test"),
        .by = id
      ),
    by = "id"
  ) |>
  mutate(n = coalesce(n, 0L))

fba <- record_exclusion(
  fba,
  rule = "incomplete_run",
  description = sprintf(rule_texts[["incomplete_run"]], n_types),
  ids = test_counts$id[test_counts$n < n_types]
)

fba <- fba_full <- rebuild(fba)


# ---- 7. Rule 4 (learning) ----------------------------------------------------

learning_scores <- score_learning(fba)
learning_tests <- test_learning(learning_scores, alpha = learning_alpha)
learning_screen <- screen_learning(learning_tests, rule = "any")

stages <- c("stage1", "stage2", "stage3")
n_stage <- provenance(fba)$blocks[stages] * provenance(fba)$trial_types
k_stage <- stats::qbinom(1 - learning_alpha, n_stage, 0.5) + 1

fba <- record_exclusion(
  fba,
  rule = "learning_not_reliably_above_chance",
  description = sprintf(
    rule_texts[["learning_not_reliably_above_chance"]],
    learning_alpha,
    k_stage[1], n_stage[1],
    k_stage[2], n_stage[2],
    k_stage[3], n_stage[3]
  ),
  ids = learning_screen$id[learning_screen$exclude]
)

fba <- fba_learned <- rebuild(fba)


# ---- 8. Rule 5 (prior knowledge), coded blind to the test data ---------------

# Every participant of the Learned set gets a row in the coding file, those
# who never reached the debriefing too (with no answer, coded FALSE in advance).
# The run stops at `read_debrief_coding()` until every answer is coded.
learned_ids <- extract_meta(fba)$id
coding_file <- file.path(run, "debrief-coding.csv")

write_debrief_coding(
  debrief = tibble::tibble(id = learned_ids) |>
    left_join(
      select(debrief, id, prior_knowledge, prior_guess),
      by = "id"
    ),
  file = coding_file,
  rule = rule_texts[["prior_knowledge_reported"]]
)

# The participants coded FALSE, i.e., not naive to blocking
coded_not_naive <- read_debrief_coding(
  file = coding_file,
  ids = learned_ids
)

meta_learned <- extract_meta(fba)
not_naive <- meta_learned$id[
  meta_learned$prior_knowledge %in% TRUE |
    meta_learned$id %in% coded_not_naive |
    meta_learned$debrief_timed_out %in% TRUE |
    is.na(meta_learned$debrief_timed_out)
]

fba <- record_exclusion(
  fba,
  rule = "prior_knowledge_reported",
  description = rule_texts[["prior_knowledge_reported"]],
  ids = not_naive
)

fba <- rebuild(fba)
fba_naive <- validate_fba_rawdata(fba)

provenance(fba_naive)


# ---- 9. Save ----------------------------------------------------------------

bundles <- list(
  imported = fba_imported,
  full = fba_full,
  learned = fba_learned,
  naive = fba_naive
)

for (set in names(bundles)) {
  write_private_rds(
    bundles[[set]],
    file = file.path(run, paste0(set, ".rds")),
    overwrite = TRUE
  )
}


# ---- 10. Shared data set -----------------------------------------------------

# The shared data set is the Full sample, for which only the structural
# exclusion rules 1 to 3 are applied, since they only remove runs without any
# usable data. Rules 4 and 5 are recorded as deferred exclusions, each with the
# analysis set it leads to, so that users can choose the set themselves.
shared_meta_cols <- c(
  "id",
  "batch_id",
  "data_source",
  "duration_min",
  "width",
  "height",
  "browser",
  "browser_version",
  "os",
  "vsync_rate",
  "prior_knowledge",
  "debrief_timed_out"
)

shared_trial_cols <- c(
  "id",
  "stage",
  "block",
  "type",
  "cue1",
  "cue2",
  "cues_reversed",
  "response",
  "is_correct",
  "confidence",
  "rt1",
  "rt2",
  "timed_out"
)

# The analysis set each deferred rule leads to
deferred_sets <- c(
  learning_not_reliably_above_chance = "learned",
  prior_knowledge_reported = "naive"
)

rules_applied <- map_chr(provenance(fba_full)$exclusions, "rule")
deferred <- keep(
  provenance(fba_naive)$exclusions,
  \(e) !e$rule %in% rules_applied
)

if (!identical(map_chr(deferred, "rule"), names(deferred_sets))) {
  cli::cli_abort("The deferred rules must be rules 4 and 5, in this order.")
}

fba_allergy_online_02 <- build_fba_rawdata(
  meta = select(extract_meta(fba_full), all_of(shared_meta_cols)),
  stimuli = extract_stimuli(fba_full),
  trials = select(extract_trials(fba_full), all_of(shared_trial_cols)),
  provenance = provenance(fba_full)
)

fba_allergy_online_02$provenance$analysis_set <- "full"
fba_allergy_online_02$provenance$deferred_exclusions <- map(
  deferred,
  \(e) c(e, list(set = deferred_sets[[e$rule]]))
)

fba_allergy_online_02 <- validate_fba_rawdata(fba_allergy_online_02)
provenance(fba_allergy_online_02)

if (!test_run) {
  usethis::use_data(
    fba_allergy_online_02,
    overwrite = TRUE,
    compress = "xz"
  )
}
