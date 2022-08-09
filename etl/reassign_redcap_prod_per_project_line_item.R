library(tidyverse)
library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("reassign_redcap_prod_per_project_line_item")

# TODO: Uncomment for prod
# rc_conn <- connect_to_redcap_db()
# rcc_billing_conn <- connect_to_rcc_billing_db()

sent_line_items <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(service_type_code == 1 & status == "sent") %>%
  collect() %>%
  mutate(project_id = str_replace(service_instance_id, "1-", "")) %>%
  # TODO: remove dummy data creation
  mutate(pi_email = if_else(pi_email == "tls@ufl.edu", "test@ufl.edu", pi_email))

redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!sent_line_items$project_id) %>%
  mutate_at("pid", as.character) %>%
  collect()

reassigned_line_items <- sent_line_items %>%
  left_join(redcap_entity_project_ownership, by = c("project_id" = "pid")) %>%
  filter(
    gatorlink  != username |
      pi_email != email |
      pi_first_name != firstname |
      pi_last_name != lastname
  ) %>%
  mutate(
    gatorlink  = username,
    pi_email = email,
    pi_first_name = firstname,
    pi_last_name = lastname,
    reason = "PI reassigned",
    created = get_script_run_time(),
    updated = get_script_run_time()
  ) %>%
  select(
    service_type_code,
    any_of(csbt_column_names$ctsit),
    gatorlink,
    reason,
    status,
    created,
    updated
  )

reassigned_line_items_for_csbt <- transform_invoice_line_items_for_csbt(reassigned_line_items)
updates_reassigned_line_item_communications <- draft_communication_record_from_line_item(reassigned_line_items)

reassigned_line_items_for_csbt_filename <- "reassigned_line_items.csv"
tmp_invoice_file <- paste0(tempdir(), reassigned_line_items_for_csbt_filename)

reassigned_line_items_for_csbt %>%
  writexl::write_xlsx(tmp_invoice_file)


# Send Email --------------------------------------------------------------


email_subject <- paste("Updates to invoice line items for REDCap Project billing")
attachment_object <- sendmailR::mime_part(tmp_invoice_file, reassigned_line_items_for_csbt_filename)

# TODO: Confirm message
body <- "The attached file has updates to invoice line items for REDCap Project billing. Please load these into the CSBT invoicing system."
email_body <- list(body, attachment_object)
send_email(
  email_body = email_body,
  email_subject = email_subject,
  email_to = Sys.getenv("CSBT_EMAIL")
)


# Update SQL Tables -------------------------------------------------------


redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  df_to_write = reassigned_line_items,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

redcapcustodian::write_to_sql_db(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item_communications",
  df_to_write = updates_reassigned_line_item_communications,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)


# Log Job -----------------------------------------------------------------


invoice_line_items_sent <- sent_line_items %>%
  mutate(
    status = "sent",
    updated = get_script_run_time()
  ) %>%
  select(
    id,
    service_instance_id,
    fiscal_year,
    month_invoiced,
    status,
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
  invoice_line_item = updates_reassigned_line_item_communications %>%
    mutate(diff_type = "insert") %>%
    select(diff_type, everything()),
  invoice_line_item_communications = invoice_line_item_sent_diff$update_records %>%
    mutate(diff_type = "update") %>%
    select(diff_type, everything())
)

log_job_success(jsonlite::toJSON(activity_log))

unlink(tmp_invoice_file)

dbDisconnect(rcc_billing_conn)
dbDisconnect(rc_conn)
