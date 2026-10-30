# Study identifier grammar: <prefix>-<task>-<mode>-<wave>
# The prefix names the manuscript family and must match the raw-data subclass.
.study_id_pattern <- "^([a-z]+)-([a-z0-9]+)-([a-z]+)-([0-9]{2})$"

# Recognised study prefixes, task types, and data-collection modes:
.catlas_prefixes <- c(
  "fba"
)

.catlas_tasks <- c(
  "allergy"
)

.catlas_modes <- c(
  "online",
  "lab",
  "eye",
  "eeg"
)

# Recognised data origins
.catlas_platforms <- c(
  "JATOS",
  "Prolific",
  "OSF",
  "synthetic" # For simulated data
)


#' Resolve and parse a CATLAS study identifier
#'
#' The study identity is a property of the pull, not of any derivative, so it
#' is resolved once at construction and stored on the object. Every consumer
#' reads `provenance(x)$mode` rather than re-parsing the string.
#'
#' Components are **derived**, never supplied separately. Supplying `mode`
#' alongside `study` admits a state where the two disagree.
#'
#' @param study Character(1). Identifier of the form `fba-allergy-online-01`.
#' @param arg Character(1). Name used in error messages.
#' @param call Environment for error reporting.
#'
#' @returns A list with `study`, `prefix`, `task`, `mode` and `wave`.
#'
#' @noRd
.resolve_study_id <- function(
    study,
    arg = "study",
    call = rlang::caller_env()
) {
  if (!is.character(study) || length(study) != 1L || is.na(study)) {
    study_class <- paste(class(study), collapse = " / ")
    cli::cli_abort(c(
            "`{arg}` must be a single non-missing character string.",
      "x" = "Received an object of class {study_class} of length {length(study)}."
    ), call = call)
  }

  parts <- regmatches(study, regexec(.study_id_pattern, study))[[1L]]
  if (length(parts) != 5L) {
    cli::cli_abort(c(
            "`{arg}` must follow the {.val <prefix>-<task>-<mode>-<wave>} grammar.",
      "i" = "For example {.val fba-allergy-online-01}.",
      "x" = "Received {.val {study}}."
    ), call = call)
  }

  prefix <- parts[2L]
  if (!prefix %in% .catlas_prefixes) {
    cli::cli_abort(c(
            "`{arg}` contains an unrecognised study prefix.",
      "x" = "Found prefix: {.val {prefix}}.",
      "i" = "Recognised prefix{?s}: {.val {(.catlas_prefixes)}}.",
      "i" = "Study prefix is located first within the study id and indicates manuscript family or study type.",
      "i" = "E.g., `fba` in `fba-allergy-online-01` refers to `forward-blocking-attention` studies."
    ), call = call)
  }

  task <- parts[3L]
  if (!task %in% .catlas_tasks) {
    cli::cli_abort(c(
            "`{arg}` contains an unrecognised experimental task.",
      "x" = "Found task: {.val {task}}.",
      "i" = "Recognised task{?s}: {.val {(.catlas_tasks)}}.",
      "i" = "Experimental task is located second within the study id and indicates what cover story and task were used in the experiment.",
      "i" = "E.g., `allergy` in `fba-allergy-online-01` refers to the (in)famous {.emph allergy prediction} family of tasks."
    ), call = call)
  }

  mode <- parts[4L]
  if (!mode %in% .catlas_modes) {
    cli::cli_abort(c(
            "`{arg}` contains an unrecognised collection mode.",
      "x" = "Found mode: {.val {mode}}.",
      "i" = "Recognised mode{?s}: {.val {(.catlas_modes)}}.",
      "i" = "Data collection mode is located third within the study id and indicates how were the data collected.",
      "i" = "E.g., `online` in `fba-allergy-online-01` refers to an online experiment distributed via JATOS."
    ), call = call)
  }

  list(
    study  = study,
    prefix = prefix,
    task   = task,
    mode   = mode,
    wave   = as.integer(parts[5L])
  )
}


#' Is a field effectively absent?
#'
#' `NULL`, `NA`, `""` and anything that is not a single value all mean "this
#' field was not filled in".
#'
#' @param x A provenance field.
#'
#' @returns `TRUE` when the field carries no usable value.
#'
#' @noRd
.is_blank <- function(x) {
  is.null(x) || length(x) != 1L || is.na(x) || !nzchar(as.character(x))
}


