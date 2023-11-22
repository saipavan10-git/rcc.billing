# Recommended approach from https://www.rdocumentation.org/packages/usethis/versions/2.1.5/topics/use_data
library(tibble)
library(usethis)

service_type_test_data <- tribble(
  ~service_type_code,
  ~service_type,
  ~price,
  ~billing_frequency,
  1, "Annual REDCap Project Maintenance", 130, 12,
  2, "redcap_project_phone", 1000, 0,
  3, "redcap_table_account_prod", 35, 6,
  4, "redcap_table_account_phone", 35, 6,
  5, "redcap_mobile", 1000, 0,
  6, "redcap_consulting", 100, 0
)

usethis::use_data(service_type_test_data, overwrite = TRUE)
