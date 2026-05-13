library(readr)
library(here)

forward_blocking_designs <- read_delim(
  here("data-raw", "forward_blocking_designs.csv"),
  delim = ";"
)

forward_blocking_effects <- read_delim(
  here("data-raw", "forward_blocking_effects.csv"),
  delim = ";"
)

usethis::use_data(
  forward_blocking_designs,
  forward_blocking_effects,
  overwrite = TRUE
)
