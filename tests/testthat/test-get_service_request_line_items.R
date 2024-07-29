# Test the function with updated expected_result to include all fields
test_that("get_service_request_line_items returns correct results", {

  # TODO: Move script run time hear and in the make test data script to 2024-08-01 12:00:00
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-02-05 12:00:00"))

  # DuckDB setup
  mem_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  test_tables <- c(
    "redcap_projects", # lives in REDCap DB
    "redcap_entity_project_ownership", # ibid
    "redcap_user_information", # ibid
    "invoice_line_item", # lives in rcc_billing DB
    "service_requests" # lives in REDCap PID 1414
  )
  purrr::walk(test_tables, ~create_a_table_from_rds_test_data(.x, mem_conn, "get_service_request_line_items"))

  service_requests <- tbl(mem_conn, "service_requests") |>
    collect()
  # TODO: Add a time filter to read only the previous month's data

  result <- get_service_request_line_items(
    service_requests = service_requests,
    rc_billing_conn = mem_conn,
    rc_conn = mem_conn
    )

  # TODO: Add a real test
  # testthat::expect_equal(result, expected_result)

  # Disconnect from DuckDB
  DBI::dbDisconnect(mem_conn, shutdown = TRUE)
})

