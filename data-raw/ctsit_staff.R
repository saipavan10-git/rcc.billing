library(tibble)
library(usethis)
library(lubridate)

ctsit_staff <- tribble(
  ~redcap_username,
  "pbc",
  "tls",
  "cpb",
  "mbentz",
  "kyle.chesney",
  "taeber"
)

usethis::use_data(ctsit_staff, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff)

ctsit_staff_employment_periods <- tribble(
  ~redcap_username,
  ~employment_interval,
  "pbc", lubridate::interval(ymd("2011-05-01"), ymd("2100-01-01")),
  "tls", lubridate::interval(ymd("2014-01-01"), ymd("2100-01-01")),
  "cpb", lubridate::interval(ymd("2011-05-11"), ymd("2100-01-01")),
  "mbentz", lubridate::interval(ymd("2020-12-01"), ymd("2100-01-01")),
  "kyle.chesney", lubridate::interval(ymd("2019-04-01"), ymd("2100-01-01")),
  "taeber", lubridate::interval(ymd("2000-01-01"), ymd("2000-01-02")),
  "taeber", lubridate::interval(ymd("2001-01-01"), ymd("2001-01-02"))
)

usethis::use_data(ctsit_staff_employment_periods, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff_employment_periods)
