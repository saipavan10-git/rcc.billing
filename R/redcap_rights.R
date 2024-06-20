#' get_user_rights_and_info
#'
#' Get redcap_user_rights combined with roles and user_information
#'
#' @param redcap_user_rights, The contents of the REDCap table of the same name.
#' @param redcap_user_roles, The contents of the REDCap table of the same name.
#' @param redcap_user_information, The contents of the REDCap table of the same name.
#'
#' @return a dataframe of combined redcap_user_rights, roles, and user_information
#' @export
#'
#' @examples
#' \dontrun{
#' get_user_rights_and_info(
#'   redcap_user_rights,
#'   redcap_user_roles,
#'   redcap_user_information
#' )
#' }
get_user_rights_and_info <- function(redcap_user_rights,
                                     redcap_user_roles,
                                     redcap_user_information) {
  direct_rights <- redcap_user_rights |>
    dplyr::filter(is.na(.data$role_id))
  role_derived_rights <- redcap_user_rights |>
    dplyr::select("project_id", "username", "expiration", "role_id", "group_id") |>
    dplyr::inner_join(redcap_user_roles |>
      dplyr::select(-"role_name", -"unique_role_name"), by = c("project_id", "role_id"))

  combined_user_rights <- dplyr::bind_rows(direct_rights, role_derived_rights)

  result <- combined_user_rights |>
    dplyr::left_join(redcap_user_information, by = "username", suffix = c("", ".redcap_user_information"))

  return(result)
}
