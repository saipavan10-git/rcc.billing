# records 1128 and 4907 contains duplicated project id.The record with the least time
# will be updated by get_probono_service_request_updates in addition to record_id 3
# which contians a unique project_id.
testthat::test_that("get_probono_service_request_updates returns the correct output", {
  service_requests <- data.frame(
    record_id = rep(c(3, 66, 1128, 4907, 6458, 6473, 5883), each = 2),
    redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 7),
    redcap_repeat_instance = rep(c(NA, 1), 7),
    project_id = c(851, NA, NA, NA, 6058, NA, 6058, NA, 12034, NA, 13433, NA, 10172, NA),
    time2 = c(NA, 45, NA, 15, NA, 30, NA, 15, NA, 30, NA, 15, NA, 75),
    time_more = c(rep(NA, 13), 3),
    billable_rate = c(NA, 0, rep(NA, 3), 0, NA, 0, NA, 130, NA, 0, NA, 0)
  )

  expected_output <- data.frame(
    record_id = c(4907, 3),
    redcap_repeat_instrument = c("help_desk_response", "help_desk_response"),
    redcap_repeat_instance = c(1, 1),
    billable_rate = c(0, 0)
  ) |>
    as_tibble()

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})
