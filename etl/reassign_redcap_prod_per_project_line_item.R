library(tidyverse)
library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(lubridate)
library(dotenv)

init_etl("reassign_redcap_prod_per_project_line_item")
rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

sent_line_items <- get_unpaid_redcap_prod_per_project_line_items(rcc_billing_conn)

reassigned_line_items <- get_reassigned_line_items(sent_line_items, rc_conn)

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
