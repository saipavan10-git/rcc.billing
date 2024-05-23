testthat::test_that("get_probono_service_request_updates handles single records with one repeat, no existing probono and time <= 1 hour", {
  service_requests <- data.frame(
    record_id = rep(seq(1,4), each = 2),
    redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 4),
    redcap_repeat_instance = rep(c(NA, 1), 4),
    project_id = c(
      10, NA,
      20, NA,
      30, NA,
      40, NA
    ),
    time2 = c(
      NA, 15,
      NA, 30,
      NA, 45,
      NA, 60
    ),
    time_more = c(rep(NA, 8)),
    billable_rate = rep(c(NA, 130), 4)
  )

  expected_output <- dplyr::tibble(
    record_id = seq(1,4),
    redcap_repeat_instrument = rep("help_desk_response", 4),
    redcap_repeat_instance = rep(1, 4),
    billable_rate = rep(0, 4)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

testthat::test_that("get_probono_service_request_updates handles single records with one repeat, all existing time being probono, and time <= 1 hour", {
  service_requests <- data.frame(
    record_id = rep(seq(1,4), each = 2),
    redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 4),
    redcap_repeat_instance = rep(c(NA, 1), 4),
    project_id = c(
      10, NA,
      20, NA,
      30, NA,
      40, NA
    ),
    time2 = c(
      NA, 15,
      NA, 30,
      NA, 45,
      NA, 60
    ),
    time_more = c(rep(NA, 8)),
    billable_rate = rep(c(NA, 0), 4)
  )

  # expected_output is an empty data frame
  testthat::expect_equal(
    nrow(get_probono_service_request_updates(service_requests)),
    0
  )

})

testthat::test_that("get_probono_service_request_updates handles single records with one repeat, 50% probono and time <= 1 hour", {
  service_requests <- data.frame(
    record_id = rep(seq(1,4), each = 2),
    redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 4),
    redcap_repeat_instance = rep(c(NA, 1), 4),
    project_id = c(
      10, NA,
      20, NA,
      30, NA,
      40, NA
    ),
    time2 = c(
      NA, 15,
      NA, 30,
      NA, 45,
      NA, 60
    ),
    time_more = c(rep(NA, 8)),
    billable_rate = rep(c(NA, 130, NA, 0), 2)
  )

  expected_output <- dplyr::tibble(
    record_id = c(1,3),
    redcap_repeat_instrument = rep("help_desk_response", 2),
    redcap_repeat_instance = rep(1, 2),
    billable_rate = rep(0, 2)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

testthat::test_that("get_probono_service_request_updates handles multiple helpdesk requests for a project, where nothing is yet probono", {
  service_requests <- data.frame(
    record_id = rep(seq(1,4), each = 2),
    redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 4),
    redcap_repeat_instance = rep(c(NA, 1), 4),
    project_id = c(
      10, NA,
      10, NA,
      10, NA,
      10, NA
    ),
    time2 = c(
      NA, 15,
      NA, 30,
      NA, 45,
      NA, 60
    ),
    time_more = c(rep(NA, 8)),
    billable_rate = rep(c(NA, 130, NA, 130), 2)
  )

  expected_output <- dplyr::tibble(
    record_id = c(1,2,3),
    redcap_repeat_instrument = rep("help_desk_response", 3),
    redcap_repeat_instance = rep(1, 3),
    billable_rate = rep(0, 3)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

testthat::test_that("get_probono_service_request_updates handles multiple time entries on one helpdesk request for a project, where some entries are already probono", {
  service_requests <- data.frame(
    record_id = rep(1, 5),
    redcap_repeat_instrument = c(NA, rep("help_desk_response", 4)),
    redcap_repeat_instance = c(NA, seq(1,4)),
    project_id = c(10, rep(NA, 4)),
    time2 = c(NA, 15, 15, 45, 75),
    time_more = c(rep(NA, 4), 1.5),
    billable_rate = c(NA, 0, 130, 130, 130)
  )

  expected_output <- dplyr::tibble(
    record_id = c(1,1),
    redcap_repeat_instrument = rep("help_desk_response", 2),
    redcap_repeat_instance = c(2, 3),
    billable_rate = c(0, 0)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

testthat::test_that("get_probono_service_request_updates handles multiple requests with multiple time entries for 3 projects, where some entries are already probono", {
  service_requests <- data.frame(
    record_id = c(rep(1, 5), rep(2, 5), rep(3, 5)),
    redcap_repeat_instrument = rep(c(NA, rep("help_desk_response", 4)), 3),
    redcap_repeat_instance = rep(c(NA, seq(1, 4)), 3),
    project_id = c(
      10, rep(NA, 4),
      20, rep(NA, 4),
      10, rep(NA, 4)
    ),
    time2 = c(
      NA, 15, 15, 15, 15,
      NA, 15, 15, 15, 15,
      NA, 15, 15, 45, 75
    ),
    time_more = c(
      NA, NA, NA, NA, NA,
      NA, NA, NA, NA, NA,
      NA, NA, NA, NA, 3.5
    ),
    billable_rate = c(
      NA, 0, 130, 130, 130,
      NA, 0, 0, 130, 130,
      NA, 130, 130, 130, 130
    )
  )

  expected_output <- dplyr::tibble(
    record_id = c(1, 1, 1, 2, 2),
    redcap_repeat_instrument = rep("help_desk_response", 5),
    redcap_repeat_instance = c(2, 3, 4, 3, 4),
    billable_rate = rep(0, 5)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

testthat::test_that("get_probono_service_request_updates handles multiple requests with multiple time entries for 3 projects, where some entries are already probono. Also add non-project entries", {
  service_requests <-
    dplyr::bind_rows(
      data.frame(
        record_id = c(rep(1, 5), rep(2, 5), rep(3, 5)),
        redcap_repeat_instrument = rep(c(NA, rep("help_desk_response", 4)), 3),
        redcap_repeat_instance = rep(c(NA, seq(1, 4)), 3),
        project_id = c(
          10, rep(NA, 4),
          20, rep(NA, 4),
          10, rep(NA, 4)
        ),
        time2 = c(
          NA, 15, 15, 15, 15,
          NA, 15, 15, 15, 15,
          NA, 15, 15, 45, 75
        ),
        time_more = c(
          NA, NA, NA, NA, NA,
          NA, NA, NA, NA, NA,
          NA, NA, NA, NA, 3.5
        ),
        billable_rate = c(
          NA, 0, 130, 130, 130,
          NA, 0, 0, 130, 130,
          NA, 130, 130, 130, 130
        )
      ),
      # Add non-project requests
      data.frame(
        record_id = rep(c(4, 5, 6), each = 2),
        redcap_repeat_instrument = rep(c(NA, "help_desk_response"), 3),
        redcap_repeat_instance = rep(c(NA, 1), 3),
        project_id = rep(NA, 6),
        time2 = c(
          NA, 15,
          NA, 75,
          NA, 45
        ),
        time_more = c(
          NA, NA, NA, 2.5, NA, NA
        ),
        billable_rate = c(
          NA, 0, NA, 130, NA, 130
        )
      )
    )

  expected_output <- dplyr::tibble(
    record_id = c(1, 1, 1, 2, 2),
    redcap_repeat_instrument = rep("help_desk_response", 5),
    redcap_repeat_instance = c(2, 3, 4, 3, 4),
    billable_rate = rep(0, 5)
  )

  testthat::expect_equal(
    get_probono_service_request_updates(service_requests),
    expected_output
  )

})

