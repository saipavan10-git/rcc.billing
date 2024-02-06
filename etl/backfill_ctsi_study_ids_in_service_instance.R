library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)

init_etl("backfill_ctsi_study_ids_in_service_instance")

rcc_billing_conn <- connect_to_rcc_billing_db()

service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
collect()

invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
collect()

service_instance_updates <- get_new_ctsi_study_ids(service_instance, invoice_line_item) |>
  select(service_instance_id, ctsi_study_id)

service_instance_diff <- redcapcustodian::dataset_diff(
  source = service_instance_updates,
  source_pk = "service_instance_id",
  target = service_instance,
  target_pk = "service_instance_id",
  insert = T,
  delete = F
)

service_instance_sync_activity <- redcapcustodian::sync_table(
  conn = rcc_billing_conn,
  table_name = "service_instance",
  primary_key = "service_instance_id",
  data_diff_output = service_instance_diff,
  insert = F,
  update = T,
  delete = F
)

activity_log <- lst(service_instance_updates)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rcc_billing_conn)
