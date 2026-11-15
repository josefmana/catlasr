#' Keep a private key mapping platform identifiers to random participant IDs
#'
#' Replaces platform identifiers, such as JATOS study result IDs, with random
#' participant identifiers, so that no data bundle and nothing derived from
#' one, carries an identifier that links back to the platform and, through it,
#' to e-mail addresses or start times. The key lives in the private folder and
#' grows with every call, with identifiers seen before keeping their participant
#' ID and new ones getting fresh random IDs.
#'
#' **Call this function before building any bundle, writing any coding file or
#' recording any exclusion.**
#'
#' @param ids Platform identifiers, one per study result, e.g. the `id_sr`
#'   column of [pull_jatos_batches()]. Coerced to character. Must not contain
#'   `NA`.
#' @param file Character(1). Path of the key file within the private folder,
#'   e.g. `"fba-allergy-online-02/id-key.rds"`. It must be an `.rds` file.
#' @param prefix Character(1), `NA` or `NULL`. Prefix of the participant IDs.
#'   `NULL` (default) and `NA` prepend no prefix.
#' @inheritParams write_private_csv
#'
#' @returns A character vector of participant IDs, of the same length and in
#'   the same order as `ids`.
#'
#' @details
#' ## Participant IDs
#'
#' A participant ID is a random six-digit number, e.g. `"482913"`, preceded by
#' `prefix` if one is given (e.g. `"p482913"`), drawn without replacement
#' among those not yet in the key. The number never starts with zero, so that
#' spreadsheet programs, which drop leading zeros of numbers, cannot alter an
#' ID in the debriefing coding file. Unlike sequential numbers, such as JATOS's
#' `id_sr`, the CATLAS participant IDs do not contain any information about
#' the order or the time of participation.
#'
#' ## Randomness
#'
#' The digits are drawn from a freshly initialised random number generator, so
#' that they do not depend on any seed set in the calling script, because anyone
#' with the correct seed and the platform identifiers could rebuild the key
#' otherwise. The state of the session's generator is restored after the IDs are
#' generated. The key file makes the IDs reproducible, so losing it breaks the
#' link between later pulls and earlier IDs.
#'
#' ## The key
#'
#' A tibble with the columns `source_id` (the platform identifier, as
#' character), `id` (the participant ID) and `assigned_at` (UTC), saved in the
#' private folder, with the guards of [write_private_rds()], whenever new
#' identifiers arrive. Like every private file, it must never enter a
#' repository.
#'
#' @seealso [write_private_rds()], [read_private_rds()]
#'
#' @export
update_id_key <- function(
    ids,
    file,
    prefix = NULL,
    dir = Sys.getenv("CATLAS_PRIVATE_DIR")
) {
  if (!is.atomic(ids) || length(ids) == 0L || anyNA(ids)) {
    cli::cli_abort(c(
            "`ids` must be a non-empty vector of identifiers without `NA`.",
      "i" = "Pass, e.g., the {.field id_sr} column of {.fn pull_jatos_batches}."
    ))
  }

  if (is.null(prefix) || (length(prefix) == 1L && is.na(prefix))) {
    prefix <- ""
  }

  if (!rlang::is_string(prefix)) {
    cli::cli_abort("`prefix` must be a single string, `NA` or `NULL`.")
  }

  ids <- as.character(ids)
  path <- .private_path(file, dir, overwrite = TRUE)

  key <- if (file.exists(path)) {
    .check_id_key(readRDS(path), path)
  } else {
    tibble::tibble(
      source_id = character(),
      id = character(),
      assigned_at = as.POSIXct(character(), tz = "UTC")
    )
  }

  new <- setdiff(unique(ids), key$source_id)

  if (length(new) > 0L) {
    assigned_at <- Sys.time()
    attr(assigned_at, "tzone") <- "UTC"
    key <- dplyr::bind_rows(
      key,
      tibble::tibble(
        source_id = new,
        id = .draw_participant_ids(
          n = length(new),
          prefix = prefix,
          taken = key$id
        ),
        assigned_at = assigned_at
      )
    )
    saveRDS(key, path)
  }

  n_known <- length(unique(ids)) - length(new)
  cli::cli_inform(c(
    "i" = paste(
      "{n_known} identifier{?s} already in the key; {length(new)} new",
      "participant ID{?s} assigned."
    ),
    "i" = "Key file: {.path {path}} ({nrow(key)} entr{?y/ies})."
  ))

  key$id[match(ids, key$source_id)]
}


#' Check a participant ID key read from disk
#'
#' @param key The object read from the key `.rds` file.
#' @param path Character(1). The key file, for messages.
#' @param call Environment for error reporting.
#'
#' @returns `key`, with `source_id` and `id` as character, if it is a valid
#'   key; otherwise an informative error.
#'
#' @noRd
.check_id_key <- function(key, path, call = rlang::caller_env()) {
  if (!is.data.frame(key) || !all(c("source_id", "id") %in% names(key))) {
    cli::cli_abort(c(
            "The key file does not contain a participant ID key.",
      "x" = "{.path {path}}",
      "i" = "A key must have the columns {.field source_id} and {.field id}."
    ), call = call)
  }

  key$source_id <- as.character(key$source_id)
  key$id <- as.character(key$id)

  duplicated_ids <- c(
    key$source_id[duplicated(key$source_id)],
    key$id[duplicated(key$id)]
  )
  if (length(duplicated_ids) > 0L || anyNA(key$source_id) || anyNA(key$id)) {
    cli::cli_abort(c(
            "The participant ID key is damaged.",
      "x" = "{.path {path}} holds duplicated or missing identifiers.",
      "i" = "Restore the key from a backup before importing any new data."
    ), call = call)
  }

  tibble::as_tibble(key)
}


#' Draw new random participant IDs
#'
#' @param n Integer(1). How many IDs to draw.
#' @param prefix Character(1). Prefix of the IDs.
#' @param taken Character. IDs already in use.
#'
#' @returns A character vector of `n` IDs, distinct from each other and from
#'   `taken`.
#'
#' @details
#' Because the user can specify IDs with no prefix (default), any random ID
#' starting with zero would be at risk of incorrect reading (e.g., in Excel,
#' leading zeroes would be most likely dropped). Consequently, the sampled
#' integers to serve as IDs can go from 100000 to 999999.
#'
#' @noRd
.draw_participant_ids <- function(n, prefix, taken) {
  if (n > 9e5L - length(taken)) {
    cli::cli_abort("Not enough six-digit participant IDs left in the key.")
  }

  seed_exists <- exists(
    ".Random.seed",
    envir = globalenv(),
    inherits = FALSE
  )
  if (seed_exists) {
    old_seed <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  }
  on.exit(
    if (seed_exists) {
      assign(
        ".Random.seed",
        old_seed,
        envir = globalenv()
      )
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    },
    add = TRUE
  )

  set.seed(NULL)

  drawn <- character()
  while (length(drawn) < n) {
    candidates <- sprintf("%s%d", prefix, sample.int(9e5L, n) + 99999L)
    drawn <- unique(c(drawn, setdiff(candidates, taken)))
  }

  drawn[seq_len(n)]
}
