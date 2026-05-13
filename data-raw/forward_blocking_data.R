# library(catlasr)
library(readr)
library(here)

# --- Read ---------------------------------------------------------------------
forward_blocking_designs_raw <- read_delim(
  here("data-raw", "forward_blocking_designs.csv"),
  delim = ";"
)

forward_blocking_effects_raw <- read_delim(
  here("data-raw", "forward_blocking_effects.csv"),
  delim = ";"
)

# --- Validate -----------------------------------------------------------------
forward_blocking_designs <-
  catlasr:::catlas_designs(forward_blocking_designs_raw) |>
  catlasr:::validate_catlas_designs()

forward_blocking_effects <-
  catlasr:::catlas_effects(forward_blocking_effects_raw) |>
  catlasr:::validate_catlas_effects()

# --- Write --------------------------------------------------------------------
usethis::use_data(
  forward_blocking_designs,
  forward_blocking_effects,
  overwrite = TRUE
)
