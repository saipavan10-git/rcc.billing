#' mutate_columns_to_posixct
#'
#' Mutates column data types to POSIXct
#'
#' @param data - a dataframe to mutate
#' @param column_names - a vector of column names to mutate
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' time_columns <- c("created", "updated")
#' mutate_columns_to_posixct(data, time_columns)
#' }
#' @export
mutate_columns_to_posixct <- function(data, column_names) {
  result <- data %>%
    dplyr::mutate(dplyr::across(
      dplyr::any_of(column_names),
      ~ as.POSIXct(., origin = "1970-01-01 00:00.00 UTC", tz = "UTC")
    ))

  return(result)
}

#' Creates a invoice_line_item data from invoice_line_item_communications_data
#'
#' @param invoice_line_item_communications, data that follows the format of invoice_line_item_communications_test_data located in R/data.R
#'
#' @returns invoice_line_item dataframe
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' invoice_line_item_df_from(invoice_line_item_communications_test_data)
#' }
#' @export
invoice_line_item_df_from <- function(invoice_line_item_communications) {
  excluded_columns <- "created"

  id_columns <- c(
    "service_identifier", "fiscal_year", "month_invoiced"
  )

  created <- invoice_line_item_communications %>%
    dplyr::arrange(created) %>%
    dplyr::distinct(.data$service_identifier, .data$fiscal_year, .data$month_invoiced, .keep_all = T) %>%
    dplyr::select(dplyr::any_of(id_columns), created)

  invoice_line_item <- invoice_line_item_communications %>%
    dplyr::arrange(dplyr::desc(created)) %>%
    dplyr::distinct(.data$service_identifier, .data$fiscal_year, .data$month_invoiced, .keep_all = T) %>%
    dplyr::select(-dplyr::any_of(excluded_columns)) %>%
    dplyr::inner_join(created, by = id_columns) %>%
    dplyr::relocate(.data$updated, .after = created) %>%
    dplyr::arrange((.data$je_number)) %>%
    dplyr::mutate(id = as.double(dplyr::row_number()))

  return(invoice_line_item)
}

#' fix_data_in_invoice_line_item
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3.
#' This allows testing in SQLite3 while production is MariaDB
#'
#' @param data - a dataframe with data from the invoice_line_item table
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' fix_data_in_invoice_line_item(invoice_line_item_test_data)
#' }
#' @export
fix_data_in_invoice_line_item <- function(data) {
  time_columns <- c(
    "created",
    "updated",
    "je_posting_date",
    "date_sent",
    "date_received"
  )

  return(mutate_columns_to_posixct(data, time_columns))
}

#' fix_data_in_invoice_line_item_communication
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3.
#' This allows testing in SQLite3 while production is MariaDB
#'
#' @param data - a dataframe with data from the invoice_line_item_communication table
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' fix_data_in_invoice_line_item_communication(invoice_line_item_communication_test_data)
#' }
#' @export
fix_data_in_invoice_line_item_communication <- function(data) {
  time_columns <- c(
    "created",
    "updated",
    "je_posting_date",
    "date_sent",
    "date_received"
  )

  return(mutate_columns_to_posixct(data, time_columns))
}

#' fix_data_in_redcap_projects
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3.
#' This allows testing in SQLite3 while production is MariaDB
#'
#' @param data - a dataframe with data from the redcap_projects table
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' fix_data_in_redcap_projects(redcap_projects_test_data)
#' }
#' @export
fix_data_in_redcap_projects <- function(data) {
  time_columns <- c(
    "creation_time",
    "production_time",
    "inactive_time",
    "completed_time",
    "date_deleted",
    "last_logged_event",
    "datamart_cron_end_date",
    "twilio_request_inspector_checked"
  )

  return(mutate_columns_to_posixct(data, time_columns))
}

#' fix_data_in_redcap_user_information
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3.
#' This allows testing in SQLite3 while production is MariaDB
#'
#' @param data - a dataframe with data from the redcap_user_information table
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' fix_data_in_redcap_user_information(redcap_user_information_test_data)
#' }
#' @export
fix_data_in_redcap_user_information <- function(data) {
  time_columns <- c(
    "user_creation",
    "user_firstvisit",
    "user_firstactivity",
    "user_lastactivity",
    "user_lastlogin",
    "user_suspended_time",
    "user_expiration",
    "user_access_dashboard_view",
    "messaging_email_ts",
    "messaging_email_queue_time"
  )

  return(mutate_columns_to_posixct(data, time_columns))
}

#' fix_data_in_redcap_log_event
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3.
#' This allows testing in SQLite3 while production is MariaDB
#'
#' @param data - a dataframe containing data from the redcap_log_event tables
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' fix_data_in_redcap_log_event(redcap_log_event_test_data)
#' }
#' @export
fix_data_in_redcap_log_event <- function(data) {
  integer64_columns <- c(
    "ts"
  )
  if (nrow(data) == 0) { # zero-row SQLite3 tables get the wrong data type on ts
    result <- data %>%
      dplyr::mutate(
        dplyr::across(
          dplyr::any_of(integer64_columns),
          bit64::as.integer64.character
        )
      )
  } else {
    result <- data
  }

  return(result)
}
