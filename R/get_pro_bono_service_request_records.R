#' Update Pro Bono Service Request Details
#'
#' This function processes a dataframe of service requests to update the billable_rate field
#'
#' @param service_requests A dataframe containing service request data, including record IDs, instrument names,
#' instance numbers, project IDs, and billing details.
#'
#' @return Returns a dataframe with updated billable rate
#'
#' @examples
#' \dontrun{
#' updates <- get_probono_service_request_updates(service_requests)
#' }
#' @export
get_probono_service_request_updates <- function(service_requests) {
  probono_updates <- service_requests |>
    dplyr::arrange(
      .data$record_id,
      .data$redcap_repeat_instrument,
      .data$redcap_repeat_instance) |>
    # fill project ids on each record group
    dplyr::group_by(.data$record_id) |>
    tidyr::fill(.data$project_id, .direction = "updown") |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$project_id)) |>
    # Compute time, and time total for each project_id-probono group
    dplyr::mutate(time = service_request_time(.data$time2, .data$time_more)) |>
    dplyr::mutate(probono = (.data$billable_rate == 0)) |>
    dplyr::select(
      "record_id",
      "redcap_repeat_instrument",
      "redcap_repeat_instance",
      "project_id",
      "probono",
      "time",
      "billable_rate"
    ) |>
    dplyr::group_by(.data$project_id, .data$probono) |>
    dplyr::mutate(total_time = sum(.data$time)) |>
    dplyr::ungroup() |>
    # Copy probono time to each record across a project_id group
    dplyr::group_by(.data$project_id) |>
    dplyr::mutate(probono_time = dplyr::case_when(
      .data$probono ~ total_time,
      TRUE ~ 0)) |>
    dplyr::mutate(probono_time = max(.data$probono_time)) |>
    # Mark additional records as probono as needed
    dplyr::filter(.data$probono_time < 1) |>
    dplyr::arrange(.data$time) |>
    dplyr::mutate(additional_time = cumsum(.data$time)) |>
    dplyr::filter(.data$additional_time + .data$probono_time >= 1) |>
    dplyr::filter(.data$additional_time == min(.data$additional_time)) |>
    dplyr::mutate(billable_rate = 0) |>
    dplyr::ungroup() |>
    # keep only enough columns to update the service request DB
    dplyr::select(
      "record_id",
      "redcap_repeat_instrument",
      "redcap_repeat_instance",
      "billable_rate")

  return(probono_updates)
}

