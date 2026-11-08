#' Repair trial-by-trial JATOS result data into a valid JSON
#'
#' CATLAS experiments stream every jsPsych trial to JATOS as it finishes, via
#' `jatos.appendResultData(JSON.stringify(data))`. JATOS stores the appended
#' strings back to back, so a study result arrives as a sequence of JSON
#' objects, `{...}{...}{...}`, with neither the enclosing brackets nor the
#' separating commas that would make it one JSON array. `repair_jatos_json()`
#' supplies both missing components, so the result can be parsed with
#' [jsonlite::fromJSON()].
#'
#' @param x Character. One element per JATOS study result, typically the
#'   `data_raw` column of `jatosR::process_results()$data`. A logical vector of
#'   `NA`s is accepted too and will be returned unchanged.
#'
#' @returns A character vector of the same length as `x`. Each element is a JSON
#'   array of trial records. `NA` stays `NA`, an empty string becomes `"[]"`,
#'   and an element that already is a JSON array is returned unchanged.
#'
#' @details
#' The repair inserts a comma wherever a closing brace is followed, possibly
#' after whitespace, by an opening brace. It does not parse the JSON, so a
#' string *value* containing `}{` would be split as well. jsPsych escapes
#' quotes but not braces, so this can only happen when a participant types
#' `}{` into a free-text field. The record would then fail to parse, which
#' shows up as an invalid result.
#'
#' @examples
#' raw <- c(
#'   '{"trial_type":"consent","response":1}{"trial_type":"stimuli-map"}',
#'   NA,
#'   ""
#' )
#' repair_jatos_json(raw)
#'
#' @export
repair_jatos_json <- function(x) {
  if (is.logical(x) && all(is.na(x))) {
    x <- as.character(x)
  }

  if (!is.character(x)) {
    cli::cli_abort(c(
            "`x` must be a character vector of JATOS result data.",
      "x" = "Received {.cls {class(x)}}.",
      "i" = "Pass the {.field data_raw} column of {.code jatosR::process_results()$data}."
    ))
  }

  trimmed  <- trimws(x)
  is_array <- !is.na(trimmed) & startsWith(trimmed, "[")

  repaired <- paste0("[", gsub("\\}\\s*\\{", "},{", trimmed, perl = TRUE), "]")

  out <- ifelse(is_array, trimmed, repaired)
  out[is.na(x)] <- NA_character_
  out
}


