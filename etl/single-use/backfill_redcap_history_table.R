library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(dotenv)
library(jsonlite)
library(lubridate)

init_etl("backfill_redcap_history_table")

rc_conn <- connect_to_redcap_db()
rc_billing_conn <- connect_to_rcc_billing_db()

NA_POSIXct_ <- as.POSIXct(NA)

creation_data_from_redcap_projects <- dplyr::tbl(rc_conn, "redcap_projects") |>
  dplyr::select(project_id, creation_time) |>
  dplyr::collect() |>
  dplyr::mutate(creation_time = lubridate::as_datetime(creation_time))

redcap_projects_history_current <- dplyr::tbl(rc_billing_conn, "redcap_projects_history") |>
  dplyr::collect()

convert_df_datetimes <- function(df, cols_to_convert, tz = "UTC") {
  if (nrow(df) == 0) {
    for (col_name in cols_to_convert) {
      if (!col_name %in% names(df)) {
        df[[col_name]] <- as.POSIXct(character(0), tz = tz)
      } else if (!inherits(df[[col_name]], "POSIXct")) {
        df[[col_name]] <- as.POSIXct(df[[col_name]], tz = tz)
      }
    }
    return(df)
  }
  df |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::any_of(cols_to_convert),
        ~ lubridate::as_datetime(.x, tz = tz)
      )
    )
}

cols_to_convert <- creation_data_from_redcap_projects |>
  dplyr::select(where(~ lubridate::is.POSIXt(.x))) |>
  colnames()

creation_data_from_redcap_projects <- creation_data_from_redcap_projects |>
  convert_df_datetimes(cols_to_convert)

redcap_projects_history <- redcap_projects_history_current |>
  convert_df_datetimes(cols_to_convert)

project_life_cycle <- get_project_life_cycle(rc_conn)

creation_and_deletion_facts <- project_life_cycle |>
  select(project_id, ts, description) |>
  group_by(project_id) |>
  mutate(field_name = case_when(
    str_detect(description, "^Create project") ~ "creation_time",
    str_detect(description, "^Copy project from") ~ "creation_time",
    str_detect(description, "^Copy project$") ~ "creation_time",
    str_detect(description, "^(D|d)elete project$") ~ "date_deleted"
  )) |>
  ungroup() |>
  mutate(description = if_else(str_detect(description, "^delete project$"), "Delete project", description)) |>
  arrange(desc(ts)) |>
  distinct(project_id, description, .keep_all = TRUE) |>
  filter(!is.na(field_name)) |>
  mutate(value = ymd_hms(ts)) |>
  select(-ts) |>
  pivot_wider(
    id_cols = "project_id",
    names_from = "field_name",
    values_from = "value"
  ) |>
  left_join(creation_data_from_redcap_projects, by = "project_id", suffix = c(".log", ".live")) |>
  mutate(
    creation_time = coalesce(creation_time.live, creation_time.log)
  ) |>
  arrange(project_id) |>
  fill(creation_time, .direction = "downup") |>
  select(project_id, creation_time, date_deleted)

sync_summary <- redcapcustodian::sync_table_2(
  conn = rc_billing_conn,
  table_name = "redcap_projects_history",
  source = creation_and_deletion_facts,
  source_pk = "project_id",
  target = redcap_projects_history,
  target_pk = "project_id",
  insert = TRUE,
  update = TRUE,
  delete = FALSE
)

activity_log <- list(
  inserts = sync_summary$insert_n,
  updates = sync_summary$update_n,
  records_inserted = sync_summary$insert_records,
  records_updated = sync_summary$update_records
)

log_job_success(jsonlite::toJSON(activity_log, auto_unbox = TRUE, pretty = TRUE))
