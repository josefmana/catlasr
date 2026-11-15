# Keep a private key mapping platform identifiers to random participant IDs

Replaces platform identifiers, such as JATOS study result IDs, with
random participant identifiers, so that no data bundle and nothing
derived from one, carries an identifier that links back to the platform
and, through it, to e-mail addresses or start times. The key lives in
the private folder and grows with every call, with identifiers seen
before keeping their participant ID and new ones getting fresh random
IDs.

## Usage

``` r
update_id_key(ids, file, prefix = NULL, dir = Sys.getenv("CATLAS_PRIVATE_DIR"))
```

## Arguments

- ids:

  Platform identifiers, one per study result, e.g. the `id_sr` column of
  [`pull_jatos_batches()`](https://josefmana.github.io/catlasr/reference/pull_jatos_batches.md).
  Coerced to character. Must not contain `NA`.

- file:

  Character(1). Path of the key file within the private folder, e.g.
  `"fba-allergy-online-02/id-key.rds"`. It must be an `.rds` file.

- prefix:

  Character(1), `NA` or `NULL`. Prefix of the participant IDs. `NULL`
  (default) and `NA` prepend no prefix.

- dir:

  Character(1). The private folder. Defaults to the environment variable
  `CATLAS_PRIVATE_DIR`, which belongs in `.Renviron`.

## Value

A character vector of participant IDs, of the same length and in the
same order as `ids`.

## Details

**Call this function before building any bundle, writing any coding file
or recording any exclusion.**

### Participant IDs

A participant ID is a random six-digit number, e.g. `"482913"`, preceded
by `prefix` if one is given (e.g. `"p482913"`), drawn without
replacement among those not yet in the key. The number never starts with
zero, so that spreadsheet programs, which drop leading zeros of numbers,
cannot alter an ID in the debriefing coding file. Unlike sequential
numbers, such as JATOS's `id_sr`, the CATLAS participant IDs do not
contain any information about the order or the time of participation.

### Randomness

The digits are drawn from a freshly initialised random number generator,
so that they do not depend on any seed set in the calling script,
because anyone with the correct seed and the platform identifiers could
rebuild the key otherwise. The state of the session's generator is
restored after the IDs are generated. The key file makes the IDs
reproducible, so losing it breaks the link between later pulls and
earlier IDs.

### The key

A tibble with the columns `source_id` (the platform identifier, as
character), `id` (the participant ID) and `assigned_at` (UTC), saved in
the private folder, with the guards of
[`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md),
whenever new identifiers arrive. Like every private file, it must never
enter a repository.

## See also

[`write_private_rds()`](https://josefmana.github.io/catlasr/reference/write_private_rds.md),
[`read_private_rds()`](https://josefmana.github.io/catlasr/reference/read_private_rds.md)
