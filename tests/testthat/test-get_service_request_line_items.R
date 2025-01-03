# Test get_service_request_line_items
#
# DuckDB setup
mem_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
test_tables <- c(
  "redcap_projects", # lives in REDCap DB
  "redcap_entity_project_ownership", # ibid
  "redcap_user_information", # ibid
  "invoice_line_item", # lives in rcc_billing DB
  "service_requests" # lives in REDCap PID 1414
)
purrr::walk(
  test_tables,
  ~ create_a_table_from_rds_test_data(
    .x, mem_conn,
    "get_service_request_line_items"
  )
)

service_requests <- dplyr::tbl(mem_conn, "service_requests") |>
  dplyr::collect()

# Test the function with updated expected_result to include all fields
test_that("get_service_request_line_items always has a non-NA pi_email", {
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2024-08-01 12:00:00"))

  result <- get_service_request_line_items(
    service_requests = service_requests,
    rc_billing_conn = mem_conn,
    rc_conn = mem_conn
  )

  result_na_pi_email <- result |>
    dplyr::filter(is.na(pi_email)) |>
    nrow()
  testthat::expect_equal(result_na_pi_email, 0)
}
)

test_that("get_service_request_line_items returns the correct list of columns", {
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2024-08-01 12:00:00"))

  result <- get_service_request_line_items(
    service_requests = service_requests,
    rc_billing_conn = mem_conn,
    rc_conn = mem_conn
  )

  expected_columns <- c(
    "service_identifier",
    "service_type_code",
    "service_instance_id",
    "ctsi_study_id",
    "name_of_service",
    "name_of_service_instance",
    "other_system_invoicing_comments",
    "price_of_service",
    "qty_provided",
    "amount_due",
    "fiscal_year",
    "month_invoiced",
    "pi_last_name",
    "pi_first_name",
    "pi_email",
    "gatorlink",
    "reason",
    "status",
    "created",
    "updated",
    "fiscal_contact_fn",
    "fiscal_contact_ln",
    "fiscal_contact_name",
    "fiscal_contact_email"
  )
  testthat::expect_equal(colnames(result), expected_columns)
})

test_that("get_service_request_line_items sees one 'Fake Study'", {
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2025-01-02 17:00:00", tz = "America/New_York"))

  result <- get_service_request_line_items(
    service_requests = service_requests,
    rc_billing_conn = mem_conn,
    rc_conn = mem_conn
  ) |>
    dplyr::filter(name_of_service_instance == "Fake Study")

  testthat::expect_equal(nrow(result), 1)
})

test_that("get_service_request_line_items sees 16 rows of data", {
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2025-01-02 17:00:00", tz = "America/New_York"))

  result <- get_service_request_line_items(
    service_requests = service_requests,
    rc_billing_conn = mem_conn,
    rc_conn = mem_conn
  )

  testthat::expect_equal(nrow(result), 16)
})

# Disconnect from DuckDB
DBI::dbDisconnect(mem_conn, shutdown = TRUE)
