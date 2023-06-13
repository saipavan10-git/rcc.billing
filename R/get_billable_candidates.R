#' get_billable_candidates
#'
#' Return a data frame of REDCap projects with relevant billing details
#'
#' @param rc_conn - DBI connection object to a REDCap database
#' @param rcc_billing_conn - DBI connection object to an rcc.billing database
#'
#' @return A dataframe of REDCap projects with relevant billing details
#' @export
#'
#' @examples
#' \dontrun{
#'
#' library(tidyverse)
#' library(rcc.billing)
#' library(lubridate)
#' library(DBI)
#' library(dotenv)
#' library(redcapcustodian)
#'
#' init_etl("billable_candidates")
#'
#' rc_conn <- connect_to_redcap_db()
#' rcc_billing_conn <- connect_to_rcc_billing_db()
#'
#' billable_candidates <- get_billable_candidates(rc_conn, rcc_billing_conn)
#' }
get_billable_candidates <- function(rc_conn, rcc_billing_conn) {
  redcap_version <- dplyr::tbl(rc_conn, "redcap_config") %>%
    dplyr::filter(.data$field_name == "redcap_version") %>%
    dplyr::collect(.data$value) %>%
    dplyr::pull()

  redcap_project_uri_base <- stringr::str_remove(Sys.getenv("URI"), "/api") %>%
    paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

  redcap_project_uri_home_base <- stringr::str_remove(Sys.getenv("URI"), "/api") %>%
    paste0("redcap_v", redcap_version, "/index.php?pid=")

  redcap_project_ownership_page <- stringr::str_remove(Sys.getenv("URI"), "/api") %>%
    paste0("index.php?action=project_ownership")

  current_month_name <- lubridate::month(
    lubridate::floor_date(redcapcustodian::get_script_run_time(), unit = "month"),
    label = T
  ) %>%
    as.character()
  next_month_name <- lubridate::month(
    lubridate::ceiling_date(redcapcustodian::get_script_run_time(), unit = "month"),
    label = T,
    abbr = F
  ) %>%
    as.character()
  current_fiscal_year <- rcc.billing::fiscal_years %>%
    dplyr::filter(redcapcustodian::get_script_run_time() %within% .data$fy_interval) %>%
    dplyr::slice_head(n = 1) %>% # HACK: overlaps may occur on July 1, just choose the earlier year
    dplyr::pull(.data$csbt_label)

  initial_invoice_line_item <- dplyr::tbl(rcc_billing_conn, "invoice_line_item") %>%
    dplyr::collect() %>%
    # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
    rcc.billing::mutate_columns_to_posixct(c("created", "updated"))

  recent_invoices <- initial_invoice_line_item %>%
    dplyr::filter(.data$service_type_code == 1) %>%
    dplyr::filter(redcapcustodian::get_script_run_time() - .data$created < lubridate::dyears(1)) %>%
    dplyr::mutate(service_identifier = as.numeric(.data$service_identifier)) %>%
    dplyr::select("invoice_number", "fiscal_year", "month_invoiced", "status", "service_identifier")

  target_projects <- dplyr::tbl(rc_conn, "redcap_projects") %>%
    dplyr::inner_join(
      dplyr::tbl(rc_conn, "redcap_entity_project_ownership") %>%
        dplyr::filter(.data$billable == 1),
      by = c("project_id" = "pid")
    ) %>%
    dplyr::mutate(is_deleted = !is.na(.data$date_deleted)) %>%
    dplyr::mutate(
      project_is_mature =
        (.data$creation_time <=
          local(lubridate::add_with_rollback(
            lubridate::ceiling_date(redcapcustodian::get_script_run_time(),
              unit = "month"
            ),
            -years(1)
          )))
    ) %>%
    dplyr::collect() %>%
    # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
    rcc.billing::mutate_columns_to_posixct("creation_time") %>%
    dplyr::left_join(recent_invoices,
      by = c("project_id" = "service_identifier"),
      suffix = c(".project", ".line_item")
    )

  email_info <- target_projects %>%
    # join with user to ensure correct email
    dplyr::left_join(
      dplyr::tbl(rc_conn, "redcap_user_information") %>%
        dplyr::select(
          "username",
          "user_firstname",
          "user_lastname",
          "user_email",
          "user_email2",
          "user_email3",
          "user_suspended_time",
          "user_lastlogin"
        ) %>%
        dplyr::collect(),
      by = "username"
    ) %>%
    dplyr::mutate(
      project_owner_firstname = dplyr::coalesce(.data$firstname, .data$user_firstname),
      project_owner_lastname = dplyr::coalesce(.data$lastname, .data$user_lastname),
      project_owner_full_name = paste(.data$project_owner_firstname, .data$project_owner_lastname),
      project_owner_email = dplyr::coalesce(.data$email, .data$user_email, .data$user_email2, .data$user_email3)
    ) %>%
    dplyr::mutate(link_to_project = paste0(redcap_project_uri_base, .data$project_id)) %>%
    dplyr::mutate(app_title = stringr::str_replace_all(.data$app_title, '"', "")) %>%
    dplyr::mutate(project_hyperlink = paste0(
      "<a href=\"", paste0(redcap_project_uri_base, .data$project_id), "\">",
      .data$app_title, "</a>"
    )) %>%
    dplyr::filter(!is.na(.data$project_owner_email))

  project_record_counts <- dplyr::tbl(rc_conn, "redcap_record_counts") %>%
    dplyr::filter(.data$project_id %in% local(target_projects$project_id)) %>%
    dplyr::select("project_id", "record_count") %>%
    dplyr::collect()

  billable_candidates <- email_info %>%
    dplyr::mutate(app_title = writexl::xl_hyperlink(
      paste0(redcap_project_uri_home_base, .data$project_id),
      .data$app_title
    )) %>%
    dplyr::left_join(project_record_counts, by = "project_id") %>%
    dplyr::mutate(creation_month = lubridate::month(.data$creation_time)) %>%
    dplyr::mutate(sequestered = as.numeric(.data$sequestered)) %>%
    dplyr::mutate(project_is_mature = as.numeric(.data$project_is_mature)) %>%
    dplyr::mutate(is_deleted = as.numeric(.data$is_deleted)) %>%
    dplyr::mutate(is_deleted_but_not_paid = as.numeric(
      .data$is_deleted == 1 &
        !is.na(.data$status.line_item) &
        .data$status.line_item == "sent"
    )) %>%
    dplyr::mutate(sequestered = dplyr::if_else(is.na(.data$sequestered), 0, .data$sequestered)) %>%
    dplyr::select(
      "project_owner_email",
      "project_owner_full_name",
      "user_suspended_time",
      "user_lastlogin",
      "project_id",
      project_creation_time = "creation_time",
      "creation_month",
      "project_is_mature",
      "sequestered",
      "is_deleted",
      "record_count",
      "last_logged_event",
      "is_deleted_but_not_paid",
      "invoice_number",
      "fiscal_year",
      "month_invoiced",
      "status.line_item",
      "project_irb_number",
      project_title = "app_title"
    )

  return(billable_candidates)
}
