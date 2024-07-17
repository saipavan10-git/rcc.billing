#' Get details on the projects we need to create invoice line items for.
#'
#' @param rc_conn A connection to a REDCap database that uses the project_ownership module
#'
#' @return a dataframe of project and owner details
#' @export
#'
#' @examples
#' \dontrun{
#'   get_target_projects_to_invoice(rc_conn)
#' }
get_target_projects_to_invoice <- function(rc_conn) {
  target_projects <-
    dplyr::tbl(rc_conn, "redcap_projects") |>
    dplyr::inner_join(
      dplyr::tbl(rc_conn, "redcap_entity_project_ownership") |>
        dplyr::filter(
          .data$billable == 1,
          .data$sequestered == 0 | is.na(.data$sequestered)
        ),
      by = c("project_id" = "pid")
    ) |>
    # get user info for owners who are also redcap users
    dplyr::left_join(
      dplyr::tbl(rc_conn, "redcap_user_information") |>
        dplyr::select(
          "username",
          "user_email",
          "user_firstname",
          "user_lastname"
        ),
      by = "username"
    ) |>
    # project is not deleted
    dplyr::filter(is.na(.data$date_deleted)) |>
    # project at least 1 year old
    dplyr::filter(.data$creation_time <=
      local(redcapcustodian::get_script_run_time() - lubridate::dyears(1))) |>
    dplyr::collect() |>
    # Assure non-distinct rows in redcap_entity_project_ownership do not foment chaos
    dplyr::distinct(.data$project_id, .keep_all = T) |>
    # birthday in past month
    dplyr::filter(rcc.billing::previous_month(lubridate::month(redcapcustodian::get_script_run_time())) ==
      lubridate::month(.data$creation_time)) |>
    dplyr::mutate(
      # coerce empty strings to NA for coalesce operations
      dplyr::across(
        dplyr::any_of(c("user_email", "project_pi_email")),
        ~ dplyr::if_else(.x == "", as.character(NA), .x)
      ),
      dplyr::across(
        dplyr::contains(c("name")),
        ~ dplyr::if_else(.x == "", as.character(NA), .x)
      ),
      # ...and make our PI strings
      pi_last_name = dplyr::coalesce(
        .data$user_lastname,
        .data$project_pi_lastname,
        .data$lastname
      ),
      pi_first_name = dplyr::coalesce(
        .data$user_firstname,
        .data$project_pi_firstname,
        .data$firstname
      ),
      pi_email = dplyr::coalesce(
        .data$user_email,
        .data$project_pi_email,
        .data$email
      )
    ) |>
    ## Do not send any invoices to PIs/Owners with no email address
    dplyr::filter(!is.na(.data$pi_email))

  return(target_projects)
}
