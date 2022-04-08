#' Sample data for invoice_line_item table
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
#'   \item{price_of_service}{price of the service, in US dollars}
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

#' Sample data for service_instance table
#'
#' @format
#' \describe{
#'   \item{service_instance_id}{the primary key}
#'   \item{service_type_code}{a numeric code that uniquely identifies the service_type}
#'   \item{service_identifier}{either a redcap project ID, or redcap username}
#'   \item{ctsi_study_id}{CSBT’s unique identifier for a service}
#'   \item{active}{a boolean indicating if we expect to continue billing for this service}
#' }
#'
#' @source \url{https://github.com/ctsit/rcc.billing/issues/2}
"service_instance_test_data"

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

#' @title invoice_line_item_communications_test_data
#' @description A test dataset for testing functions that write or read invoice_line_item_communications
#' @format A data frame with 26 rows and 31 variables:
#' \describe{
#'   \item{\code{id}}{double: the primary key}
#'   \item{\code{service_identifier}}{character: either a redcap project ID, or redcap username}
#'   \item{\code{service_type_code}}{double: a numeric code that uniquely identifies the service_type}
#'   \item{\code{service_instance_id}}{character: a numeric code that uniquely identifies the service_instance}
#'   \item{\code{ctsi_study_id}}{double: CSBT's unique identifier for a service}
#'   \item{\code{name_of_service}}{character: name of the service}
#'   \item{\code{other_system_invoicing_comments}}{character: additional invoice information, either project url, or sponsor and pi}
#'   \item{\code{price_of_service}}{double: price of the service, in US dollars}
#'   \item{\code{qty_provided}}{double: quantity provided}
#'   \item{\code{amount_due}}{double: amount due, in US dollars}
#'   \item{\code{fiscal_year}}{character: fiscal year of the invoice}
#'   \item{\code{month_invoiced}}{character: month of the invoice}
#'   \item{\code{pi_last_name}}{character: last name of the person invoiced}
#'   \item{\code{pi_first_name}}{character: first name of the person invoiced}
#'   \item{\code{pi_email}}{character: email of the person invoiced}
#'   \item{\code{gatorlink}}{character: gatorlink of the person invoiced}
#'   \item{\code{crc_number}}{double: Clinical Research Center number}
#'   \item{\code{ids_number}}{character: Investigational Drug Service number}
#'   \item{\code{ocr_number}}{character: Office of Clinical Research study number}
#'   \item{\code{invoice_number}}{double: invoice number}
#'   \item{\code{je_number}}{character: journal entry number}
#'   \item{\code{je_posting_date}}{POSIXct: journal entry posting date}
#'   \item{\code{reason}}{character: reason for the invoice}
#'   \item{\code{status}}{character: status of the invoice}
#'   \item{\code{created}}{POSIXct: created at timestamp}
#'   \item{\code{updated}}{POSIXct: updated at timestamp}
#'   \item{\code{sender}}{character: message sender, typically an email address}
#'   \item{\code{recipient}}{character: message recipient, typically an email address}
#'   \item{\code{date_sent}}{POSIXct: date CTSI sent the message}
#'   \item{\code{date_received}}{POSIXct: date CTSIT received the email}
#'   \item{\code{script_name}}{character: the script that created this record}
#'}
#'
#' @source \url{https://github.com/ctsit/rcc.billing/issues/7}
"invoice_line_item_communications_test_data"

#' @title CTS-IT Staff
#' @description A limited set of facts about a limited number of CTS-IT staff. This
#' dataset will be used to inform default data ownership and setting billable flags
#' in the REDCap Entity / Project Ownership table.
#' @format A data frame with 5 rows and 2 variables:
#' \describe{
#'   \item{\code{redcap_username}}{character: a REDCap username. Typically this is Gatorlink ID.}
#'   \item{\code{employment_intervals}}{character: a JSON array of date intervals that defines
#'     the CTS-IT employee's employment periods in the form
#'     `[ {start: "2011-05-01", end : "2022-01-14"} ]`}
#'}
"ctsit_staff"
