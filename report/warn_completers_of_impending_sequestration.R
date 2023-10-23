library(tidyverse)
library(rcc.billing)
library(lubridate)
library(REDCapR)
library(DBI)
library(dotenv)
library(redcapcustodian)
library(sendmailR)
library(tableHTML)

init_etl("warn_completers_of_impending_sequestration")

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

completed_times_and_completers_of_targets <- tbl(rc_conn, "redcap_projects") %>%
  select(completed_time, completed_by) %>%
  collect() %>%
  count(completed_time, completed_by) %>%
  filter(n == 1) %>%
  arrange(desc(completed_time))

target_projects <-
  tbl(rc_conn, "redcap_projects") %>%
  filter(completed_time %in% local(completed_times_and_completers_of_targets$completed_time)) %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership") %>%
      filter(billable == 1),
    by = c("project_id" = "pid")
  ) %>%
  filter(is.na(date_deleted)) %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct("creation_time")

email_info <- target_projects %>%
  # join with user to ensure correct email
  left_join(
    tbl(rc_conn, "redcap_user_information") %>%
      select(username, user_firstname, user_lastname, user_email, user_email2, user_email3, user_suspended_time) %>%
      collect(),
    by = c("completed_by" = "username")
  ) %>%
  mutate(
    project_completer_firstname = coalesce(firstname, user_firstname),
    project_completer_lastname = coalesce(lastname, user_lastname),
    project_completer_full_name = paste(project_completer_firstname, project_completer_lastname),
    project_completer_email = coalesce(email, user_email, user_email2, user_email3)
  ) %>%
  mutate(link_to_project = paste0(redcap_project_uri_base, project_id)) %>%
  mutate(app_title = str_replace_all(app_title, '"', "")) %>%
  mutate(project_hyperlink = paste0("<a href=\"", paste0(redcap_project_uri_base, project_id), "\">", app_title, "</a>")) %>%
  filter(!is.na(project_completer_email)) %>%
  select(project_completer_email, project_completer_full_name, user_suspended_time, project_id, app_title, project_hyperlink, creation_time, last_logged_event, completed_time)
  # uncomment for local testing
  ## mutate( project_completer_email = case_when(
  ##   !is.na(project_completer_email) ~ "your_primary_email",
  ##   is.na(project_completer_email) ~ "your_secondary_email",
  ##   T ~ project_completer_email
  ## )
  ## )

project_record_counts <- tbl(rc_conn, "redcap_record_counts") %>%
  filter(project_id %in% local(target_projects$project_id)) %>%
  select(project_id, record_count) %>%
  collect()

projects_to_be_sequestered <- email_info %>%
  mutate(app_title = writexl::xl_hyperlink(paste0(redcap_project_uri_home_base, project_id), app_title)) %>%
  left_join(project_record_counts, by = "project_id") %>%
  select(project_completer_email, project_completer_full_name, user_suspended_time, project_id, creation_time, completed_time, record_count, last_logged_event, app_title)
basename = "projects_to_be_sequestered"
projects_to_be_sequestered_filename <- paste0(basename, "_", format(get_script_run_time(), "%Y%m%d%H%M%S"), ".xlsx")
projects_to_be_sequestered_full_path <- here::here("output", projects_to_be_sequestered_filename)
projects_to_be_sequestered %>% writexl::write_xlsx(projects_to_be_sequestered_full_path)

message = "The attached file describes the REDCap projects we expect to sequester on 2023-01-30."
redcapcustodian::send_email(
  email_body = list(message, sendmailR::mime_part(projects_to_be_sequestered_full_path, name = projects_to_be_sequestered_filename)),
  email_subject = "Impending REDCap project sequestrations",
  email_to = Sys.getenv("EMAIL_TO"),
  email_cc = paste(Sys.getenv("REDCAP_BILLING_L")),
  # email_to = "pbc@ufl.edu",
  email_from = "ctsit-redcap-reply@ad.ufl.edu"
)


email_template_text <- "<p><owner_name>,<p>
<p>This REDCap project is marked as completed in the CTSI REDCap system:</p>

<table_of_projects_to_be_sequestered>

<p>That status is no longer supported in our system. As it looks like you are done with this project, we are going to sequester it on 1/30 unless you ask us not to. If the project is not sequestered, you will be expected to pay the normal $130 annual fee to keep it on the REDCap system when it comes due. Sequestered projects will be automatically deleted after one year in sequestration.</p>

<p>Regards,</p>
<p>REDCap Support</p>

<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>"

email_tables <- email_info %>%
  select(-c(creation_time, last_logged_event, user_suspended_time)) %>%
  group_by(project_completer_email) %>%
  mutate(projects = paste(project_id, collapse = ", ")) %>%
  nest() %>%
  mutate(detail_table = map(data, function(df) {
    df %>%
      select(
        "Project ID" = project_id,
        "Name" = project_hyperlink) %>%
      tableHTML(rownames = FALSE, escape = FALSE) %>%
      as.character()
  }
  )) %>%
  unnest(cols = c(data, detail_table)) %>%
  ungroup() %>%
  distinct(project_completer_email, detail_table, .keep_all = T)

email_df <- email_tables %>%
  rowwise() %>%
  mutate(email_text =
           str_replace(email_template_text, "<owner_name>", project_completer_full_name) %>%
           str_replace("<table_of_projects_to_be_sequestered>", detail_table) %>%
           htmltools::HTML()
         ) %>%
  ungroup()
  # TEST_METHOD_B: uncomment to test.
  # Set the email address to your own
  # %>% mutate(project_completer_email = "YOUR_EMAIL_ADDRESS_HERE") %>% slice_sample(n=3)

send_billing_alert_email <- function(row) {
  msg <- mime_part(paste(row["email_text"]))
  ## Override content type.
  msg[["headers"]][["Content-Type"]] <- "text/html"
  # Sleep in case there is an email/s rate limiter
  Sys.sleep(1)
  result <- tryCatch(
    expr = {
      redcapcustodian::send_email(
        email_body = list(msg),
        email_subject = "Impending sequestration",
        email_to = row["project_completer_email"],
        email_cc = paste(Sys.getenv("REDCAP_BILLING_L")),
        # email_to = "pbc@ufl.edu",
        email_from = "ctsit-redcap-reply@ad.ufl.edu"
      )
      my_response <- data.frame(
        recipient = row["project_completer_email"],
        projects = row["projects"],
        error_message = "",
        row.names = NULL
      )
      return(my_response)
    },
    error = function(error_message) {
    my_error <- data.frame(
        recipient = row["project_completer_email"],
        projects = row["projects"],
        error_message = as.character(error_message),
        row.names = NULL
      )
      return(my_error)
    }
  )
  return(result)
}

billing_alert_log_list <- apply(email_df,
  MARGIN = 1,
  FUN = send_billing_alert_email
)

billing_alert_log <- do.call("rbind", billing_alert_log_list)

activity_log <- list(
  billing_alert_log = billing_alert_log
)

log_job_success(jsonlite::toJSON(activity_log))
