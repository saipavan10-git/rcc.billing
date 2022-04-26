# Create redcap_log_event_test_data with a subset of logged data
# that shows the entire logged project life-cycle across every
# redcap_log_event* table

library(redcapcustodian)
library(rcc.billing)
library(tidyverse)
library(DBI)
library(RMariaDB)
library(dotenv)

project_event_descriptions <-
  c(
    "Approve production project modifications (automatic)",
    "Create project",
    "Delete project",
    "Request approval for production project modifications",
    "Send request to move project to production status",
    "Move project to production status",
    "Permanently delete project",
    "Copy project",
    "Approve production project modifications",
    "Create project using template",
    "Archive project",
    "Send request to create project",
    "Set project as inactive",
    "Reject production project modifications",
    "Move project back to development status",
    "Return project to production from inactive status",
    "Reset production project modifications",
    "Send request to copy project",
    "Restore/undelete project",
    "Create project (API)"
  )

# run this once against a test redcap to extract the part we need
conn <- connect_to_redcap_db()

base_table <- "redcap_log_event"
redcap_log_event_test_data <- list()
for (i in seq(1:9)) {
  my_table <- if_else(i == 1, base_table, paste0(base_table, i))
  single_log_table <-
    tbl(conn, my_table) %>%
    filter(description %in% project_event_descriptions) %>%
    collect()
  redcap_log_event_test_data[[my_table]] <- single_log_table

  # write the schema
  DBI::dbGetQuery(conn, paste("show create table", my_table))$`Create Table` %>%
    write(file = paste0("inst/schema/", my_table, ".sql"))
}

# write the test data
usethis::use_data(redcap_log_event_test_data, overwrite = T)

dbDisconnect(conn)
