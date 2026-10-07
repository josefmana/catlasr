#' Format one argument of a reconstructed call
#'
#' @param name Character(1). Argument name.
#' @param code Character(1). The argument's value as R source text.
#'
#' @returns Character(1), one line.
#'
#' @noRd
.fmt_call_arg <- function(name, code) {
  sprintf("  %-17s = %s", name, code)
}


#' Render a provenance record as the `build_provenance()` call that runs it
#'
#' Built from the values the user typed rather than by deparsing the
#' constructed object, because `deparse()` of a POSIXct prints its
#' `structure(..., class = ...)` internals and is not pasteable.
#'
#' @param a A named list of the collected values, as assembled by
#'   [.provenance_wizard()].
#'
#' @returns Character vector, one element per line.
#'
#' @noRd
.deparse_provenance_call <- function(a) {
  quoted <- function(x) {
    if (is.null(x) || is.na(x)) {
      "NA"
    } else {
      encodeString(x, quote = '"')
    }
  }

  blocks_code <- sprintf(
    "c(%s)",
    paste(sprintf("%s = %dL", names(a$blocks), a$blocks), collapse = ", ")
  )

  origin_code <- c(
    "list(",
    sprintf('    platform  = %s,', quoted(a$origin$platform)),
    sprintf('    url       = %s,', quoted(a$origin$url)),
    sprintf('    study_id  = %s,', quoted(a$origin$study_id)),
    sprintf(
      "    batch_ids = %s",
      if (length(a$origin$batch_ids) == 0L) {
        "integer(0)"
      } else {
        sprintf("c(%s)", paste0(a$origin$batch_ids, "L", collapse = ", "))
      }
    ),
    "  )"
  )

  build_code <- c(
    "list(",
    sprintf('    repo    = %s,', quoted(a$experiment_build$repo)),
    sprintf('    release = %s,', quoted(a$experiment_build$release)),
    sprintf('    commit  = %s', quoted(a$experiment_build$commit)),
    "  )"
  )

  collected_code <- if (is.null(a$collected_between)) {
    "NULL"
  } else {
    sprintf(
      'c(first = as.Date("%s"), last = as.Date("%s"))',
      a$collected_between[["first"]],
      a$collected_between[["last"]]
    )
  }

  retrieved_code <- sprintf(
    'as.POSIXct("%s", tz = "UTC")',
    format(a$retrieved_at, "%Y-%m-%d %H:%M:%S", tz = "UTC")
  )

  notes_code <- if (length(a$notes) == 0L) {
    "character()"
  } else {
    quoted(a$notes)
  }

  c(
    "build_provenance(",
    paste0(.fmt_call_arg("study",       quoted(a$study)), ","),
    paste0(.fmt_call_arg("design",      quoted(a$design)), ","),
    paste0(.fmt_call_arg("blocks",      blocks_code), ","),
    paste0(.fmt_call_arg("trial_types", sprintf("%dL", a$trial_types)), ","),
    paste0(.fmt_call_arg("origin",      origin_code[1L])),
    paste0(origin_code[-1L], collapse = "\n") |> paste0(","),
    paste0(.fmt_call_arg("collected_between", collected_code), ","),
    paste0(.fmt_call_arg("retrieved_at",      retrieved_code), ","),
    paste0(.fmt_call_arg("experiment_build",  build_code[1L])),
    paste0(build_code[-1L], collapse = "\n") |> paste0(","),
    .fmt_call_arg("notes", notes_code),
    ")"
  )
}


#' Collect a provenance record by prompting at the console
#'
#' Asks for each field in turn, validating as it goes. Finishes by printing the
#' equivalent [build_provenance()] call.
#'
#' @returns A validated `catlas_provenance` object.
#'
#' @noRd
.provenance_wizard <- function() {
  if (!rlang::is_interactive()) {
    cli::cli_abort(c(
            "`guided = TRUE` needs an interactive session.",
      "i" = "In a script or a Quarto chunk, pass the fields directly."
    ))
  }

  cli::cli_h1("Provenance record")

  study <- .ask(
    "Study identifier (e.g. fba-allergy-online-01)",
    validate = \(a) .resolve_study_id(a)
  )

  design <- .ask_choice(
    "Which of the following study designs was used?",
    .catlas_designs
  )
  stages <- .design_spec(design)$stages

  cli::cli_h2("Block counts")
  cli::cli_text("How many blocks did each stage consist of?")
  blocks <- vapply(
    stages,
    \(s) .ask_integer(sprintf("  blocks in %s", s)),
    integer(1L)
  )

  trial_types <- .ask_integer("Distinct trial types per block", default = 8L)

  cli::cli_h2("Where did the data come from?")
  platform  <- .ask_choice("Collection platform:", .catlas_platforms)
  synthetic <- identical(platform, "synthetic")

  origin <- list(
    platform  = platform,
    url       = .ask("Platform URL",      required = !synthetic),
    study_id  = .ask("Platform study ID", required = !synthetic),
    batch_ids = if (identical(platform, "JATOS")) {
      .ask_integers("Batch ids, comma separated")
    } else {
      integer(0L)
    }
  )

  cli::cli_h2("When did data collection take place?")

  collected_between <- if (synthetic) {
    NULL
  } else {
    first <- .ask_date("First day of collection, YYYY-MM-DD")
    last  <- .ask_date("Last day of collection, YYYY-MM-DD")
    c(first = first, last = last)
  }

  retrieved_date <- .ask_date(
    "Retrieval date (YYYY-MM-DD)",
    default = format(Sys.Date())
  )

  # Use the actual moment when the date is today,
  # and use midnight UTC for a date in the past
  retrieved_at <- if (identical(retrieved_date, Sys.Date())) {
    Sys.time()
  } else {
    as.POSIXct(retrieved_date, tz = "UTC")
  }

  cli::cli_h2("Which experiment build produced the data?")
  experiment_build <- list(
    repo    = .ask("Experiment repository", default = "josefmana/catlaslab"),
    release = .ask("Release tag, blank if none", required = FALSE),
    commit  = .ask("Commit SHA, blank if none", required = FALSE)
  )

  if (!synthetic && is.na(experiment_build$release) && is.na(experiment_build$commit)) {
    cli::cli_alert_danger("Empirical data need a release tag or a commit.")
    experiment_build$commit <- .ask("Commit SHA")
  }

  notes <- .ask("Notes (keep blank to skip)", required = FALSE)

  args <- list(
    study             = study,
    design            = design,
    blocks            = blocks,
    trial_types       = trial_types,
    origin            = origin,
    collected_between = collected_between,
    retrieved_at      = retrieved_at,
    experiment_build  = experiment_build,
    notes             = if (is.na(notes)) character() else notes
  )

  # Deliberately without `guided`: this is the non-interactive path, and
  # passing it through would recurse until the stack gave out.
  obj <- do.call(build_provenance, args)

  cli::cli_h2("Equivalent call")
  cli::cli_text("Paste this into the import script so that next time you need no prompts.")
  cat("\n")
  cat(.deparse_provenance_call(args), sep = "\n")
  cat("\n")

  obj
}
