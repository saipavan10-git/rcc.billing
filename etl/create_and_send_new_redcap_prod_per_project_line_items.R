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

redcap_version <- tbl(rc_conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect(value) %>%
  pull()

table_names <- c(
  "redcap_entity_project_ownership",
  "redcap_projects",
  "service_instance",
  "invoice_line_item",
  "service_type",
  "invoice_line_item_communications"
)

# # run these lines to test in MySQL (but not REDCap)
# for (table_name in table_names) {
#   create_and_load_test_table(
#     table_name = table_name,
#     conn = rcc_billing_conn,
#     load_test_data = T,
#     is_sqllite = F
#   )
# }
# dbListTables(rcc_billing_conn)
# rc_conn <- rcc_billing_conn
#
# # run these lines to test in an in-memory database
# conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
# for (table_name in table_names) {
#   create_and_load_test_table(
#     table_name = table_name,
#     conn = conn,
#     load_test_data = T,
#     is_sqllite = T
#   )
# }
#
# rc_conn <- conn
# rcc_billing_conn <- conn
#
# dbListTables(conn)

redcap_project_uri_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

current_month_name <- month(get_script_run_time(), label = T)
current_fiscal_year <- fiscal_years %>%
  filter(get_script_run_time() %within% fy_interval) %>%
  head(1) %>% # HACK: overlaps may occur on July 1, just choose the earlier year
  pull(csbt_label)

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

initial_service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
  collect()

service_type <- tbl(rcc_billing_conn, "service_type") %>% collect()

target_projects <- tbl(rc_conn, "redcap_projects") %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership") %>%
      filter(billable == 1),
    by = c("project_id" = "pid")
  ) %>%
  # project is not deleted
  filter(is.na(date_deleted)) %>%
  # project at least 1 year old
  filter(creation_time <= local(get_script_run_time() - dyears(1))) %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct("creation_time") %>%
  # not have an entry for the same month in the invoice_line_item table
  anti_join(
    initial_invoice_line_item %>%
      filter(
        fiscal_year == current_fiscal_year,
        month_invoiced == current_month_name
      ) %>%
      select(ctsi_study_id, fiscal_year, month_invoiced),
    by = c("project_id" = "ctsi_study_id")
  ) %>%
  # birthday in past month
  filter(previous_month(month(get_script_run_time())) == month(creation_time))

# Make new service_instance rows ##############################################

new_service_instances <- target_projects %>%
  mutate(
    service_type_code = 1,
    service_identifier = as.character(project_id),
    service_instance_id = paste(service_type_code, service_identifier, sep="-"),
    active = 1,
    ctsi_study_id = as.numeric(NA)
  ) %>%
  select(
    service_type_code,
    service_identifier,
    service_instance_id,
    active,
    ctsi_study_id
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

updated_service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
  collect()

# Create invoice_line_item rows ###############################################

new_invoice_line_item_writes <- target_projects %>%
  mutate(
    service_type_code = 1,
    service_identifier = as.character(project_id),
    name_of_service_instance = app_title,
    other_system_invoicing_comments = paste0(redcap_project_uri_base, project_id),
    fiscal_year = current_fiscal_year,
    month_invoiced = current_month_name,
    pi_last_name = lastname,
    pi_first_name = firstname,
    pi_email = email,
    # TODO: should this be stripped from the PI email instead?
    gatorlink = username,
    reason = "new_item",
    status = "draft",
    created = get_script_run_time(),
    updated = get_script_run_time()
  ) %>%
  inner_join(
    updated_service_instance,
    by = c("service_type_code", "service_identifier")
  ) %>%
  inner_join(
    service_type, by = "service_type_code"
  ) %>%
  mutate(
    price_of_service = price,
    qty_provided = 1,
    amount_due = price * qty_provided
  ) %>%
  # fabricate new IDs
  mutate(id = row_number() + nrow(initial_invoice_line_item)) %>%
  select(
    id,
    service_identifier,
    service_type_code,
    service_instance_id,
    ctsi_study_id,
    name_of_service = service_type,
    name_of_service_instance,
    other_system_invoicing_comments,
    price_of_service,
    qty_provided,
    amount_due,
    fiscal_year,
    month_invoiced,
    pi_last_name,
    pi_first_name,
    pi_email,
    gatorlink,
    reason,
    status,
    created,
    updated
  )

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
    month_invoiced == current_month_name,
    fiscal_year == current_fiscal_year
  ) %>%
  collect()

new_invoice_line_items_for_csbt <- transform_invoice_line_items_for_csbt(new_invoice_line_items)

new_invoice_line_items_filename = "new_invoice_line_item_communications.xlsx"
tmp_invoice_file <- paste0(tempdir(), new_invoice_line_items_filename)

new_invoice_line_items_for_csbt %>%
  writexl::write_xlsx(tmp_invoice_file)

# TODO: consider if IDs need to be generated due to mismatch between invoice_line_item ID col
new_invoice_line_item_communications <- draft_communication_record_from_line_item(new_invoice_line_items)

# Email CSBT
email_subject <- paste("New invoice line items for REDCap Project billing")
attachment_object <- sendmailR::mime_part(tmp_invoice_file, new_invoice_line_items_filename)
body <- "The attached file has new invoice line items for REDCap Project billing. Please load these into the CSBT invoicing system."
email_body <- list(body, attachment_object)
send_email(
  email_body = email_body,
  email_subject = email_subject,
  email_to = Sys.getenv("CSBT_EMAIL")
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
