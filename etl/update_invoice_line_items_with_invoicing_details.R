library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("update_invoice_line_items_with_invoicing_details")

rcc_billing_conn <- connect_to_rcc_billing_db()

# TODO: autopath this with script run month
billable_file <- "CTSIT_SeptBillable.xlsx"
csbt_billable_details <- readxl::read_excel(billable_file)

billable_details <- transform_invoice_line_items_for_ctsit(csbt_billable_details) %>%
  janitor::clean_names() %>%
  # HACK: CSBT month invoiced may be inconsistent
  mutate(month_invoiced = "Oct") %>%
  # HACK: when testing, in-memory data for dates are converted to int upon collection
  mutate_columns_to_posixct(c("creation_time", "updated"))

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  mutate_columns_to_posixct(c("creation_time", "updated"))

invoice_line_item_with_billable_details <- billable_details %>%
  inner_join(
    initial_invoice_line_item,
    by = c("service_instance_id",
           "fiscal_year",
           "month_invoiced"
           ),
    suffix = c(".billable", ".line_item")
  ) %>%
  select(
    service_instance_id,
    fiscal_year,
    month_invoiced,
    ctsi_study_id = ctsi_study_id.billable,
    invoice_number = invoice_number.billable,
    je_number,
    je_posting_date
  ) %>%
  mutate(updated = get_script_run_time())

# NOTE: this is probably unecessary due to use of sync_table_2
invoice_line_item_diff <- redcapcustodian::dataset_diff(
  source = invoice_line_item_with_billable_details,
  source_pk = "service_instance_id",
  target = initial_invoice_line_item,
  target_pk = "service_instance_id"
)

invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  source = invoice_line_item_diff$update_records,
  source_pk = "service_instance_id",
  target = initial_invoice_line_item,
  target_pk = "service_instance_id"
)

updated_invoice_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  # NOTE: you may run in to issues with type mismatch testing with SQLite
  filter(updated == redcapcustodian::get_script_run_time()) %>%
  filter(service_instance_id %in% local(update_diff$update_records$service_instance_id)) %>%
  collect()

new_invoice_line_item_communications <- draft_communication_record_from_line_item(updated_invoice_line_items)

redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item_communications",
  df_to_write = new_invoice_line_item_communications,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

activity_log <- list(
  invoice_line_item_updates = invoice_line_item_sync_activity,
  invoice_line_item_communications = new_invoice_line_item_communications
)

log_job_success(jsonlite::toJSON(activity_log))

DBI::dbDisconnect(rcc_billing_conn)
