testthat::test_that("get_service_request_lines returns the proper df", {

  service_requests <- readRDS(testthat::test_path("get_service_request_lines", "service_requests.rds"))

  expected_output <- tibble(
    record_id = c(6267, 6436, 6445, 6469, 6473),
    project_id = c("14242", "11843", "10929", "12665", "13433"),
    service_identifier = c("6267", "6436", "6445", "6469", "6473"),
    service_type_code = rep(2, 5),
    service_instance_id = c("2-6267", "2-6436", "2-6445", "2-6469", "2-6473-PB"),
    irb_number = c("123", NA_character_, "123", "123", NA_character_),
    pi_last_name = c("PI", "l_name", "PI", "PI", "l_name"),
    pi_first_name = c("Bogus", "f_name","Bogus", "Bogus", "f_name"),
    pi_email = c("pi_email@ufl.edu", "bogus@ufl.edu", "pi_email@ufl.edu", "pi_email@ufl.edu", "bogus@ufl.edu"),
    other_system_invoicing_comments = c(
      "6267bogus_rc_username2024-02-29fake response fake response :",
      "6436bogus_rc_username2024-04-23fake response :",
      "6445bogus_rc_username2024-04-24NA :",
      "6469bogus_rc_username2024-04-30fake response :",
      "6473bogus_gatorlink2024-05-01Pro-bono : fake response :"
    ),
    qty_provided = c(1.50, 0.25, 0.25, 0.50, 0.25),
    amount_due = c(195.0, 32.5, 32.5, 65.0, 0.0),
    price_of_service = c(130, 130, 130, 130, 0)
  )


  testthat::expect_equal(
    get_service_request_lines(service_requests),
    expected_output
  )

})
