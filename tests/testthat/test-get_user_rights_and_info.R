testthat::test_that("get_user_rights_and_info returns the correct counts of records and role_ids", {
  redcapcustodian::set_script_run_time(as.Date("2023-07-01"))

  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")

  purrr::walk(
    get_user_rights_and_info_test_tables,
    create_a_table_from_rds_test_data,
    mem_rc_conn,
    "get_user_rights_and_info"
  )

  expected_counts <- tribble(
    ~username, ~n_records, ~n_roles,
    "pbc", 2, 1,
    "tls", 1, 1
  )

  # summarize output
  counts <- get_user_rights_and_info(
    mem_rc_conn,
    require_active_account = T,
    require_active_permissions = T
  ) |>
    dplyr::add_count(username, name = "n_records") |>
    dplyr::add_count(username, !is.na(role_id), name = "n_roles") |>
    dplyr::select(
      "username",
      "n_records",
      "n_roles"
    ) |>
    dplyr::distinct()

  dbDisconnect(mem_rc_conn, shutdown=TRUE)

  testthat::expect_equal(counts, expected_counts)
})
