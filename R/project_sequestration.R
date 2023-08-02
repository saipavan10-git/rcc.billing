#' sequester_projects
#'
#' sequester projects listed in `project_ids` that can be sequestered
#'
#' @param conn - a connection to a redcap database
#' @param project_id - a vector of project IDs to be sequestered
#' @param reason - a vector of reasons the project IDs were sequestered
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
    projects_to_sequester <- tibble(project_id, reason)
  }

  project_ownership <- dplyr::tbl(conn, "redcap_entity_project_ownership")
  projects <- dplyr::tbl(conn, "redcap_projects") %>%
    dplyr::filter(is.na(.data$date_deleted)) %>%
    dplyr::select(
      "project_id",
      "completed_time",
      "completed_by",
      "log_event_table"
    ) %>%
    dplyr::filter(.data$project_id %in% !!projects_to_sequester$project_id)

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
    dplyr::rename(pid = "project_id") %>%
    dplyr::select(
      "id",
      "updated",
      "pid",
      "sequestered"
    )

  project_ownership_update <- project_ownership_state %>%
    dplyr::mutate(sequestered = as.integer(1)) %>%
    dplyr::mutate(updated = as.integer(redcapcustodian::get_script_run_time()))

  redcap_projects_state <- project_state %>%
    dplyr::select(
      "project_id",
      "completed_time",
      "completed_by",
      "log_event_table",
      "moved_from_completed_status_events"
    )

  redcap_projects_update <- redcap_projects_state %>%
    left_join(projects_to_sequester, by = "project_id") %>%
    dplyr::mutate(
      completed_time = redcapcustodian::get_script_run_time(),
      completed_by = paste(
        "Sequestered by",
        redcapcustodian::get_script_name(),
        "with a reason of ",
        reason,
        "- Previously sequestered",
        .data$moved_from_completed_status_events,
        "times"
      )
    ) %>%
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
#' @param rc_conn - a connection to a redcap database, \code{\link{connect_to_redcap_db}}
#' @param rcc_billing_conn - a connection to an rcc_billing database, \code{\link{connect_to_rcc_billing_db}}
#' @param months_previous - the nth month previous to today to consider
#' @importFrom dplyr %>% arrange  bind_rows collect distinct filter inner_join left_join mutate pull select tbl
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
#'   rc_conn = rc_conn,
#'   rcc_billing_conn = rcc_billing_conn,
#'   months_previous = 0
#' )
#' }
get_orphaned_projects <- function(rc_conn, rcc_billing_conn, months_previous = 0) {
  redcap_projects <- tbl(rc_conn, "redcap_projects")
  redcap_record_counts <- tbl(rc_conn, "redcap_record_counts")
  project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership")

  banned_owners_table <- tbl(rcc_billing_conn, "banned_owners") %>% collect()

  project_ownership_billable_not_sequestered <-
    project_ownership %>%
    # is billable
    filter(.data$billable == 1 &
      # ...but is not sequestered
      (is.na(.data$sequestered) | .data$sequestered == 0))

  target_projects <-
    redcap_projects %>%
    filter(
      # project is not deleted
      is.na(.data$date_deleted) &
        # project at least 1 year old
        .data$creation_time <= local(add_with_rollback(ceiling_date(get_script_run_time(), unit = "month"), -months(11))) &
        # project has an anniversary months_previous months ago
        rcc.billing::previous_n_months(month(get_script_run_time()), months_previous) == month(.data$creation_time)
    ) %>%
    inner_join(project_ownership_billable_not_sequestered, by = c("project_id" = "pid")) %>%
    left_join(redcap_record_counts, by = "project_id") %>%
    collect()

  # empty and inactive projects
  empty_and_inactive_projects <- target_projects %>%
    # the record count was recorded after the last update
    filter(.data$time_of_count > .data$last_logged_event + days(1) |
      is.na(.data$last_logged_event)) %>%
    # no records saved
    filter(.data$record_count == 0) %>%
    # no activity in a year
    filter(.data$last_logged_event <= get_script_run_time() - months(11) |
      is.na(.data$last_logged_event)) %>%
    mutate(
      reason = "empty_and_inactive",
      priority = 3
    )

  ## Enumerate each user on the project that has any permission ever
  redcap_user_rights <- tbl(rc_conn, "redcap_user_rights") %>%
    filter(.data$project_id %in% local(target_projects$project_id)) %>%
    collect()
  redcap_user_roles <- tbl(rc_conn, "redcap_user_roles") %>%
    filter(.data$project_id %in% local(target_projects$project_id)) %>%
    collect()
  redcap_user_information <- tbl(rc_conn, "redcap_user_information") %>%
    collect()
  user_info <- get_user_rights_and_info(
    redcap_user_rights = redcap_user_rights,
    redcap_user_roles = redcap_user_roles,
    redcap_user_information = redcap_user_information
  )

  pids_of_project_with_viable_permissions <- user_info %>%
    filter(.data$user_lastlogin >= get_script_run_time() - months(11)) %>%
    filter(.data$expiration > get_script_run_time() | is.na(.data$expiration)) %>%
    distinct(.data$project_id) %>%
    pull(.data$project_id)

  empty_and_inactive_projects_with_no_viable_users <- empty_and_inactive_projects %>%
    filter(!.data$project_id %in% pids_of_project_with_viable_permissions) %>%
    mutate(
      reason = "empty_and_inactive_with_no_viable_users",
      priority = 1
    )

  # Inactive projects with no viable users
  inactive_projects_with_no_viable_users <- target_projects %>%
    filter(!.data$project_id %in% pids_of_project_with_viable_permissions) %>%
    # the record count was recorded after the last update
    filter(.data$time_of_count > .data$last_logged_event + days(1) |
      is.na(.data$last_logged_event)) %>%
    # no records saved
    filter(.data$last_logged_event <= get_script_run_time() - months(11) |
      is.na(.data$last_logged_event)) %>%
    mutate(
      reason = "inactive_with_no_viable_users",
      priority = 2
    )

  # complete but non sequestered projects
  complete_but_non_sequestered <-
    redcap_projects %>%
    # project is not deleted
    filter(is.na(.data$date_deleted) &
      # project is marked as completed, ...
      !is.na(.data$completed_time)) %>%
    inner_join(project_ownership_billable_not_sequestered, by = c("project_id" = "pid")) %>%
    left_join(redcap_record_counts, by = "project_id") %>%
    collect() %>%
    mutate(
      reason = "complete_but_non_sequestered",
      priority = 4
    )

  banned_owners <-
    target_projects %>%
    filter(
      (!is.na(.data$email) & (.data$email %in% banned_owners_table$email)) |
        (!is.na(.data$username) & (.data$username %in% banned_owners_table$username))
    ) %>%
    collect() %>%
    mutate(
      reason = "banned_owner",
      priority = 5
    )

  unresolvable_ownership_issues <-
    redcap_projects %>%
    # project is not deleted
    filter(is.na(.data$date_deleted)) %>%
    # NOTE: filtering for billable before the join operation is called is significantly faster (<1s vs >30s)
    left_join(project_ownership %>% filter(!is.na(.data$billable) & .data$billable == 1), by = c("project_id" = "pid")) %>%
    # HACK: NA billable is not filtered in above statement so do it here
    filter(!is.na(.data$billable) & .data$billable == 1) %>%
    ## the project is not sequestered
    filter(is.na(.data$sequestered) | .data$sequestered == 0) %>%
    ## fields email, firstname, lastname, username are NA
    filter(
      is.na(.data$email) &
        is.na(.data$firstname) &
        is.na(.data$lastname) &
        is.na(.data$username)
    ) %>%
    ## the updated in the project ownership table greater than 90ish days old.
    # NOTE: this fails if is.na(updated)
    ## filter(updated - lubridate::ddays(90) <= get_script_run_time()) %>%
    collect() %>%
    mutate(
      reason = "unresolvable_ownership_issues",
      priority = 6
    )

  orphaned_projects <- bind_rows(
    empty_and_inactive_projects_with_no_viable_users,
    inactive_projects_with_no_viable_users,
    empty_and_inactive_projects,
    complete_but_non_sequestered,
    banned_owners,
    unresolvable_ownership_issues
  ) %>%
    arrange(.data$priority) %>%
    distinct(.data$project_id, .keep_all = T) %>%
    select(
      "project_id",
      "reason",
      "priority"
    )

  return(orphaned_projects)
}
