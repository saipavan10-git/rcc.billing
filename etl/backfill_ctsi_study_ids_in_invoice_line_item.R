library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)

init_etl("backfill_ctsi_study_ids_in_invoice_line_item")

rcc_billing_conn <- connect_to_rcc_billing_db()

service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
collect()

invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
collect()

invoice_line_item_updates <- invoice_line_item |>
  filter(is.na(ctsi_study_id)) |>
  select(-ctsi_study_id) |>
  left_join(service_instance |> select(service_instance_id, ctsi_study_id), by = "service_instance_id") |>
  filter(!is.na(ctsi_study_id)) |>
  select(id, ctsi_study_id)

invoice_line_item_diff <- redcapcustodian::dataset_diff(
  source = invoice_line_item_updates,
  source_pk = "id",
  target = invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

invoice_line_item_sync_activity <- redcapcustodian::sync_table(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  primary_key = "id",
  data_diff_output = invoice_line_item_diff,
  insert = F,
  update = T,
  delete = F
)

activity_log <- lst(invoice_line_item_updates)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rcc_billing_conn)
