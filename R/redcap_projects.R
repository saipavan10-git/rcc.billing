#' get_last_project_user
#'
#' Returns the last user to log an event on a project. This function is not vectorized.
#'
#' @param con, a DBI connection object to a REDCap database
#' @param pid, the project ID of the project of interest.
#'
#' @return Username of the last user to log an actio against the project
#' @export
#' @importFrom magrittr "%>%"
#'
#' @examples
#' \dontrun{
#'   get_last_project_user(
#'     con = redcap_connection,
#'     pid = project_id
#'   )
#' }
get_last_project_user <- function(con, pid) {

  log_event_table <- dplyr::tbl(con, "redcap_projects") %>%
    dplyr::filter(.data$project_id == pid) %>%
    dplyr::pull(.data$log_event_table)

  last_user <- dplyr::tbl(con, log_event_table) %>%
    dplyr::filter(.data$project_id == pid) %>%
    dplyr::arrange(dplyr::desc(.data$ts)) %>%
    utils::head(1) %>%
    dplyr::select(.data$user) %>%
    dplyr::collect() %>%
    dplyr::pull(.data$user)

  return(last_user)
}


#' get_projects_needing_new_owners
#'
#' Returns the project IDs of projects that are owned by a REDCap user that has no primary email address
#'
#' @param redcap_entity_project_ownership, The contents of the REDCap Project Ownership table of the same name.
#' @param redcap_user_information, The contents of the REDCap table of the same name.
#'
#' @return a vector of project IDs
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' get_projects_needing_new_owners(
#'   redcap_entity_project_ownership =
#'     cleanup_project_ownership_test_data$redcap_entity_project_ownership,
#'   redcap_user_information =
#'     cleanup_project_ownership_test_data$redcap_user_information
#' )
get_projects_needing_new_owners <- function(redcap_entity_project_ownership,
                                            redcap_user_information) {
  projects_needing_new_owners <- redcap_entity_project_ownership %>%
    dplyr::left_join(redcap_user_information, by = "username") %>%
    dplyr::filter(is.na(.data$user_email)) %>%
    dplyr::pull(.data$pid)

  return(projects_needing_new_owners)
}

#' get_projects_without_owners
#'
#' Returns the project_ids of projects without owners
#'
#' @param redcap_projects, The contents of the REDCap table of the same name.
#' @param redcap_entity_project_ownership, The contents of the REDCap Project Ownership table of the same name.
#'
#' @return a vector of project IDs
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' get_projects_without_owners(
#'   redcap_projects =
#'     cleanup_project_ownership_test_data$redcap_projects,
#'   redcap_entity_project_ownership =
#'     cleanup_project_ownership_test_data$redcap_entity_project_ownership
#' )
get_projects_without_owners <- function(redcap_projects,
                                        redcap_entity_project_ownership) {
  redcap_projects %>%
    dplyr::anti_join(redcap_entity_project_ownership, by = c("project_id" = "pid")) %>%
    dplyr::filter(!.data$project_id %in% seq(from = 1, to = 14)) %>%
    dplyr::pull(.data$project_id)
}

#' get_project_pis
#'
#' Returns a dataframe of all project_PI details in redcap_projects for PIs with an email address in project_pi_email
#'
#' @param redcap_projects, The contents of the REDCap table of the same name.
#' @param return_project_ownership_format, Rename the columns to match the
#'   redcap_entity_project_ownership format
#'
#' @return a dataframe of project_PI details from redcap_projects
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' get_project_pis(
#'   redcap_projects =
#'     cleanup_project_ownership_test_data$redcap_projects,
#'   return_project_ownership_format = TRUE
#' )
get_project_pis <- function(redcap_projects,
                            return_project_ownership_format = FALSE) {
  non_blank_project_pis <- redcap_projects %>%
    dplyr::filter(stringr::str_detect(.data$project_pi_email, "^.+@.+\\..+")) %>%
    dplyr::select(
      .data$project_id,
      .data$project_pi_email,
      .data$project_pi_firstname,
      .data$project_pi_mi,
      .data$project_pi_lastname,
      .data$project_pi_username
    )

  if(return_project_ownership_format) {
    result <- non_blank_project_pis %>%
      dplyr::rename(
        pid = .data$project_id,
        email = .data$project_pi_email,
        firstname = .data$project_pi_firstname,
        lastname = .data$project_pi_lastname,
        username = .data$project_pi_username
      ) %>%
      dplyr::select(-.data$project_pi_mi)
  } else {
    result <- non_blank_project_pis
  }

  return(result)
}

