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

# create a target table if it does not exist.
if (!"redcap_projects_history" %in% DBI::dbListTables(rc_billing_conn)) {
  create_redcap_projects_history <-
    DBI::dbGetQuery(rc_conn, "SHOW CREATE TABLE redcap_projects") |>
    janitor::clean_names() |>
    # rename the table
    mutate(create_table = str_replace(create_table, "`redcap_projects`", "`redcap_projects_history`")) |>
    # remove all constraints because we are not creating any of the referenced tables
    mutate(create_table = str_replace_all(create_table, ",\n  CONSTRAINT [^,]+ CASCADE", "")) |>
    pull(create_table)
  DBI::dbExecute(rc_billing_conn, create_redcap_projects_history)
}

elapsed_run_time_of_get_project_life_cycle <- system.time({
  project_life_cycle <- get_project_life_cycle(rc_conn)
})
elapsed_run_time_of_get_project_life_cycle

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

elapsed_run_time_of_replay <- system.time({
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
})
elapsed_run_time_of_replay

successful_statements <- sum(execution_results)
failed_statements <- sum(!execution_results)

# Sync the current redcap_projects table to the new history table
redcap_projects_history <- tbl(rc_billing_conn, "redcap_projects_history") |> collect()

# Ensure redcap_projects_source does not have any columns not already in redcap_projects_history
# This protects us from the more common alterations to redcap_projects
redcap_projects_source <- tbl(rc_conn, "redcap_projects") |>
  collect() |>
  select(any_of(names(redcap_projects_history)))

# sync the data
elapsed_run_time_of_rp_sync <- system.time({
  sync_activity_results <- redcapcustodian::sync_table_2(
    conn = rc_billing_conn,
    table_name = "redcap_projects_history",
    source = redcap_projects_source,
    source_pk = "project_id",
    target = redcap_projects_history,
    target_pk = "project_id",
    insert = T,
    update = T,
    delete = F
  )
})
elapsed_run_time_of_rp_sync

# log the work
rp_summary_data <- list(
  rp_updates = sync_activity_results$update_n,
  rp_inserts = sync_activity_results$insert_n,
  rp_records_updated = sync_activity_results$update_records,
  rp_records_inserted = sync_activity_results$insert_records,
  rp_records_deleted = sync_activity_results$delete_records
)

# fill the blank creation dates via interpolation
redcap_projects_history <- tbl(rc_billing_conn, "redcap_projects_history") |> collect()

first_record_with_non_na_creation_time <-
  redcap_projects_history |>
    filter(!is.na(creation_time)) |>
    filter(project_id == min(project_id)) |>
    pull(project_id)

interpolated_creation_dates <- redcap_projects_history |>
  filter(project_id >= first_record_with_non_na_creation_time) |>
  mutate(creation_time = as.POSIXct(zoo::na.approx(creation_time), tz="UTC")) |>
  select("project_id", "creation_time")

elapsed_run_time_of_ct_sync <- system.time({
  creation_time_sync_results <- redcapcustodian::sync_table_2(
    conn = rc_billing_conn,
    table_name = "redcap_projects_history",
    source = interpolated_creation_dates,
    source_pk = "project_id",
    target = redcap_projects_history |> select("project_id", "creation_time"),
    target_pk = "project_id",
    insert = F,
    update = T,
    delete = F
  )
})
elapsed_run_time_of_ct_sync

ct_summary_data <- list(
  ct_updates = creation_time_sync_results$update_n,
  ct_inserts = creation_time_sync_results$insert_n,
  ct_records_updated = creation_time_sync_results$update_records
)

activity_log <- list(
  statements_executed = successful_statements,
  statements_failed = failed_statements,
  total_statements = nrow(sql_statements_to_replay),
  max_project_id = max_project_id
)

log_job_success(jsonlite::toJSON(activity_log, auto_unbox = TRUE, pretty = TRUE))
# rp_summary is too long to write, so skip it
# log_job_success(jsonlite::toJSON(rp_summary_data, auto_unbox = TRUE, pretty = TRUE))
log_job_success(jsonlite::toJSON(ct_summary_data, auto_unbox = TRUE, pretty = TRUE))
