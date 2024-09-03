library(tibble)
library(usethis)
library(lubridate)

ctsit_staff_employment_periods <- tribble(
  ~redcap_username,
  ~employment_interval,
  ~term_date_is_accurate,
  "theriaqu", lubridate::interval(ymd("2010-04-21"), ymd("2013-05-22")), 1,
  "tls", lubridate::interval(ymd("2012-04-11"), ymd("2100-01-01")), 0,
  "amcmurra", lubridate::interval(ymd("2012-05-07"), ymd("2014-03-05")), 1,
  "cabernat", lubridate::interval(ymd("2014-02-21"), ymd("2015-04-17")), 1,
  "cpb", lubridate::interval(ymd("2010-05-06"), ymd("2100-01-01")), 0,
  "pbc", lubridate::interval(ymd("2013-08-28"), ymd("2100-01-01")), 0,
  "mbentz", lubridate::interval(ymd("2020-12-01"), ymd("2024-08-23")), 1,
  "kyle.chesney", lubridate::interval(ymd("2019-04-01"), ymd("2024-04-27")), 1,
  "lawjames1", lubridate::interval(ymd("2017-11-14"), ymd("2100-01-01")), 0,
  "melimore86", lubridate::interval(ymd("2019-12-13"), ymd("2100-01-01")), 0,
  "s.emerson", lubridate::interval(ymd("2019-09-12"), ymd("2100-01-01")), 0,
  "maxprok", lubridate::interval(ymd("2022-01-06"), ymd("2023-07-01")), 0,
  "kshanson", lubridate::interval(ymd("2014-06-01"), ymd("2021-05-31")), 1,
  "cooper.martin", lubridate::interval(ymd("2019-05-21"), ymd("2021-12-21")), 1,
  "colembl", lubridate::interval(ymd("2021-08-23"), ymd("2100-01-01")), 0,
  "j.johnston", lubridate::interval(ymd("2017-07-24"), ymd("2021-04-26")), 1,
  "marlycormar", lubridate::interval(ymd("2017-07-24"), ymd("2019-12-23")), 1,
  "tbembersimeao", lubridate::interval(ymd("2017-07-26"), ymd("2018-12-21")), 1,
  "taeber", lubridate::interval(ymd("2014-08-06"), ymd("2017-01-01")), 1,
  "taeber", lubridate::interval(ymd("2018-08-03"), ymd("2020-10-08")), 1
) |>
  bind_rows(
    tribble(
      ~redcap_username, ~hire_date, ~term_date, ~term_date_is_accurate,
      "looseymoose", "2017-02-27", "2023-07-01", 0,
      "jmjenny", "2016-12-02", "2023-07-01", 0,
      "v.pandey", "2019-06-28", "2023-07-01", 0,
      "purvakulkarni", "2019-06-28", "2023-07-01", 0,
      "hunter.jarrell", "2018-08-24", "2023-07-01", 0,
      "alyssakelly", "2019-09-04", "2023-07-01", 0,
      "joshabraham", "2021-12-17", "2023-07-01", 0,
      "amoghagarwal", "2021-07-06", "2023-07-01", 0,
      "karanasthana", "2021-12-17", "2023-07-01", 0,
      "rtatiraju", "2021-12-17", "2023-07-01", 0,
      "puranikpurva", "2023-03-03", "2023-07-01", 0,
      "millerjohn", "2022-07-01", "2023-07-01", 0,
      "mehuljhaver", "2023-08-18", "2023-07-01", 0,
      "emilyolsen", "2021-10-06", "2023-07-01", 0,
      "sinha.kshitij", "2023-03-03", "2023-07-01", 0,
      "amineni95", "2016-12-02", "2018-07-01", 1,
      "mbuchholz ", "2014-06-06", "2018-12-01", 1,
      "anthony7131998", "2018-08-24", "2019-01-25", 1,
      "niraja1101", "2019-02-08", "2019-06-20", 1,
      "henderson.b", "2023-02-23", "2023-07-13", 1,
      "tracy.blair", "2019-04-01", "2024-08-23", 1,
      "deshpande.v", "2023-08-01", "2024-08-23", 0
    ) |>
      mutate(across(c("hire_date", "term_date"), lubridate::ymd)) |>
      mutate(employment_interval = lubridate::interval(hire_date, term_date), .after = redcap_username) |>
      mutate(term_date_is_accurate = as.logical(term_date_is_accurate)) |>
      select(-c("hire_date", "term_date"))
  )

usethis::use_data(ctsit_staff_employment_periods, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff_employment_periods)

ctsit_staff <- ctsit_staff_employment_periods |>
  distinct(redcap_username) |>
  arrange(redcap_username)

usethis::use_data(ctsit_staff, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff)

