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