#' get_creators
#'
#' Returns a dataframe of project creator usernames for non-suspended,
#'  non-redcap-staff, with a primary email address. Suspended creators
#'  can be optionally included.
#'
#' @param redcap_projects, The contents of the REDCap table of the same name.
#' @param redcap_user_information, The contents of the REDCap table of the same name.
#' @param redcap_staff_employment_periods, a dataset of redcap usernames and employment
#'        intervals with one interval per row
#' @param include_suspended_users, Include users whose accounts are suspended
#' @param return_project_ownership_format, Rename the columns to match the
#'   redcap_entity_project_ownership format
#'
#' @return a dataframe of project creators from redcap_projects
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' unsuspended_creators <- get_creators(
#'   redcap_projects = redcap_projects,
#'   redcap_user_information = redcap_user_information,
#'   redcap_staff_employment_periods = ctsit_staff_employment_periods,
#'   return_project_ownership_format = T
#' )
#'
#' creators <- get_creators(
#'   redcap_projects = redcap_projects,
#'   redcap_user_information = redcap_user_information,
#'   redcap_staff_employment_periods = ctsit_staff_employment_periods,
#'   include_suspended_users = T,
#'   return_project_ownership_format = T
#' )
#' }
get_creators <- function(redcap_projects,
                         redcap_user_information,
                         redcap_staff_employment_periods,
                         include_suspended_users = FALSE,
                         return_project_ownership_format = FALSE) {
  redcap_user_information_without_extra_columns <- redcap_user_information %>%
    dplyr::select(
      .data$ui_id,
      .data$username,
      .data$user_email,
      .data$user_suspended_time
    )

  result <- redcap_projects %>%
    dplyr::left_join(redcap_user_information_without_extra_columns, by = c("created_by" = "ui_id")) %>%
    dplyr::filter(!is.na(.data$user_email)) %>%
    dplyr::filter(is.na(.data$user_suspended_time) | include_suspended_users) %>%
    dplyr::left_join(redcap_staff_employment_periods, by = c("username" = "redcap_username")) %>%
    dplyr::filter(!.data$creation_time %in% .data$employment_interval) %>%
    dplyr::select(
      .data$project_id,
      .data$username
    )

  if (return_project_ownership_format) {
    result <- result %>%
      dplyr::rename(pid = .data$project_id)
  }

  return(result)
}

#' get_privileged_user
#'
#' Returns a dataframe of project IDs and usernames of users with design or user_rights
#'  who are non-suspended, non-redcap-staff, with a primary email address.
#'  Optionally include users with any privilege on the project.
#'  Optionally include suspended users.
#'
#' @param redcap_projects, The contents of the REDCap table of the same name.
#' @param redcap_user_information, The contents of the REDCap table of the same name.
#' @param redcap_staff_employment_periods, a dataset of redcap usernames and employment
#'        intervals with one interval per row
#' @param redcap_user_rights, The contents of the REDCap table of the same name.
#' @param redcap_user_roles, The contents of the REDCap table of the same name.
#' @param include_low_privilege_users, Include users whose accounts have any permission on a project
#' @param include_suspended_users, Include users whose accounts are suspended
#' @param return_project_ownership_format, Rename the columns to match the
#'   redcap_entity_project_ownership format
#'
#' @return a dataframe of privileged,  _user_ accounts on the projects provided
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' unsuspended_high_privilege_user <- get_privileged_user(
#'   redcap_projects = redcap_projects,
#'   redcap_user_information = redcap_user_information,
#'   redcap_staff_employment_periods = ctsit_staff_employment_periods,
#'   redcap_user_rights = redcap_user_rights,
#'   redcap_user_roles = redcap_user_roles,
#'   return_project_ownership_format = T
#' )
#'
#' unsuspended_low_privilege_user <- get_privileged_user(
#'   redcap_projects = redcap_projects,
#'   redcap_user_information = redcap_user_information,
#'   redcap_staff_employment_periods = ctsit_staff_employment_periods,
#'   redcap_user_rights = redcap_user_rights,
#'   redcap_user_roles = redcap_user_roles,
#'   include_low_privilege_users = T,
#'   include_suspended_users = FALSE,
#'   return_project_ownership_format = T
#' )
#'
#' any_low_privilege_user <- get_privileged_user(
#'   redcap_projects = redcap_projects,
#'   redcap_user_information = redcap_user_information,
#'   redcap_staff_employment_periods = ctsit_staff_employment_periods,
#'   redcap_user_rights = redcap_user_rights,
#'   redcap_user_roles = redcap_user_roles,
#'   include_low_privilege_users = T,
#'   include_suspended_users = T,
#'   return_project_ownership_format = T
#' )
#' }
get_privileged_user <- function(redcap_projects,
                                                redcap_user_information,
                                                redcap_staff_employment_periods,
                                                redcap_user_rights,
                                                redcap_user_roles,
                                                include_low_privilege_users = FALSE,
                                                include_suspended_users = FALSE,
                                                return_project_ownership_format = FALSE) {
  redcap_user_information_without_extra_columns <- redcap_user_information %>%
    dplyr::select(
      .data$ui_id,
      .data$username,
      .data$user_email,
      .data$user_suspended_time
    )

  result <- redcap_projects %>%
    dplyr::left_join(redcap_user_rights, by = c("project_id")) %>%
    dplyr::left_join(redcap_user_roles, by = c("project_id", "role_id"), suffix = c(".rights", ".roles")) %>%
    # Test for any privileges aka "Low privileges". Will satisfy PID 31 in test data
    dplyr::filter(dplyr::if_any(dplyr::ends_with(c(".rights", ".roles")), ~ .x == 1)) %>%
    # Test for high privileges. Will satisfy PID 30 in test data
    # include_low_privilege_users bypasses this test
    dplyr::filter(include_low_privilege_users |
                  dplyr::if_any(dplyr::starts_with(c("design.", "user_rights.")), ~ .x == 1)) %>%
    dplyr::left_join(redcap_user_information_without_extra_columns, by = "username") %>%
    dplyr::filter(!is.na(.data$user_email)) %>%
    dplyr::filter(is.na(.data$user_suspended_time) | include_suspended_users) %>%
    dplyr::left_join(redcap_staff_employment_periods, by = c("username" = "redcap_username")) %>%
    dplyr::filter(!.data$creation_time %in% .data$employment_interval) %>%
    dplyr::select(
      .data$project_id,
      .data$username
    ) %>%
    dplyr::distinct(.data$project_id, .keep_all = T)

  if (return_project_ownership_format) {
    result <- result %>%
      dplyr::rename(pid = .data$project_id)
  }

  return(result)
}

