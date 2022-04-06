#' Sample data for service_type table
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
