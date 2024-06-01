library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))

read_service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  batch_size = 2000
)$data

record_ids <- c(3, 6267, 6436, 6445,6473, 6469)

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
    response
  ) |>
  mutate(response = if_else(!is.na(response), "fake response", response))

saveRDS(
  service_requests,
  testthat::test_path(
    "get_service_request_lines",
    "service_requests.rds"
  )
)

