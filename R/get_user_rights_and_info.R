#' Get every attribute of every permission entry and userinfo for each user on each permission
#'
#' @param rc_conn A DBI connection object to a REDCap Database on a system.
#' @param require_active_account A boolean to indicate if only active accounts are returned. Defaults to TRUE.
#' @param require_active_permissions A boolean to indicate if only active permission entries are returned. Defaults to TRUE.
#'
#' @return a dataframe of every permission entry and with the matching user_information data appended
#' @export
#'
#' @examples
#' \dontrun{
#' get_user_rights_and_info <- function(
#'   rc_conn = rc_conn,
#'   require_active_account = T,
#'   require_active_permissions = T
#' )
#' }
get_user_rights_and_info <- function(rc_conn,
                                     require_active_account = T,
                                     require_active_permissions = T) {
  redcap_user_information <-
    dplyr::tbl(rc_conn, "redcap_user_information") |>
    dplyr::collect() |>
    dplyr::filter(!require_active_account | is.na(.data$user_suspended_time))

  direct_rights <- tbl(rc_conn, "redcap_user_rights") |>
    dplyr::filter(is.na(.data$role_id)) |>
    dplyr::collect()

  role_derived_rights <-
    dplyr::tbl(rc_conn, "redcap_user_rights") |>
    dplyr::select("project_id", "username", "expiration", "role_id", "group_id") |>
    dplyr::filter(!is.na(.data$role_id)) |>
    dplyr::inner_join(
      dplyr::tbl(rc_conn, "redcap_user_roles") |>
        dplyr::select(-"role_name", -"unique_role_name"),
      by = c("project_id", "role_id")
    ) |>
    dplyr::collect()

  combined_user_rights <- dplyr::bind_rows(direct_rights, role_derived_rights) |>
    dplyr::filter(!require_active_permissions |
      is.na(.data$expiration) |
      .data$expiration >= redcapcustodian::get_script_run_time())

  result <- combined_user_rights %>%
    dplyr::inner_join(redcap_user_information,
      by = "username",
      suffix = c("", ".redcap_user_information")
    ) |>
    filter(.data$username %in% redcap_user_information$username)

  return(result)
}
