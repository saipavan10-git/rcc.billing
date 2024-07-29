# make_test_data_for_get_project_details_for_billing.R

library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
set_script_run_time(ymd_hms("2023-06-12 12:00:00"))

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

# find 120 viable project_ids
provisional_redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  collect() %>%
  sample_n(size = 200) %>%
  arrange(project_id)

provisional_redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!provisional_redcap_projects$project_id) %>%
  collect()

redcap_projects <-
  tbl(rc_conn, "redcap_projects") %>%
  # filter(is.na(date_deleted)) %>%
  filter(project_id %in% !!provisional_redcap_entity_project_ownership$pid) %>%
  collect() %>%
  sample_n(size = 120) %>%
  arrange(project_id) %>%
  rowwise() %>%
  mutate(across(
    c(
      "project_pi_firstname",
      "project_pi_lastname",
      "project_pi_email",
      "project_irb_number"
    ),
    my_hash
  )) %>%
  mutate(across("project_pi_email", append_fake_email_domain))

redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() %>%
  rowwise() %>%
  mutate(across(c("username", "email", "firstname", "lastname"), my_hash)) %>%
  mutate(across("email", append_fake_email_domain))

redcap_user_information <- tbl(rc_conn, "redcap_user_information") %>%
  collect() %>%
  rowwise() %>%
  mutate(across(c(
    "username",
    "user_email",
    "user_email2",
    "user_email3",
    "user_firstname",
    "user_lastname",
    "user_sponsor"
  ), my_hash)) %>%
  mutate(across("user_email", append_fake_email_domain))

invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(service_identifier %in% !!redcap_projects$project_id) %>%
  collect() %>%
  rowwise() %>%
  mutate(across(c("invoice_number"), my_hash))

# Write rc db tables ##########################################################

write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("get_project_details_for_billing", paste0(basename, ".rds")))
}

# write all of the test inputs
test_tables <- c(
  "redcap_projects", # lives in REDCap DB
  "redcap_entity_project_ownership", # ibid
  "redcap_user_information", # ibid
  "invoice_line_item" # lives in rcc_billing DB
)
walk(test_tables, ~ write_to_testing_rds(get(.), .))
