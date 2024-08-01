# make test data for get_service_request_line_items
library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

dotenv::load_dot_env("prod.env")
source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))
redcapcustodian::set_script_run_time(lubridate::ymd_hms("2024-08-01 12:00:00"))

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

# record_ids <- c(3, 6267, 6436, 6445,6473, 6469)
#
read_service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  batch_size = 2000
  # records = record_ids
)$data

service_requests_of_interest <-
  read_service_requests |>
  filter(!is.na(project_id)) |>
    arrange(desc(record_id)) |>
    slice_head(n = 100)

service_requests <- read_service_requests |>
  filter(record_id %in% service_requests_of_interest$record_id) |>
  select(
    record_id,
    redcap_repeat_instrument,
    project_id,
    irb_number,
    submit_date,
    pi,
    last_name,
    first_name,
    pi_email,
    email,
    role,
    redcap_username,
    gatorlink,
    billable_rate,
    time2,
    time_more,
    mtg_scheduled_yn,
    meeting_date_time,
    date_of_work,
    end_date,
    response,
    comments,
    fiscal_contact_fn,
    fiscal_contact_ln,
    fiscal_contact_email,
    help_desk_response_complete
  ) |>
  mutate(
    # irb_number = if_else(!is.na(irb_number), "123", irb_number),
    pi = if_else(!is.na(pi), "Dr. Bogus PI", pi),
    last_name = if_else(!is.na(last_name), "l_name", last_name),
    first_name = if_else(!is.na(first_name), "f_name", first_name),
    pi_email = if_else(!is.na(pi_email), "pi_email@ufl.edu", pi_email),
    email = if_else(!is.na(email), "bogus@ufl.edu", email),
    redcap_username = if_else(!is.na(redcap_username), "bogus_rc_username", redcap_username),
    gatorlink= if_else(!is.na(gatorlink), "bogus_gatorlink", gatorlink),
    response = if_else(!is.na(response), "fake response", response),
    comments = if_else(!is.na(comments), "fake comment", comments),
    irb_number = c("123"),
    fiscal_contact_fn = c("John"),
    fiscal_contact_ln = c("Doe"),
    fiscal_contact_email = c("test@xyz.com")
  )

project_ids_of_interest <- service_requests |>
  distinct(project_id) |>
  pull(project_id)

invoice_line_item <- dplyr::tbl(rcc_billing_conn, "invoice_line_item") |>
  # collect() |>str()
  filter(service_type_code == 1 & service_identifier %in% local(as.character(project_ids_of_interest))) |>
  collect() %>%
  rowwise() %>%
  mutate(across(c("invoice_number", contains("pi_"), gatorlink), my_hash))

redcap_projects <-
  tbl(rc_conn, "redcap_projects") %>%
  filter(project_id %in% project_ids_of_interest) %>%
  collect() %>%
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
  filter(pid %in% project_ids_of_interest) %>%
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

# Write rc db tables ##########################################################

write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("get_service_request_line_items", paste0(basename, ".rds")))
}

# write all of the test inputs
test_tables <- c(
  "redcap_projects", # lives in REDCap DB
  "redcap_entity_project_ownership", # ibid
  "redcap_user_information", # ibid
  "invoice_line_item", # lives in rcc_billing DB
  "service_requests" # lives in REDCap PID 1414
)
walk(test_tables, ~ write_to_testing_rds(get(.), .))
