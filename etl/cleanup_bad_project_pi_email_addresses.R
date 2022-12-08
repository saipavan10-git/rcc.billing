library(tidyverse)
library(lubridate)
library(REDCapR)
library(dotenv)
library(redcapcustodian)
library(rcc.billing)
library(DBI)
library(RMariaDB)

init_etl("cleanup_bad_project_pi_email_addresses")

rc_conn <- connect_to_redcap_db()

redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  collect()

pi_emails <- redcap_projects %>%
  select(project_pi_email) %>%
  filter(!is.na(project_pi_email)) %>%
  distinct()

bounce_data_from_listserv <-
  tryCatch(
    expr = {
      get_bad_emails_from_listserv_digest(
        username = Sys.getenv("IMAP_USERNAME"),
        password = Sys.getenv("IMAP_PASSWORD"),
        messages_since_date = now(tzone = "America/New_York") - ddays(7)
      )
    },
    error = function(error_msg) {
      warning("get_bad_emails_from_listserv_digest failed, returning an empty dataframe")
      return(
        data.frame(email = c("")) %>%
          filter(FALSE)
      )
    }
  )

bounce_data_from_individual_bounces <-
  tryCatch(
    expr = {
      get_bad_emails_from_individual_emails(
        username = Sys.getenv("IMAP_USERNAME"),
        password = Sys.getenv("IMAP_PASSWORD"),
        messages_since_date = now(tzone = "America/New_York") - ddays(7)
      )
    },
    error = function(error_msg) {
      warning("get_bad_emails_from_individual_emails failed, returning an empty dataframe")
      return(
        data.frame(email = c("")) %>%
          filter(FALSE)
      )
    }
  )

bad_emails_from_log_data <- get_bad_emails_from_log()

bounce_data <-
  bind_rows(
    bounce_data_from_listserv,
    bounce_data_from_individual_bounces,
    bad_emails_from_log_data
  ) %>%
  distinct(email)

bad_pi_emails <- pi_emails %>%
  inner_join(
    bounce_data,
    by = c("project_pi_email" = "email")
  ) %>%
  pull(project_pi_email)

bad_pi_entries <- redcap_projects %>%
  filter(project_pi_email %in% local(bad_pi_emails)) %>%
  collect() %>%
  mutate(project_pi_email = "")

# Update Project PI Email with one sourced from their user entry ##############
bad_pi_user_info <- tbl(rc_conn, "redcap_user_information") %>%
  select(username, user_email) %>%
  filter(username != "") %>%
  filter(username %in% local(bad_pi_entries$project_pi_username)) %>%
  filter(!user_email %in% local(bad_pi_emails)) %>%
  collect()

bad_pi_updates <- bad_pi_entries %>%
  left_join(
    bad_pi_user_info,
    by = c("project_pi_username" = "username")
  ) %>%
  mutate(project_pi_email = if_else(is.na(user_email), "", user_email)) %>%
  # Limit data set to improve performance of sync and minimize log entry
  select(project_id, project_pi_email)

project_pi_sync_activity <- redcapcustodian::sync_table_2(
  conn = rc_conn,
  table_name = "redcap_projects",
  source = bad_pi_updates,
  source_pk = "project_id",
  target = redcap_projects,
  target_pk = "project_id"
)

summary_data <- list(
  pi_email_update_n = project_pi_sync_activity$update_n,
  pi_email_updates = project_pi_sync_activity$update_records
)

log_job_success(jsonlite::toJSON(summary_data))

dbDisconnect(rc_conn)
