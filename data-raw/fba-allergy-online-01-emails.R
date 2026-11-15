# fba-allergy-online-01-emails.R
#
# Export the participant ID and e-mail pairs of `fba-allergy-online-01`.
#
# Deliberately separate from the import vignette: e-mail addresses are needed
# for administration (contacting participants), never for analysis, and must
# never sit next to the data or inside a repository.
#
# The CSV goes to the study folder `fba-allergy-online-01` of the private
# folder, named by `CATLAS_PRIVATE_DIR` in `.Renviron`
# (`usethis::edit_r_environ()`); `write_private_csv()` refuses any folder
# inside a git work tree.
#
# Requires the same token and packages as the import vignette.

library(catlasr)
library(dplyr)

batch_ids <- c(
  30206L, # precedes the debriefing variable naming patch (`forward-blocking-replication-online-pre-pilot`)
  30275L, # LABELS
  30832L, # acquaintances
  30829L  # family
)

results <-
  pull_jatos_batches(
    url = "https://jatos.mindprobe.eu",
    batch_ids = batch_ids,
    token = Sys.getenv("mindprobe_catlas_token")
  ) |>
  parse_jatos_results()

# The e-mail screen repeats until the entry is valid, so the last non-missing
# entry of a result is the one that counts. Builds that skip the screen
# (English-language runs from 18 June 2026 on) have no `email` column at all.
last_email <- function(trials) {
  if (!"email" %in% names(trials)) {
    return(NA_character_)
  }
  entries <- trials$email[trials$trial_type %in% "email-collection" & !is.na(trials$email)]
  if (length(entries) == 0L) NA_character_ else entries[[length(entries)]]
}

emails <-
  results |>
  filter(has_data) |>
  mutate(
    id,
    email = vapply(jspsych, last_email, character(1L)),
    .keep = "none"
  ) |>
  filter(!is.na(email), email != "x") # "x" is the anonymous-participation answer

path <- write_private_csv(
  emails,
  file = "fba-allergy-online-01/emails.csv",
  overwrite = TRUE
)

cli::cli_alert_success(
  "Wrote {nrow(emails)} ID/e-mail pair{?s} to {.path {path}}."
)
