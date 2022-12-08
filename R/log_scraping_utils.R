#' Get bad email adresses from the billing log
#'
#' @return A vector of email adresses that resulted in an error in the rcc_job_log table
#' @examples
#'
#' \dontrun{
#' bad_recipients <- get_bad_emails_from_log()
#' }
#' @export
get_bad_emails_from_log <- function() {
  log_conn <- redcapcustodian::get_package_scope_var("log_con")

  job_log <- tbl(log_conn, "rcc_job_log") %>%
    dplyr::filter(str_detect(.data$job_summary_data, "Recipient address rejected: User unknown in virtual alias table")) %>%
    collect()

  result <- job_log %>%
    dplyr::arrange(dplyr::desc(.data$id)) %>%
    dplyr::pull(.data$job_summary_data) %>%
    utils::head(1) %>%
    jsonlite::fromJSON()

  bad_recipients <- result$billing_alert_log %>%
    ## filter(str_detect(error_message, "Recipient address rejected: User unknown in virtual alias table")) %>%
    select(email = recipient) %>%
    distinct()

  return(bad_recipients)
}
