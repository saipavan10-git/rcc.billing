test_that("redcap_log_event sqlite schemata are created and correct test data is returned", {
  table_name <- "redcap_log_event"
  test_data <- get0(paste0(table_name, "_test_data"))
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  for (log_table in names(redcap_log_event_test_data)) {
    sqlite_schema <- convert_schema_to_sqlite(table_name = log_table)
    create_table(
      conn = conn,
      schema = sqlite_schema
    )

    result <- DBI::dbAppendTable(
      conn = conn,
      name = log_table,
      value = test_data[[log_table]],
      overwrite = TRUE
    )

    results <- DBI::dbGetQuery(conn, paste("select * from", log_table)) %>%
      fix_data_in_redcap_log_event()

    testthat::expect_equal(dplyr::as_tibble(results), test_data[[log_table]])
  }

  DBI::dbDisconnect(conn)
})
