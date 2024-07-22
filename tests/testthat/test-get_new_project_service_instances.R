test_that("get_new_project_service_instances works", {
  projects_to_invoice <- dplyr::tribble(
    ~project_id,
    111,
    222,
    333,
    444
  )

  initial_service_instance <- dplyr::tribble(
    ~service_type_code,
    ~service_identifier,
    ~service_instance_id,
    ~active,
    ~ctsi_study_id,
    1, "111", "1-111", 1, 123,
    1, "222", "1-222", 1, 223
  )

  testthat::expect_true(all.equal(
    get_new_project_service_instances(projects_to_invoice, initial_service_instance)$service_instance_id,
    c("1-333", "1-444")
  ))
})
