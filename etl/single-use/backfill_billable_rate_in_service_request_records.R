library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

load_dot_env("prod.env")
init_etl("backfill_billable_rate_in_service_request_records")

source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))
target_credentials <- source_credentials
# target_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID_TEST"))

fields_to_read <- c(
  "record_id",
  "submit_date",
  "project_id",
  "time2",
  "time_more",
  "billable_rate"
)

service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  fields = fields_to_read,
  batch_size = 2000
)$data

rc_upload <- service_requests |>
  dplyr::arrange(
    .data$record_id,
    .data$redcap_repeat_instrument,
    .data$redcap_repeat_instance
  ) |>
  # fill project ids and submit date on each record group
  dplyr::group_by(.data$record_id) |>
  tidyr::fill(c("project_id", "submit_date"), .direction = "updown") |>
  dplyr::ungroup() |>
  dplyr::filter(!is.na(.data$project_id)) |>
  dplyr::filter(!is.na(.data$redcap_repeat_instrument)) |>
  filter(is.na(billable_rate)) |>
  mutate(billable_rate = case_when(
    submit_date >= lubridate::ymd("2023-11-01") ~ 130,
    submit_date >= lubridate::ymd("2023-07-01") ~ 100,
    T ~ NA_real_
  )) |>
  filter(!is.na(billable_rate)) |>
  select(record_id,
         redcap_repeat_instrument,
         redcap_repeat_instance,
         billable_rate
         )

if (!interactive() && nrow(rc_upload) > 0) {
  write_result <- redcap_write(
    redcap_uri = target_credentials$redcap_uri,
    token =  target_credentials$token,
    ds_to_write = rc_upload,
    batch_size = 100
  )
}

log_job_success(jsonlite::toJSON(rc_upload))
