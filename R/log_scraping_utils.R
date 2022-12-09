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
    dplyr::filter(script_name %in% c("warn_owners_of_impending_bill", "sequester_orphans")) %>%
    filter(log_date > local(get_script_run_time() - ddays(31))) %>%
    collect()

  if (nrow(job_log) > 0) {
    job_summaries <- job_log %>%
      dplyr::arrange(dplyr::desc(.data$id)) %>%
      dplyr::pull(.data$job_summary_data)

    billing_alert_logs <- tribble(
      ~recipient, ~projects, ~error_message,
      "asdf", "asdf", "asdf"
    ) %>% filter(F)

    for (job in seq(1,length(job_summaries))) {
      job_summary <- jsonlite::fromJSON(job_summaries[job])$billing_alert_log
      message("converting job ", job)
      billing_alert_logs <- bind_rows(df, job_summary)
    }

    bad_recipients <- billing_alert_logs %>%
      filter(str_detect(error_message, "Recipient address rejected: User unknown in virtual alias table")) %>%
      select(email = recipient) %>%
      distinct()
  } else {
    bad_recipients <- tribble(
      ~email, "asdf"
    ) %>% filter(F)
  }

  return(bad_recipients)
}
