testthat::test_that("get_user_rights_and_info_v1 works", {
  result <- get_user_rights_and_info_v1(
    redcap_user_rights = redcap_rights_test_data$redcap_user_rights,
    redcap_user_roles = redcap_rights_test_data$redcap_user_roles,
    redcap_user_information = redcap_rights_test_data$redcap_user_information
  )

  limited_result <- result %>%
    select(
      project_id,
      username,
      expiration,
      role_id
    )

  expected_result <- tribble(
    ~project_id,
    ~username,
    ~expiration,
    ~role_id,
    15, "admin", as.Date(NA), as.integer(NA),
    17, "admin", as.Date(NA), as.integer(NA),
    18, "admin", lubridate::ymd("2022-10-10"), as.integer(NA),
    18, "bob", as.Date(NA), 2,
    18, "carol", as.Date(NA), 1
  )

  testthat::expect_equal(limited_result, expected_result)
})
