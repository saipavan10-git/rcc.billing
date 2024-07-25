#' Get new project billing invoice line items given a dataframe of projects to invoice,
#' the initial state of the invoice_line_item table,
#' a connection to the redcap database, and a connection to the rcc billing database.
#'
#' @param projects_to_invoice a dataframe of projects to invoice
#' @param initial_invoice_line_item a dataframe with the initial state of the invoice_line_item table
#' @param rc_conn a DBI connection to the REDCap database
#' @param rcc_billing_conn a DBI connection to the rcc billing database
#' @param api_uri the URI to the redcap host's API interface
#' @param service_request_lines a dataframe of service request line items
#'
#' @return a data frame of new invoice line items
#' @export
#'
#' @examples
#' \dontrun{
#' get_new_project_invoice_line_items <- function(
#'   projects_to_invoice,
#'   initial_invoice_line_item,
#'   rc_conn,
#'   rcc_billing_conn,
#'   api_uri,
#'   service_request_lines
#' }
get_new_project_invoice_line_items <- function(
    projects_to_invoice,
    initial_invoice_line_item,
    rc_conn,
    rcc_billing_conn,
    api_uri,
    service_request_lines
  ) {

  previous_month_name <- rcc.billing::previous_month(
    lubridate::month(redcapcustodian::get_script_run_time())
    ) |>
    lubridate::month(label = TRUE, abbr = FALSE)

  fiscal_year_invoiced <- rcc.billing::fiscal_years |>
    dplyr::filter((redcapcustodian::get_script_run_time() - lubridate::dmonths(1)) %within% .data$fy_interval) |>
    dplyr::slice_head(n = 1) |> # HACK: overlaps may occur on July 1, just choose the earlier year
    dplyr::pull(.data$csbt_label)

  redcap_version <- dplyr::tbl(rc_conn, "redcap_config") |>
    dplyr::filter(.data$field_name == "redcap_version") |>
    dplyr::collect() |>
    dplyr::pull(.data$value)

  redcap_project_uri_base <- stringr::str_remove(api_uri, "/api") |>
    paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

  service_type <- dplyr::tbl(rcc_billing_conn, "service_type") |> dplyr::collect()

  updated_service_instance <- dplyr::tbl(rcc_billing_conn, "service_instance") |>
    dplyr::collect()

  new_invoice_line_items <- projects_to_invoice |>
    dplyr::mutate(
      service_type_code = 1,
      service_identifier = as.character(.data$project_id),
      name_of_service_instance = .data$app_title,
      fiscal_year = fiscal_year_invoiced,
      month_invoiced = previous_month_name,
      # TODO: should this be stripped from the PI email instead?
      gatorlink = .data$username,
      reason = "new_item",
      status = "draft",
      created = redcapcustodian::get_script_run_time(),
      updated = redcapcustodian::get_script_run_time()
    ) |>
    dplyr::inner_join(
      updated_service_instance,
      by = c("service_type_code", "service_identifier")
    ) |>
    dplyr::inner_join(
      service_type, by = "service_type_code"
    ) |>
    dplyr::mutate(
      other_system_invoicing_comments = paste0(
        .data$service_type,
        ": ",
        redcap_project_uri_base,
        .data$project_id
      ),
      name_of_service = "Biomedical Informatics Consulting",
      price_of_service = .data$price,
      qty_provided = 1,
      amount_due = .data$price * .data$qty_provided
    ) |>
    # Make sure we are not making a duplicate entry with these new invoice line items
    dplyr::anti_join(
      initial_invoice_line_item |>
        dplyr::filter(
          .data$fiscal_year == fiscal_year_invoiced,
          .data$month_invoiced == previous_month_name
        ) |>
        dplyr::select("service_identifier", "fiscal_year", "month_invoiced"),
      by = c("service_identifier", "fiscal_year", "month_invoiced")
    ) |>
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
      "updated"
    )

  service_request_lines <- get_service_request_line_items(service_request_lines,rcc_billing_conn,rc_conn)

  #standardize the datatypes
  service_request_lines <- service_request_lines |>
    dplyr::mutate_all(as.character)

  new_invoice_line_items <- new_invoice_line_items |>
    dplyr::mutate_all(as.character)

  final_invoice_line_items <- dplyr::bind_rows(new_invoice_line_items,service_request_lines)
  return(final_invoice_line_items)
}
