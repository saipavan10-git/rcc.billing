testthat::test_that("get_orphaned_projects identifies orphans in the correct sequence", {
  # Create test tables and set the date
  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  purrr::walk(get_orphaned_projects_test_tables, create_a_table_from_rds_test_data, mem_rc_conn, "get_orphaned_projects/rc")

  mem_rcc_billing_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  purrr::walk(c("banned_owners"), create_a_table_from_rds_test_data, mem_rcc_billing_conn, "get_orphaned_projects/rcc_billing")

  # TODO: this needs to be dynamic
  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-04-01 12:00:00"))

  result <- get_orphaned_projects(mem_rc_conn, mem_rcc_billing_conn)
  # NOTE: it would be great if we could use the "orphaned_project_types" df from make_get_orphaned_projects_test_data
  orphaned_project_priorities <- c(1, 2, 3, 4, 5, 5, 6)
  testthat::expect_equal(result$priority, orphaned_project_priorities)
})