#' First non-blank candidate, or a fallback
#'
#' @param ... Candidates, tried in order.
#' @param fallback Character(1) returned when every candidate is blank.
#'
#' @returns Character(1).
#'
#' @noRd
.first_present <- function(..., fallback = "unknown") {
  for (v in list(...)) {
    if (!.is_blank(v)) return(as.character(v))
  }
  fallback
}


#' Base constructor for `catlas_provenance`
#'
#' Internal. Performs only structural checks. Vocabularies, block names and
#' timestamp sanity checks are enforced by [validate_catlas_provenance()]. The
#' study identifier is parsed here, because its components are derived rather
#' than stored and a malformed identifier must fail at construction.
#'
#' `exclusions` is deliberately left empty. It starts empty at construction and
#' is only ever appended to, by [record_exclusion()], once participant exclusion
#' criteria are decided.
#'
#' @param study Character(1). `fba-<task>-<mode>-0X` identifier.
#' @param design Character(1). Structural variant, from `.catlas_designs`.
#' @param blocks Named integer. Block count per stage.
#' @param trial_types Integer(1). Distinct trial types per block.
#' @param origin List. `platform`, `url`, `study_id`, `batch_ids`.
#' @param experiment_build Named Date vector, `c(first = , last = )`, defining the data
#'   collection window.
#' @param retrieved_at POSIXct(1). When the data were pulled, in UTC.
#' @param experiment_build List. `repo`, `release`, `commit` of the experiment
#'   build that generated the data.
#' @param catlasr_version Character(1). Package version at construction.
#' @param notes Character. Free text; anything a reader of the object would
#'   otherwise have to find in a lab notebook.
#' @param call Environment for error reporting.
#'
#' @returns An S3 list with class `"catlas_provenance"`.
#'
#' @noRd
catlas_provenance <- function(
    study,
    design,
    blocks,
    trial_types,
    origin,
    collected_between,
    retrieved_at,
    experiment_build,
    catlasr_version,
    notes = character(),
    call = rlang::caller_env()
) {
  stopifnot(is.list(origin))
  stopifnot(is.list(experiment_build))
  stopifnot(is.character(notes))

  ids <- .resolve_study_id(study, call = call)

  structure(
    c(
      ids,
      list(
        design            = design,
        blocks            = blocks,
        trial_types       = trial_types,
        origin            = origin,
        collected_between = collected_between,
        retrieved_at      = retrieved_at,
        experiment_build  = experiment_build,
        catlasr_version   = catlasr_version,
        exclusions        = list(),
        notes             = notes
      )
    ),
    class = "catlas_provenance"
  )
}


