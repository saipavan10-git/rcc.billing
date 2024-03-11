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
