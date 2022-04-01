#' Sample data for service_type table
#'
#' @format
#' \describe{
#'   \item{service_type_code}{a numeric code that uniquely identifies the service_type}
#'   \item{service_type}{short name describing the service_type, in snake case}
#'   \item{cost}{price for one unit of the service, in US dollars}
#'   \item{billing_frequency}{frequency at which this service ir billed, in months}
#' }
#'
#' @source \url{https://github.com/ctsit/rcc.billing/issues/1}
"service_type_test_data"
