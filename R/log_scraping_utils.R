#' Get bad email addresses from the rcc.billing log
#'
#' @param age_of_oldest_log_in_days - an optional parameter indicating
#'        age in days of the oldest log fie to be read. Defaults to 8 days.
#' @return A vector of email addresses that resulted in an error in the rcc_job_log table
#'
#' @importFrom rlang .data
#'
#' @export
#' @examples
#'
#' \dontrun{
#' bad_recipients <- get_bad_emails_from_log(age_of_oldest_log_in_days = 31)
#' }
get_bad_emails_from_log <- function(age_of_oldest_log_in_days = 8) {
  log_conn <- redcapcustodian::get_package_scope_var("log_con")

  job_log <- dplyr::tbl(log_conn, "rcc_job_log") |>
    dplyr::filter(stringr::str_detect(
      .data$job_summary_data,
      "Recipient address rejected: User unknown in virtual alias table"
    )) |>
    dplyr::filter(.data$script_name %in% c("warn_owners_of_impending_bill", "sequester_orphans")) |>
    dplyr::filter(.data$log_date > local(redcapcustodian::get_script_run_time() -
      lubridate::ddays(age_of_oldest_log_in_days))) |>
    dplyr::collect()

  if (nrow(job_log) > 0) {
    job_summaries <- job_log |>
      dplyr::arrange(dplyr::desc(.data$id)) |>
      dplyr::pull(.data$job_summary_data)

    billing_alert_logs <- dplyr::tribble(
      ~recipient, ~projects, ~error_message,
      "asdf", "asdf", "asdf"
    ) |> dplyr::filter(F)

    for (job in seq(1, length(job_summaries))) {
      job_summary <- jsonlite::fromJSON(job_summaries[job])$billing_alert_log
      message("converting job ", job)
      billing_alert_logs <- dplyr::bind_rows(billing_alert_logs, job_summary)
    }

    bad_recipients <- billing_alert_logs |>
      dplyr::filter(stringr::str_detect(
        .data$error_message,
        "Recipient address rejected: User unknown in virtual alias table"
      )) |>
      dplyr::select(email = "recipient") |>
      dplyr::distinct()
  } else {
    bad_recipients <- dplyr::tribble(
      ~email, "asdf"
    ) |> dplyr::filter(F)
  }

  return(bad_recipients)
}
