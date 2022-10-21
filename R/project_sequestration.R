#' sequester_projects
#'
#' sequester projects listed in `project_ids` that can be sequestered
#'
#' @param conn - a connection to a redcap database
#' @param project_ids - a vector of project IDs to be sequestered
#'
#' @importFrom magrittr "%>%"
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
#'   project_ids = project_ids_to_sequester
#' }
sequester_projects <- function(conn,
                               project_ids = as.numeric(NA)) {
  # exit if there is nothing to do
  if (length(project_ids) == 1 && is.na(project_ids)) {
    result <- list(project_ids_updated = as.numeric(NA))
    return(result)
  }

  project_ownership <- dplyr::tbl(conn, "redcap_entity_project_ownership")
  projects <- dplyr::tbl(conn, "redcap_projects") %>%
    dplyr::filter(is.na(.data$date_deleted)) %>%
    dplyr::select(
      .data$project_id,
      .data$completed_time,
      .data$completed_by,
      .data$log_event_table
    ) %>%
    dplyr::filter(.data$project_id %in% project_ids)

  partial_project_state <- projects %>%
    dplyr::inner_join(project_ownership, by = c("project_id" = "pid")) %>%
    dplyr::collect() %>%
    dplyr::mutate(completed_time = as.POSIXct(.data$completed_time, tz = Sys.getenv("TIME_ZONE"))) %>%
    dplyr::filter(is.na(.data$completed_time) | is.na(.data$sequestered) | .data$sequestered == 0)

  if(nrow(partial_project_state) == 0) {
    result <- list(project_ids_updated = as.numeric(NA))
    return(result)
  }

  log_event_tables_to_query <- partial_project_state %>%
    dplyr::distinct(.data$log_event_table) %>%
    dplyr::pull()

  log_event_query <- function(conn,
                              project_ids,
                              log_event_table = "redcap_log_event") {
    result <- dplyr::tbl(conn, log_event_table) %>%
      dplyr::filter(.data$project_id %in% project_ids) %>%
      dplyr::filter(.data$event == "MANAGE") %>%
      dplyr::filter(.data$page == "ProjectGeneral/change_project_status.php") %>%
      dplyr::collect() %>%
      dplyr::filter(stringr::str_detect(.data$description, "Project moved from Completed status back to"))

    return(result)
  }

  moved_from_completed <- data.frame()
  for (log_table in log_event_tables_to_query) {
    log_query_result <- log_event_query(
      conn = conn,
      project_ids = partial_project_state %>%
        dplyr::filter(.data$log_event_table == log_table) %>%
        dplyr::pull(.data$project_id),
      log_event_table = log_table
    )
    moved_from_completed <- dplyr::bind_rows(moved_from_completed, log_query_result)
  }

  # moved_from_completed <- purrr::map_dfr(log_event_tables_to_query,
  #                log_event_query,
  #                conn = conn,
  #                project_ids = project_ids)

  moved_from_completed_counts <- moved_from_completed %>%
    dplyr::mutate(ts = lubridate::ymd_hms(.data$ts)) %>%
    dplyr::filter(redcapcustodian::get_script_run_time() - .data$ts < lubridate::days(90)) %>%
    dplyr::count(.data$project_id, name = "moved_from_completed_status_events")

  project_state <- partial_project_state %>%
    dplyr::left_join(moved_from_completed_counts, by = "project_id") %>%
    dplyr::mutate(moved_from_completed_status_events = dplyr::if_else(
      is.na(.data$moved_from_completed_status_events),
      as.integer(0),
      .data$moved_from_completed_status_events
    ))

  # prepare dataframes for update
  project_ownership_state <- project_state %>%
    dplyr::rename(pid = .data$project_id) %>%
    dplyr::select(
      .data$id,
      .data$updated,
      .data$pid,
      .data$sequestered
    )

  project_ownership_update <- project_ownership_state %>%
    dplyr::mutate(sequestered = as.integer(1)) %>%
    dplyr::mutate(updated = as.integer(redcapcustodian::get_script_run_time()))

  redcap_projects_state <- project_state %>%
    dplyr::select(
      .data$project_id,
      .data$completed_time,
      .data$completed_by,
      .data$log_event_table,
      .data$moved_from_completed_status_events
    )

  redcap_projects_update <- redcap_projects_state %>%
    dplyr::mutate(
      completed_time = redcapcustodian::get_script_run_time(),
      completed_by = paste(
        "Sequestered by",
        redcapcustodian::get_script_name(),
        "- Previously sequestered",
        .data$moved_from_completed_status_events,
        "times"
      )
    ) %>%
    dplyr::select(
      .data$project_id,
      .data$completed_time,
      .data$completed_by
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
  ) %>% unique()

  # return actions in a form suitable for logging
  result = list(
    project_ownership_sync_updates = project_ownership_sync_result$update_records,
    redcap_projects_sync_updates = redcap_projects_sync_result$update_records,
    project_ids_updated = project_ids_updated
  )

  return(result)
}

