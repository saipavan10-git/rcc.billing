library(tibble)
library(usethis)
library(lubridate)

ctsit_staff <- tribble(
  ~redcap_username,
  "theriaqu",
  "tls",
  "amcmurra",
  "cabernat",
  "cpb",
  "pbc",
  "mbentz",
  "kyle.chesney",
  "lawjames1",
  "melimore86",
  "s.emerson",
  "maxprok",
  "kshanson",
  "cooper.martin",
  "colembl",
  "j.johnston",
  "tbembersimeao",
  "marlycormar",
  "taeber"
)

usethis::use_data(ctsit_staff, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff)

ctsit_staff_employment_periods <- tribble(
  ~redcap_username,
  ~employment_interval,
  "theriaqu", lubridate::interval(ymd("2010-04-21"), ymd("2013-05-22")),
  "tls", lubridate::interval(ymd("2012-04-11"), ymd("2100-01-01")),
  "amcmurra", lubridate::interval(ymd("2012-05-07"), ymd("2014-03-05")),
  "cabernat", lubridate::interval(ymd("2014-02-21"), ymd("2015-04-17")),
  "cpb", lubridate::interval(ymd("2010-05-06"), ymd("2100-01-01")),
  "pbc", lubridate::interval(ymd("2013-08-28"), ymd("2100-01-01")),
  "mbentz", lubridate::interval(ymd("2020-12-01"), ymd("2100-01-01")),
  "kyle.chesney", lubridate::interval(ymd("2019-04-01"), ymd("2100-01-01")),
  "lawjames1", lubridate::interval(ymd("2017-11-14"), ymd("2100-01-01")),
  "melimore86", lubridate::interval(ymd("2019-12-13"), ymd("2100-01-01")),
  "s.emerson", lubridate::interval(ymd("2019-09-12"), ymd("2100-01-01")),
  "maxprok", lubridate::interval(ymd("2022-01-06"), ymd("2100-01-01")),
  "kshanson", lubridate::interval(ymd("2014-06-01"), ymd("2021-05-31")),
  "cooper.martin", lubridate::interval(ymd("2019-05-21"), ymd("2021-12-21")),
  "colembl", lubridate::interval(ymd("2021-08-23"), ymd("2100-01-01")),
  "j.johnston", lubridate::interval(ymd("2017-07-24"), ymd("2021-04-26")),
  "marlycormar", lubridate::interval(ymd("2017-07-24"), ymd("2019-12-23")),
  "tbembersimeao", lubridate::interval(ymd("2017-07-26"), ymd("2018-12-21")),
  "taeber", lubridate::interval(ymd("2014-08-06"), ymd("2017-01-01")),
  "taeber", lubridate::interval(ymd("2018-08-03"), ymd("2020-10-08"))
)

usethis::use_data(ctsit_staff_employment_periods, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff_employment_periods)
