testthat::test_that("test that get_project_details_for_billing works", {
  redcapcustodian::set_script_run_time(ymd_hms("2023-06-12 12:00:00"))

  # build test tables in memory
  mem_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  test_tables <- c(
    "redcap_projects", # lives in REDCap DB
    "redcap_entity_project_ownership", # ibid
    "redcap_user_information", # ibid
    "invoice_line_item" # lives in rcc_billing DB
  )
  purrr::walk(test_tables, create_a_table_from_rds_test_data, mem_conn, "get_project_details_for_billing")

  project_ids <- dplyr::tbl(mem_conn, "redcap_projects") |>
    dplyr::select(project_id) |>
    dplyr::collect() |>
    dplyr::arrange(project_id) |>
    dplyr::pull(project_id)

  project_details <- get_project_details_for_billing(
    rc_conn = mem_conn,
    rcc_billing_con = mem_conn,
    project_ids
  )

  expected_col_names <- c(
    "project_id",
    "app_title",
    "billable",
    "sequestered",
    "creation_time",
    "pi_last_name",
    "pi_first_name",
    "pi_email",
    "ctsi_study_id"
  )
  testthat::expect_equal(colnames(project_details), expected_col_names)
  testthat::expect_equal(
    project_details |> dplyr::arrange(project_id) |> dplyr::pull(project_id),
    project_ids
  )

  DBI::dbDisconnect(mem_conn, shutdown = TRUE)
})
