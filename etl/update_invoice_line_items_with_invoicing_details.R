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
rc_conn <- connect_to_redcap_db()

# Read the data in the latest payment file in the directory ./output/payments/
payment_dir = here::here("output", "payments")
latest_payment_file <- fs::dir_ls(payment_dir) %>%
  fs::file_info() %>%
  # NOTE: if more than one file is in here (especially if more than one was uploaded at the same time)
  # behavior may be undefined
  # TODO: check if volumes mounted in docker retain host's file metadata
  arrange(desc(modification_time)) %>%
  head(n=1) %>%
  pull(path)
csbt_billable_details <- readxl::read_excel(latest_payment_file)

billable_details <- transform_invoice_line_items_for_ctsit(csbt_billable_details) %>%
  janitor::clean_names() %>%
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
  mutate(status = if_else(!is.na(date_of_pmt), "paid", "invoiced")) %>%
  select(
    id,
    service_instance_id,
    fiscal_year,
    month_invoiced,
    ctsi_study_id = ctsi_study_id.billable,
    invoice_number = invoice_number.billable,
    je_number = deposit_or_je_number,
    je_posting_date = date_of_pmt,
    status
  ) %>%
  mutate(updated = get_script_run_time())

# NOTE: this is probably unnecessary due to use of sync_table_2
invoice_line_item_diff <- redcapcustodian::dataset_diff(
  source = invoice_line_item_with_billable_details %>% select(-updated),
  source_pk = "id",
  target = initial_invoice_line_item %>% select(-updated),
  target_pk = "id",
  insert = F,
  delete = F
)

new_updates_to_invoice_line_items <- invoice_line_item_diff$update_records %>% mutate(updated = get_script_run_time())

invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  source = new_updates_to_invoice_line_items,
  source_pk = "id",
  target = initial_invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

updated_invoice_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(id %in% !!new_updates_to_invoice_line_items$id) %>%
  collect()

# Write the communications records
max_invoice_line_item_communications_id = tbl(rcc_billing_conn, "invoice_line_item_communications") %>%
  summarise(max_id = max(id)) %>%
  collect() %>%
  pull()

new_invoice_line_item_communications <- draft_communication_record_from_line_item(updated_invoice_line_items) %>%
  mutate(id = id + max_invoice_line_item_communications_id)

redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item_communications",
  df_to_write = new_invoice_line_item_communications,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

# sync RC invoice_line_item table
initial_rc_invoice_line_item <- tbl(rc_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

billing_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

rc_db_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rc_conn,
  table_name = "invoice_line_item",
  source = initial_invoice_line_item,
  source_pk = "id",
  target = initial_rc_invoice_line_item,
  target_pk = "id",
  insert = T,
  delete = T
)

activity_log <- list(
  invoice_line_item_updates = updated_invoice_line_items,
  invoice_line_item_communications = new_invoice_line_item_communications
)

log_job_success(jsonlite::toJSON(activity_log))

DBI::dbDisconnect(rcc_billing_conn)

# flush the contents of payment_dir to safeguard subsequent runs from duplicate data
fs::dir_ls(payment_dir) %>%
  file.remove()
