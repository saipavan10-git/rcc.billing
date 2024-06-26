#' Get important boolean flags that describe projects
#'
#' @param rc_conn A DBI connection object to a REDCap Database on a system that uses the UF extensions to REDCap Project Ownership
#'
#' @return a dataframe of boolean flags for every REDCap project in the redcap_projects table
#' @export
#'
#' @examples
#' \dontrun{
#'   get_project_flags(rc_conn)
#' }
get_project_flags <- function(rc_conn) {
  dplyr::tbl(rc_conn, "redcap_projects") |>
    dplyr::inner_join(
      dplyr::tbl(rc_conn, "redcap_entity_project_ownership"),
      by = c("project_id" = "pid")
    ) |>
    dplyr::mutate(deleted = !is.na(.data$date_deleted)) |>
    dplyr::select("project_id", "deleted", "sequestered", "billable") |>
    dplyr::collect() |>
    dplyr::mutate(deleted = as.numeric(.data$deleted)) |>
    dplyr::mutate(sequestered = dplyr::if_else(is.na(.data$sequestered), 0, .data$sequestered)) |>
    dplyr::mutate(billable = dplyr::if_else(is.na(.data$billable), 1, .data$billable))
}
