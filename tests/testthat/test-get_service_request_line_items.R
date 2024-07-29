# Test the function with updated expected_result to include all fields
test_that("get_service_request_line_items returns correct results", {

  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-02-05 12:00:00", tz="America/New_York"))

  # DuckDB setup
  rcc_billing_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")

  rc_conn_tables<-c(
    "redcap_entity_project_ownership",
    "redcap_projects",
    "redcap_user_information"
  )

  rcc_billing_conn_tables<-c(
    "ctsi_study_id_map",
    "invoice_line_item",
    "project_details"
  )

  purrr::walk(rc_conn_tables, ~create_a_table_from_rds_test_data(.x, rc_conn, "get_service_request_line_items"))
  purrr::walk(rcc_billing_conn_tables, ~create_a_table_from_rds_test_data(.x, rcc_billing_conn, "get_service_request_line_items"))

  result <- get_service_request_line_items(
    mock_service_requests,
    rcc_billing_conn,
    rc_conn
    )
  expected_result <- dplyr::tibble(
    service_identifier = c("6267", "6267", "6436", "6445", "6469", "6473"),
    service_type_code = c("2", "2", "2", "2", "2", "2"),
    service_instance_id = c("2-6267", "2-6267", "2-6436", "2-6445", "2-6469", "2-6473-PB"),
    ctsi_study_id = c("300", "300", NA, NA, "970", NA),
    name_of_service = c("Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting"),
    name_of_service_instance= c("178a329b", "178a329b", NA, NA, "06b26cc0", NA),
    other_system_invoicing_comments = c(
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6436 : bogus_rc_username : 2024-04-23 : fake response",
      "6445 : bogus_rc_username : 2024-04-24 : fake comment",
      "6469 : bogus_rc_username : 2024-04-30 : fake response",
      "6473 : bogus_gatorlink : 2024-05-01 : Pro-bono : fake response"
    ),
    price_of_service = c("130", "130", "130", "130", "130", "0"),
    qty_provided = c("1","0.5","0.25","0.25","0.5","0.25"),
    amount_due = c("130", "65", "32.5", "32.5", "65", "0"),
    fiscal_year = rep("2022-2023", 6),
    month_invoiced = factor(rep("January", 6), levels = month.name, ordered = TRUE),
    pi_last_name = c("PI", "PI", "l_name", "PI", "PI", "l_name"),
    pi_first_name = c("Bogus", "Bogus", "f_name", "Bogus", "Bogus", "f_name"),
    pi_email = c("pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu"),
    gatorlink = c("bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_gatorlink"),
    reason = rep("new_item", 6),
    status  = rep("draft", 6),
    created = rep(as.POSIXct("2023-02-05 12:00:00"), 6),
    updated = rep(as.POSIXct("2023-02-05 12:00:00"), 6),
    fiscal_contact_fn = rep("John", 6),
    fiscal_contact_ln = rep("Doe", 6),
    fiscal_contact_name = rep("John Doe", 6),
  )
  testthat::expect_equal(result, expected_result)

  # Disconnect from DuckDB
  DBI::dbDisconnect(rcc_billing_conn, shutdown = TRUE)
  DBI::dbDisconnect(rc_conn, shutdown = TRUE)
})

