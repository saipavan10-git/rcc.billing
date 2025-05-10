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

redcap_projects_source <- tbl(rc_conn, "redcap_projects") |> collect()
redcap_projects_history <- tbl(rc_billing_conn, "redcap_projects_history") |> collect()

# find all <datetime<UTC>>
dt_columns <- redcap_projects_source |>
  dplyr::select(where(~ lubridate::is.POSIXt(.x))) |>
  colnames()

convert_df_datetimes <- function(df, cols_to_convert) {
  if (nrow(df) == 0) {
    for (col_name in cols_to_convert) {
      if (!col_name %in% names(df)) { df[[col_name]] <- as.POSIXct(character(0)) }
      else if (!inherits(df[[col_name]], "POSIXct")) { df[[col_name]] <- as.POSIXct(character(0)) }
    }
    return(df)
  }
  df |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::any_of(cols_to_convert),
        ~ lubridate::as_datetime(.x)
      )
    )
}

redcap_projects_source_typed <- convert_df_datetimes(redcap_projects_source, dt_columns)
redcap_projects_history_typed <- convert_df_datetimes(redcap_projects_history, dt_columns)

sync_activity_results <- redcapcustodian::sync_table_2(
  conn = rc_billing_conn,
  table_name = "redcap_projects_history",
  source = redcap_projects_source_typed,
  source_pk = "project_id",
  target = redcap_projects_history_typed,
  target_pk = "project_id",
  insert = T,
  update = T,
  delete = F
)

summary_data <- list(
  updates = sync_activity_results$update_n,
  inserts = sync_activity_results$insert_n,
  records_updated = sync_activity_results$update_records,
  records_inserted = sync_activity_results$insert_records,
  records_deleted = sync_activity_results$delete_records
)

log_job_success(jsonlite::toJSON(summary_data))
