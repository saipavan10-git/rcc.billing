library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

load_dot_env("prod.env")
source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))

record_ids <- c(
  3,    # A very old request that has no billable rate
  6267, # a record with responses that span two months
  6436, # a non-billable record
  6445, # a non-billable record
  6473, # a record we will choose to make billable in a mutate below
  6469, # a record we will choose to make billable in a mutate below
  7057, # A manually-marked non-billable record with no project ID.
        # Records without project IDs that have been manually marked as
        # probono are ignored instead of marked as billable. The number of
        # probono records created would be a non-revenue generating burden
        # on fiscal staff.
  7093  # A billable record with no project ID.
)

read_service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  batch_size = 2000,
  records = record_ids
)$data

service_requests <- read_service_requests |>
  # filter for only the requests we are testing
  filter(record_id %in% record_ids) |>
  # filter for only the responses we are testing (Because we'll
  # be adding data to record 7093 for years)
  filter(is.na(start_date) | start_date <= ymd("2024-12-18")) |>
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
    probono_reason,
    time2,
    time_more,
    mtg_scheduled_yn,
    meeting_date_time,
    date_of_work,
    start_date,
    end_date,
    response,
    comments,
    fiscal_contact_fn,
    fiscal_contact_ln,
    fiscal_contact_email,
    study_name,
    help_desk_response_complete
  ) |>
  # de-identify the person and study identifiers
  mutate(
    irb_number = if_else(!is.na(irb_number), "123", irb_number),
    pi = if_else(!is.na(pi), "Dr. Bogus PI", pi),
    redcap_username = if_else(!is.na(redcap_username), "bogus_rc_username", redcap_username),
    gatorlink = if_else(!is.na(gatorlink), "bogus_gatorlink", gatorlink),
    response = if_else(!is.na(response), "fake response", response),
    study_name = if_else(!is.na(study_name), "Fake Study", study_name),
    comments = if_else(!is.na(comments), "fake comment", comments)
  ) |>
  # de-identify more person identifiers
  mutate(
    across(c("last_name", "fiscal_contact_ln"), ~ if_else(!is.na(.), "l_name", .)),
    across(c("first_name", "fiscal_contact_fn"), ~ if_else(!is.na(.), "f_name", .)),
    across(c("pi_email"), ~ if_else(!is.na(.), "pi_email@ufl.edu", .)),
    across(c("email", "fiscal_contact_email"), ~ if_else(!is.na(.), "bogus@ufl.edu", .))
  ) |>
  # make a few more rows billable
  mutate(
    billable_rate = if_else(record_id %in% c(6473, 6469) & !is.na(redcap_repeat_instrument), 130, billable_rate)
  )

saveRDS(
  service_requests,
  testthat::test_path(
    "get_service_request_lines",
    "service_requests.rds"
  )
)
