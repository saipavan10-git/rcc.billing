testthat::test_that("get_csti_study_id_to_project_id_map returns proper mapping", {

  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  create_a_table_from_rds_test_data("invoice_line_item", mem_rc_conn, "get_ctsi_study_id_to_project_id_map")

  service_requests <- readRDS(testthat::test_path("get_ctsi_study_id_to_project_id_map", "service_requests.rds"))

  expected_output <- data.frame(
    project_id = c("400", "100", "350"),
    ctsi_study_id = c("970", "310", "200")
  ) |>
    dplyr::as_tibble()

  testthat::expect_equal(
    get_ctsi_study_id_to_project_id_map(service_requests, mem_rc_conn),
    expected_output
  )

})
