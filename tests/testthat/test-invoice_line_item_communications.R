testthat::test_that("service_type sqlite schema is created and correct test data is returned", {
  table_name <- "invoice_line_item_communications"
  mem_conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
  test_data <- readRDS(
    testthat::test_path(
      table_name, paste0(table_name, ".rds")
    )
  )
  test_data <- dplyr::mutate(test_data,
    je_posting_date = as.POSIXct(je_posting_date, tz = "UTC"),
    created = as.POSIXct(created, tz = "UTC"),
    updated = as.POSIXct(updated, tz = "UTC"),
    date_sent = as.POSIXct(date_sent, tz = "UTC"),
    date_received = as.POSIXct(date_received, tz = "UTC")
  )
  sqlite_schema <- convert_schema_to_sqlite(table_name)
  create_table(
    conn = mem_conn,
    schema = sqlite_schema
  )
  results <- populate_table(
    conn = mem_conn,
    table_name = table_name,
    use_test_data = T
  ) %>% fix_data_in_invoice_line_item_communication()

  expect_identical(test_data, dplyr::as_tibble(results))
  DBI::dbDisconnect(mem_conn)
})
