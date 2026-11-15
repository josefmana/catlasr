# Columns of a debriefing coding file
.debrief_coding_cols <- c(
  "id",
  "prior_knowledge",
  "prior_guess",
  "blocking_naive" # Must be last as it is added here; if TRUE, the answer
                   # indicates the participant did not recognise blocking
)


#' Write the free-text debriefing answers to a private coding file
#'
#' The free-text answers to the debriefing question asking whether the
#' participant knew or guessed what the study tested must be coded before any
#' blocking index is computed, from a file that holds nothing but participant
#' identifiers and debriefing answers, so that the coding is blind to the test
#' data. `write_debrief_coding()` writes such a file to the private folder as a
#' CSV with an empty column `blocking_naive` for the codes indicating whether,
#' based on the debriefing answer, the participant appears to be naive to the
#' study's purpose to investigate blocking. Fill it in manually with `TRUE` or
#' `FALSE`, then read the codes back with [read_debrief_coding()].
#'
#' @param debrief A data frame with one row per participant and the columns
#'   `id`, `prior_knowledge` (the yes/no answer) and `prior_guess` (the free
#'   text), taken from the debriefing records of the parsed jsPsych data.
#' @param file Character(1). Path of the coding file (`.csv`) within the
#'   private folder, e.g. `"fba-allergy-online-02/debrief-coding.csv"`.
#' @param rule Character(1) or `NULL`. The coding rule, printed in the
#'   message as a reminder. Defaults to `NULL`.
#' @inheritParams write_private_csv
#'
#' @returns The path of the coding file, invisibly.
#'
#' @details
#' ## Repeated calls
#'
#' The debriefing file grows with the data. When it exists, codes already
#' entered are kept, participants new to `debrief` are added with an empty code,
#' and participants absent from `debrief` keep their rows. A participant whose
#' answer differs from the one in the file aborts the call, as answers cannot
#' change between pulls, so a difference means that participant identifiers no
#' longer match.
#'
#' ## Answers that need no coding
#'
#' A missing answer (for which `is.na(prior_guess)`, e.g. after a timed-out
#' debriefing screen) cannot show that the participant was naive to blocking,
#' so it is coded `FALSE` automatically and the participant does not reach the
#' naive set (i.e., data set of participants naive to the experimental design).
#'
#' ## The file
#'
#' UTF-8, comma-separated, sorted by `id`, with empty cells for missing
#' values. Spreadsheet programs may change the separator or translate `TRUE`
#' and `FALSE` (e.g. into `PRAVDA` and `NEPRAVDA`) when saving;
#' [read_debrief_coding()] accepts semicolons, but aborts on any code other
#' than `TRUE` or `FALSE`.
#'
#' @seealso [read_debrief_coding()]
#'
#' @export
write_debrief_coding <- function(
    debrief,
    file,
    rule = NULL,
    dir = Sys.getenv("CATLAS_PRIVATE_DIR")
) {
  if (!is.data.frame(debrief)) {
    cli::cli_abort("`debrief` must be a data frame.")
  }

  missing_cols <- setdiff(.debrief_coding_cols[1:3], names(debrief))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
            "`debrief` is missing {length(missing_cols)} required column{?s}.",
      "x" = "Missing: {.field {missing_cols}}."
    ))
  }

  if (!is.null(rule) && !rlang::is_string(rule)) {
    cli::cli_abort("`rule` must be `NULL` or a single string.")
  }

  new <- tibble::tibble(
    id = as.character(debrief$id),
    prior_knowledge = as.logical(debrief$prior_knowledge),
    prior_guess = as.character(debrief$prior_guess),
    blocking_naive = dplyr::if_else(
      is.na(.data$prior_guess),
      FALSE,
      NA
    )
  )

  repeated <- unique(new$id[duplicated(new$id)])
  if (length(repeated) > 0L || anyNA(new$id)) {
    cli::cli_abort(c(
      paste(
        "`debrief` must contain exactly one row per participant, with no",
        "missing `id`."
      ),
      "x" = "Repeated: {.val {repeated}}."
    ))
  }

  path <- .private_path(file, dir, overwrite = TRUE)

  coding <- if (file.exists(path)) {
    old <- .read_coding_file(path)
    both <- intersect(old$id, new$id)

    changed <- both[
      !mapply(
        identical,
        old$prior_guess[match(both, old$id)],
        new$prior_guess[match(both, new$id)]
      )
    ]
    if (length(changed) > 0L) {
      cli::cli_abort(c(
              "Answers in the coding file differ from those in `debrief`.",
        "x" = paste(
          "Detected {length(changed)} participant{?s} with a discrepancy:",
          "{.val {changed}}."
        ),
        "i" = paste(
          "Answers do not change between pulls, so the most likely explanation",
          "is that participant identifiers no longer match."
        ),
        "i" = "See the file {.path {path}}"
      ))
    }

    parsed <- .parse_codes(old$blocking_naive, old$id)
    if (length(parsed$invalid) > 0L) {
      cli::cli_abort(c(
              "Codes in the coding file must be {.code TRUE} or {.code FALSE}.",
        "x" = paste(
          "Different values found for {length(parsed$invalid)}",
          "participant{?s}: {.val {parsed$invalid}}."
        ),
        "i" = "Correct the file first, so that no code is lost.",
        "i" = "See the file {.path {path}}"
      ))
    }

    old$blocking_naive <- parsed$codes

    dplyr::bind_rows(
      old,
      dplyr::filter(new, !.data$id %in% old$id)
    )
  } else {
    new
  }

  coding <- coding[order(coding$id), .debrief_coding_cols]

  utils::write.csv(
    coding,
    path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )

  n_open <- sum(is.na(coding$blocking_naive))
  n_auto <- sum(is.na(coding$prior_guess))

  cli::cli_inform(c(
    "i" = paste(
      "Coding file contains {nrow(coding)} participant{?s}, out of which",
      "{n_open} answer{?s} remain to be coded."
    ),
    if (n_auto > 0L) {
      c("*" = paste(
        "{n_auto} missing answer{?s} coded {.code FALSE} automatically,",
        "since missing answer cannot rule out the conservative null hypothesis",
        "of the participant recognising blocking."
      ))
    },
    if (!is.null(rule)) {
      c("i" = "Coding rule: {rule}")
    },
    "i" = paste(
      "Fill the {.field blocking_naive} column with {.code TRUE} or",
      "{.code FALSE}, save the file, and then read the codes with",
      "{.fn read_debrief_coding}."
    ),
    "i" = "See the file {.path {path}}"
  ))

  invisible(path)
}


