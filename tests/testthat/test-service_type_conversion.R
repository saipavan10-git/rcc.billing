test_that("service_type sqlite schema is created and correct test data is returned", {
    table_name <- "service_type"
    test_data <- get0(paste0(table_name, "_test_data"))

    convert_schema_to_sqlite(table_name)
    results <- write_to_sqlite(table_name)

    expect_identical(test_data, as_tibble(results))
})
