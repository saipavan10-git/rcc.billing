## code to prepare `service_instance` dataset goes here
library(tibble)
library(usethis)

service_instance_test_data <- tribble(
  ~service_instance_id,
  ~service_type_code,
  ~service_identifier,
  ~ctsi_study_id,
  ~active,
  "1-6490", 1, "6490", 1919, F,
  "1-2345", 1, "2345", 1920, T,
  "1-3456", 1, "3456", 2929, T,
  "1-4567", 1, "4567", 3030, T,
  "3-jane@esu.edu", 3, "jane@esu.edu", 3333, T,
  "3-john@esu.edu", 3, "john@esu.edu", 3334, F,
  "3-jim@example.org", 3, "jim@example.org", 3335, T,
  "5-6490", 5, "6490", 565656, T,
  "5-2345", 5, "2345", 787878, T
)

usethis::use_data(service_instance_test_data, overwrite = TRUE)
