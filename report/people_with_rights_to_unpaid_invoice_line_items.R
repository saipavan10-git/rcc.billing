library(tidyverse)
library(rcc.billing)
library(DBI)
library(dotenv)
library(redcapcustodian)

init_etl("people_with_rights_to_unpaid_invoice_line_items")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

user_info <- get_user_rights_and_info(rc_conn) |>
  mutate(project_id = as.character(project_id))

unpaid_invoice_line_items <-
  tbl(rcc_billing_conn, "invoice_line_item") |>
  filter(status == "invoiced" & service_type_code == 1) |>
  collect()

project_flags <- get_project_flags(rc_conn) |>
  mutate(project_id = as.character(project_id))

people_with_rights_to_unpaid_invoice_line_items <- unpaid_invoice_line_items |>
  left_join(project_flags, c("service_identifier" = "project_id")) |>
  left_join(user_info |> select(project_id, design, username, user_email, user_firstname, user_lastname),
            by = c("service_identifier" = "project_id"))

basename = "people_with_rights_to_unpaid_invoice_line_items"
people_with_rights_to_unpaid_invoice_line_items |>
  writexl::write_xlsx(here::here("output", paste0(basename, "_", format(get_script_run_time(), "%Y%m%d_%H%M%S"), ".xlsx")))
