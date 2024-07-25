testthat::test_that("get_service_request_lines returns the proper df", {

  service_requests <- readRDS(testthat::test_path("get_service_request_lines", "service_requests.rds"))

  expected_output <- tibble(
    record_id = c(6267, 6267, 6436, 6445, 6469, 6473),
    project_id = c("14242", "14242", "11843", "10929", "12665", "13433"),
    service_identifier = c("6267", "6267", "6436", "6445", "6469", "6473"),
    service_type_code = rep(2, 6),
    service_instance_id = c("2-6267", "2-6267", "2-6436", "2-6445", "2-6469", "2-6473-PB"),
    username = c("bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_rc_username", "bogus_gatorlink"),
    irb_number = c("123", "123", NA_character_, "123", "123", NA_character_),
    pi_last_name = c("PI", "PI", "l_name", "PI", "PI", "l_name"),
    pi_first_name = c("Bogus", "Bogus", "f_name","Bogus", "Bogus", "f_name"),
    pi_email = c("pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu"),
    other_system_invoicing_comments = c(
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6267 : bogus_rc_username : 2024-02-29 : fake response",
      "6436 : bogus_rc_username : 2024-04-23 : fake response",
      "6445 : bogus_rc_username : 2024-04-24 : fake comment",
      "6469 : bogus_rc_username : 2024-04-30 : fake response",
      "6473 : bogus_gatorlink : 2024-05-01 : Pro-bono : fake response"
    ),
    fiscal_contact_fn = rep(NA_character_, 6),
    fiscal_contact_ln = rep(NA_character_, 6),
    fiscal_contact_email = rep(NA_character_, 6),
    qty_provided = c(1.00, 0.50, 0.25, 0.25, 0.50, 0.25),
    amount_due = c(130.0, 65.0, 32.5, 32.5, 65.0, 0.0),
    price_of_service = c(130, 130, 130, 130, 130, 0),
    service_date = as.Date(c(
      "2024-03-01",
      "2024-05-01",
      "2024-04-01",
      "2024-04-01",
      "2024-04-01",
      "2024-05-01"
    ))
  )

  testthat::expect_equal(
    get_service_request_lines(service_requests),
    expected_output
  )

})
