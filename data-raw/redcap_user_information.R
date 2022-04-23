## Create redcap_projects_test_data from invoice_line_items_test_data

library(redcapcustodian)
library(rcc.billing)
library(tidyverse)
library(lubridate)
library(DBI)
library(RMariaDB)
library(dotenv)

my_table <- "redcap_user_information"

# run this once against a test redcap to extract the part we need
conn <- connect_to_redcap_db()
data <- tbl(conn, my_table)

redcap_user_information_test_data <- data %>%
  collect() %>%
  filter(ui_id >= 3)

# werite the test data
usethis::use_data(redcap_user_information_test_data, overwrite = T)

# write the schema
DBI::dbGetQuery(conn, paste("show create table", my_table))$`Create Table` %>%
  write(file = paste0("inst/schema/", my_table, ".sql"))

dbDisconnect(conn)