#' Read the codes of the free-text debriefing answers
#'
#' Reads the coding file written by [write_debrief_coding()] once
#' `blocking_naive` is filled in, and returns the participants whose answer
#' was coded as indicating they either recognised blocking or did not answer
#' (in which case them recognising blocking cannot be ruled out), ready for
#' [record_exclusion()].
#'
#' @param ids Character or `NULL`. Participants whose codes are needed, e.g.
#'   those of the data bundle the rule is applied to. Every one of them must
#'   have a coded row. `NULL` (default) uses every row of the file.
#' @inheritParams write_debrief_coding
#'
#' @returns A character vector of the participant IDs coded `FALSE`, i.e., not
#'   naive to blocking, among `ids` when given.
#'
#' @details
#' The call aborts if any row asked for has no code, if a code is anything other
#' than `TRUE` or `FALSE` (case does not matter) or if any participant from
#' `ids` is missing from the file. Codes are thus never guessed: an uncoded
#' answer stops the import until it gets its code.
#'
#' @seealso [write_debrief_coding()], [record_exclusion()]
#'
#' @export
read_debrief_coding <- function(
    file,
    ids = NULL,
    dir = Sys.getenv("CATLAS_PRIVATE_DIR")
) {
  path <- .private_path(file, dir, read = TRUE)
  coding <- .read_coding_file(path)

  if (!is.null(ids)) {
    ids <- as.character(ids)

    absent <- setdiff(ids, coding$id)
    if (length(absent) > 0L) {
      cli::cli_abort(c(
              "The coding file lacks {length(absent)} participant{?s}.",
        "x" = "Missing: {.val {absent}}.",
        "i" = "Write the file again with {.fn write_debrief_coding}."
      ))
    }

    coding <- coding[coding$id %in% ids, ]
  }

  parsed <- .parse_codes(coding$blocking_naive, coding$id)

  if (length(parsed$invalid) > 0L) {
    cli::cli_abort(c(
            "Codes must be {.code TRUE} or {.code FALSE}.",
      "x" = paste(
        "Different values found for {length(parsed$invalid)} participant{?s}:",
        "{.val {parsed$invalid}}."
      ),
      "i" = paste(
        "A spreadsheet program may have translated the values; fix the file",
        "and read it again."
      ),
      "i" = "See the file {.path {path}}"
    ))
  }

  uncoded <- coding$id[is.na(parsed$codes)]
  if (length(uncoded) > 0L) {
    cli::cli_abort(c(
            "All participants must be coded before proceeding.",
      "x" = paste(
        "Detected {length(uncoded)} uncoded participant{?s}: {.val {uncoded}}."
      ),
      "i" = "Code every answer in {.path {path}} before going on."
    ))
  }

  not_naive <- coding$id[!parsed$codes]
  cli::cli_inform(c(
    "i" = paste(
      "{length(not_naive)} of {nrow(coding)} participant{?s} coded",
      "{.code FALSE}: their answer either describes blocking or is missing,",
      "so they cannot be assumed naive to the purpose of the study."
    )
  ))

  not_naive
}


