testthat::test_that("is_faculty can distinguish faculty from non-faculty", {
  user_ids = c("pbc", "hoganwr", "cpb", "shapiroj", "pbc")
  expected_result = c(F, T, F, T, F)

  result <- is_faculty(user_ids = user_ids)
  testthat::expect_equal(result, expected_result)
})
