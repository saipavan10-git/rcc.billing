
#' Find previously unknown CTSI Study IDs in invoice_line_item data
#'
#' @description
#' Given the service instance data and invoice line item data, identify
#' the new CTSI Study IDs in the invoice line item data and return them
#' on revised service instance records.
#'
#'
#' @param service_instance - a dataframe of service_instance wiht the columns
#'        `service_instance_id` and `ctsi_study_id`. Most likely this is the
#'        entire contents of that table.
#' @param invoice_line_item - a dataframe of invoice line item records
#'        with the columns `service_instance_id` and `ctsi_study_id`.
#'
#' @return service_instance records from the service_instance where
#'         `ctsi_study_id` was NA but is now known.
#' @export
#'
#' @examples
#' \dontrun{
#' library(redcapcustodian)
#' library(rcc.billing)
#' library(RMariaDB)
#' library(DBI)
#' library(tidyverse)
#' library(dotenv)
#'
#' rcc_billing_conn <- connect_to_rcc_billing_db()
#'
#' service_instance <- tbl(rcc_billing_conn, "service_instance") %>%
#' collect()
#'
#' invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
#' collect()
#'
#' get_new_ctsi_study_ids(service_instance, invoice_line_item)
#' }
get_new_ctsi_study_ids <- function(service_instance, invoice_line_item) {
  distinct_service_instance_id <- invoice_line_item |>
    dplyr::filter(!is.na(.data$ctsi_study_id)) |>
    # keep only the most recent ctsi_study_id for each service_instance_id
    dplyr::arrange(.data$service_instance_id, dplyr::desc(.data$id)) |>
    dplyr::distinct(.data$service_instance_id, .keep_all = T) |>
    dplyr::select("service_instance_id", "ctsi_study_id")

  result <- service_instance |>
    dplyr::filter(is.na(.data$ctsi_study_id)) |>
    dplyr::select(-c("ctsi_study_id")) |>
    dplyr::inner_join(distinct_service_instance_id, by = c("service_instance_id"))

  return(result)
}
