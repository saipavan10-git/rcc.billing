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
  select(-c(id, created, updated)) %>%
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
    updated = get_script_run_time()
  ) %>%
  select(
    id,
    service_type_code,
    any_of(csbt_column_names$ctsit),
    gatorlink,
    reason,
    status,
    created,
    updated
  )

# Prepare datasets for email and communications table -------------------

reassigned_line_items_for_csbt <- transform_invoice_line_items_for_csbt(reassigned_line_items)
updates_reassigned_line_item_communications <- draft_communication_record_from_line_item(reassigned_line_items)

reassigned_line_items_for_csbt_filename <- "reassigned_line_items.csv"
tmp_invoice_file <- paste0(tempdir(), reassigned_line_items_for_csbt_filename)

reassigned_line_items_for_csbt %>%
  writexl::write_xlsx(tmp_invoice_file)

# Update invoice_line_items ----------------------------------------------

invoice_line_item_sync_activity <- redcapcustodian::sync_table_2(
  conn = rcc_billing_conn,
  table_name = "invoice_line_item",
  source = reassigned_line_items,
  source_pk = "id",
  target = sent_line_items,
  target_pk = "id"
)

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
  table_name = "invoice_line_item_communications",
  df_to_write = updates_reassigned_line_item_communications,
  schema = NA,
  overwrite = F,
  db_name = "rcc_billing",
  append = T
)

# Log Job -----------------------------------------------------------------

activity_log <- list(
  invoice_line_item_updates = invoice_line_item_sync_activity$update_records,
  invoice_line_item_communications_inserts = updates_reassigned_line_item_communications
)

log_job_success(jsonlite::toJSON(activity_log))

unlink(tmp_invoice_file)

dbDisconnect(rcc_billing_conn)
dbDisconnect(rc_conn)
