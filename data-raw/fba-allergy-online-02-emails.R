# fba-allergy-online-02-emails.R
#
# Export the e-mail addresses of `fba-allergy-online-02`, given solely for
# LABELS credit, keyed by the JATOS study result ID.
#
# Deliberately separate from the import script, as e-mail addresses are needed
# for administration (confirming participation to LABELS), not for data
# analysis, and must never sit next to the data or inside a repository. Delete
# the file once the participation has been confirmed.
#
# The CSV goes to the study folder within the folder named by
# `CATLAS_PRIVATE_DIR` in `.Renviron` (accessed, e.g. via
# `usethis::edit_r_environ()`); `write_private_csv()` refuses any folder inside
# a git work tree.
#
# Requires the same token and settings as `fba-allergy-online-02.R`.

library(catlasr)
library(dplyr)

test_run <- TRUE

# The study folder within the private folder
run <- if (test_run) "fba-allergy-online-02-test" else "fba-allergy-online-02"
batch_ids <- if (test_run) {
  33692L # Test runs of the experimenter
} else {
  integer() # The LABELS batch(es), added at release
}

results <-
  pull_jatos_batches(
    url = "https://jatos.mindprobe.eu",
    batch_ids = batch_ids,
    token = Sys.getenv("mindprobe_catlas_token"),
    result_file = "jspsych-data.json"
  ) |>
  parse_jatos_results()

# The e-mail screen repeats until the entry is valid, and every attempt stays
# in the data, so only the entry marked valid counts.
valid_email <- function(trials) {
  if (!all(c("email", "valid_email") %in% names(trials))) {
    return(NA_character_)
  }
  entries <- trials$email[
    trials$trial_type %in% "email-collection" &
      trials$valid_email %in% TRUE &
      !is.na(trials$email)
  ]
  if (length(entries) == 0L) NA_character_ else entries[[length(entries)]]
}

emails <-
  results |>
  filter(has_data) |>
  mutate(
    id_sr,
    email = vapply(jspsych, valid_email, character(1L)),
    .keep = "none"
  ) |>
  # "x" is the anonymous-participation answer
  filter(!is.na(email), email != "x")

path <- write_private_csv(
  emails,
  file = file.path(run, "emails.csv"),
  overwrite = TRUE
)

cli::cli_alert_success(
  "Wrote {nrow(emails)} study result/e-mail pair{?s} to {.path {path}}."
)
