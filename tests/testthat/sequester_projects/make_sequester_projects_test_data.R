# make_sequester_projects_test_data.R

library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
set_script_run_time(ymd_hms("2024-04-04 12:00:00"))

rc_conn <- connect_to_redcap_db()

test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership"
)

redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) |>
  collect() |>
  sample_n(size = 10) |>
  arrange(project_id) |>
  # Set the fields we will write to a null state
  mutate(completed_time = NA_POSIXct_,
         completed_by = NA_character_)

redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() |>
  # Set the fields we will write to a null state
  mutate(sequestered = sample(c(0, NA_real_), size = 10, replace = TRUE))

# Write the test inputs to rds
write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("sequester_projects", paste0(basename, ".rds")))
}
walk(test_tables, ~ write_to_testing_rds(get(.), .))

# Write out the log table data
log_event_tables_to_query <- partial_project_state %>%
  dplyr::distinct(.data$log_event_table) %>%
  dplyr::pull()

get_and_write_relevant_log_event_data <- function(log_event_table,
                            conn,
                            project_ids) {

  result <- dplyr::tbl(conn, log_event_table) %>%
    dplyr::filter(.data$project_id %in% project_ids) %>%
    dplyr::filter(.data$event == "MANAGE") %>%
    dplyr::filter(.data$page == "ProjectGeneral/change_project_status.php") %>%
    dplyr::collect() %>%
    dplyr::filter(stringr::str_detect(.data$description, "Project moved from Completed status back to"))

  result |> write_to_testing_rds(log_event_table)
  return(result)
}

# write all of the test inputs
log_rows <- map(
  log_event_tables_to_query,
  ~ get_and_write_relevant_log_event_data(
    .,
    rc_conn,
    redcap_projects$project_id
  )
) |>
  list_rbind()
