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


test_that("draft_communication_record_from_line_item correctly adds requisite columns", {
  csbt_line_items <- invoice_line_item_test_data %>%
    transform_invoice_line_items_for_csbt()

  communication_records <- csbt_line_items %>%
    draft_communication_record_from_line_item()

  added_columns <- c(
    "updated",
    "sender",
    "recipient",
    "date_sent",
    "date_received",
    "script_name"
  )

  redcapcustodian::set_script_name("test")
  redcapcustodian::set_script_run_time()

  expect_true(
    all( added_columns %in% colnames(communication_records) )
  )
})