#' Record where a CATLAS raw-data bundle came from
#'
#' Constructor for the `catlas_provenance` class. Each data bundle carries a
#' provenance record, allowing the data bundle object to answer when it was
#' extracted, from where, which study it comes from, and which experiment build
#' was used to collect the data.
#'
#' @param study Character(1). Study identifier of the form
#'   `<prefix>-<task>-<mode>-0X`. Its components are parsed, so for instance
#'   `fba-allergy-online-01` yields `prefix = "fba"`, `task = "allergy"`,
#'   `mode = "online"`, `wave = 1L`. See Details for further explanation of the
#'   naming convention.
#' @param design Character(1). Structural variant of the procedure. Currently
#'   one of `"three-stage-replication"` or `"three-stage-extension"`. See
#'   Details for explanation of supported study designs.
#' @param blocks Named integer vector. Number of blocks per stage, named by
#'   stage exactly as `trials$stage` is coded. For instance, the three-stage
#'   allergy of the `forward-blocking-attention-01` manuscript supplies:
#'   `c(stage1 = 10L, stage2 = 8L, stage3 = 6L, test = 6L)`.
#' @param trial_types Integer(1). Distinct trial types presented per block, 8
#'   for the three-stage allergy task. Together with `blocks`, the `trial_types`
#'   are used to derive the expected trial count.
#' @param origin Named list comprising of `platform` (one of `"JATOS"`,
#'   `"Prolific"`, `"OSF"`, `"synthetic"`), `url`, `study_id` and `batch_ids`.
#'   `study_id` may hold several IDs when the batches span more than one
#'   platform study, e.g. after a re-deployment.
#' @param collected_between Named `Date` vector or a pair of strings `as.Date()`
#'   can parse, as `c(first = , last = )`. Records the first and last day on
#'   which the experiment was run. Required unless the platform is
#'   `"synthetic"`. This field is **not** the same as `retrieved_at`.
#'   `collected_between` records when the experiment was run, `retrieved_at`
#'   when the data was imported.
#' @param retrieved_at POSIXct(1) or a string parseable by `as.POSIXct()`.
#'   Coerced to UTC. Defaults to the current time.
#' @param experiment_build Named list comprising of `repo`, `release` and
#'   `commit`. At least one of `release` and `commit` must be given unless the
#'   platform is `"synthetic"` (which refers to simulated, not collected data).
#' @param notes Character. Free text.
#' @param guided Logical(1). When `TRUE`, every other argument is ignored and
#'   the record is collected by prompting at the console, then the equivalent
#'   call is printed for pasting into a script. Requires an interactive
#'   session.
#'
#' @returns A validated object of class `"catlas_provenance"`.
#'
#' @details
#' ## Naming conventions (`study`)
#'
#' CATLAS uses a specific study naming convention that allows it to keep some
#' order in the chaos that is scientific publishing. Each experiment must be
#' named according to this convention, and thus be of the form
#' `<prefix>-<task>-<mode>-0X`. In this study name, each components carries its
#' own specific meaning:
#'
#' - `<prefix>` means study type or manuscript family. For instance, `fba`
#'   refers to `forward-blocking-attention` experiments aimed at illuminating
#'   the role attention plays in the forward blocking phenomenon in cue
#'   contingency learning.
#' - `<task>` is a broad family to which task used by the experiment falls. It
#'   refers to the cover story, not to the formal structure of the experiment.
#'   For instance, `allergy` refers to the commonly used allergy prediction
#'   family of tasks.
#' - `<mode>` refers to the data collection mode. Currently support online
#'   (`"online"`), behavioural on-site (`"lab"`), eye-tracking containing
#'   (`"eye"`), and electroencephalography containing (`"eeg"`) data.
#' - `0X` is the wave indicating order of this experiment in a series of
#'   experiments from the same study type/manuscript family (`<prefix>`), using
#'   the same task variant (`<task>`), and collected via the same data
#'   collection method (`<mode>`). The order does NOT reset with each new
#'   manuscript and it is thus possible to have the first experiment of a
#'   manuscript containing wave number of more than one. The wave identifier
#'   `0X` is coerced to integer via `as.integer()`.
#'
#' ## Supported study designs (`design`)
#'
#' Study `design` parameter provides information about above and beyond what you
#' put into `study`. Most importantly, while the `<task>` field of `study`
#' informs about the experiment's "cover story," `design` reflects formal
#' set-up and study procedure information. Currently, the following designs are
#' supported:
#'
#' - `three-stage-replication` refers to a formally exact replication of the
#'   Beesley & Le Pelley's (2011) study which demonstrated that forward blocking
#'   in a three-stage cue-outcome contingency learning paradigm correlates with
#'   eye-tracking proxies of overt attention
#' - `three-stage-extension` refers to a procedure reflecting Paskewitz &
#'   Jones's (2020) desing suggestion for adjudicating between attentional shift
#'   and attentional competition accounts of forward blocking within
#'   associability-based associative models of cue-outcome contingency learning
#'
#' @references
#' Beesley, T., & Le Pelley, M. E. (2011). The influence of blocking on overt
#'   attention and associability in human learning. *Journal of Experimental
#'   Psychology: Animal Behavior Processes, 37*(1), 114–120.
#'   \doi{10.1037/a0019526}
#'
#' Paskewitz, S., & Jones, M. (2020). Dissecting EXIT. Journal of Mathematical
#'   Psychology*, *97*, 102371. \doi{10.1016/j.jmp.2020.102371}
#'
#' @seealso [build_fba_rawdata()], [provenance()], [record_exclusion()]
#'
#' @examples
#' build_provenance(
#'   study = "fba-allergy-online-01",
#'   design = "three-stage-replication",
#'   blocks = c(stage1 = 10L, stage2 = 8L, stage3 = 6L, test = 6L),
#'   trial_types = 8L,
#'   origin = list(
#'     platform = "JATOS",
#'     url = "https://jatos.mindprobe.eu",
#'     study_id = "catlas_01",
#'     batch_ids = c(30206L, 30275L, 30832L, 30829L)
#'   ),
#'   collected_between = c(
#'     first = as.Date("2026-06-09"),
#'     last  = as.Date("2026-06-26")
#'   ),
#'   retrieved_at = as.POSIXct("2026-06-26 12:00:00", tz = "UTC"),
#'   experiment_build = list(
#'     repo = "josefmana/catlaslab",
#'     release = "fba-allergy-online-01",
#'     commit = "e249e74"
#'   )
#' )
#'
#' @examples
#' \dontrun{
#' # Answer the prompts, then paste the printed call into data-raw/.
#' prov <- build_provenance(guided = TRUE)
#' }
#'
#' @export
build_provenance <- function(
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
) {
  if (isTRUE(guided)) {
    return(.provenance_wizard())
  }

  blocks <- vapply(blocks, as.integer, integer(1L))
  trial_types <- as.integer(trial_types)
  retrieved_at <- as.POSIXct(retrieved_at, tz = "UTC")

  if (!is.null(collected_between)) {
    collected_between <- as.Date(collected_between)
  }

  if (!is.null(origin$batch_ids)) {
    origin$batch_ids <- as.integer(origin$batch_ids)
  }

  obj <- catlas_provenance(
    study             = study,
    design            = design,
    blocks            = blocks,
    trial_types       = trial_types,
    origin            = origin,
    collected_between = collected_between,
    retrieved_at      = retrieved_at,
    experiment_build  = experiment_build,
    catlasr_version   = as.character(utils::packageVersion("catlasr")),
    notes             = notes
  )

  validate_catlas_provenance(obj)
}


