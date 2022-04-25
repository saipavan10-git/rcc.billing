#' Creates a invoice_line_item df from invoice_line_item_communications_df
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

#' fix_data_in_redcap_user_information
#'
#' Fixes column data types that can vary between MySQL/MariaDB and SQLite3. This allows testing in SQLite while production is MariaDB
#'
#' @param data - a dataframe
#'
#' @return The input dataframe with revised data types
#' @export
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @examples
#' \dontrun{
#' invoice_line_item_df_from(invoice_line_item_communications_test_data)
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

    result <- data %>%
        dplyr::mutate(dplyr::across(
            dplyr::any_of(time_columns),
            ~ as.POSIXct(., origin = "1970-01-01 00:00.00 UTC", tz = "UTC")
        ))

    return(result)
}
