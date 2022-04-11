# Recommended approach from https://www.rdocumentation.org/packages/usethis/versions/2.1.5/topics/use_data
library(tibble)
library(usethis)

ctsit_staff <- tribble(
  ~redcap_username,
  ~employment_intervals,
  "pbc", '[ {start: "2011-05-01", end : ""} ]',
  "tls", '[ {start: "2014-01-01", end : ""} ]',
  "cpb", '[ {start: "2011-05-01", end : ""} ]',
  "mbentz", '[ {start: "2020-12-01", end : ""} ]',
  "kyle.chesney", '[ {start: "2019-04-01", end : ""} ]',
)

usethis::use_data(ctsit_staff, overwrite = TRUE)

# sinew::makeOxygen(ctsit_staff)