#' Validate a `catlas_provenance` record
#'
#' @param x A `catlas_provenance` object.
#' @param call Environment for error reporting.
#'
#' @returns `x` invisibly on success, otherwise an informative error.
#'
#' @noRd
validate_catlas_provenance <- function(x, call = rlang::caller_env()) {
  if (!is_catlas_provenance(x)) {
    cli::cli_abort("`x` must inherit from {.cls catlas_provenance}.", call = call)
  }

  # --- design -----------------------------------------------------------------
  if (length(x$design) != 1L || !x$design %in% .catlas_designs) {
    cli::cli_abort(c(
            "`design` must be one recognised structural variant.",
      "x" = "Received {.val {x$design}}.",
      "i" = "Recognised design{?s}: {.val {(.catlas_designs)}}."
    ), call = call)
  }

  # --- blocks -----------------------------------------------------------------
  expected_stages <- .design_spec(x$design)$stages
  if (!identical(sort(names(x$blocks)), sort(expected_stages))) {
    cli::cli_abort(c(
            "`blocks` must be named by the stages that {.val {x$design}} requires.",
      "x" = "Found: {.val {names(x$blocks)}}.",
      "i" = "Expected: {.val {expected_stages}}."
    ), call = call)
  }

  if (any(is.na(x$blocks)) || any(x$blocks <= 0L)) {
    block_nas  <- sum(is.na(x$blocks))
    block_negs <- sum(x$blocks <= 0L, na.rm = TRUE)
    cli::cli_abort(c(
            "`blocks` must contain strictly positive counts.",
      "x" = "Detected {block_nas} NA{?s} and {block_negs} non-positive value{?s}."
    ), call = call)
  }

  if (length(x$trial_types) != 1L || is.na(x$trial_types) || x$trial_types <= 0L) {
    cli::cli_abort(c(
            "`trial_types` must be a single strictly positive integer.",
      "x" = "Received {.val {x$trial_types}}."
    ), call = call)
  }

  # --- origin -----------------------------------------------------------------
  missing_origin <- setdiff(
    c("platform", "url", "study_id", "batch_ids"),
    names(x$origin)
  )
  if (length(missing_origin) > 0L) {
    cli::cli_abort(c(
            "`origin` is missing {length(missing_origin)} required field{?s}.",
      "x" = "Missing: {.val {missing_origin}}."
    ), call = call)
  }

  if (!x$origin$platform %in% .catlas_platforms) {
    cli::cli_abort(c(
            "`origin$platform` must be a recognised data origin.",
      "x" = "Received {.val {x$origin$platform}}.",
      "i" = "Recognised platform{?s}: {.val {(.catlas_platforms)}}."
    ), call = call)
  }

  jatos <- identical(x$origin$platform, "JATOS")

  if (jatos) {
    if (length(x$origin$batch_ids) < 1L || all(is.na(x$origin$batch_ids))) {
      cli::cli_abort(
        "For JATOS data, `origin$batch_ids` must name at least one batch.",
        call = call
      )
    }
    dup_batches <- unique(x$origin$batch_ids[duplicated(x$origin$batch_ids)])
    if (length(dup_batches) > 0L) {
      cli::cli_abort(c(
              "`origin$batch_ids` must not repeat a batch.",
        "x" = "Duplicated: {.val {dup_batches}}."
      ), call = call)
    }
  }

  # --- retrieved_at & collected_between ---------------------------------------
  if (!inherits(x$retrieved_at, "POSIXct") || length(x$retrieved_at) != 1L) {
    cli::cli_abort(c(
      "`retrieved_at` must be a single POSIXct timestamp.",
      "x" = "Received {.cls {class(x$retrieved_at)}} of length {length(x$retrieved_at)}."
    ), call = call)
  }
  if (x$retrieved_at > Sys.time()) {
    cli::cli_abort(c(
      "`retrieved_at` is in the future.",
      "x" = "Received {format(x$retrieved_at, usetz = TRUE)}."
    ), call = call)
  }

  synthetic <- identical(x$origin$platform, "synthetic")

  if (is.null(x$collected_between)) {
    if (!synthetic) {
      cli::cli_abort(c(
              "`collected_between` must give the data collection window.",
        "i" = "Pass {.code c(first = , last = )} as dates.",
        "i" = "Only {.val synthetic} data may omit it."
      ), call = call)
    }
  } else {
    if (!inherits(x$collected_between, "Date") || !identical(sort(names(x$collected_between)), c("first", "last"))) {
      cli::cli_abort(c(
              "`collected_between` must be a named Date vector.",
        "x" = "Received {.cls {class(x$collected_between)}} named {.val {names(x$collected_between)}}.",
        "i" = "Expected {.code c(first = , last = )}."
      ), call = call)
    }
    if (anyNA(x$collected_between)) {
      cli::cli_abort("`collected_between` must not contain NA.", call = call)
    }
    if (x$collected_between[["first"]] > x$collected_between[["last"]]) {
      cli::cli_abort(c(
              "`collected_between` runs backwards.",
        "x" = "First ({x$collected_between[['first']]}) comes after last ({x$collected_between[['last']]})."
      ), call = call)
    }

    if (x$collected_between[["last"]] > as.Date(x$retrieved_at)) {
      cli::cli_abort(c(
              "`collected_between$last` is after `retrieved_at`.",
        "x" = "Collection ends {x$collected_between[['last']]}, retrieval is {as.Date(x$retrieved_at)}.",
        "i" = "Data cannot be retrieved before they were collected."
      ), call = call)
    }
  }

  # --- experiment build -------------------------------------------------------
  missing_ref <- setdiff(c("repo", "release", "commit"), names(x$experiment_build))
  if (length(missing_ref) > 0L) {
    cli::cli_abort(c(
            "`experiment_build` is missing {length(missing_ref)} required field{?s}.",
      "x" = "Missing: {.val {missing_ref}}.",
      "i" = "Pass {.code NA} for a field that genuinely does not apply."
    ), call = call)
  }

  # Empirical data need to point to an experiment build
  if (.is_blank(x$experiment_build$release) && .is_blank(x$experiment_build$commit) && !synthetic) {
    cli::cli_abort("`experiment_build` must carry a release tag or a commit.", call = call)
  }

  invisible(x)
}