#' Get a dataframe of updated billable status for project ownership projects,
#' set all projects as billable except those created by CTS-IT staff
#'
#' @param conn - A REDCap database connection, e.g. the object returned from \code{\link[redcapcustodian]{connect_to_redcap_db}}
#'
#' @importFrom magrittr "%>%"
#' @importFrom lubridate "%within%"
#' @importFrom rlang .data
#'
#' @return A \code{\link{dataset_diff}} containing updates to project ownerhsip's "billable" column
#' @export
#'
#' @examples
#' \dontrun{
#' conn <- redcapcustodian::connect_to_redcap_db()
#' billable_updates <- update_billable_by_ownership(conn)
#' dbx::dbxUpdate(conn,
#'   table = "redcap_entity_project_ownership",
#'   records = billable_updates$update_records,
#'   where_cols = c("id")
#' )
#' }
update_billable_by_ownership <- function(conn) {
  actionable_projects <- dplyr::tbl(conn, "redcap_entity_project_ownership") %>%
    dplyr::filter(is.na(.data$billable)) %>%
    # filter out projects created less than 1 month ago
    dplyr::inner_join(
      dplyr::tbl(conn, "redcap_projects") %>%
        dplyr::select(.data$project_id, .data$creation_time),
      by = c("pid" = "project_id")
    ) %>%
    dplyr::collect() %>%
    dplyr::filter(.data$creation_time < redcapcustodian::get_script_run_time() - lubridate::dmonths(1)) %>%
    dplyr::select(-.data$creation_time)

  billable_update <- actionable_projects %>%
    dplyr::full_join(rcc.billing::ctsit_staff_employment_periods, by = c("username" = "redcap_username" )) %>%
    dplyr::mutate(billable = dplyr::if_else(
      as.Date.POSIXct(.data$created) %within% .data$employment_interval, 0, 1)
      ) %>%
    # correct non-staff NA values
    dplyr::mutate(billable = dplyr::if_else(is.na(.data$billable), 1, .data$billable)) %>%
    dplyr::select(-c(.data$employment_interval)) %>%
    # address "duplicate" rows from ctsit staff with multiple employment periods, keep the non-billable entry
    dplyr::arrange(.data$pid, .data$billable) %>%
    dplyr::distinct(.data$pid, .keep_all = TRUE) %>%
    dplyr::mutate(updated = as.integer(redcapcustodian::get_script_run_time()))

  billable_update_diff <- redcapcustodian::dataset_diff(
    source = billable_update,
    source_pk = "id",
    target = actionable_projects,
    target_pk = "id"
  )

  return(billable_update_diff)
}
