#' Get a dataframe of updated billable status for project ownership projects,
#' set all projects as billable except those created by CTS-IT staff
#'
#' @param conn - A REDCap database connection, e.g. the object returned from \code{\link[redcapcustodian]{connect_to_redcap_db}}
#'
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#'
#' @return A \code{\link{dataset_diff}} containing updates to project ownerhsip's "billable" column
#' @export
#'
#' @examples
#' \dontrun{
#' conn <- redcapcustodian::connect_to_redcap_db()
#' project_ownership_changes <- update_billable_by_ownership(conn)
#' dbx::dbxUpdate(conn,
#'   table = "redcap_entity_project_ownership",
#'   records = updates$update_records,
#'   where_cols = c("id")
#' )
#' }
update_billable_by_ownership <- function(conn) {
  conn <- redcapcustodian::connect_to_redcap_db()

  actionable_projects <- dplyr::tbl(conn, "redcap_entity_project_ownership") %>%
    dplyr::filter(is.na(.data$billable)) %>%
    dplyr::collect()

  updates <- actionable_projects %>%
    dplyr::mutate(billable = dplyr::if_else(
      # TODO: ensure created between employment_intervals
      .data$username %in% rcc.billing::ctsit_staff,
      0, 1))

  billable_updates <- redcapcustodian::dataset_diff(
    source = updates,
    source_pk = "id",
    target = actionable_projects,
    target_pk = "id"
  )

  return(billable_updates)
}
