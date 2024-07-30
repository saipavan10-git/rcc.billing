# make_get_target_projects_to_invoice_test_data.R

library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-04-05 12:00:00"))

rc_conn <- connect_to_redcap_db()

test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information"
)

redcap_projects <-
  dplyr::tbl(rc_conn, "redcap_projects") |>
  dplyr::collect() |>
  dplyr::sample_n(size = 8) |>
  dplyr::arrange(project_id) |>
  dplyr::mutate(
    creation_time = redcapcustodian::get_script_run_time() - lubridate::dyears(1) - lubridate::ddays(15)
  ) |>
  dplyr::mutate(date_deleted = if_else(
    row_number()/4 == round(row_number()/4),
    as.Date(NA),
    redcapcustodian::get_script_run_time() - lubridate::dmonths(7))
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(dplyr::across(dplyr::contains(c("project_pi", "app_title", "project_name")), my_hash))

redcap_entity_project_ownership_raw <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  dplyr::filter(pid %in% !!redcap_projects$project_id) %>%
  dplyr::collect() |>
  dplyr::arrange(pid) |>
  dplyr::mutate(billable = dplyr::if_else(dplyr::row_number() <= n()/2, 1, 0)) |>
  dplyr::mutate(sequestered = dplyr::if_else(dplyr::row_number()/2 == round(dplyr::row_number()/2), 0, 1))

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
  dplyr::mutate(dplyr::across(dplyr::contains("email"), append_fake_email_domain))

purrr::walk(test_tables, write_rds_to_test_dir, "get_target_projects_to_invoice")
