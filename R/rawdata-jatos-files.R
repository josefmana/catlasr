#' Read a JATOS result file per study result, the stream as fallback
#'
#' For every study result of `x`, downloads the result file `result_file` of
#' its component result. Where the file exists and parses, it replaces the
#' streamed data in `data_raw`; otherwise the streamed data stay. The two are
#' never combined, since a finished run writes the file at its end, so the file
#' repeats every streamed trial and adds those whose upload failed.
#'
#' Where both exist, the file must hold every streamed trial apart from
#' `email-collection` records, matched on `trial_index`. A file that misses
#' streamed trials is still read, with a warning naming the study result.
#'
#' @param jc A JATOS connection, from `jatosR::define_connection()`.
#' @param x The bound table of [pull_jatos_batches()], with the columns
#'   `id_sr`, `id_cr` and `data_raw`.
#' @param result_file Character(1). Name of the result file.
#' @param call Environment for error reporting.
#'
#' @returns `x` with `data_raw` taken from the file wherever the file was read,
#'   and the column `data_source` after `data_raw`.
#'
#' @noRd
.read_result_files <- function(
    jc,
    x,
    result_file,
    call = rlang::caller_env()
) {
  if (!"id_cr" %in% names(x)) {
    cli::cli_abort(c(
            "The pulled results carry no component result IDs ({.field id_cr}).",
      "i" = "The IDs are needed to request {.file {result_file}} from JATOS."
    ), call = call)
  }

  n <- nrow(x)
  file_json <- rep(NA_character_, n)

  cli::cli_progress_bar(
    "Requesting {.file {result_file}}",
    total = n
  )
  for (i in seq_len(n)) {
    if (!is.na(x$id_cr[i])) {
      file_json[i] <- .download_result_file(
        jc = jc,
        id_cr = x$id_cr[i],
        id_sr = x$id_sr[i],
        filename = result_file,
        call = call
      )
    }
    cli::cli_progress_update()
  }
  cli::cli_progress_done()

  stream <- lapply(repair_jatos_json(x$data_raw), .parse_jspsych_result)
  file <- lapply(repair_jatos_json(file_json), .parse_jspsych_result)

  has_file <- !is.na(file_json)
  readable <- !vapply(file, is.null, logical(1L))
  use_file <- has_file & readable

  comparison <- t(vapply(
    seq_len(n),
    \(i) {
      if (use_file[i] && !is.null(stream[[i]])) {
        .compare_result_sources(stream[[i]], file[[i]])
      } else {
        c(missing = NA_integer_, recovered = NA_integer_)
      }
    },
    integer(2L)
  ))

  x$data_raw[use_file] <- file_json[use_file]
  x$data_source <- ifelse(
    use_file,
    "file",
    ifelse(!is.na(x$data_raw), "stream", NA_character_)
  )

  x <- dplyr::relocate(x, "data_source", .after = "data_raw")

  .report_result_sources(
    x = x,
    result_file = result_file,
    unreadable = has_file & !readable,
    compared = use_file & !vapply(stream, is.null, logical(1L)),
    comparison = comparison,
    call = call
  )

  x
}


#' Download one JATOS result file
#'
#' Requests `GET /jatos/api/v1/results/files/{filename}?componentResultId=`
#' (JATOS 3.8.1 and later). Status 200 returns the file, 404 means that the
#' component result has no such file, and any other status aborts.
#'
#' @param jc A JATOS connection, from `jatosR::define_connection()`.
#' @param id_cr Integer(1). JATOS component result ID.
#' @param id_sr Integer(1). JATOS study result ID, for messages.
#' @param filename Character(1). Name of the result file.
#' @param call Environment for error reporting.
#'
#' @returns Character(1): the file's content as UTF-8 text, or `NA` when the
#'   file does not exist.
#'
#' @noRd
.download_result_file <- function(
    jc,
    id_cr,
    id_sr,
    filename,
    call = rlang::caller_env()
) {
  endpoint <- paste0(
    "/jatos/api/v1/results/files/",
    utils::URLencode(filename, reserved = TRUE)
  )

  resp <- tryCatch(
    jatosR::base_request(jc, endpoint) |>
      httr2::req_url_query(componentResultId = id_cr) |>
      httr2::req_retry(max_tries = 3L) |>
      httr2::req_error(is_error = \(resp) FALSE) |>
      httr2::req_perform(),
    error = function(e) {
      cli::cli_abort(c(
        paste(
          "Could not request {.file {filename}} of study result",
          "{.val {id_sr}}."
        ),
        "i" = "Component result {.val {id_cr}}."
      ), parent = e, call = call)
    }
  )

  status <- httr2::resp_status(resp)

  if (status == 404L) {
    return(NA_character_)
  }

  if (status != 200L) {
    cli::cli_abort(c(
      paste(
        "JATOS answered {.val {status}} to the request for",
        "{.file {filename}} of study result {.val {id_sr}}."
      ),
      "i" = paste(
        "Only 200 (the file is read) and 404 (no file, the streamed data",
        "are read) are expected."
      )
    ), call = call)
  }

  httr2::resp_body_string(resp, encoding = "UTF-8")
}


