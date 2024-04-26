# Recommended approach from https://www.rdocumentation.org/packages/usethis/versions/2.1.5/topics/use_data
library(tibble)
library(usethis)

service_type_test_data <- tribble(
  ~service_type_code,
  ~service_type,
  ~price,
  ~billing_frequency,
  1, "Annual REDCap Project Maintenance", 130, 12,
  2, 'REDCap consulting', 130, 0
)

usethis::use_data(service_type_test_data, overwrite = TRUE)
