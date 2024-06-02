#' Get Service Request Lines
#'
#' This function processes a dataset of service requests to extract and transform
#' various service details.
#'
#' @param service_requests A data frame of service requests, REDCap Service Request PID 1414.

#' @return A data frame with response details to the service request
#'
#' @examples
#' \dontrun{
#' processed_requests <- get_service_request_lines(service_requests)
#'}
#' @export
get_service_request_lines <- function(service_requests) {
  request_details <- service_requests |>
    dplyr::filter(is.na(.data$redcap_repeat_instrument)) |>
    #TODO: Is a column missing in paste?
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
      too_few = "debug",
      too_many = "debug"
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
      "service_identifier",
      "service_instance_id",
      "service_type_code"
    )

  response_details <- service_requests |>
    dplyr::filter(!is.na(.data$redcap_repeat_instrument)) |>
    dplyr::filter(!is.na(.data$billable_rate)) |>
    dplyr::mutate(probono = (.data$billable_rate == 0)) |>
    dplyr::rename(price_of_service = "billable_rate") |>
    dplyr::group_by(.data$record_id, .data$probono, .data$price_of_service) |>
    dplyr::mutate(time = rcc.billing::service_request_time(.data$time2, .data$time_more)) |>
    dplyr::summarize(qty_provided = sum(.data$time),
              response = paste(.data$response, collapse = " ")) |>
    dplyr::ungroup() |>
    dplyr::mutate(amount_due = .data$price_of_service * .data$qty_provided)

  request_lines <- request_details |>
    dplyr::inner_join(response_details, by = "record_id") |>
    dplyr::mutate(service_instance_id = dplyr::if_else(
      .data$probono,
      paste0(.data$service_instance_id, "-PB"),
      .data$service_instance_id
    )) |>
    dplyr::mutate(other_system_invoicing_comments =
             stringr::str_trim(stringr::str_sub(
               paste0(
                 .data$service_identifier,
                 .data$username,
                 .data$submit_date,
                 dplyr::if_else(.data$probono, paste0("Pro-bono : ", .data$response), .data$response),
                 sep = " : "
               ),
               1,
               255
             ))) |>
    dplyr::select(
      "record_id",
      "project_id",
      "service_identifier",
      "service_type_code",
      "service_instance_id",
      "irb_number",
      "pi_last_name",
      "pi_first_name",
      "pi_email",
      "other_system_invoicing_comments",
      "qty_provided",
      "amount_due",
      "price_of_service"
    )

  return(request_lines)
}
