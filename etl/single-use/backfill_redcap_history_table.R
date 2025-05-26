library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)
library(jsonlite)
library(lubridate)

init_etl("backfill_redcap_project_history_table_from_log_event_table")

rc_conn <- connect_to_redcap_db()
rc_billing_conn <- connect_to_rcc_billing_db()

# create a target table if it does not exist. empty after creation.
if (!"redcap_projects_history" %in% DBI::dbListTables(rc_billing_conn)) {
  redcap_projects_source <- tbl(rc_conn, "redcap_projects") |> collect()
  result <- DBI::dbWriteTable(rc_billing_conn, "redcap_projects_history", redcap_projects_source)
  DBI::dbExecute(rc_billing_conn, "truncate redcap_projects_history")
}

system.time({
  project_life_cycle <- get_project_life_cycle(rc_conn)
})

sql_statements_to_replay <-
  project_life_cycle |>
  filter(str_detect(sql_log, "^update redcap_projects")) |>
  filter(!str_detect(sql_log, "^delete")) |>
  filter(!str_detect(description, "report")) |>
  filter(project_id != 0) |>
  select(log_event_id, project_id, description, sql_log) |>
  mutate(sql_log = str_replace(sql_log, "^update redcap_projects ", "update redcap_projects_history "))

max_project_id <- sql_statements_to_replay |>
  summarize(max_project_id = max(project_id)) |>
  pull(max_project_id)

initial_projects <- tibble(
  project_id = 1:max_project_id
)

result <- DBI::dbWriteTable(
  rc_billing_conn,
  "redcap_projects_history",
  initial_projects,
  append = TRUE
)

execution_results <- sql_statements_to_replay$sql_log |>
  map_lgl(~ {
    tryCatch(
      {
        DBI::dbExecute(rc_billing_conn, .x)
        TRUE
      },
      error = function(e) {
        FALSE
      }
    )
  })

successful_statements <- sum(execution_results)
failed_statements <- sum(!execution_results)

DBI::dbExecute(rc_billing_conn, "UPDATE redcap_projects_history h
JOIN redcap_projects p USING(project_id)
SET h.creation_time = p.creation_time
WHERE h.creation_time IS NULL")

activity_log <- list(
  statements_executed = successful_statements,
  statements_failed = failed_statements,
  total_statements = nrow(sql_statements_to_replay),
  max_project_id = max_project_id
)

log_job_success(jsonlite::toJSON(activity_log, auto_unbox = TRUE, pretty = TRUE))
