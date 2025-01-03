#' get_orphaned_projects
#'
#' Return a dataframe of projects that have been orphaned
#'
#' @param rc_conn - a connection to a redcap database, \code{\link[redcapcustodian]{connect_to_redcap_db}}
#' @param rcc_billing_conn - a connection to an rcc_billing database, \code{\link{connect_to_rcc_billing_db}}
#' @param months_previous - the nth month previous to today to consider
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
  redcap_projects <- dplyr::tbl(rc_conn, "redcap_projects")
  redcap_record_counts <- dplyr::tbl(rc_conn, "redcap_record_counts")
  project_ownership <- dplyr::tbl(rc_conn, "redcap_entity_project_ownership")

  banned_owners_table <- dplyr::tbl(rcc_billing_conn, "banned_owners") |> dplyr::collect()

  project_ownership_billable_not_sequestered <-
    project_ownership |>
    # is billable
    dplyr::filter(.data$billable == 1 &
      # ...but is not sequestered
      (is.na(.data$sequestered) | .data$sequestered == 0))

  target_projects <-
    redcap_projects |>
    dplyr::collect() |>
    dplyr::filter(
      # project is not deleted
      is.na(.data$date_deleted) &
        # project at least 1 year old
        .data$creation_time <= lubridate::add_with_rollback(lubridate::ceiling_date(redcapcustodian::get_script_run_time(), unit = "month"), -months(11)) &
        # project has an anniversary months_previous months ago
        rcc.billing::previous_n_months(lubridate::month(redcapcustodian::get_script_run_time()), months_previous) == lubridate::month(.data$creation_time)
    ) |>
    dplyr::inner_join(project_ownership_billable_not_sequestered |> dplyr::collect(), by = c("project_id" = "pid")) |>
    dplyr::left_join(redcap_record_counts |> dplyr::collect(), by = "project_id")

  # empty and inactive projects
  empty_and_inactive_projects <- target_projects |>
    # the record count was recorded after the last update
    dplyr::filter(.data$time_of_count > .data$last_logged_event + lubridate::days(1) |
      is.na(.data$last_logged_event)) |>
    # no records saved
    dplyr::filter(.data$record_count == 0) |>
    # no activity in a year
    dplyr::filter(.data$last_logged_event <= redcapcustodian::get_script_run_time() - months(11) |
      is.na(.data$last_logged_event)) |>
    dplyr::mutate(
      reason = "empty_and_inactive",
      priority = 3
    )

  ## Enumerate each user on the project that has any permission ever
  redcap_user_rights <- dplyr::tbl(rc_conn, "redcap_user_rights") |>
    dplyr::filter(.data$project_id %in% local(target_projects$project_id)) |>
    dplyr::collect()
  redcap_user_roles <- dplyr::tbl(rc_conn, "redcap_user_roles") |>
    dplyr::filter(.data$project_id %in% local(target_projects$project_id)) |>
    dplyr::collect()
  redcap_user_information <- dplyr::tbl(rc_conn, "redcap_user_information") |>
    dplyr::collect()
  user_info <- get_user_rights_and_info_v1(
    redcap_user_rights = redcap_user_rights,
    redcap_user_roles = redcap_user_roles,
    redcap_user_information = redcap_user_information
  )

  pids_of_project_with_viable_permissions <- user_info |>
    dplyr::filter(.data$user_lastlogin >= redcapcustodian::get_script_run_time() - months(11)) |>
    dplyr::filter(.data$expiration > redcapcustodian::get_script_run_time() | is.na(.data$expiration)) |>
    dplyr::distinct(.data$project_id) |>
    dplyr::pull(.data$project_id)

  empty_and_inactive_projects_with_no_viable_users <- empty_and_inactive_projects |>
    dplyr::filter(!.data$project_id %in% pids_of_project_with_viable_permissions) |>
    dplyr::mutate(
      reason = "empty_and_inactive_with_no_viable_users",
      priority = 1
    )

  # Inactive projects with no viable users
  inactive_projects_with_no_viable_users <- target_projects |>
    dplyr::filter(!.data$project_id %in% pids_of_project_with_viable_permissions) |>
    # the record count was recorded after the last update
    dplyr::filter(.data$time_of_count > .data$last_logged_event + lubridate::days(1) |
      is.na(.data$last_logged_event)) |>
    # no records saved
    dplyr::filter(.data$last_logged_event <= redcapcustodian::get_script_run_time() - months(11) |
      is.na(.data$last_logged_event)) |>
    dplyr::mutate(
      reason = "inactive_with_no_viable_users",
      priority = 2
    )

  # complete but non sequestered projects
  complete_but_non_sequestered <-
    redcap_projects |>
    # project is not deleted
    dplyr::filter(is.na(.data$date_deleted) &
      # project is marked as completed, ...
      !is.na(.data$completed_time)) |>
    dplyr::inner_join(project_ownership_billable_not_sequestered, by = c("project_id" = "pid")) |>
    dplyr::left_join(redcap_record_counts, by = "project_id") |>
    dplyr::collect() |>
    dplyr::mutate(
      reason = "complete_but_non_sequestered",
      priority = 4
    )

  banned_owners <-
    target_projects |>
    dplyr::filter(
      (!is.na(.data$email) & (.data$email %in% banned_owners_table$email)) |
        (!is.na(.data$username) & (.data$username %in% banned_owners_table$username))
    ) |>
    dplyr::collect() |>
    dplyr::mutate(
      reason = "banned_owner",
      priority = 5
    )

  unresolvable_ownership_issues <-
    redcap_projects |>
    # project is not deleted
    dplyr::filter(is.na(.data$date_deleted)) |>
    # NOTE: filtering for billable before the join operation is called is significantly faster (<1s vs >30s)
    dplyr::left_join(project_ownership |> dplyr::filter(!is.na(.data$billable) & .data$billable == 1), by = c("project_id" = "pid")) |>
    # HACK: NA billable is not filtered in above statement so do it here
    dplyr::filter(!is.na(.data$billable) & .data$billable == 1) |>
    ## the project is not sequestered
    dplyr::filter(is.na(.data$sequestered) | .data$sequestered == 0) |>
    ## fields email, firstname, lastname, username are NA
    dplyr::filter(
      is.na(.data$email) &
        is.na(.data$firstname) &
        is.na(.data$lastname) &
        is.na(.data$username)
    ) |>
    ## the updated in the project ownership table greater than 90ish days old.
    # NOTE: this fails if is.na(updated)
    ## filter(updated - lubridate::ddays(90) <= get_script_run_time()) |>
    dplyr::collect() |>
    dplyr::mutate(
      reason = "unresolvable_ownership_issues",
      priority = 6
    )

  orphaned_projects <- dplyr::bind_rows(
    empty_and_inactive_projects_with_no_viable_users,
    inactive_projects_with_no_viable_users,
    empty_and_inactive_projects,
    complete_but_non_sequestered,
    banned_owners,
    unresolvable_ownership_issues
  ) |>
    dplyr::arrange(.data$priority) |>
    dplyr::distinct(.data$project_id, .keep_all = T) |>
    dplyr::select(
      "project_id",
      "reason",
      "priority"
    )

  return(orphaned_projects)
}
