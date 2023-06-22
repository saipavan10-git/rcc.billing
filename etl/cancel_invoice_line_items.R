library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("cancel_invoice_line_items")

rcc_billing_conn <- connect_to_rcc_billing_db()

# manually describe the invoices to revise
fiscal_year_of_interest <- "2022-2023"
month_invoiced_of_interest <- "October"
service_instance_ids <- c(
  "1-7554",
  "1-7565",
  "1-9314",
  "1-11039",
  "1-11041"
)

ctsi_study_ids_to_cancel <- c(
  2508
)

# Read the records we will need to revise
invoice_line_item_initial <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(status != "canceled") %>%
  filter(
    (fiscal_year == fiscal_year_of_interest &
      month_invoiced == month_invoiced_of_interest &
      service_instance_id %in% service_instance_ids) |
      ctsi_study_id %in% ctsi_study_ids_to_cancel
  ) %>%
  select(id, service_instance_id, fiscal_year, month_invoiced, status, updated) %>%
  collect()

# create the dataset of updates
invoice_line_item_updates <- invoice_line_item_initial %>%
  mutate(status = "canceled") %>%
  mutate(updated = redcapcustodian::get_script_run_time()) %>%
  select(id, status, updated)

if (nrow(invoice_line_item_updates) > 0) {
  # write those updates
  invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
    conn = rcc_billing_conn,
    table_name = "invoice_line_item",
    source = invoice_line_item_updates,
    source_pk = "id",
    target = invoice_line_item_initial,
    target_pk = "id"
  )

  # log what we did
  activity_log <- list(
    invoice_line_item_updates = invoice_line_item_sync_activity$update_records
  )

  log_job_success(jsonlite::toJSON(activity_log))
}
DBI::dbDisconnect(rcc_billing_conn)