#' get_orphaned_projects
#'
#' Return a dataframe of projects that have been orphaned
#'
#' @param conn - a connection to a redcap database
#' @param months_previous - the nth month previous today to consider
#' @importFrom dplyr %>% arrange  bind_rows collect distinct filter inner_join left_join mutate select tbl
#' @importFrom lubridate add_with_rollback ceiling_date days month years
#' @importFrom redcapcustodian get_script_run_time
#'
#' @return a dataframe describing orphaned projects
#' \itemize{
#'   \item project_id - project_id of the orphaned project
#'   \item reason - why this project was selected
#'   \item priority - the priority of the reason
#' }
#' @export
#'
#' @examples
#' \dontrun{
#' get_orphaned_projects(
#'   conn = rc_conn,
#'   months_previous = 0
#' )
#' }
get_orphaned_projects <- function(conn, months_previous = 0) {
  redcap_projects <- tbl(conn, "redcap_projects")
  redcap_record_counts <- tbl(conn, "redcap_record_counts")
  project_ownership <- tbl(conn, "redcap_entity_project_ownership")

  target_projects <-
    redcap_projects %>%
    # project is not deleted
    filter(is.na(.data$date_deleted)) %>%
    # project at least 1 year old
    filter(.data$creation_time <= local(add_with_rollback(ceiling_date(get_script_run_time(), unit = "month"), -years(1)))) %>%
    # project has an anniversary months_previous months ago
    filter(rcc.billing::previous_n_months(month(get_script_run_time()), months_previous) == month(.data$creation_time)) %>%
    left_join(project_ownership, by = c("project_id" = "pid")) %>%
    filter(.data$billable == 1) %>%
    filter(is.na(.data$sequestered) | .data$sequestered == 0) %>%
    left_join(redcap_record_counts, by = "project_id") %>%
    collect() %>%
    # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
    mutate_columns_to_posixct("creation_time")

  # empty and inactive projects
  empty_and_inactive_projects <- target_projects %>%
    # the record count was recorded after the last update
    filter(.data$time_of_count > .data$last_logged_event + days(1)) %>%
    # no records saved
    filter(.data$record_count == 0) %>%
    # no activity in a year
    filter(.data$last_logged_event <= get_script_run_time() - years(1)) %>%
    mutate(
      reason = "empty_and_inactive",
      priority = 1
    )

  ## Enumerate each user on the project that has any permission ever
  redcap_user_rights = tbl(conn, "redcap_user_rights") %>%
    filter(project_id %in% local(empty_and_inactive_projects$project_id)) %>%
    collect()
  redcap_user_roles = tbl(conn, "redcap_user_roles") %>%
    filter(project_id %in% local(empty_and_inactive_projects$project_id)) %>%
    collect()
  redcap_user_information = tbl(conn, "redcap_user_information") %>%
    collect()
  user_info <- get_user_rights_and_info(
    redcap_user_rights = redcap_user_rights,
    redcap_user_roles = redcap_user_roles,
    redcap_user_information = redcap_user_information
  )

  pids_of_project_with_viable_permissions <- user_info %>%
    filter(is.na(.data$user_suspended_time)) %>%
    filter(expiration > get_script_run_time() | is.na(expiration)) %>%
    distinct(project_id) %>%
    pull(project_id)

  empty_and_inactive_projects_with_no_viable_users <- empty_and_inactive_projects %>%
    filter(!.data$project_id %in% pids_of_project_with_viable_permissions)

  orphaned_projects <- bind_rows(
    empty_and_inactive_projects_with_no_viable_users
  ) %>%
    arrange(.data$priority) %>%
    distinct(.data$project_id, .keep_all = T) %>%
  select(
    .data$project_id,
    .data$reason,
    .data$priority
  )

  return(orphaned_projects)
}
