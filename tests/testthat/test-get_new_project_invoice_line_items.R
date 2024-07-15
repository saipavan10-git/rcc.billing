testthat::test_that("get_new_project_invoice_line_items works", {

  test_tables <- c(
    "redcap_config",
    "redcap_projects",
    "redcap_entity_project_ownership",
    "redcap_user_information",
    "service_type",
    "service_instance",
    "invoice_line_item",
    "projects_to_invoice"
  )

  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  purrr::walk(test_tables,
              create_a_table_from_rds_test_data,
              mem_rc_conn,
              "get_new_project_invoice_line_items")

  projects_to_invoice <- dplyr::tbl(mem_rc_conn, "projects_to_invoice") |>
    dplyr::collect()

  initial_invoice_line_item <- dplyr::tbl(mem_rc_conn, "invoice_line_item") |>
    dplyr::collect()

  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-04-05 12:00:00"))

  new_project_invoice_line_items <- get_new_project_invoice_line_items(
    projects_to_invoice = projects_to_invoice,
    initial_invoice_line_item = initial_invoice_line_item,
    rc_conn = mem_rc_conn,
    rcc_billing_conn = mem_rc_conn,
    api_uri = "https://example.org/redcap/api/"
  )

  testthat::expect_equal(
    new_project_invoice_line_items$service_identifier,
                         as.character(projects_to_invoice$project_id)
    )
  testthat::expect_equal(new_project_invoice_line_items$service_type_code, rep(1, 4))
  testthat::expect_equal(as.character(new_project_invoice_line_items$month_invoiced), rep("March", 4))
})
