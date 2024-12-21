#' Assemble line items for service requests billing
#'
#' @param service_requests A data frame of service requests, REDCap Service Request PID 1414.
#' @param rc_billing_conn  A connection to REDCap billing database containing an invoice_line_items table. \code{\link{connect_to_rcc_billing_db}}
#' @param rc_conn A connection to REDCap database. \code{\link[redcapcustodian]{connect_to_redcap_db}}
#'
#' @return A data frame of line items for service requests billing.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' line_items <- get_service_request_line_items(service_requests, rc_billing_conn, rc_conn)
#' }
#'
get_service_request_line_items <- function(service_requests,
                                           rc_billing_conn,
                                           rc_conn) {
  service_request_lines <- get_service_request_lines(service_requests)
  ctsi_study_id_map <- get_ctsi_study_id_to_project_id_map(service_requests, rc_billing_conn)
  project_ids <- unique(service_request_lines$project_id)
  project_details <- get_project_details_for_billing(rc_conn, rc_billing_conn, project_ids)

  # Get data for missing fields
  previous_month_name <- previous_month(
    lubridate::month(redcapcustodian::get_script_run_time())) |>
    lubridate::month(label = TRUE, abbr = FALSE)

  fiscal_year_invoiced <- rcc.billing::fiscal_years |>
    dplyr::filter((
      redcapcustodian::get_script_run_time() -
        lubridate::dmonths(1)
    ) %within% .data$fy_interval) |>
    dplyr::slice_head(n = 1) |>
    dplyr::pull(.data$csbt_label)


  # standardize the datatypes
  ctsi_study_id_map <- ctsi_study_id_map |>
    dplyr::mutate_all(as.character)

  project_details <- project_details |>
    dplyr::mutate_all(as.character)

  service_request_lines <- service_request_lines |>
    dplyr::mutate_all(as.character)

  # Join the data and select required fields
  result <- service_request_lines |>
    dplyr::left_join(ctsi_study_id_map, by = "project_id") |>
    dplyr::left_join(project_details,
      by = "project_id",
      suffix = c("_srv", "_proj")
    ) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("_srv"), ~ dplyr::coalesce(.x, get(
      sub("_srv", "_proj", dplyr::cur_column())
    )))) |>
    dplyr::select(-dplyr::ends_with("_proj")) |>
    dplyr::rename_with(~ gsub("_srv$", "", .), dplyr::ends_with("_srv")) |>
    dplyr::mutate(
      name_of_service = "Biomedical Informatics Consulting",
      name_of_service_instance = .data$app_title,
      fiscal_year = fiscal_year_invoiced,
      month_invoiced = previous_month_name,
      gatorlink = service_request_lines$username,
      status = "draft",
      reason = "new_item",
      created = redcapcustodian::get_script_run_time(),
      updated = redcapcustodian::get_script_run_time(),
      fiscal_contact_name = paste(
        service_request_lines$fiscal_contact_fn,
        service_request_lines$fiscal_contact_ln
      )
    )

  final_result <- result |>
    dplyr::select(
      "service_identifier",
      "service_type_code",
      "service_instance_id",
      "ctsi_study_id",
      "name_of_service",
      "name_of_service_instance",
      "other_system_invoicing_comments",
      "price_of_service",
      "qty_provided",
      "amount_due",
      "fiscal_year",
      "month_invoiced",
      "pi_last_name",
      "pi_first_name",
      "pi_email",
      "gatorlink",
      "reason",
      "status",
      "created",
      "updated",
      "fiscal_contact_fn",
      "fiscal_contact_ln",
      "fiscal_contact_name",
      "fiscal_contact_email"
    )

  return(final_result)
}
