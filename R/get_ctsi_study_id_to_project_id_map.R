#' Map CTSI Study IDs to Project IDs
#'
#' This function generates a mapping between CTSI study IDs and project IDs from invoice_line_item and REDCap Service Request project.
#' It filters invoice line items for service type codes 1 and 2, ensuring CTSI study IDs are present, and collects distinct pairs of project IDs and CTSI study IDs.
#'
#' @param service_requests A data frame of service requests, REDCap Service Request PID 1414.
#' @param rcc_billing_conn  A connection to REDCap billing database. \code{\link{connect_to_rcc_billing_db}}
#' @return A data frame with distinct project_id and ctsi_study_id columns, representing the mapping between project IDs and CTSI study IDs.
#' @export
#'
#' @examples
#' \dontrun{
#' get_ctsi_study_id_to_project_id_map(service_requests, rcc_billing_conn)
#' }
get_ctsi_study_id_to_project_id_map <- function(service_requests, rcc_billing_conn) {
    extant_invoice_line_items <-
      dplyr::tbl(rcc_billing_conn, "invoice_line_item") |>
      dplyr::filter(.data$service_type_code %in% 1:2 & !is.na(.data$ctsi_study_id)) |>
      dplyr::select(
        "id",
        "service_type_code",
        "service_identifier",
        "ctsi_study_id"
      ) |>
      dplyr::arrange(dplyr::desc(.data$id)) |>
      dplyr::mutate_all(as.character) |>
      dplyr::collect()

    annual_project_billing_line_items <- extant_invoice_line_items |>
      dplyr::filter(.data$service_type_code == 1) |>
      dplyr::rename(project_id = .data$service_identifier)

    service_request_line_items <- extant_invoice_line_items |>
      dplyr::filter(.data$service_type_code == 2) |>
      dplyr::inner_join(
        service_requests |>
          dplyr::filter(
            is.na(.data$redcap_repeat_instrument) & !is.na(.data$project_id)
          ) |>
          dplyr::mutate_all(as.character),
        by = c("service_identifier" = "record_id")
      )

    result <- annual_project_billing_line_items |>
      dplyr::bind_rows(service_request_line_items) |>
      dplyr::select(.data$project_id, .data$ctsi_study_id) |>
      dplyr::slice_max(order_by = .data$ctsi_study_id, by = .data$project_id, n = 1) |>
      dplyr::distinct("project_id", "ctsi_study_id")

    return(result)
  }
