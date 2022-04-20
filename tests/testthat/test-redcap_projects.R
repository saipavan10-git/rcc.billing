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
        table_name = table_name
    ) %>%
        dplyr::mutate(dplyr::across(c(creation_time,
                                      production_time,
                                      inactive_time,
                                      completed_time,
                                      date_deleted,
                                      last_logged_event,
                                      datamart_cron_end_date,
                                      twilio_request_inspector_checked),
                                    ~ as.POSIXct(., origin = "1970-01-01 00:00.00 UTC", tz = "UTC"))) %>%
        dplyr::mutate(
            project_id = as.double(project_id),
            protected_email_mode_custom_trigger = as.null.default(protected_email_mode_custom_trigger)
        )

    DBI::dbDisconnect(conn)
    expect_equal(dplyr::as_tibble(results), test_data)
})