#' Extract the provenance record of a CATLAS object
#'
#' @param x An object carrying a `catlas_provenance` record.
#' @param ... Currently unused.
#'
#' @returns An object of class `"catlas_provenance"`.
#'
#' @seealso [build_provenance()]
#'
#' @export
provenance <- function(x, ...) {
  UseMethod("provenance")
}


#' @rdname provenance
#' @export
provenance.default <- function(x, ...) {
  cli::cli_abort(c(
    "No {.fn provenance} method for objects of class {.cls {class(x)}}."
  ))
}


#' @rdname provenance
#' @export
provenance.catlas_rawdata <- function(x, ...) {
  x$provenance
}


#' Drop participants and record why
#'
#' This function is the one and only sanctioned way to exclude a participant
#' from a CATLAS raw-data bundle. It removes the identifiers from all three
#' components **and** appends the rule to `provenance(x)$exclusions`, so the
#' object can always answer who was removed and why.
#'
#' @param x A `catlas_rawdata` object.
#' @param rule Character(1). Short machine-friendly rule name, e.g.
#'   `"incomplete_learning"`.
#' @param description Character(1). The rule in pre-registrable language.
#' @param ids Character. Identifiers to remove. May be empty, in which case the
#'   rule is still recorded.
#'
#' @returns `x` with the identifiers removed and the rule appended.
#'
#' @details
#' ## Write `description` concrete
#'
#' `description` is written in such a way that it can be pasted into a
#' pre-registration verbatim. Consequently, provide clear thresholds, not vague
#' adjectives. For instance, do not write `"excluded for inattention"` but
#' `"fewere than 200 experiment trials recorded"`.
#'
#' @seealso [provenance()]
#'
#' @export
record_exclusion <- function(x, rule, description, ids) {
  if (!is_catlas_rawdata(x)) {
    cli::cli_abort("`x` must be a {.cls catlas_rawdata} object.")
  }
  stopifnot(is.character(rule), length(rule) == 1L)
  stopifnot(is.character(description), length(description) == 1L)

  ids <- as.character(ids)

  known <- as.character(x$meta$id)
  unknown <- setdiff(ids, known)
  if (length(unknown) > 0L) {
    cli::cli_warn(c(
            "Some identifiers to exclude are not in this data bundle.",
      "i" = "Unknown ID{?s}: {.val {unknown}}.",
      "i" = "They are recorded in the rule, without removing any rows."
    ))
  }

  x$meta    <- dplyr::filter(x$meta,    !as.character(.data$id) %in% ids)
  x$stimuli <- dplyr::filter(x$stimuli, !as.character(.data$id) %in% ids)
  x$trials  <- dplyr::filter(x$trials,  !as.character(.data$id) %in% ids)

  record <- list(
    rule        = rule,
    description = description,
    ids         = ids,
    n           = length(intersect(ids, known)),
    applied_at  = Sys.time()
  )

  x$provenance$exclusions[[length(x$provenance$exclusions) + 1L]] <- record
  x
}


