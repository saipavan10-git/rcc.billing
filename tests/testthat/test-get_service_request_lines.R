service_requests <- readRDS(testthat::test_path("get_service_request_lines", "service_requests.rds"))

expected_output <- tibble(
  record_id = c(6267, 6267, 6436, 6445, 6469, 6473, 7093),
  project_id = c("14242", "14242", "11843", "10929", "12665", "13433", NA_character_),
  service_identifier = c("6267", "6267", "6436", "6445", "6469", "6473", "7093"),
  service_type_code = rep(2, 7),
  service_instance_id = c("2-6267", "2-6267-PB", "2-6436-PB", "2-6445-PB", "2-6469", "2-6473", "2-7093"),
  username = c("bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_gatorlink", "bogus_gatorlink"),
  irb_number = c("123", "123", NA_character_, "123", "123", NA_character_, NA_character_),
  study_name = c(NA_character_, NA_character_, NA_character_, NA_character_, NA_character_, NA_character_, "Fake Study"),
  pi_last_name = c("PI", "PI", "l_name", "PI", "PI", "l_name", "PI"),
  pi_first_name = c("Bogus", "Bogus", "f_name","Bogus", "Bogus", "f_name", "Bogus"),
  pi_email = c("pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu"),
  other_system_invoicing_comments = c(
    "6267 : bogus_rc_username : 2024-02-29 : fake response",
    "6267 : bogus_rc_username : 2024-02-29 : Pro-bono : fake response",
    "6436 : bogus_rc_username : 2024-04-23 : Pro-bono : fake response",
    "6445 : bogus_rc_username : 2024-04-24 : Pro-bono : fake comment",
    "6469 : bogus_rc_username : 2024-04-30 : fake response",
    "6473 : bogus_gatorlink : 2024-05-01 : fake response",
    "7093 : bogus_gatorlink : 2024-12-10 : fake response fake response fake response fake response fake response fake response"
  ),
  fiscal_contact_fn = c(rep(NA_character_, 6), "f_name"),
  fiscal_contact_ln = c(rep(NA_character_, 6), "l_name"),
  fiscal_contact_email = c(rep(NA_character_, 6), "bogus@ufl.edu"),
  qty_provided = c(1.00, 0.50, 0.25, 0.25, 0.50, 0.25, 5),
  amount_due = c(130.0, 0, 0, 0, 65.0, 32.5, 650),
  price_of_service = c(130, 0, 0, 0, 130, 130, 130),
  service_date = as.Date(c(
    "2024-03-01",
    "2024-05-01",
    "2024-04-01",
    "2024-04-01",
    "2024-04-01",
    "2024-05-01",
    "2024-12-01"
  ))
)

testthat::test_that("get_service_request_lines returns nothing when billable_rate is not set", {
  redcapcustodian::set_script_run_time(ymd_hms("2014-10-03 12:00:00"))
  testthat::expect_equal(
    get_service_request_lines(service_requests) |> nrow(),
    0
  )
})

testthat::test_that("get_service_request_lines returns multiple lines both Paid and Probono", {
  redcapcustodian::set_script_run_time(ymd_hms("2024-05-03 12:00:00"))
  testthat::expect_equal(
    get_service_request_lines(service_requests),
    expected_output |> filter(service_date == as.Date("2024-04-01"))
  )
})

testthat::test_that("get_service_request_lines returns lines for a different time period", {
  redcapcustodian::set_script_run_time(ymd_hms("2024-06-03 12:00:00"))
  testthat::expect_equal(
    get_service_request_lines(service_requests),
    expected_output |> filter(service_date == as.Date("2024-05-01"))
  )
})

testthat::test_that("get_service_request_lines returns all the lines", {
  redcapcustodian::set_script_run_time(ymd_hms("2024-06-03 12:00:00"))
  testthat::expect_equal(
    get_service_request_lines(service_requests, return_all_records = T),
    expected_output
  )
})

testthat::test_that("get_service_request_lines returns a line of paid service for a request with no project ID", {
  redcapcustodian::set_script_run_time(ymd_hms("2025-01-03 12:00:00"))
  testthat::expect_equal(
    get_service_request_lines(service_requests),
    expected_output |> filter(service_date == as.Date("2024-12-01"))
  )
  testthat::expect_equal(
    get_service_request_lines(service_requests)$project_id,
    NA_character_
  )
})
