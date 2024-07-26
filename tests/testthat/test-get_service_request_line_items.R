# Test the function with updated expected_result to include all fields
test_that("get_service_request_line_items returns correct results", {

  redcapcustodian::set_script_run_time(lubridate::ymd_hms("2023-02-05 12:00:00", tz="America/New_York"))

  mock_service_requests<- readRDS(testthat::test_path("get_service_request_lines", "service_requests.rds")) |>
  dplyr::mutate(
    irb_number = c("123"),
    fiscal_contact_fn = c("John"),
    fiscal_contact_ln = c("Doe"),
    fiscal_contact_email = c("test@xyz.com")
  )

  mock_invoice_line_item <- data.frame(
    id = c(1, 2, 3, 4),
    service_type_code = c(1, 1, 2, 1),
    service_identifier = c(14242, 12665, 14242, 12665),
    ctsi_study_id = c(300, 310, 200, 970)
  ) |>
    dplyr::mutate(across(everything(), as.integer)) |>
    dplyr::mutate(stringAsFactors = FALSE)

  mock_ctsi_study_id_map <- data.frame(
    project_id = c(14242, 12665),
    ctsi_study_id = c(300, 310, 200, 970)
  ) |>
    dplyr::mutate(across(everything(), as.integer)) |>
    dplyr::mutate(stringAsFactors = FALSE)

  # Create mock data for project details
  mock_project_details <- data.frame(
    project_id = as.integer(c("14242", "12665")),
    app_title = c("Project 14242", "Project 12665"),
    pi_last_name = c(NA, "Doe"),
    pi_first_name = c(NA, "John"),
    pi_email = c(NA, "john.doe@example.com"),
    irb_number = c(NA, "123"),
    ctsi_study_id = c(NA, "300"),
    stringsAsFactors = FALSE
  )

  # Create mock data for redcap_entity_project_ownership
  mock_redcap_entity_project_ownership <- data.frame(
    id = 1:2,
    created = as.numeric(Sys.time()),
    updated = as.numeric(Sys.time()),
    pid = as.integer(c("14242", "12665")),
    username = c(NA, "jsmith"),
    email = c("jdoe@example.com", NA),
    firstname = c("John", NA),
    lastname = c("Doe", NA),
    billable = c(1, 1),
    sequestered = c(0, 0)
  )

  # DuckDB setup
  rcc_billing_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")

  # Register mock data frames with DuckDB
  DBI::dbWriteTable(rcc_billing_conn, "ctsi_study_id_map", mock_ctsi_study_id_map)
  DBI::dbWriteTable(rcc_billing_conn, "project_details", mock_project_details)
  DBI::dbWriteTable(rcc_billing_conn, "invoice_line_item", mock_invoice_line_item)

  DBI::dbWriteTable(rc_conn, "redcap_entity_project_ownership", mock_redcap_entity_project_ownership)

  create_a_table_from_rds_test_data("redcap_projects", rc_conn, "get_new_project_invoice_line_items")
  updated_project_ids<- dbReadTable(rc_conn, "redcap_projects")|>
    dplyr::mutate(project_id= case_when(
      project_id %in% c(11987,12271) ~ as.integer(14242),
      project_id %in% c(13934,15467) ~ as.integer(12665),
    ))
  duckdb::duckdb_register(conn = rc_conn, name = "redcap_projects", df = updated_project_ids)

  create_a_table_from_rds_test_data("redcap_user_information", rc_conn, "get_new_project_invoice_line_items")
  create_a_table_from_rds_test_data("invoice_line_item", rc_conn, "get_ctsi_study_id_to_project_id_map")

  result <- get_service_request_line_items(
    mock_service_requests,
    rcc_billing_conn,
    rc_conn
    )
  expected_result <- dplyr::tibble(
    service_identifier = c("6267", "6267", "6436", "6445", "6469", "6473"),
    service_type_code = c("2", "2", "2", "2", "2", "2"),
    service_instance_id = c("2-6267", "2-6267", "2-6436", "2-6445", "2-6469", "2-6473-PB"),
    ctsi_study_id = c("300", "300", NA, NA, "970", NA),
    name_of_service = c("Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting", "Biomedical Informatics Consulting"),
    name_of_service_instance= c("178a329b", "178a329b", NA, NA, "06b26cc0", NA),
    other_system_invoicing_comments = c(
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6436 : bogus_rc_username : 2024-04-23 : fake response",
      "6445 : bogus_rc_username : 2024-04-24 : fake comment",
      "6469 : bogus_rc_username : 2024-04-30 : fake response",
      "6473 : bogus_gatorlink : 2024-05-01 : Pro-bono : fake response"
    ),
    price_of_service = c("130", "130", "130", "130", "130", "0"),
    qty_provided = c("1","0.5","0.25","0.25","0.5","0.25"),
    amount_due = c("130", "65", "32.5", "32.5", "65", "0"),
    fiscal_year = rep("2022-2023", 6),
    month_invoiced = factor(rep("January", 6), levels = month.name, ordered = TRUE),
    pi_last_name = c("PI", "PI", "l_name", "PI", "PI", "l_name"),
    pi_first_name = c("Bogus", "Bogus", "f_name", "Bogus", "Bogus", "f_name"),
    pi_email = c("pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu"),
    gatorlink = c("bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_gatorlink"),
    reason = rep("new_item", 6),
    status  = rep("draft", 6),
    created = rep(as.POSIXct("2023-02-05 12:00:00", tz="America/New_York"), 6),
    updated = rep(as.POSIXct("2023-02-05 12:00:00", tz="America/New_York"), 6),
    fiscal_contact_fn = rep("John", 6),
    fiscal_contact_ln = rep("Doe", 6),
    fiscal_contact_name = rep("John Doe", 6),
  )
  testthat::expect_equal(result, expected_result)

  # Disconnect from DuckDB
  DBI::dbDisconnect(rcc_billing_conn, shutdown = TRUE)
  DBI::dbDisconnect(rc_conn, shutdown = TRUE)
})

