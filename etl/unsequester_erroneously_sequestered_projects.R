library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)
library(rcc.billing)

init_etl("unsequester_erroneously_sequestered_projects")

rcc_billing_conn <- connect_to_rcc_billing_db()
rc_conn <- connect_to_redcap_db()

redcap_projects <- dplyr::tbl(rc_conn, "redcap_projects") |>
  collect()

project_details <- get_project_details_for_billing(
  rc_conn,
  rcc_billing_conn,
  redcap_projects$project_id
)

wrongly_sequestered_projects <- project_details |>
  dplyr::filter(sequestered == 1) |>
  dplyr::left_join(redcap_projects, by = "project_id") |>
  dplyr::filter(is.na(completed_time)) |>
  dplyr::filter(is.na(date_deleted)) |>
  dplyr::select(
    project_id,
    app_title.x,
    billable,
    sequestered,
    creation_time.x,
    date_deleted
  )

rcepo_original <- dplyr::tbl(rc_conn, "redcap_entity_project_ownership") |>
  dplyr::filter(pid %in% wrongly_sequestered_projects$project_id) |>
  dplyr::select(
    id,
    updated,
    sequestered
  ) |>
  dplyr::collect()

rcepo_updates <- rcepo_original |>
  dplyr::mutate(
    sequestered = 0,
    updated = as.numeric(now())
  )

if (nrow(rcepo_updates) > 0) {
  result <- redcapcustodian::sync_table_2(
    conn = rc_conn,
    table_name = "redcap_entity_project_ownership",
    source = rcepo_updates,
    source_pk = "id",
    target = rcepo_original,
    target_pk = "id",
    update = T,
    delete = F,
    insert = F
  )

  # log what we did
  activity_log <- list(
    redcap_entity_project_ownership_updates = result$update_records
  )

  log_job_success(jsonlite::toJSON(activity_log))
}

DBI::dbDisconnect(rcc_billing_conn)
DBI::dbDisconnect(rc_conn)
