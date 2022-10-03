testthat::test_that("previous_n_months handles some trivial and commoncases", {

  testthat::expect_equal(1:12, previous_n_months(month = 1:12, n = 0))
  testthat::expect_equal(1:12, previous_n_months(month = 1:12, n = 12))
  testthat::expect_equal(c(12, 1:11), previous_n_months(month = 1:12, n = 1))
  testthat::expect_equal(c(11:12, 1:10), previous_n_months(month = 1:12, n = 2))

})
