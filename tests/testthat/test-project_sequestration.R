# test sequester_project
testthat::test_that("sequester_projects closes and sequesters projects", {

  set_script_run_time()
  # build test tables in memory
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  create_table_2 <- function(this_table_name, test_data_tibble, conn) {
    table_schema <- test_data_tibble %>%
      dplyr::filter(.data$name == this_table_name) %>%
      dplyr::pull(schema) %>%
      magrittr::extract2(1)

    create_table(
      conn = conn,
      #schema = mysql_schema_to_sqlite(table_schema)
      schema = rcc.billing::mysql_schema_to_sqlite(table_schema)
    )
  }

  purrr::walk(
    sequester_project_test_data$name,
    create_table_2,
    test_data_tibble = sequester_project_test_data,
    conn = conn
  )
  dbListTables(conn)

  # populate test tables
  populate_table_2 <- function(this_table_name, test_data_tibble, conn) {
    table_data <- test_data_tibble %>%
      dplyr::filter(.data$name == this_table_name) %>%
      dplyr::pull(data) %>%
      magrittr::extract2(1)

    DBI::dbAppendTable(
      conn = conn,
      name = this_table_name,
      value = table_data,
      overwrite = TRUE
    )
  }

  tables <- sequester_project_test_data$name

  purrr::walk(
    tables,
    populate_table_2,
    test_data_tibble = sequester_project_test_data,
    conn = conn
  )

  # # inspect the test tables in memory
  # purrr::walk(
  #   tables,
  #   ~ print(dplyr::tbl(conn, .x)),
  #   conn
  # )

  project_ids_to_sequester <- c(17,18,666)
  expected_project_ids_sequestered <- c(17,18)
  result <- sequester_projects(conn = conn, project_ids = project_ids_to_sequester)
  testthat::expect_equal(expected_project_ids_sequestered, result$project_ids_updated)

  dbDisconnect(conn)
})
