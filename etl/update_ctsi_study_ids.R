library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("update_ctsi_study_ids")

rcc_billing_conn <- connect_to_rcc_billing_db()

initial_service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
  ## head(3) %>%
  collect()

## ctsi_study_ids <- initial_service_instance %>%
##   tail(3)

ctsi_study_ids <- read_csv("./output/ctsi_study_ids.csv") %>%
  janitor::clean_names() %>%
  select(ctsi_study_id, service_instance_id = ctsi_it_id)

service_instances_diff <-
  redcapcustodian::dataset_diff(
    source = ctsi_study_ids,
    source_pk = "service_instance_id",
    target = initial_service_instance,
    target_pk = "service_instance_id",
    insert = T,
    delete = F
  )

service_instance_sync_activity <- redcapcustodian::sync_table(
  conn = rcc_billing_conn,
  table_name = "service_instance",
  primary_key = "service_instance_id",
  data_diff_output = service_instances_diff,
  insert = T,
  update = F,
  delete = F
)

updated_service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
  ## head(6) %>%
  collect()

# Update invoice_line_items ###################################################

initial_invoice_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  # randomly assign NA for testing
  ## collect() %>%
  ## mutate(ctsi_study_id = if_else(
  ##   sample(c(T, F), n(), replace = TRUE),
  ##   NA_real_,
  ##   ctsi_study_id
  ##   )
  ## ) %>%
  filter(is.na(ctsi_study_id)) %>%
  collect()

invoice_line_item_updates <- initial_invoice_line_items %>%
  inner_join(updated_service_instance, by = c("service_identifier" = "service_instance_id")) %>%
  mutate(ctsi_study_id = ctsi_study_id.y) %>%
  select(-ends_with(c(".x", ".y")))

invoice_line_item_diff <-
  redcapcustodian::dataset_diff(
    source = invoice_line_item_updates,
    source_pk = "service_identifier",
    target = initial_invoice_line_items,
    target_pk = "service_identifier",
    insert = T,
    delete = F
  )

invoice_line_item_sync_activity <- redcapcustodian::sync_table(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  primary_key = "service_identifier",
  data_diff_output = invoice_line_item_diff,
  insert = T,
  update = F,
  delete = F
)

activity_log <- bind_rows(
  service_instances_diff$insert_records,
  invoice_line_item_sync_activity$update_records
)

log_job_success(jsonlite::toJSON(activity_log))

DBI::dbDisconnect(rcc_billing_conn)
