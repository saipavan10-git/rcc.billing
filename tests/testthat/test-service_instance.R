test_that("service_type sqlite schema is created and correct test data is returned", {
  table_name <- "service_instance"
  test_data <- get0(paste0(table_name, "_test_data"))
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  sqlite_schema <- convert_schema_to_sqlite(table_name = table_name)
  create_table(
    conn = conn,
    schema = sqlite_schema
  )
  results <- populate_table(
    conn = conn,
    table_name = table_name,
    use_test_data = TRUE
  )
  results$active <- as.logical(results$active)

  DBI::dbDisconnect(conn)
  expect_identical(test_data, dplyr::as_tibble(results))
})
