test_that("get_target_projects_to_invoice returns one project to invoice", {
  # Create test tables and set the date
  test_tables <- c(
    "redcap_projects",
    "redcap_entity_project_ownership",
    "redcap_user_information"
  )

  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-04-05 12:00:00"))

  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  purrr::walk(test_tables, create_a_table_from_rds_test_data, mem_rc_conn, "get_target_projects_to_invoice")

  testthat::expect_equal(get_target_projects_to_invoice(mem_rc_conn) |> nrow(), 1)

  DBI::dbDisconnect(mem_rc_conn, shutdown=TRUE)
})
