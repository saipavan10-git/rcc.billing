#' Update Pro Bono Service Request Details
#'
#' This function processes a dataframe of service requests to update the billable_rate field
#'
#' @param service_requests A dataframe containing service request data from REDCap PID 1414
#'
#' @return Returns a dataframe with updated billable rate
#'
#' @examples
#' \dontrun{
#' updates <- get_probono_service_request_updates(service_requests)
#' }
#' @export
get_probono_service_request_updates <- function(service_requests) {
  non_probono_records_that_should_be_probono <-
    service_requests |>
    dplyr::arrange(
      .data$record_id,
      .data$redcap_repeat_instrument,
      .data$redcap_repeat_instance
    ) |>
    # fill project ids on each record group
    dplyr::group_by(.data$record_id) |>
    tidyr::fill("project_id", .direction = "updown") |>
    dplyr::ungroup() |>
    dplyr::filter(!is.na(.data$project_id)) |>
    dplyr::filter(!is.na(.data$redcap_repeat_instrument)) |>
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
      "billable_rate",
      dplyr::everything()
    ) |>
    dplyr::group_by(.data$project_id, .data$probono) |>
    dplyr::mutate(total_time_by_project = sum(.data$time)) |>
    dplyr::ungroup() |>
    # Copy probono time to each record across a project_id group
    dplyr::group_by(.data$project_id) |>
    dplyr::mutate(probono_time = dplyr::case_when(
      .data$probono ~ .data$total_time_by_project,
      TRUE ~ 0
    )) |>
    dplyr::mutate(probono_time = max(.data$probono_time)) |>
    # eliminate records that have already been marked as probono
    dplyr::filter(.data$billable_rate != 0) |>
    # Mark additional records as probono as needed
    dplyr::filter(.data$probono_time < 1) |>
    dplyr::arrange(.data$time) |>
    dplyr::mutate(draft_probono_time = cumsum(.data$time) + .data$probono_time) |>
    dplyr::mutate(sufficient_draft_probono_time = (.data$draft_probono_time >= 1)) |>
    dplyr::ungroup()

  if (nrow(non_probono_records_that_should_be_probono) == 0) {
    # Prevent -Inf warnings form min when non_probono_records_that_should_be_probono is empty
    probono_updates <- non_probono_records_that_should_be_probono |>
      dplyr::ungroup() |>
      # keep only enough columns to update the service request DB
      dplyr::select(
        "record_id",
        "redcap_repeat_instrument",
        "redcap_repeat_instance",
        "billable_rate"
      )
  } else {
    max_row_num_by_project <- dplyr::bind_rows(
      # projects where there is sufficient_draft_probono_time
      non_probono_records_that_should_be_probono |>
        dplyr::group_by(.data$project_id) |>
        dplyr::mutate(row_num = dplyr::row_number()) |>
        dplyr::filter(.data$sufficient_draft_probono_time) |>
        dplyr::slice_head(n = 1) |>
        dplyr::ungroup() |>
        dplyr::select("project_id", max_row_num_by_project = "row_num"),
      # All projects
      non_probono_records_that_should_be_probono |>
        dplyr::group_by(.data$project_id) |>
        dplyr::mutate(row_num = dplyr::row_number()) |>
        dplyr::filter(!.data$sufficient_draft_probono_time) |>
        dplyr::slice_tail(n = 1) |>
        dplyr::ungroup() |>
        dplyr::select("project_id", max_row_num_by_project = "row_num")
    ) |>
      dplyr::arrange(dplyr::desc(.data$max_row_num_by_project)) |>
      dplyr::distinct(.data$project_id, .keep_all = T)

    probono_updates <- non_probono_records_that_should_be_probono |>
      dplyr::group_by(.data$project_id) |>
      dplyr::left_join(max_row_num_by_project, by = "project_id") |>
      dplyr::filter(dplyr::row_number() <= max_row_num_by_project) |>
      dplyr::mutate(billable_rate = 0) |>
      dplyr::ungroup() |>
      # keep only enough columns to update the service request DB
      dplyr::select(
        "record_id",
        "redcap_repeat_instrument",
        "redcap_repeat_instance",
        "billable_rate"
      )
  }

  return(probono_updates)
}
