# testthat/get_new_project_invoice_line_items/make_test_Data.R

library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
set_script_run_time(lubridate::ymd_hms("2023-04-05 12:00:00"))

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

test_tables <- c(
  "redcap_config",
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "service_type",
  "service_instance",
  "invoice_line_item"
)

redcap_config <- dplyr::tbl(rc_conn, "redcap_config") |>
  dplyr::filter(.data$field_name == "redcap_version") |>
  dplyr::collect()

service_type <- dplyr::tbl(rcc_billing_conn, "service_type") |> dplyr::collect()

redcap_projects <-
  dplyr::tbl(rc_conn, "redcap_projects") |>
  dplyr::collect() |>
  dplyr::sample_n(size = 4) |>
  dplyr::arrange(project_id) |>
  dplyr::mutate(
    creation_time = redcapcustodian::get_script_run_time() - lubridate::dyears(1) - lubridate::ddays(15)
  ) |>
  dplyr::mutate(date_deleted = as.Date(NA)) |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::contains(c("project_pi", "app_title", "project_name")), my_hash))

redcap_entity_project_ownership_raw <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() |>
  dplyr::arrange(pid) |>
  mutate(billable = 1) |>
  mutate(sequestered = 0)

redcap_entity_project_ownership <- redcap_entity_project_ownership_raw |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::contains(c("username", "email", "name")), my_hash)) |>
  dplyr::mutate(dplyr::across(dplyr::contains("email"), append_fake_email_domain))

redcap_user_information <- dplyr::tbl(rc_conn, "redcap_user_information") |>
  dplyr::filter(username %in% redcap_entity_project_ownership_raw$username) |>
  dplyr::select(
    "username",
    "user_email",
    "user_firstname",
    "user_lastname"
  ) |>
  dplyr::collect() |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::everything(), my_hash)) |>
  dplyr::mutate(dplyr::across(dplyr::contains("email"), ~ if_else(is.na(.), "dummy", .))) |>
  dplyr::mutate(dplyr::across(dplyr::contains("email"), append_fake_email_domain))

service_instance <-
  dplyr::tbl(rcc_billing_conn, "service_instance") |>
  dplyr::collect() |>
  dplyr::slice_sample(n = 10) |>
  dplyr::filter(service_type_code == 1 & !service_identifier %in% redcap_projects$project_id) |>
  dplyr::bind_rows(
    dplyr::tibble(
      service_instance_id = paste0("1-", redcap_projects$project_id),
      service_type_code = 1,
      service_identifier = as.character(redcap_projects$project_id),
      ctsi_study_id = NA_real_,
      active = 1
    )
  )

invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") |>
  collect() |>
  filter(service_type_code == 1 & !service_identifier %in% redcap_projects$project_id) |>
  slice_sample(n = 4) |>
  rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::contains(c(
    "name_of_service_instance",
    "other_system_invoicing_comments",
    "gatorlink",
    "invoice_number",
    "pi_"
  )), my_hash))

mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
purrr::walk(test_tables, ~ duckdb::duckdb_register(mem_rc_conn, ., get(.)))

projects_to_invoice <- get_target_projects_to_invoice(mem_rc_conn)

purrr::walk(test_tables, ~ duckdb::duckdb_unregister(mem_rc_conn, .))

# write a dataframe, referenced by 'table_name' to tests/testthat/directory_under_test_path
write_rds_to_test_dir <- function(table_name, directory_under_test_path) {
  get(table_name) |> saveRDS(testthat::test_path(directory_under_test_path, paste0(table_name, ".rds")))
}

purrr::walk(c(test_tables, "projects_to_invoice"), write_rds_to_test_dir, "get_new_project_invoice_line_items")
