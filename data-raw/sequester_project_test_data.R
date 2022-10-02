## Create sequester_project_test_data

library(redcapcustodian)
library(rcc.billing)
library(tidyverse)
library(lubridate)
library(DBI)
library(RMariaDB)
library(dotenv)

# run this once against a test redcap to extract the part we need
conn <- connect_to_redcap_db()

project_lifecycle_event_descriptions <-
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
    "Project moved from Completed status back to Development status",
    "Project moved from Completed status back to Production status",
    "Create project (API)"
  )

log_event_project_lifecycle <- function(conn,
                                        log_event_table = "redcap_log_event") {
  result <- dplyr::tbl(conn, log_event_table) %>%
    dplyr::filter(event == "MANAGE") %>%
    dplyr::filter(description %in% project_lifecycle_event_descriptions) %>%
    dplyr::collect()

  return(result)
}

generic_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership"
)

read_generic_tables <- function(conn, table_name) {
  return(dplyr::tbl(src = conn, table_name) %>% as_tibble())
}

read_schema <- function(conn, table_name) {
  schema = DBI::dbGetQuery(conn, paste("show create table", table_name))$`Create Table`
  return(schema)
}

# # run this section only once to build a suitable test data set from a test redcap system
# sequester_project_test_data <- bind_rows(
#   tibble(
#     name = log_event_tables,
#     schema = purrr::map(log_event_tables, read_schema, conn = conn),
#     data = purrr::map(log_event_tables, log_event_project_lifecycle, conn = conn)
#   ),
#   tibble(
#     name = generic_tables,
#     schema = purrr::map(generic_tables, read_schema, conn = conn),
#     data = purrr::map(generic_tables, read_generic_tables, conn = conn)
#   )
# )
#
# # write the test data
# usethis::use_data(sequester_project_test_data, overwrite = T)

dbDisconnect(conn)
