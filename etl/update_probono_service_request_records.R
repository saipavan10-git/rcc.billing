library(dotenv)
library(redcapcustodian)
library(REDCapR)
library(tidyverse)
library(rcc.billing)

init_etl("update_probono_service_request_records")

source_credentials <- get_redcap_credentials(Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))

fields_to_read <- c(
  "record_id",
  "project_id",
  "time2",
  "time_more",
  "billable_rate",
  "always_bill"
)

service_requests <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  fields = fields_to_read,
  batch_size = 2000
)$data

rc_upload <- get_probono_service_request_updates(service_requests)

if (!interactive() && nrow(rc_upload) > 0) {
  write_result <- redcap_write(
    redcap_uri = source_credentials$redcap_uri,
    token =  source_credentials$token,
    ds_to_write = rc_upload
  )
}

log_job_success(jsonlite::toJSON(rc_upload))
