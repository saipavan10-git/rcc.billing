library(redcapcustodian)
library(tidyverse)
library(REDCapR)
library(dotenv)
library(rcc.billing)
library(RMariaDB)

init_etl("update_free_support_time_remaining")

source_credentials <- get_redcap_credentials(project_pid = Sys.getenv("REDCAP_SERVICE_REQUEST_PID"))

service_requests_all <- redcap_read(
  redcap_uri = source_credentials$redcap_uri,
  token = source_credentials$token,
  batch_size = 2000
)$data

all_service_request_lines <- get_service_request_lines(service_requests_all, return_all_records = T)

rc_conn <- connect_to_redcap_db()

projects <- dplyr::tbl(rc_conn, "redcap_projects") |>
  select(project_id) |>
  collect()

partial_free_support_time_remaining <- all_service_request_lines |>
  filter(stringr::str_ends(service_instance_id, "-PB")) |>
  group_by(project_id) |>
  summarize(qty_provided = sum(qty_provided)) |>
  mutate(free_support_time_remaining = pmax(0, 1 - qty_provided)) |>
  filter(project_id %in% projects$project_id) |>
  mutate(project_id = as.numeric(project_id)) |>
  select(project_id, free_support_time_remaining)

free_support_time_remaining <- projects |>
  left_join(partial_free_support_time_remaining, by = "project_id") |>
  mutate(across("free_support_time_remaining", ~ if_else(is.na(.), 1, .)))

free_support_time_remaining_original <- dplyr::tbl(rc_conn, "free_support_time_remaining") |>
  collect()

result <- redcapcustodian::sync_table_2(
  conn = rc_conn,
  table_name = "free_support_time_remaining",
  source = free_support_time_remaining,
  source_pk = "project_id",
  target = free_support_time_remaining_original,
  target_pk = "project_id",
  insert = T,
  update = T,
  delete = F
)

update_records <- result$update_records
insert_records <- result$insert_records

if (nrow(update_records) > 0 | nrow(insert_records) > 0) {
  activity_log <- lst(
    update_records,
    insert_records
  )

  log_job_success(jsonlite::toJSON(activity_log))
}
