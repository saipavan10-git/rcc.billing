library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

dotenv::load_dot_env("prod.env")
source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))
redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-02-05 12:00:00"))

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

record_ids <- c(3, 6267, 6436, 6445,6473, 6469)

read_service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  batch_size = 2000,
  records = record_ids
)$data

service_requests <- read_service_requests |>
  filter(record_id %in% record_ids) |>
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
saveRDS(
  service_requests,
  testthat::test_path(
    "get_service_request_line_items",
    "service_requests.rds"
  )
)

mock_invoice_line_item <- data.frame(
    id = c(1, 2, 3, 4),
    service_type_code = c(1, 1, 2, 1),
    service_identifier = c(14242, 12665, 14242, 12665),
    ctsi_study_id = c(300, 310, 200, 970)
  ) |>
    dplyr::mutate(across(everything(), as.integer)) |>
    dplyr::mutate(stringAsFactors = FALSE)
saveRDS(
  mock_invoice_line_item,
  testthat::test_path(
    "get_service_request_line_items",
    "invoice_line_item.rds"
  )
)

mock_ctsi_study_id_map <- data.frame(
    project_id = c(14242, 12665),
    ctsi_study_id = c(300, 310, 200, 970)
  ) |>
    dplyr::mutate(across(everything(), as.integer)) |>
    dplyr::mutate(stringAsFactors = FALSE)
saveRDS(
  mock_ctsi_study_id_map,
  testthat::test_path(
    "get_service_request_line_items",
    "ctsi_study_id_map.rds"
  )
)

# Create mock data for project details
mock_project_details <- data.frame(
    project_id = as.integer(c("14242", "12665")),
    app_title = c("Project 14242", "Project 12665"),
    pi_last_name = c(NA, "Doe"),
    pi_first_name = c(NA, "John"),
    pi_email = c(NA, "john.doe@example.com"),
    irb_number = c(NA, "123"),
    ctsi_study_id = c(NA, "300"),
    stringsAsFactors = FALSE
  )
saveRDS(
  mock_project_details,
  testthat::test_path(
    "get_service_request_line_items",
    "project_details.rds"
  )
)
# Create mock data for redcap_entity_project_ownership
mock_redcap_entity_project_ownership <- data.frame(
    id = 1:2,
    created = as.numeric(Sys.time()),
    updated = as.numeric(Sys.time()),
    pid = as.integer(c("14242", "12665")),
    username = c(NA, "jsmith"),
    email = c("jdoe@example.com", NA),
    firstname = c("John", NA),
    lastname = c("Doe", NA),
    billable = c(1, 1),
    sequestered = c(0, 0)
  )
saveRDS(
  mock_redcap_entity_project_ownership,
  testthat::test_path(
    "get_service_request_line_items",
    "redcap_entity_project_ownership.rds"
  )
)

redcap_projects <-
  dplyr::tbl(rc_conn, "redcap_projects") |>
  dplyr::collect() |>
  dplyr::sample_n(size = 4) |>
  dplyr::arrange(project_id) |>
  dplyr::mutate(
    creation_time = redcapcustodian::get_script_run_time() - lubridate::dyears(1) - lubridate::ddays(15)
  ) |>
  dplyr::mutate(date_deleted = as.Date(NA)) |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::contains(c("project_pi", "app_title", "project_name")), my_hash)) |>
  dplyr::mutate(project_id= case_when(
      project_id %in% c(11987,12271) ~ as.integer(14242),
      project_id %in% c(13934,15467) ~ as.integer(12665),
    ))
saveRDS(
  redcap_projects,
  testthat::test_path(
    "get_service_request_line_items",
    "redcap_projects.rds"
  )
)

redcap_entity_project_ownership_raw <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() |>
  dplyr::arrange(pid) |>
  mutate(billable = 1) |>
  mutate(sequestered = 0)

redcap_user_information <- dplyr::tbl(rc_conn, "redcap_user_information") |>
  dplyr::filter(username %in% redcap_entity_project_ownership_raw$username) |>
  dplyr::select(
    "username",
    "user_email",
    "user_firstname",
    "user_lastname"
  ) |>
  dplyr::collect() |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::everything(), my_hash)) |>
  dplyr::mutate(dplyr::across(dplyr::contains("email"), ~ if_else(is.na(.), "dummy", .))) |>
  dplyr::mutate(dplyr::across(dplyr::contains("email"), append_fake_email_domain))
saveRDS(
  redcap_user_information,
  testthat::test_path(
    "get_service_request_line_items",
    "redcap_user_information.rds"
  )
)


