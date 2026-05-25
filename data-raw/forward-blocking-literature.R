# forward-blocking-literature.R
#
# Import, validate and save data sets regarding studies forward blocking
# experimental designs (`forward_blocking_designs.csv`) and reported effect
# sizes (`forward_blocking_effects.csv`) from available literature, saved the as
# `fb_designs` and `fb_effects` data via {usethis} with the goal to be
# distribute them along with the package.

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
fb_designs <-
  catlasr:::catlas_designs(forward_blocking_designs_raw) |>
  catlasr:::validate_catlas_designs()

fb_effects <-
  catlasr:::catlas_effects(forward_blocking_effects_raw) |>
  catlasr:::validate_catlas_effects()


# --- Write --------------------------------------------------------------------
usethis::use_data(
  fb_designs,
  fb_effects,
  overwrite = TRUE
)
