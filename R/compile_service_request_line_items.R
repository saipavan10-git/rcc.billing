#' Assemble line items for service requests billing
#'
#' @param service_requests A data frame of service requests, REDCap Service Request PID 1414.
#' @param rc_billing_conn  A connection to REDCap billing database containing an invoice_line_items table. \code{\link{connect_to_rcc_billing_db}}
#'
#' @return A data frame of line items for service requests billing.
#' @export
#'
#' @examples
#' \dontrun{
#' line_items <- compile_service_request_line_items(service_requests, rc_billing_conn)
#' }
#'
compile_service_request_line_items <- function(service_requests, rc_billing_conn) {
  # Retrieve the required data
  service_request_lines <- get_service_request_lines(service_requests)
  ctsi_study_id_map <- get_ctsi_study_id_to_project_id_map(service_requests, rc_billing_conn)
  project_ids <- unique(service_request_lines$project_id)
  project_details <- get_project_details_for_billing(rc_billing_conn, project_ids)

  # Join the data and select required fields
  result <- service_request_lines |>
    dplyr::left_join(ctsi_study_id_map, by = "project_id") |>
    dplyr::left_join(project_details, by = "project_id") |>
    dplyr::mutate(
      pi_last_name = dplyr::coalesce(service_request_lines$pi_last_name, project_details$pi_last_name),
      pi_first_name = dplyr::coalesce(service_request_lines$pi_first_name, project_details$pi_first_name),
      pi_email = dplyr::coalesce(service_request_lines$pi_email, project_details$pi_email),
      irb_number = dplyr::coalesce(service_request_lines$irb_number, project_details$irb_number),
      ctsi_study_id = dplyr::coalesce(ctsi_study_id_map$ctsi_study_id, project_details$ctsi_study_id),
      fiscal_contact_name = paste(service_request_lines$fiscal_contact_fn, service_request_lines$fiscal_contact_ln)
    )

  # Define all columns that should be in the result
  all_columns <- unique(c(
    names(service_request_lines),
    names(ctsi_study_id_map),
    names(project_details),
    "fiscal_contact_name"
  ))

  # Select only the columns that are present in the result
  result <- result |>
    dplyr::select(dplyr::all_of(intersect(names(result), all_columns)))

  return(result)
}
