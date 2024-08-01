testthat::test_that("sequester_projects completes projects and flips the sequester flag in project_ownership", {
  function_to_test <- c("sequester_projects")
  # Create test tables and set the date
  mem_rc_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  files <- fs::dir_ls(testthat::test_path(function_to_test), glob = "*.rds")
  purrr::walk(files, create_a_table_from_rds, mem_rc_conn)

  # enumerate the projects we will iterate over
  projects <- dplyr::tbl(mem_rc_conn, "redcap_projects") |>
    dplyr::collect() |>
    dplyr::pull(project_id)

  # Set a known run time so we can test for it in the output
  run_time <- lubridate::ymd_hms("2024-04-04 12:00:00")
  redcapcustodian::set_script_run_time(run_time)

  result <- sequester_projects(conn = mem_rc_conn, project_id = projects, reason = "unpaid_after_90_days")

  # Get some measures of sequester_projects' performance so we can test them
  sequestered_count <- dplyr::tbl(mem_rc_conn, "redcap_entity_project_ownership") |>
    dplyr::filter(sequestered == 1) |>
    dplyr::collect() |>
    nrow()

  completed_by_count <- tbl(mem_rc_conn, "redcap_projects") |>
    dplyr::filter(stringr::str_detect(completed_by, "unpaid_after_90_days")) |>
    dplyr::collect() |>
    nrow()

  completed_time <- tbl(mem_rc_conn, "redcap_projects") |>
    dplyr::distinct(completed_time) |>
    dplyr::collect() |>
    dplyr::pull(completed_time)

  testthat::expect_equal(result$project_ids_updated, projects)
  testthat::expect_equal(sequestered_count, length(projects))
  testthat::expect_equal(completed_by_count, length(projects))
  testthat::expect_equal(completed_time, run_time)

  DBI::dbDisconnect(mem_rc_conn, shutdown = TRUE)
})
