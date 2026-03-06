# Compendium of previous research findings about forward blocking
# Serves as a basis for power/study design analysis of the blocking replication
library(readr)
library(here)

designs <- read_delim(here("data-raw", "blocking_power_designs.csv"), delim = ";")
results <- read_delim(here("data-raw", "blocking_power_results.csv"), delim = ";")

blocking0 <- list(designs = designs, data = results)

usethis::use_data(blocking0, overwrite = TRUE)

# Add export to OSF?