# make_test_data_for_request_correction_of_bad_ownership.R
library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
set_script_run_time()

conn <- connect_to_redcap_db()

test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_config"
)

redcap_projects <- tbl(conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  collect() %>%
  sample_n(size = 10) %>%
  mutate(project_pi_email = if_else(!is.na(project_pi_email) | project_pi_email == "",
    "bogus_user@ufl.edu",
    project_pi_email
  ))

# redcap_entity_project_ownership
redcap_entity_project_ownership <- tbl(conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() %>%
  mutate(across(c("username", "email", "firstname", "lastname"), ~NA_character_)) %>%
  mutate(
    billable = 1,
    updated = case_when(
      row_number() %in% c(1, 2, 3, 4) ~ ymd_hms("2023-04-01 07:00:00"),
      row_number() %in% c(5, 6) ~ ymd_hms("2023-03-01 07:00:00"),
      row_number() %in% c(7, 8) ~ ymd_hms("2023-04-01 07:00:00"),
      row_number() %in% c(9, 10) ~ ymd_hms("2023-05-01 07:00:00")
    )
  ) %>%
  mutate(
    sequestered = case_when(
      row_number() %in% c(1, 2, 3, 4) ~ 1,
      T ~ NA_real_
    )
  )

redcap_user_rights <- tbl(conn, "redcap_user_rights") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  collect()

redcap_user_roles <- tbl(conn, "redcap_user_roles") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  collect()

redcap_user_information <- tbl(conn, "redcap_user_information") %>%
  filter(username %in% !!redcap_user_rights$username) %>%
  collect() %>%
  mutate(across(starts_with("user_email"), ~ if_else(is.na(.), ., "bogus_user@ufl.edu")))

redcap_config <- tbl(conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect()

write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("request_correction_of_bad_ownership", paste0(basename, ".rds")))
}

# write all of the test inputs
walk(test_tables, ~ write_to_testing_rds(get(.), .))

