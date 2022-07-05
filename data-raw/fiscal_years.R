# Create static list of fiscal year intervals and labels so dates
# can be mapped to they correct FY labels.
library(lubridate)
library(dplyr)

START_YEAR <- 2019
END_YEAR <- 2040

starts_of_years <- START_YEAR:(END_YEAR - 1)
ends_of_years <- (START_YEAR + 1):END_YEAR

fy_start <- lubridate::ymd(paste0(starts_of_years, "-07-01"), tz="America/New_York")
fy_end <- lubridate::ymd(paste0(ends_of_years, "-07-01"), tz="America/New_York")

fiscal_years <- tibble::tibble(
  "csbt_label" = paste0(starts_of_years, "-", ends_of_years),
  "fy_interval" = lubridate::interval(fy_start, fy_end)
)

usethis::use_data(fiscal_years, overwrite = TRUE)

#sinew::makeOxygen("fiscal_years")
