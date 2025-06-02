library(DBI)
library(redcapcustodian)
library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(tidyverse)
library(dotenv)

init_etl("sync_redcap_projects_to_history")

rc_conn <- connect_to_redcap_db()
rc_billing_conn <- connect_to_rcc_billing_db()

# create the target table and load it with data if it does not exist
if (!"redcap_projects_history" %in% DBI::dbListTables(rc_billing_conn)) {
  redcap_projects_source <- tbl(rc_conn, "redcap_projects") |> collect()
  result <- DBI::dbWriteTable(rc_billing_conn, "redcap_projects_history", redcap_projects_source)
}

redcap_projects_history <- tbl(rc_billing_conn, "redcap_projects_history") |> collect()

# Ensure redcap_projects_source does not have any columns not already in redcap_projects_history
# This protects us from the more common alterations to redcap_projects
redcap_projects_source <- tbl(rc_conn, "redcap_projects") |>
  collect() |>
  select(any_of(names(redcap_projects_history)))

# If there is novel data in the source, sync the data
novel_data <- all.equal(
  redcap_projects_source,
  redcap_projects_history |>
    filter(project_id %in% redcap_projects_source$project_id)
)
novel_data <- if_else(length(novel_data) > 1, T, F)

if (novel_data) {
  # sync the data
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

  # log the work
  summary_data <- list(
    updates = sync_activity_results$update_n,
    inserts = sync_activity_results$insert_n,
    records_updated = sync_activity_results$update_records,
    records_inserted = sync_activity_results$insert_records,
    records_deleted = sync_activity_results$delete_records
  )

  log_job_success(jsonlite::toJSON(summary_data))
}