#' Pull the study results of one or more JATOS batches
#'
#' Downloads every study result of the listed batches through `{jatosR}` and
#' binds them into one table. The connection is tested first, so a wrong token
#' fails before any batch is requested. Batch that cannot be pulled is named in
#' the error.
#'
#' @param url Character(1). Address of the JATOS server, e.g.
#'   `"https://jatos.mindprobe.eu"`.
#' @param batch_ids Integer-valued numeric vector of JATOS batch IDs, without
#'   duplicates.
#' @param token Character(1). A JATOS API token, `"jap_..."` with or without
#'   the `"Bearer "` prefix. Read it from `.Renviron` rather than typing it into
#'   a script, e.g. `Sys.getenv("mindprobe_catlas_token")`.
#' @param result_file `NULL` (default) or Character(1). Name of a JATOS result
#'   file that holds the complete data of a study result, e.g.
#'   `"jspsych-data.json"` from `fba-allergy-online-02` on. `NULL` reads the
#'   streamed data only, as for builds that upload no result file (e.g.
#'   `fba-allergy-online-01`). See details.
#'
#' @returns A tibble with one row per JATOS study result, including the columns
#'   of `jatosR::process_results()$data` (among them `id_sr`, `id_cr`,
#'   `batch_id`, `start_date_sr`, `study_state` and `data_raw`),
#'   `jatos_study_id` representing the JATOS study each batch belongs to, and
#'   `data_source`, the source of `data_raw`: `"file"` (the result file),
#'   `"stream"` (the streamed data) or `NA` (neither exists). The time the pull
#'   finished, in UTC, is attached as the attribute `"retrieved_at"`, ready for
#'   [build_provenance()].
#'
#' @details
#' Batches may belong to different JATOS studies, for instance when a study was
#' re-deployed after a patch. `jatos_study_id` keeps this fact visible.
#'
#' ## Result files
#'
#' CATLAS experiments stream every trial to JATOS as it finishes, and from
#' `fba-allergy-online-02` on they also upload the complete jsPsych data as a
#' result file at the end of the run. A trial whose upload failed, e.g. during
#' a dropped internet connection, is missing from the streamed data but present
#' in the file. With `result_file` given, the file of every study result is
#' requested from the JATOS API (`/jatos/api/v1/results/files/`, JATOS 3.8.1
#' and later), and the following rule applies:
#'
#' * Where the file exists, it is read instead of the streamed data. The two
#'   are never combined, because the file of a finished run repeats every
#'   streamed trial.
#' * Where it does not exist (unfinished runs, failed uploads), the streamed
#'   data are read.
#' * Where it exists but does not parse, the streamed data are read, with a
#'   warning.
#'
#' Where both exist, the file must hold every streamed trial apart from
#' `email-collection` records, matched on `trial_index`. A file that does not
#' is still read, with a warning naming the affected study result. Every call
#' reports how many study results were read from each source, names those read
#' from the streamed data, and counts the trials recovered from the files.
#'
#' @seealso [parse_jatos_results()], [repair_jatos_json()]
#'
#' @export
pull_jatos_batches <- function(
    url,
    batch_ids,
    token,
    result_file = NULL
) {
  rlang::check_installed(
    "jatosR",
    reason = paste(
      "to download results from JATOS.",
      "Install it with `remotes::install_github(\"visionlabels/jatosR\")`."
    )
  )

  if (!is.character(url) || length(url) != 1L || is.na(url) || !nzchar(url)) {
    cli::cli_abort("`url` must be a single non-empty string.")
  }

  if (!is.numeric(batch_ids) || length(batch_ids) == 0L || anyNA(batch_ids) ||
      any(batch_ids != round(batch_ids))) {
    cli::cli_abort(c(
            "`batch_ids` must be a non-empty vector of integers.",
      "x" = "Received: {.val {batch_ids}}."
    ))
  }
  batch_ids <- as.integer(batch_ids)

  dup_batches <- unique(batch_ids[duplicated(batch_ids)])
  if (length(dup_batches) > 0L) {
    cli::cli_abort(c(
            "All `batch_ids` must be unique.",
      "x" = "Duplicated: {.val {dup_batches}}."
    ))
  }

  if (!is.character(token) || length(token) != 1L || is.na(token) || !nzchar(token)) {
    cli::cli_abort(c(
            "`token` must be a single non-empty string.",
      "i" = "An empty token usually means the variable is missing from {.file .Renviron} or that R was not restarted after adding it."
    ))
  }

  if (!is.null(result_file)) {
    if (!is.character(result_file) || length(result_file) != 1L ||
        is.na(result_file) || !nzchar(result_file) ||
        grepl("/", result_file, fixed = TRUE)) {
      cli::cli_abort(c(
              "`result_file` must be `NULL` or a single file name.",
        "x" = "Received: {.val {result_file}}."
      ))
    }
    rlang::check_installed(
      "httr2",
      reason = "to download JATOS result files."
    )
  }

  jc <- tryCatch(
    jatosR::define_connection(url, token),
    error = function(e) {
      cli::cli_abort(c(
              "`token` is not a JATOS API token.",
        "i" = "JATOS tokens start with {.val jap_}."
      ), parent = e)
    }
  )

  tryCatch(
    jatosR::test_connection(jc),
    error = function(e) {
      cli::cli_abort(c(
              "Cannot reach JATOS at {.url {url}} with this token.",
        "i" = "Check the server address and that the token has not expired."
      ), parent = e)
    }
  )

  pulls <- lapply(batch_ids, function(batch) {
    tryCatch(
      {
        meta    <- jatosR::get_metadata(jc, batch_id = batch)
        results <- jatosR::get_results(jc, batch_id = batch)
        jatosR::process_results(meta, results)
      },
      error = function(e) {
        cli::cli_abort(c(
                "Could not pull JATOS batch {.val {batch}}.",
          "i" = "A batch without any study result, or one from another server, typically produces this error."
        ), parent = e)
      }
    )
  })

  out <- dplyr::bind_rows(lapply(pulls, function(pull) {
    study_id <- pull$meta$study_id
    if (is.null(study_id)) {
      study_id <- NA_integer_
    }
    dplyr::mutate(
      pull$data,
      jatos_study_id = as.integer(study_id),
      .before = 1L
    )
  }))

  dup_results <- unique(out$id_sr[duplicated(out$id_sr)])
  if (length(dup_results) > 0L) {
    cli::cli_abort(c(
            "Each JATOS study result must appear once.",
      "x" = "Repeated {.field id_sr}: {.val {dup_results}}.",
      "i" = "The same result in two batches means the batch list overlaps."
    ))
  }

  if (is.null(result_file)) {
    out$data_source <- ifelse(is.na(out$data_raw), NA_character_, "stream")
    out <- dplyr::relocate(out, "data_source", .after = "data_raw")
  } else {
    out <- .read_result_files(
      jc = jc,
      x = out,
      result_file = result_file,
      call = rlang::current_env()
    )
  }

  retrieved_at <- Sys.time()
  attr(retrieved_at, "tzone") <- "UTC"
  attr(out, "retrieved_at") <- retrieved_at
  out
}


