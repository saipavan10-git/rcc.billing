## Create cleanup_project_ownership_test_data

library(redcapcustodian)
library(rcc.billing)
library(tidyverse)
library(lubridate)
library(DBI)
library(RMariaDB)
library(dotenv)

# # run this once against a test redcap to extract the part we need
# conn <- connect_to_redcap_db()
#
# redcap_user_information <- tbl(conn, "redcap_user_information") %>%
#   collect() %>%
#   filter(ui_id >= 2)
#
# redcap_projects <- tbl(conn, "redcap_projects") %>%
#   collect()
#
# redcap_user_rights <- tbl(conn, "redcap_user_rights") %>%
#   collect()
#
# redcap_user_roles <- tbl(conn, "redcap_user_roles") %>%
#   collect()
#
# redcap_entity_project_ownership <- tbl(conn, "redcap_entity_project_ownership") %>%
#   collect()
#
# redcap_project_last_users <- tribble(
#   ~project_id, ~last_user,
#   123, "dummy"
# ) %>% filter(F)
#
# for (pid in redcap_projects$project_id) {
#   redcap_project_last_users <- redcap_project_last_users %>%
#     add_row(
#       project_id = pid,
#       last_user = get_last_project_user(conn, pid)
#     )
# }
#
# dbDisconnect(conn)
#
# cleanup_project_ownership_test_data <- list(
#   redcap_user_information = redcap_user_information,
#   redcap_projects = redcap_projects,
#   redcap_user_rights = redcap_user_rights,
#   redcap_user_roles = redcap_user_roles,
#   redcap_entity_project_ownership = redcap_entity_project_ownership,
#   redcap_project_last_users = redcap_project_last_users
# )
#
# save(cleanup_project_ownership_test_data,
#      file = testthat::test_path("cleanup_project_ownership",
#                                 "cleanup_project_ownership_test_data.rda"))
