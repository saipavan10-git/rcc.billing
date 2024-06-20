library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)
library(fs)

init_etl("update_invoice_line_items_to_correct_fiscal_year")

rcc_billing_conn <- connect_to_rcc_billing_db()
rc_conn <- connect_to_redcap_db()

# # Run this to mirror tables into memory for testing
# copy_table_to_memory <- function(table_name, source_conn, target_conn) {
#   df <- DBI::dbReadTable(conn = source_conn, name = table_name)
#   DBI::dbWriteTable(
#     conn = target_conn,
#     name = table_name,
#     value = df
#   )
# }
# rcc_billing_conn_tables <- c(
#   "invoice_line_item",
#   "invoice_line_item_communications",
#   "banned_owners"
# )
# rcc_billing_conn_m <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
# purrr::walk(rcc_billing_conn_tables, copy_table_to_memory, source_conn = rcc_billing_conn, target_conn = rcc_billing_conn_m)
#
# rc_conn_tables <- c(
#   "invoice_line_item"
# )
# rc_conn_m <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
# purrr::walk(rc_conn_tables, copy_table_to_memory, source_conn = rc_conn, target_conn = rc_conn_m)
# rcc_billing_conn <- rcc_billing_conn_m
# rc_conn <- rc_conn_m

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  # filter(fiscal_year == "2023-2024") %>%
  filter(fiscal_year == "2022-2023") %>%
  filter(month_invoiced == "June") %>%
  collect()

updated_invoice_line_items <-
  initial_invoice_line_item %>%
  mutate(fiscal_year = "2022-2023",
   updated = get_script_run_time()
  ) %>%
  select(id, fiscal_year, updated)

invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  source = updated_invoice_line_items,
  source_pk = "id",
  target = initial_invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

# sync RC invoice_line_item table
initial_rc_invoice_line_item <- tbl(rc_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

rc_db_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rc_conn,
  table_name = "invoice_line_item",
  source = updated_invoice_line_items,
  source_pk = "id",
  target = initial_rc_invoice_line_item,
  target_pk = "id",
  update = T,
  insert = F,
  delete = F
)


activity_log <- list(
  invoice_line_item_updates = updated_invoice_line_items
)

log_job_success(jsonlite::toJSON(activity_log))

# flush the contents of payment_dir to safeguard subsequent runs from duplicate data
fs::dir_ls(payment_dir) %>%
  file.remove()

DBI::dbDisconnect(rcc_billing_conn)
DBI::dbDisconnect(rc_conn)