#' Parse pulled JATOS results into jsPsych trial data
#'
#' Repairs and parses the `data_raw` column of [pull_jatos_batches()], one
#' study result at a time, so that one damaged result cannot stop the others.
#'
#' @param x A tibble from [pull_jatos_batches()], or any data frame with the
#'   columns `id_sr` and `data_raw`.
#'
#' @returns `x` without `data_raw`, with three columns added in front:
#' \describe{
#'   \item{`id`}{The JATOS study result ID as character; represents the
#'   participant identifier used by [build_fba_rawdata()].}
#'   \item{`jspsych`}{A list of tibbles, one row per jsPsych trial, or `NULL`
#'   for a result without parseable data.}
#'   \item{`has_data`}{Logical, `FALSE` on rows where `jspsych` is `NULL`.}
#' }
#'
#' Attributes of `x`, such as `"retrieved_at"`, are kept.
#'
#' @details
#' A `response` column is coerced to character for every result. jsPsych records
#' a button press as its index and a choice as text, so a participant whose run
#' holds only button presses, such as one who declined consent, would, without
#' the coercion, get a numeric `response` column that does not stack with
#' everyone else's.
#'
#' @seealso [pull_jatos_batches()], [repair_jatos_json()]
#'
#' @export
parse_jatos_results <- function(x) {
  if (!is.data.frame(x)) {
    cli::cli_abort("`x` must be a data frame, usually from {.fn pull_jatos_batches}.")
  }
  missing_cols <- setdiff(c("id_sr", "data_raw"), names(x))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
            "`x` is missing {length(missing_cols)} required column{?s}.",
      "x" = "Missing: {.field {missing_cols}}.",
      "i" = "Pass the table returned by {.fn pull_jatos_batches}."
    ))
  }

  jspsych <- lapply(repair_jatos_json(x$data_raw), .parse_jspsych_result)

  x$data_raw <- NULL
  x$id       <- as.character(x$id_sr)
  x$jspsych  <- jspsych
  x$has_data <- !vapply(jspsych, is.null, logical(1L))

  dplyr::relocate(x, "id", "jspsych", "has_data")
}


#' Parse one repaired JATOS study result
#'
#' @param json Character(1). One element of [repair_jatos_json()] output.
#'
#' @returns A tibble of jsPsych trials, or `NULL` when nothing parseable is
#'   present in `json`.
#'
#' @noRd
.parse_jspsych_result <- function(json) {
  if (is.na(json)) {
    return(NULL)
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(json),
    error = function(e) NULL
  )

  if (!is.data.frame(parsed) || nrow(parsed) == 0L) {
    return(NULL)
  }

  parsed <- tibble::as_tibble(parsed)
  if ("response" %in% names(parsed)) {
    parsed$response <- as.character(parsed$response)
  }
  parsed
}
