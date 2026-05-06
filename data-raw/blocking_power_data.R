# Compendium of previous research findings about forward blocking
# Serves as a basis for power/study design analysis of the blocking replication
library(readr)
library(here)

designs <- read_delim(here("data-raw", "forward_blocking_designs.csv"), delim = ";")
effects <- read_delim(here("data-raw", "forward_blocking_effects.csv"), delim = ";")

forward_blocking <- list(designs = designs, effects = effects)

usethis::use_data(forward_blocking, overwrite = TRUE)

# Add export to OSF?
