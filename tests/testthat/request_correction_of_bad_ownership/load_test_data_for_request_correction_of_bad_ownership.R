# load_test_data_for_request_correction_of_bad_ownership.R
#
library(redcapcustodian)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

set_script_run_time(ymd_hms("2023-04-01 12:00:00"))

# Create test tables
test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_config"
)
conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
create_a_table_from_test_data <- function(table_name, conn, directory_under_test_path) {
  readRDS(testthat::test_path(directory_under_test_path, paste0(table_name, ".rds"))) %>%
    DBI::dbWriteTable(conn = conn, name = table_name, value = .)
}

purrr::walk(test_tables, create_a_table_from_test_data, conn, "request_correction_of_bad_ownership")

# check your work
DBI::dbListTables(conn)