#' Format a `catlas_provenance` record
#'
#' @param x A `catlas_provenance` object.
#' @param ... Currently unused.
#'
#' @returns A character vector, one element per line.
#'
#' @export
format.catlas_provenance <- function(x, ...) {
  blocks <- x$blocks[.design_spec(x$design)$stages]

  c(
    "<catlas_provenance>",
    sprintf("  study      : %s", x$study),
    sprintf("  design     : %s", x$design),
    sprintf(
      "  structure  : %s blocks x %d trial types = %d trials",
      paste(blocks, collapse = "/"),
      x$trial_types,
      sum(blocks) * x$trial_types
    ),
    sprintf(
      "  origin     : %s, %d batch(es), %s",
      x$origin$platform,
      length(x$origin$batch_ids),
      paste(x$origin$study_id, collapse = ", ")
    ),
    sprintf(
      "  collected  : %s",
      if (is.null(x$collected_between)) {
        "not collected (synthetic)"
      } else {
        sprintf(
          "%s to %s (%d days)",
          x$collected_between[["first"]],
          x$collected_between[["last"]],
          as.integer(x$collected_between[["last"]] - x$collected_between[["first"]]) + 1L
        )
      }
    ),
    sprintf("  retrieved  : %s", format(x$retrieved_at, usetz = TRUE)),
    sprintf(
      "  exp. build : %s @ %s",
      x$experiment_build$repo,
      .first_present(
        x$experiment_build$release,
        x$experiment_build$commit,
        fallback = "unversioned"
      )
    ),
    sprintf("  exclusions : %d rule(s) applied", length(x$exclusions)),
    sprintf("  catlasr    : %s", x$catlasr_version)
  )
}


#' Print a `catlas_provenance` record
#'
#' @param x A `catlas_provenance` object.
#' @param ... Passed to [format.catlas_provenance()].
#'
#' @returns `x` invisibly.
#'
#' @export
print.catlas_provenance <- function(x, ...) {
  cat(format(x, ...), sep = "\n")

  if (length(x$exclusions) > 0L) {
    cat("\n")
    for (e in x$exclusions) {
      cat(sprintf("  - %s: %s (n = %d)\n", e$rule, e$description, e$n))
    }
  }

  invisible(x)
}


#' Test whether an object inherits from `catlas_provenance`
#'
#' @param x Any R object.
#'
#' @returns `TRUE` iff `x` inherits from `"catlas_provenance"`.
#'
#' @noRd
is_catlas_provenance <- function(x) {
  inherits(x, "catlas_provenance")
}
