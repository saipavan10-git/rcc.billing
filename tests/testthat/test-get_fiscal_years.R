testthat::test_that("The start of the first fiscal year interval is precise",{
    testthat::expect_equal(
    fiscal_years %>%
      filter(lubridate::ymd("2019-07-01", tz="America/New_York") %within% fy_interval) %>%
      pull(csbt_label),
    "2019-2020"
    )
})

testthat::test_that("The end of the first fiscal year interval is precise",{
  testthat::expect_equal(
    fiscal_years %>%
      dplyr::filter(lubridate::ymd("2020-06-30", tz="America/New_York") %within% fy_interval) %>%
      dplyr::pull(csbt_label),
    "2019-2020"
  )
})

testthat::test_that("We have an interval for FY 2023-2024",{
  testthat::expect_equal(
    fiscal_years %>%
      filter(lubridate::ymd("2024-06-30", tz="America/New_York") %within% fy_interval) %>%
      pull(csbt_label),
    "2023-2024"
  )
})
