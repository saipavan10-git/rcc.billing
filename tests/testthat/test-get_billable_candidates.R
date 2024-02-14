testthat::test_that("get_billable_candidates returns the correct names", {
  redcapcustodian::set_script_run_time()
  # build test tables in memory
  conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  purrr::walk(get_billable_candidates_test_tables, create_a_table_from_rds_test_data, conn, "get_billable_candidates")

  # DBI::dbListTables(conn)

  expected_names <- c(
    "project_owner_email",
    "project_owner_full_name",
    "project_owner_username",
    "primary_uf_fiscal_org",
    "dept_name",
    "user_suspended_time",
    "user_lastlogin",
    "project_id",
    "project_creation_time",
    "creation_month",
    "project_is_mature",
    "sequestered",
    "is_deleted",
    "record_count",
    "last_logged_event",
    "is_deleted_but_not_paid",
    "invoice_number",
    "fiscal_year",
    "month_invoiced",
    "status.line_item",
    "project_irb_number",
    "project_title"
  )

  testthat::expect_named(
    get_billable_candidates(
      rc_conn = conn,
      rcc_billing_conn = conn
    ),
    expected_names
  )

  DBI::dbDisconnect(conn)
})
