# test get_project_details_for_billing
redcapcustodian::set_script_run_time(ymd_hms("2023-06-12 12:00:00"))

# build test tables in memory
mem_conn <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
test_tables <- c(
  "redcap_projects", # lives in REDCap DB
  "redcap_entity_project_ownership", # ibid
  "redcap_user_information", # ibid
  "invoice_line_item" # lives in rcc_billing DB
)
purrr::walk(test_tables, create_a_table_from_rds_test_data, mem_conn, "get_project_details_for_billing")

project_ids <- dplyr::tbl(mem_conn, "redcap_projects") |>
  dplyr::select(project_id) |>
  dplyr::collect() |>
  dplyr::arrange(project_id) |>
  dplyr::pull(project_id)

sample_size <- 5
sampled_project_ids <- project_ids[1:sample_size]

project_details <- get_project_details_for_billing(
  rc_conn = mem_conn,
  rcc_billing_con = mem_conn
)

expected_col_names <- c(
  "project_id",
  "app_title",
  "billable",
  "sequestered",
  "creation_time",
  "pi_last_name",
  "pi_first_name",
  "pi_email",
  "ctsi_study_id"
)

testthat::test_that("test that get_project_details_for_billing has the correct columns", {
  testthat::expect_equal(colnames(project_details), expected_col_names)
})

testthat::test_that("test that get_project_details_for_billing returns the right list of project IDs", {
  testthat::expect_equal(
    project_details |> dplyr::arrange(project_id) |> dplyr::pull(project_id),
    project_ids
  )
})

testthat::test_that("test that get_project_details_for_billing will return a subset of the existing projects given a vector of project IDs", {
  testthat::expect_equal(
    get_project_details_for_billing(
      rc_conn = mem_conn,
      rcc_billing_con = mem_conn,
      sampled_project_ids
    ) |> nrow(),
    sample_size
  )
})
