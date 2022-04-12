## Create redcap_projects_test_data from invoice_line_items_test_data

library(redcapcustodian)
library(rcc.billing)
library(tidyverse)
library(lubridate)
library(DBI)
library(RMariaDB)
library(dotenv)

project_table_cols <-
  invoice_line_item_test_data %>%
  filter(service_type_code == 1) %>%
  filter(id >= 4) %>%
  head(4) %>%
  select(
    project_id = service_instance_id,
    app_title = name_of_service,
    project_pi_firstname = pi_first_name,
    project_pi_lastname = pi_last_name,
    project_pi_email = pi_email
  ) %>%
  mutate(project_id = as.numeric(project_id)) %>%
  mutate(project_name = gsub(" ", "_", tolower(app_title))) %>%
  mutate(creation_time = ymd("2021-05-15") + ddays(c(-3.2, 5.5, -1.7, -7.4)) - years(c(0,3,2,1)))

# # run this once against a test redcap to extract the part we need
# conn <- connect_to_redcap_db()
# projects <- tbl(conn, "redcap_projects")
#
# projects_table_fragment <- projects %>%
#   filter(project_id >= 15) %>%
#   filter(status == 0) %>%
#   filter(is.na(date_deleted)) %>%
#   head(nrow(project_table_cols)) %>%
#   collect() %>%
#   select(-colnames(project_table_cols))
# usethis::use_data(projects_table_fragment, overwrite = T)
#
# one_deleted_project_record <- projects %>%
#   filter(project_id >= 15) %>%
#   filter(status == 0) %>%
#   filter(is.na(date_deleted)) %>%
#   head(nrow(project_table_cols) + 1) %>%
#   collect() %>%
#   tail(1) %>%
#   mutate(project_id = min(as.numeric(project_table_cols$project_id)) - 2,
#          creation_time = min(project_table_cols$creation_time) - ddays(2),
#          date_deleted = creation_time + ddays(30)
#   )
# usethis::use_data(one_deleted_project_record, overwrite = T)

redcap_projects_test_data <-
  bind_cols(project_table_cols,
            projects_table_fragment) %>%
  bind_rows(one_deleted_project_record)

usethis::use_data(redcap_projects_test_data, overwrite = T)
