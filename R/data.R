#' Sample data for service_type table
#'
#' @format
#' \describe{
#'   \item{id}{the primary key}
#'   \item{service_identifier}{either a redcap project ID, or redcap username}
#'   \item{service_type_code}{a numeric code that uniquely identifies the service_type}
#'   \item{service_instance_id}{a numeric code that uniquely identifies the service_instance}
#'   \item{ctsi_study_id}{CSBT's unique identifier for a service}
#'   \item{name_of_service}{name of the service}
#'   \item{other_system_invoicing_comments}{additional invoice information, either project url, or sponsor and pi}
#'   \item{cost_of_service}{price of the service, in US dollars}
#'   \item{qty_provided}{quantity provided}
#'   \item{amount_due}{amount due, in US dollars}
#'   \item{fiscal_year}{fiscal year of the invoice}
#'   \item{month_invoiced}{month of the invoice}
#'   \item{pi_last_name}{last name of the person invoiced}
#'   \item{pi_first_name}{first name of the person invoiced}
#'   \item{pi_email}{email of the person invoiced}
#'   \item{gatorlink}{gatorlink of the person invoiced}
#'   \item{reason}{reason for the invoice}
#'   \item{status}{status of the invoice}
#'   \item{created}{created at timestamp}
#'   \item{updated}{updated at timestamp}
#' }
#'
#' @source \url{https://github.com/ctsit/rcc.billing/issues/3}
"invoice_line_item_test_data"

#' Sample data for service_type table
#'
#' @format
#' \describe{
#'   \item{service_type_code}{a numeric code that uniquely identifies the service_type}
#'   \item{service_type}{short name describing the service_type, in snake case}
#'   \item{price}{price for one unit of the service, in US dollars}
#'   \item{billing_frequency}{frequency at which this service ir billed, in months}
#' }
#'
#' @source \url{https://github.com/ctsit/rcc.billing/issues/1}
"service_type_test_data"
