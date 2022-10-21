library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)

conn <- connect_to_redcap_db()

redcap_user_information <- tbl(conn, "redcap_user_information") %>% collect()
redcap_user_rights <- tbl(conn, "redcap_user_rights") %>% collect()
redcap_user_roles <- tbl(conn, "redcap_user_roles") %>% collect()

redcap_rights_test_data <- lst(
  redcap_user_information,
  redcap_user_rights,
  redcap_user_roles
)

usethis::use_data(redcap_rights_test_data, overwrite = TRUE)