#' Read a debriefing coding file
#'
#' @param path Character(1). Full path of the coding file.
#' @param call Environment for error reporting.
#'
#' @returns A tibble with the columns of `.debrief_coding_cols`, all character
#'   apart from `prior_knowledge` (logical); empty cells are `NA`.
#'
#' @noRd
.read_coding_file <- function(path, call = rlang::caller_env()) {
  read <- function(sep) {
    utils::read.csv(
      path,
      sep = sep,
      colClasses = "character",
      na.strings = "",
      fileEncoding = "UTF-8-BOM",
      check.names = FALSE
    )
  }

  coding <- read(",")
  if (!all(.debrief_coding_cols %in% names(coding))) {
    coding <- read(";")
  }

  missing_cols <- setdiff(.debrief_coding_cols, names(coding))
  if (length(missing_cols) > 0L) {
    cli::cli_abort(c(
            "The coding file lacks {length(missing_cols)} column{?s}.",
      "x" = "Missing: {.field {missing_cols}}.",
      "i" = "See the file {.path {path}}"
    ), call = call)
  }

  coding <- tibble::as_tibble(coding[, .debrief_coding_cols])
  coding$id <- trimws(coding$id)
  coding$prior_knowledge <- as.logical(coding$prior_knowledge)
  coding$blocking_naive <- trimws(coding$blocking_naive)

  repeated <- unique(coding$id[duplicated(coding$id)])
  if (length(repeated) > 0L) {
    cli::cli_abort(c(
            "The coding file must not contain any participant more than once.",
      "x" = "Detected {length(repeated)} repeated ID{?s}: {.val {repeated}}."
    ), call = call)
  }

  coding
}


#' Parse the codes of naivety to blocking
#'
#' @param codes Character or logical. Codes as read from a coding file.
#' @param ids Character. Participant IDs of `codes`, for messages.
#'
#' @returns A list with `codes` (logical; `NA` for an empty code) and
#'   `invalid` (the IDs whose code is neither `TRUE` nor `FALSE`).
#'
#' @noRd
.parse_codes <- function(codes, ids) {
  text <- toupper(trimws(as.character(codes)))
  text[text %in% ""] <- NA_character_
  valid <- is.na(text) | text %in% c("TRUE", "FALSE")
  list(
    codes = ifelse(valid, text == "TRUE", NA),
    invalid = as.character(ids[!valid])
  )
}
