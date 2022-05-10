test_that("service_type sqlite schema is created and correct test data is returned", {
    table_name <- "redcap_projects"
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
        use_test_data = T
    ) %>% fix_data_in_redcap_projects()

    DBI::dbDisconnect(conn)
    expect_equal(dplyr::as_tibble(results), test_data)
})
