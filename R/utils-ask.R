#' Ask for a value at the console, re-asking until it validates
#'
#' @param prompt Character(1). The question, without trailing punctuation.
#' @param default Character(1) or `NULL`. Shown in brackets; an empty answer
#'   takes it.
#' @param validate Function or `NULL`. Called on the answer and expected to
#'   abort on bad input. Its condition message is shown and the question is
#'   repeated, so the user corrects one field instead of restarting.
#' @param required Logical(1). Whether an empty answer with no default is
#'   refused.
#'
#' @returns Character(1), or `NA_character_` for a skipped optional field.
#'
#' @noRd
.ask <- function(prompt, default = NULL, validate = NULL, required = TRUE) {
  label <- if (is.null(default)) {
    sprintf("%s: ", prompt)
  } else {
    sprintf("%s [%s by default]: ", prompt, default)
  }

  repeat {
    answer <- trimws(readline(label))

    if (!nzchar(answer)) {
      if (!is.null(default)) return(default)
      if (!required)         return(NA_character_)
      cli::cli_alert_warning("This field is required.")
      next
    }

    if (is.null(validate)) return(answer)

    # Validate by calling the real validator rather than re-implementing it,
    # so the wizard and `build_provenance()` cannot disagree about what is
    # acceptable.
    checked <- tryCatch(validate(answer), error = function(e) e)
    if (inherits(checked, "error")) {
      cli::cli_alert_danger(conditionMessage(checked))
      next
    }
    return(answer)
  }
}


#' Ask the user to pick one of a fixed set of values
#'
#' @param prompt Character(1).
#' @param choices Character. The permitted values, shown as a numbered menu.
#'
#' @returns Character(1), one of `choices`.
#'
#' @noRd
.ask_choice <- function(prompt, choices) {
  cli::cli_text(prompt)
  picked <- utils::menu(choices)

  # `menu()` returns 0 when the user chooses to exit, which is a deliberate
  # cancellation rather than bad input, so it aborts the procees
  if (picked == 0L) {
    cli::cli_abort("Cancelled at the {.val {prompt}} prompt.")
  }

  choices[picked]
}


#' Ask for a positive whole number
#'
#' @param prompt Character(1).
#' @param default Integer(1) or `NULL`.
#'
#' @returns Integer(1).
#'
#' @noRd
.ask_integer <- function(prompt, default = NULL) {
  answer <- .ask(
    prompt,
    default = if (is.null(default)) {
      NULL
    } else {
      as.character(default)
    },
    validate = function(a) {
      n <- suppressWarnings(as.integer(a))
      if (is.na(n) || n <= 0L) {
        stop("Enter a positive whole number.", call. = FALSE)
      }
    }
  )
  as.integer(answer)
}


#' Ask for a date
#'
#' @param prompt Character(1).
#' @param default Character(1) or `NULL`, as `YYYY-MM-DD`.
#'
#' @returns A `Date` of length 1.
#'
#' @noRd
.ask_date <- function(prompt, default = NULL) {
  answer <- .ask(
    prompt,
    default  = default,
    validate = function(a) {
      d <- try(as.Date(a), silent = TRUE)
      if (inherits(d, "try-error") || is.na(d)) {
        stop("Enter a date as YYYY-MM-DD.", call. = FALSE)
      }
    }
  )
  as.Date(answer)
}


#' Ask for a comma-separated list of positive whole numbers
#'
#' @param prompt Character(1).
#'
#' @returns Integer vector, at least length 1.
#'
#' @noRd
.ask_integers <- function(prompt) {
  answer <- .ask(
    prompt,
    validate = function(a) {
      n <- suppressWarnings(as.integer(strsplit(a, "\\s*,\\s*")[[1L]]))
      if (length(n) == 0L || anyNA(n) || any(n <= 0L)) {
        stop("Enter one or more positive whole numbers, comma separated.", call. = FALSE)
      }
      if (anyDuplicated(n)) {
        stop("The same value appears twice.", call. = FALSE)
      }
    }
  )
  as.integer(strsplit(answer, "\\s*,\\s*")[[1L]])
}
