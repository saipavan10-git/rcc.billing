library(tidyverse)
library(rcc.billing)
library(DBI)
library(dotenv)
library(redcapcustodian)

dotenv::load_dot_env("prod.env")
rc_conn <- connect_to_redcap_db()

test_users <- c("pbc", "tls")

redcap_user_information <-
  dplyr::tbl(rc_conn, "redcap_user_information") |>
  dplyr::filter(username %in% test_users) |>
  dplyr::mutate(
    user_email = paste0("username", "@example.org"),
    user_email2 = NA_character_,
    user_email3 = NA_character_,
    user_phone = "3525551212",
    user_phone_sms = "3525551212",
    user_first_name = paste0("username", "_first"),
    user_lastname = paste0("username", "_last"),
    user_inst_id = "01010101"
  ) |>
  dplyr::collect()

redcap_user_rights_raw <- tbl(rc_conn, "redcap_user_rights") |>
  dplyr::filter(username %in% test_users) |>
  dplyr::collect()

redcap_user_rights <- redcap_user_rights_raw |>
  dplyr::group_by(username, is.na(role_id)) |>
  dplyr::slice_sample(n=1) |>
  dplyr::mutate(expiration = dplyr::if_else(username == "tls" & is.na(role_id), as.Date("2023-01-01"), expiration)) |>
  dplyr::ungroup()

redcap_user_roles <-
  dplyr::tbl(rc_conn, "redcap_user_roles") |>
  dplyr::filter(role_id %in% local(redcap_user_rights$role_id)) |>
  dplyr::collect()

# write all of the test inputs
purrr::walk(get_user_rights_and_info_test_tables, write_rds_to_test_dir, "get_user_rights_and_info")