#' Compare the trials of a result file with the streamed trials
#'
#' @param stream,file Tibbles of jsPsych trials, parsed from the streamed data
#'   and from the result file of the same study result.
#'
#' @returns Named integer(2): `missing`, the streamed trials other than
#'   `email-collection` records that the file lacks, and `recovered`, the
#'   trials of the file other than `email-collection` records that the stream
#'   lacks; both `NA` when either source has no `trial_index`.
#'
#' @noRd
.compare_result_sources <- function(stream, file) {
  if (!"trial_index" %in% names(stream) || !"trial_index" %in% names(file)) {
    return(c(missing = NA_integer_, recovered = NA_integer_))
  }

  not_email <- function(d) {
    if ("trial_type" %in% names(d)) {
      !d$trial_type %in% "email-collection"
    } else {
      rep(TRUE, nrow(d))
    }
  }

  streamed <- stream$trial_index[not_email(stream)]
  filed <- file$trial_index[not_email(file)]

  c(
    missing = length(setdiff(streamed, file$trial_index)),
    recovered = length(setdiff(filed, stream$trial_index))
  )
}


#' Report which source each study result was read from
#'
#' @param x The table after the sources were chosen, with `id_sr` and
#'   `data_source`.
#' @param result_file Character(1). Name of the result file.
#' @param unreadable Logical. Study results whose file exists but does not
#'   parse.
#' @param compared Logical. Study results read from the file that also have
#'   parseable streamed data.
#' @param comparison Integer matrix with columns `missing` and `recovered`,
#'   from `.compare_result_sources()`, one row per study result.
#' @param call Environment for error reporting.
#'
#' @returns `NULL`, invisibly. Called for its messages and warnings.
#'
#' @noRd
.report_result_sources <- function(
    x,
    result_file,
    unreadable,
    compared,
    comparison,
    call = rlang::caller_env()
) {
  n_file <- sum(x$data_source %in% "file")
  n_stream <- sum(x$data_source %in% "stream")
  n_none <- sum(is.na(x$data_source))
  ids_stream <- as.character(x$id_sr[x$data_source %in% "stream"])

  missing <- comparison[, "missing"]
  recovered <- comparison[, "recovered"]
  n_recovered <- sum(recovered[compared], na.rm = TRUE)
  ids_recovered <- as.character(
    x$id_sr[compared & !is.na(recovered) & recovered > 0L]
  )

  cli::cli_inform(c(
    "*" = "{n_file} study result{?s} read in full from {.file {result_file}}.",
    if (n_stream > 0L) {
      c("*" = "{n_stream} record{?s} read from the streamed data: {.val {ids_stream}}.")
    },
    if (n_none > 0L) {
      c("*" = "{n_none} record{?s} without experimental data.")
    },
    if (n_recovered > 0L) {
      c("i" = paste(
        "{n_recovered} trial{?s} missing from the streamed data",
        "{?was/were} recovered from the file, in {.val {ids_recovered}}."
      ))
    },
    "i" = paste(
      "The file is always read if it exists; the streamed data are read",
      "only for study results without a file, and the two are never combined."
    )
  ))

  if (any(unreadable)) {
    ids <- as.character(x$id_sr[unreadable])
    cli::cli_warn(c(
      paste(
        "{length(ids)} result file{?s} could not be parsed, so the",
        "streamed data {?was/were} read instead."
      ),
      "i" = "Affected: {.val {ids}}."
    ), call = call)
  }

  lacking <- compared & !is.na(missing) & missing > 0L
  if (any(lacking)) {
    ids <- as.character(x$id_sr[lacking])
    cli::cli_warn(c(
      paste(
        "{length(ids)} result file{?s} lack{?s/} streamed trials other than",
        "{.val email-collection} records, matched on {.field trial_index}."
      ),
      "i" = "Affected: {.val {ids}}.",
      "i" = "The files were read nonetheless; check these runs."
    ), call = call)
  }

  uncompared <- compared & is.na(missing)
  if (any(uncompared)) {
    ids <- as.character(x$id_sr[uncompared])
    cli::cli_warn(c(
      paste(
        "{length(ids)} study result{?s} could not be compared with the",
        "streamed data, because a source has no {.field trial_index}."
      ),
      "i" = "Affected: {.val {ids}}."
    ), call = call)
  }

  invisible(NULL)
}
