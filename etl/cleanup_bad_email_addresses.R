# Locate bad UF addresses in REDCap replace them if possible, erase them if not,
# then disable accounts with no primary email address

library(tidyverse)
library(lubridate)
library(REDCapR)
library(dotenv)
library(redcapcustodian)
library(DBI)
library(RMariaDB)
library(rcc.billing)

init_etl("cleanup_bad_email_addresses")

conn <- connect_to_redcap_db()

redcap_emails <- get_redcap_emails(conn)

# get list errors directly from an inbox
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

bad_redcap_user_emails <- redcap_emails$tall %>%
  inner_join(bounce_data, by = c("email"))

person <- dplyr::tribble(
  ~user_id, ~email,
  "foo", "bar"
) |>
  dplyr::filter(F)

redcap_email_revisions <- get_redcap_email_revisions(bad_redcap_user_emails, person)
update_n <- update_redcap_email_addresses(
  conn = conn,
  redcap_email_revisions = redcap_email_revisions,
  redcap_email_original = redcap_emails$wide
)

user_suspensions <- suspend_users_with_no_primary_email(conn)

summary_data <- list(
  email_updates_n = update_n,
  email_updates = redcap_email_revisions,
  user_suspensions = user_suspensions
)

log_job_success(jsonlite::toJSON(summary_data))

dbDisconnect(conn)
