test_that("invoice_line_item_df_from invoice_line_item_communications works properly", {
    expect_identical(
        invoice_line_item_test_data,
        invoice_line_item_df_from(invoice_line_item_communications_test_data)
    )
})
