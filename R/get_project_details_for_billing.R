#' Get Project Details for Billing
#'
#' This function retrieves detailed information about specific projects for billing purposes. It queries:
#' \itemize{
#'  \item redcap_projects
#'  \item redcap_entity_project_ownership
#'  \item redcap_user_information
#'  \item invoice_line_item
#'  }
#'
#' @param rc_conn A REDCap database connection, e.g. the object returned from \code{\link[redcapcustodian]{connect_to_redcap_db}}
#' @param rc_billing_conn  A connection to REDCap billing database. \code{\link{connect_to_rcc_billing_db}}
#' @param project_ids Vector of project IDs to retrieve details for.
#'
#' @return A data frame with project details.
#'
#' @examples
#' \dontrun{
#' rc_conn <- connect_to_redcap_db()
#' rcc_billing_conn <- connect_to_rcc_billing_db()
#' project_ids <- c(12, 14, 22)
#' project_details <- get_project_details_for_billing(rc_conn, rc_billing_con, project_ids)
#' }
#'
#' @export
get_project_details_for_billing <- function(rc_conn, rc_billing_con, project_ids) {
    redcap_projects <- tbl(rc_conn, "redcap_projects")
    redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership")
    redcap_user_information <- tbl(rc_conn, "redcap_user_information") |>
      select(username, user_email, user_firstname, user_lastname)

    invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
      distinct(service_identifier, ctsi_study_id) |>
      collect()

    project_details <- redcap_projects %>%
      filter(project_id %in% project_ids) |>
      dplyr::inner_join(redcap_entity_project_ownership, by = c("project_id" = "pid")) %>%
      # get user info for owners who are also redcap users
      dplyr::left_join(redcap_user_information, by = "username") |>
      dplyr::collect() |>
      dplyr::left_join(
        invoice_line_item |>
          dplyr::mutate_at("service_identifier", as.integer),
        by = c("project_id" = "service_identifier")
      ) |>
      # Assure non-distinct rows in redcap_entity_project_ownership do not foment chaos
      dplyr::distinct(.data$project_id, .keep_all = T) %>%
      # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
      mutate_columns_to_posixct("creation_time") %>%
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
        pi_email = dplyr::coalesce(.data$user_email, .data$project_pi_email, .data$email)
      ) |>
      dplyr::select(
        "project_id",
        "app_title",
        "billable",
        "sequestered",
        "creation_time",
        "pi_last_name",
        "pi_first_name",
        "pi_email",
        "ctsi_study_id"
      )

    return(project_details)
  }


