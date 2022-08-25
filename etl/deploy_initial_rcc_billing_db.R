library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

# load_dot_env("prod.env")
init_etl("deploy_initial_rcc_billing_db")

rcc_billing_conn <- connect_to_rcc_billing_db()

dbListTables(rcc_billing_conn)

# create the load the service_type table -----------------------------
create_and_load_test_table(
  conn = rcc_billing_conn,
  table_name = "service_type",
  load_test_data = TRUE
)


# make the empty job log table using redcapcustodian schema ----------
table_name = "rcc_job_log"
schema_file_name <- paste0(table_name, ".sql")
original_schema_file <- system.file(
  "schema",
  schema_file_name,
  package = "redcapcustodian")
schema <- readr::read_file(original_schema_file)
create_table(
  conn = rcc_billing_conn,
  schema = schema
)


# make the other empty tables ---------------------------------------
empty_tables <- c(
  "invoice_line_item",
  "invoice_line_item_communications",
  "service_instance"
)

for (table_name in empty_tables) {
  create_and_load_test_table(
    conn = rcc_billing_conn,
    table_name = table_name,
    load_test_data = FALSE
  )
}


# log our work and exit ---------------------------------------------
extant_tables <- dbListTables(rcc_billing_conn)

activity_log <- list(
  extant_tables = extant_tables
)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rcc_billing_conn)
