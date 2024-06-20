#' sequester_projects
#'
#' sequester projects listed in `project_ids` that can be sequestered
#'
#' @param conn - a connection to a redcap database
#' @param project_id - a vector of project IDs to be sequestered
#' @param reason - a vector of reasons the project IDs were sequestered
#'
#' @return - a list describing the function activity via these objects
#' \itemize{
#'   \item project_ownership_sync_updates - updates made to project_ownership
#'   \item redcap_projects_sync_updates - updates made to redcap_projects
#'   \item project_ids_updated - project ids that received updates
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' sequester_projects(
#'   conn = rc_conn,
#'   project_id = project_ids_to_sequester
#'   reason = reasons_project_ids_should_be_sequestered
#' }
sequester_projects <- function(conn,
                               project_id = as.numeric(NA),
                               reason = as.character(NA)) {
  # exit if there is nothing to do
  if (length(project_id) == 1 && is.na(project_id)) {
    result <- list(project_ids_updated = as.numeric(NA))
    return(result)
  }

  # bind project_ids to reasons if we can
  if (length(project_id) == length(reason) | length(reason) == 1) {
    projects_to_sequester <- dplyr::tibble(project_id, reason)
  }

  project_ownership <- dplyr::tbl(conn, "redcap_entity_project_ownership")
  projects <- dplyr::tbl(conn, "redcap_projects") |>
    dplyr::filter(is.na(.data$date_deleted)) |>
    dplyr::select(
      "project_id",
      "completed_time",
      "completed_by",
      "log_event_table"
    ) |>
    dplyr::filter(.data$project_id %in% !!projects_to_sequester$project_id)

  partial_project_state <- projects |>
    dplyr::inner_join(project_ownership, by = c("project_id" = "pid")) |>
    dplyr::collect() |>
    dplyr::mutate(completed_time = as.POSIXct(.data$completed_time, tz = Sys.getenv("TIME_ZONE"))) |>
    dplyr::filter(is.na(.data$completed_time) | is.na(.data$sequestered) | .data$sequestered == 0)

  if(nrow(partial_project_state) == 0) {
    result <- list(project_ids_updated = as.numeric(NA))
    return(result)
  }

  log_event_tables_to_query <- partial_project_state |>
    dplyr::distinct(.data$log_event_table) |>
    dplyr::pull()

  log_event_query <- function(conn,
                              project_ids,
                              log_event_table = "redcap_log_event") {
    result <- dplyr::tbl(conn, log_event_table) |>
      dplyr::filter(.data$project_id %in% project_ids) |>
      dplyr::filter(.data$event == "MANAGE") |>
      dplyr::filter(.data$page == "ProjectGeneral/change_project_status.php") |>
      dplyr::collect() |>
      dplyr::filter(stringr::str_detect(.data$description, "Project moved from Completed status back to"))

    return(result)
  }

  moved_from_completed <- data.frame()
  for (log_table in log_event_tables_to_query) {
    log_query_result <- log_event_query(
      conn = conn,
      project_ids = partial_project_state |>
        dplyr::filter(.data$log_event_table == log_table) |>
        dplyr::pull(.data$project_id),
      log_event_table = log_table
    )
    moved_from_completed <- dplyr::bind_rows(moved_from_completed, log_query_result)
  }

  moved_from_completed_counts <- moved_from_completed |>
    dplyr::mutate(ts = lubridate::ymd_hms(.data$ts)) |>
    dplyr::filter(redcapcustodian::get_script_run_time() - .data$ts < lubridate::days(90)) |>
    dplyr::count(.data$project_id, name = "moved_from_completed_status_events")

  project_state <- partial_project_state |>
    dplyr::left_join(moved_from_completed_counts, by = "project_id") |>
    dplyr::mutate(moved_from_completed_status_events = dplyr::if_else(
      is.na(.data$moved_from_completed_status_events),
      as.integer(0),
      .data$moved_from_completed_status_events
    ))

  # prepare dataframes for update
  project_ownership_state <- project_state |>
    dplyr::rename(pid = "project_id") |>
    dplyr::select(
      "id",
      "updated",
      "pid",
      "sequestered"
    )

  project_ownership_update <- project_ownership_state |>
    dplyr::mutate(sequestered = as.integer(1)) |>
    dplyr::mutate(updated = as.integer(redcapcustodian::get_script_run_time()))

  redcap_projects_state <- project_state |>
    dplyr::select(
      "project_id",
      "completed_time",
      "completed_by",
      "log_event_table",
      "moved_from_completed_status_events"
    )

  redcap_projects_update <- redcap_projects_state |>
    dplyr::left_join(projects_to_sequester, by = "project_id") |>
    dplyr::mutate(
      completed_time = redcapcustodian::get_script_run_time(),
      # Limit the completed_by string to 100 characters to conform to the
      # table design of the redcap_projects table
      completed_by = substring(
        paste0(
          redcapcustodian::get_script_name(),
          " says, '",
          reason,
          "'. Previously sequestered ",
          .data$moved_from_completed_status_events,
          " times"
        ), 1, 100
      )
    ) |>
    dplyr::select(
      "project_id",
      "completed_time",
      "completed_by"
    )

  # update tables
  project_ownership_sync_result <- redcapcustodian::sync_table_2(
    conn = conn,
    table_name = "redcap_entity_project_ownership",
    source = project_ownership_update,
    source_pk = "id",
    target = project_ownership_state,
    target_pk = "id"
  )

  redcap_projects_sync_result <- redcapcustodian::sync_table_2(
    conn = conn,
    table_name = "redcap_projects",
    source = redcap_projects_update,
    source_pk = "project_id",
    target = redcap_projects_state,
    target_pk = "project_id"
  )

  project_ids_updated <- c(
    project_ownership_sync_result$update_records$pid,
    redcap_projects_sync_result$update_records$project_id
  ) |> unique()

  # return actions in a form suitable for logging
  result = list(
    project_ownership_sync_updates = project_ownership_sync_result$update_records,
    redcap_projects_sync_updates = redcap_projects_sync_result$update_records,
    project_ids_updated = project_ids_updated
  )

  return(result)
}
