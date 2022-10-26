library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)
library(fs)

init_etl("update_invoice_line_items_with_invoicing_details")

rcc_billing_conn <- connect_to_rcc_billing_db()

# Read the data in the latest payment file in the directory ./output/payments/
payment_dir = here::here("output", "payments")
latest_payment_file <- fs::dir_ls(payment_dir) %>%
  fs::file_info() %>%
  arrange(desc(modification_time)) %>%
  head(n=1) %>%
  pull(path)
csbt_billable_details <- readxl::read_excel(latest_payment_file)

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
    id,
    service_instance_id,
    fiscal_year,
    month_invoiced,
    ctsi_study_id = ctsi_study_id.billable,
    invoice_number = invoice_number.billable,
    je_number = deposit_or_je_number,
    je_posting_date = date_of_pmt,
  ) %>%
  mutate(updated = get_script_run_time())

# NOTE: this is probably unnecessary due to use of sync_table_2
invoice_line_item_diff <- redcapcustodian::dataset_diff(
  source = invoice_line_item_with_billable_details,
  source_pk = "id",
  target = initial_invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  source = invoice_line_item_diff$update_records,
  source_pk = "id",
  target = initial_invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

updated_invoice_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  # NOTE: you may run in to issues with type mismatch testing with SQLite
  filter(updated == redcapcustodian::get_script_run_time()) %>%
  filter(service_instance_id %in% local(invoice_line_item_diff$update_records$service_instance_id)) %>%
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
  invoice_line_item_updates = invoice_line_item_sync_activity$update_records,
  invoice_line_item_communications = new_invoice_line_item_communications
)

log_job_success(jsonlite::toJSON(activity_log))

DBI::dbDisconnect(rcc_billing_conn)
