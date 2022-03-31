#' Sample data for service_type table
#' Recommended approach from https://r-pkgs.org/data.html#documenting-data
#'
#' @format
#' tribble(
#'   ~service_type_code,
#'   ~service_type,
#'   ~cost,
#'   ~billing_frequency,
#'   1, "redcap_project_prod", 100, 12,
#'   2, "redcap_project_phone", 1000, 0,
#'   3, "redcap_table_account_prod", 35, 6,
#'   4, "redcap_table_account_phone", 35, 6,
#'   5, "redcap_mobile", 1000, 0,
#'   6, "redcap_consulting", 100, 0
#' )
#' @source \url{https://github.com/ctsit/rcc.billing/issues/1}
"service_type_test_data"
