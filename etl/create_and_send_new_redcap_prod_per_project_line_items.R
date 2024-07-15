library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("create_and_send_new_redcap_prod_per_project_line_items")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect()

target_projects <- get_target_projects_to_invoice(rc_conn)

# Make new service_instance rows ##############################################
initial_service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
  collect()

new_service_instances <- get_new_project_service_instances(
  projects_to_invoice = target_projects,
  initial_service_instance = initial_service_instance
)

new_service_instances_diff <- redcapcustodian::dataset_diff(
  source = new_service_instances,
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
  data_diff_output = new_service_instances_diff,
  insert = T,
  update = F,
  delete = F
)

# Create invoice_line_item rows ###############################################
new_project_invoice_line_items <- get_new_project_invoice_line_items(
    projects_to_invoice = target_projects,
    initial_invoice_line_item,
    rc_conn,
    rcc_billing_conn,
    api_uri = str_remove(Sys.getenv("URI"), "/api") %>%
      paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")
)

# Row bind all new invoice line items and add IDs
new_invoice_line_item_writes <- bind_rows(new_project_invoice_line_items) |>
  mutate(id = row_number() + max(initial_invoice_line_item$id))

# Write the new invoice line items
redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  df_to_write = new_invoice_line_item_writes,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

# Send new line items #########################################################

new_invoice_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(
    status == "draft",
    month_invoiced == previous_month_name,
    fiscal_year == fiscal_year_invoiced
  ) %>%
  collect()

new_invoice_line_items_for_csbt <- transform_invoice_line_items_for_csbt(new_invoice_line_items)

new_invoice_line_items_filename = "new_invoice_line_item_communications.xlsx"
tmp_invoice_file <- paste0(tempdir(), new_invoice_line_items_filename)

new_invoice_line_items_for_csbt %>%
  writexl::write_xlsx(tmp_invoice_file)

# create new rows for invoice_line_item_communications
max_id_in_invoice_line_item_communications <- tbl(rcc_billing_conn, "invoice_line_item_communications") %>%
  summarise(max_id = max(id)) %>%
  collect() %>%
  pull(max_id)

new_invoice_line_item_communications <- draft_communication_record_from_line_item(new_invoice_line_items) %>%
  mutate(id = row_number() + max_id_in_invoice_line_item_communications)

# Email CSBT
email_subject <- paste("New invoice line items for REDCap Annual Project Maintenance")
attachment_object <- sendmailR::mime_part(tmp_invoice_file, new_invoice_line_items_filename)
body <- "The attached file has new invoice line items for REDCap Annual Project Maintenance. Please load these into the CSBT invoicing system."
email_body <- list(body, attachment_object)
send_email(
  email_body = email_body,
  email_subject = email_subject,
  email_to = Sys.getenv("CSBT_EMAIL"),
  email_cc = Sys.getenv("EMAIL_TO")
)

redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item_communications",
  df_to_write = new_invoice_line_item_communications,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

invoice_line_items_sent <- new_invoice_line_items %>%
  mutate(
    status = "sent",
    date_sent = get_script_run_time(),
    updated = get_script_run_time()
  ) %>%
  select(
    id,
    service_instance_id,
    fiscal_year,
    month_invoiced,
    status,
    date_sent,
    updated
  )

current_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  mutate_columns_to_posixct(c("created", "updated"))

invoice_line_item_sent_diff <- redcapcustodian::dataset_diff(
  source = invoice_line_items_sent,
  source_pk = "id",
  target = current_invoice_line_item,
  target_pk = "id",
  insert = F,
  delete = F
)

invoice_line_item_sync_activity <- redcapcustodian::sync_table(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  primary_key = "id",
  data_diff_output = invoice_line_item_sent_diff,
  insert = F,
  update = T,
  delete = F
)

activity_log <- list(
  service_instance = new_service_instances_diff$insert_records %>%
    mutate(diff_type = "insert") %>%
    select(diff_type, everything()),
  invoice_line_item = new_invoice_line_item_communications %>%
    mutate(diff_type = "insert") %>%
    select(diff_type, everything()),
  invoice_line_item_communications = invoice_line_item_sent_diff$update_records %>%
    mutate(diff_type = "update") %>%
    select(diff_type, everything())
)

log_job_success(jsonlite::toJSON(activity_log))

unlink(tmp_invoice_file)
DBI::dbDisconnect(rcc_billing_conn)
DBI::dbDisconnect(rc_conn)
