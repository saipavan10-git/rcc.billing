#' Get Service Request Lines
#'
#' This function processes a dataset of service requests to extract and transform
#' various service details. It groups response data by record_id, service_date,
#' and probono status to summarize response data and create a source dataset for
#' invoice line items and other tasks.
#'
#' @param service_requests A data frame of service requests, REDCap Service Request PID 1414.
#' @param return_all_records A boolean to indicate every record should be returned or just last month's records
#'
#' @return A data frame with response details to the service request
#'
#' @examples
#' \dontrun{
#' # get just last month's records
#' service_request_lines <- get_service_request_lines(service_requests)
#'
#' # get all the records
#' service_request_lines <- get_service_request_lines(service_requests, return_all_records = T)
#' }
#' @export
get_service_request_lines <- function(service_requests, return_all_records = F) {
  request_details <- service_requests |>
    dplyr::filter(is.na(.data$redcap_repeat_instrument)) |>
    dplyr::filter(!is.na(.data$project_id)) |>
    # TODO: Is a column missing in paste?
    dplyr::mutate(
      service_identifier = paste(.data$record_id),
      service_type_code = 2,
      service_instance_id = paste(.data$service_type_code, .data$service_identifier, sep = "-"),
      username = dplyr::coalesce(.data$redcap_username, .data$gatorlink)
    ) |>
    # simple pi clean up. Doesn't need to be perfect
    dplyr::mutate(
      clean_pi = stringr::str_remove_all(
        .data$pi,
        ", MD|, M.D.| MD|, M.D|, PH.D|, Ph.D|, PhD| PhD|, Ph.D.|Dr. |, MBA|, M.P.H"
      )
    ) |>
    tidyr::separate_wider_delim(
      "clean_pi",
      delim = " ",
      names = c("pi_fn", "pi_ln"),
      too_few = "align_start",
      too_many = "drop"
    ) |>
    dplyr::mutate(
      pi_last_name = dplyr::coalesce(.data$pi_ln, .data$last_name),
      pi_first_name = dplyr::coalesce(.data$pi_fn, .data$first_name),
      pi_email = dplyr::coalesce(.data$pi_email, .data$email)
    ) |>
    dplyr::select(
      "record_id",
      "project_id",
      "irb_number",
      "submit_date",
      "username",
      "pi_last_name",
      "pi_first_name",
      "pi_email",
      "fiscal_contact_fn",
      "fiscal_contact_ln",
      "fiscal_contact_email",
      "service_identifier",
      "service_instance_id",
      "service_type_code"
    )

  response_details <- service_requests |>
    dplyr::filter(!is.na(.data$redcap_repeat_instrument)) |>
    dplyr::filter(!is.na(.data$billable_rate)) |>
    dplyr::filter(.data$help_desk_response_complete == 2) |>
    dplyr::mutate(probono = (.data$billable_rate == 0)) |>
    dplyr::rename(price_of_service = "billable_rate") |>
    dplyr::mutate(service_date = lubridate::floor_date(
      dplyr::coalesce(
        .data$end_date,
        as.Date(.data$meeting_date_time),
        as.Date(.data$date_of_work)
      ),
      unit = "month"
    )) |>
    dplyr::filter(return_all_records |
      .data$service_date ==
        lubridate::floor_date(redcapcustodian::get_script_run_time() -
          lubridate::dmonths(1), unit = "month")) |>
    dplyr::mutate(response = dplyr::coalesce(
      .data$response,
      .data$comments,
      dplyr::if_else(.data$mtg_scheduled_yn == 1, "Meeting", NA_character_)
    )) |>
    dplyr::mutate(time = rcc.billing::service_request_time(.data$time2, .data$time_more)) |>
    dplyr::group_by(.data$record_id, .data$service_date, .data$probono, .data$price_of_service) |>
    dplyr::summarize(
      qty_provided = sum(.data$time),
      response = paste(.data$response, collapse = " "),
      service_date = max(.data$service_date)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(amount_due = .data$price_of_service * .data$qty_provided)

  request_lines <- request_details |>
    dplyr::inner_join(response_details, by = "record_id") |>
    dplyr::mutate(service_instance_id = dplyr::if_else(
      .data$probono,
      paste0(.data$service_instance_id, "-PB"),
      .data$service_instance_id
    )) |>
    dplyr::mutate(
      other_system_invoicing_comments =
        stringr::str_trim(stringr::str_sub(
          paste(
            .data$service_identifier,
            .data$username,
            .data$submit_date,
            dplyr::if_else(.data$probono, paste0("Pro-bono : ", .data$response), .data$response),
            sep = " : "
          ),
          1,
          255
        ))
    ) |>
    dplyr::mutate(dplyr::across(c(
      "project_id",
      "fiscal_contact_fn",
      "fiscal_contact_ln",
      "fiscal_contact_email"
    ), as.character)) |>
    dplyr::select(
      "record_id",
      "project_id",
      "service_identifier",
      "service_type_code",
      "service_instance_id",
      "username",
      "irb_number",
      "pi_last_name",
      "pi_first_name",
      "pi_email",
      "other_system_invoicing_comments",
      "fiscal_contact_fn",
      "fiscal_contact_ln",
      "fiscal_contact_email",
      "qty_provided",
      "amount_due",
      "price_of_service",
      "service_date"
    )

  return(request_lines)
}
