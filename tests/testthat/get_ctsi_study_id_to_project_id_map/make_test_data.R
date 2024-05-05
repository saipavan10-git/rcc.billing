invoice_line_item <- data.frame(
  id = c(1, 2, 3, 4),
  service_type_code = c(1, 1, 2, 1),
  service_identifier = c(100, 100, 115, 400),
  ctsi_study_id = c(300, 310, 200, 970)
) |>
  dplyr::mutate_all(as.character)

saveRDS(
  invoice_line_item,
  testthat::test_path(
    "get_ctsi_study_id_to_project_id_map",
    "invoice_line_item.rds"
  )
)

service_requests <- data.frame(
  record_id = c(115, 300),
  redcap_repeat_instrument = c(NA, NA),
  project_id = c(350, NA)
) |>
  dplyr::mutate_all(as.character)

saveRDS(
  service_requests,
  testthat::test_path(
    "get_ctsi_study_id_to_project_id_map",
    "service_requests.rds"
  )
)
