test_that("invoice_line_item_df_from invoice_line_item_communications works properly", {
    expect_identical(
        invoice_line_item_test_data,
        invoice_line_item_df_from(invoice_line_item_communications_test_data)
    )
})


test_that("transform_invoice_line_items_for_csbt correctly converts all column names in CTSIT to CSBT format", {

  initial_colnames <- invoice_line_item_test_data %>%
    colnames() %>%
    sort()

  results <- invoice_line_item_test_data %>%
    transform_invoice_line_items_for_csbt()

  transformed_colnames <- results %>%
    colnames() %>%
    sort()

  expect_false( any(transformed_colnames %in% csbt_column_names$ctsit) )
})
