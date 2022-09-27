library(tidyverse)
library(rcc.billing)
library(lubridate)
library(DBI)
library(dotenv)
library(redcapcustodian)
library(sendmailR)

init_etl("billable_candidates")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

redcap_version <- tbl(rc_conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect(value) %>%
  pull()
# Local testing override
## redcap_version <- "11.3.4"

redcap_project_uri_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

redcap_project_uri_home_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/index.php?pid=")

redcap_project_ownership_page <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("index.php?action=project_ownership")

current_month_name <- month(floor_date(get_script_run_time(), unit = "month"), label = T) %>% as.character()
next_month_name <- month(ceiling_date(get_script_run_time(), unit = "month"), label = T, abbr = F) %>% as.character()
current_fiscal_year <- fiscal_years %>%
  filter(get_script_run_time() %within% fy_interval) %>%
  head(1) %>% # HACK: overlaps may occur on July 1, just choose the earlier year
  pull(csbt_label)

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

target_projects <- tbl(rc_conn, "redcap_projects") %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership") %>%
      filter(billable == 1),
    by = c("project_id" = "pid")
  ) %>%
  mutate(is_deleted = !is.na(date_deleted)) %>%
  mutate(project_is_mature =
           (creation_time <= local(add_with_rollback(ceiling_date(get_script_run_time(), unit = "month"), -years(1))))
         ) %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct("creation_time")

email_info <- target_projects %>%
  # join with user to ensure correct email
  left_join(
    tbl(rc_conn, "redcap_user_information") %>%
      select(username, user_firstname, user_lastname, user_email, user_email2, user_email3, user_suspended_time) %>%
      collect(),
    by = "username"
  ) %>%
  mutate(
    project_owner_firstname = coalesce(firstname, user_firstname),
    project_owner_lastname = coalesce(lastname, user_lastname),
    project_owner_full_name = paste(project_owner_firstname, project_owner_lastname),
    project_owner_email = coalesce(email, user_email, user_email2, user_email3)
  ) %>%
  mutate(link_to_project = paste0(redcap_project_uri_base, project_id)) %>%
  mutate(app_title = str_replace_all(app_title, '"', "")) %>%
  mutate(project_hyperlink = paste0("<a href=\"", paste0(redcap_project_uri_base, project_id), "\">", app_title, "</a>")) %>%
  filter(!is.na(project_owner_email))
  # uncomment for local testing
  ## mutate( project_owner_email = case_when(
  ##   !is.na(project_owner_email) ~ "your_primary_email",
  ##   is.na(project_owner_email) ~ "your_secondary_email",
  ##   T ~ project_owner_email
  ## )
  ## )

project_record_counts <- tbl(rc_conn, "redcap_record_counts") %>%
  filter(project_id %in% local(target_projects$project_id)) %>%
  select(project_id, record_count) %>%
  collect()

billable_candidates <- email_info %>%
  mutate(app_title = writexl::xl_hyperlink(paste0(redcap_project_uri_home_base, project_id), app_title)) %>%
  left_join(project_record_counts, by = "project_id") %>%
  mutate(creation_month = month(creation_time)) %>%
  mutate(sequestered = as.numeric(sequestered)) %>%
  mutate(project_is_mature = as.numeric(project_is_mature)) %>%
  mutate(is_deleted = as.numeric(is_deleted)) %>%
  mutate(sequestered = if_else(is.na(sequestered), 0, sequestered)) %>%
  select(
    project_owner_email,
    project_owner_full_name,
    user_suspended_time,
    project_id,
    project_creation_time = creation_time,
    creation_month,
    project_is_mature,
    sequestered,
    is_deleted,
    record_count,
    last_logged_event,
    project_title = app_title
  )

basename = "billable_candidates"
billable_candidates_filename <- paste0(basename, "_", format(get_script_run_time(), "%Y%m%d%H%M%S"), ".xlsx")
billable_candidates_full_path <- here::here("output", billable_candidates_filename)
billable_candidates %>% writexl::write_xlsx(billable_candidates_full_path)

message = "The attached file describes the REDCap project invoice line items we expect to be sent out on the first of next month."
redcapcustodian::send_email(
  email_body = list(message, sendmailR::mime_part(billable_candidates_full_path, name = billable_candidates_filename)),
  email_subject = "Impending REDCap project invoice line items",
  email_to = Sys.getenv("EMAIL_TO"),
  email_cc = paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL")),
  email_from = "ctsit-redcap-reply@ad.ufl.edu"
)

log_job_success("Sent billing candidates")
