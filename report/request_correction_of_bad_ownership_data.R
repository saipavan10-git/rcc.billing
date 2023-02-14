library(tidyverse)
library(rcc.billing)
library(lubridate)
library(REDCapR)
library(dotenv)
library(redcapcustodian)
library(sendmailR)
library(tableHTML)
library(DBI)
library(RMariaDB)
library(rcc.ctsit)

init_etl("request_correction_of_bad_ownership_data")

rc_conn <- connect_to_redcap_db()

rcp <- tbl(rc_conn, "redcap_projects")
rcpo <- tbl(rc_conn, "redcap_entity_project_ownership")
rcur <- tbl(rc_conn, "redcap_user_rights")
rcui <- tbl(rc_conn, "redcap_user_information")

redcap_version <- tbl(rc_conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect(value) %>%
  pull()
# Local testing overrides
## redcap_version <- "11.3.4"
## your_email1 <- "foo@bar.edu"
## your_email2 <- "foo@bar.com"

redcap_project_uri_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

redcap_project_uri_home_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/index.php?pid=")

redcap_project_ownership_page <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("index.php?action=project_ownership")

projects_with_unresolvable_ownership_issues <- rcp %>%
  inner_join(rcpo, by = c("project_id" = "pid")) %>%
  filter(billable == 1) %>%
  filter(is.na(date_deleted)) %>%
  filter(is.na(email) || email == "") %>%
  filter(is.na(firstname) || firstname == "") %>%
  filter(is.na(lastname) || lastname == "") %>%
  # NOTE: as of this PR this filter results in an empty set
  ## filter(is.na(username) || username == "") %>%
  collect() %>%
  mutate_columns_to_posixct("updated") %>%
  filter(get_script_run_time() - ddays(120) > updated)

## HACK: inject a "sequestered today" for local testing
## hack1 <- projects_with_unresolvable_ownership_issues %>%
##   tail(1) %>%
##   mutate(
##     project_name = "hack1",
##     sequestered = 1,
##     updated = get_script_run_time()
##   )
## projects_with_unresolvable_ownership_issues <- projects_with_unresolvable_ownership_issues %>%
##   head(5) %>%
##   rbind(hack1)

# ["foo", "", NA, "bar", NA] -> "foo,bar"
# https://stackoverflow.com/a/49201394/7418735
collapse_with_omit_blank <- function(x, sep = " ") paste(x[!is.na(x) & x != ""], collapse = sep)

project_contact_information <- rcur %>%
  filter(project_id %in% local(projects_with_unresolvable_ownership_issues$project_id)) %>%
  inner_join(rcp, by = "project_id") %>%
  inner_join(rcui, by = "username") %>%
  select(project_id, username, starts_with("user_email"), app_title, design) %>%
  collect() %>%
  mutate(link_to_project = paste0(redcap_project_uri_base, project_id)) %>%
  mutate(app_title = str_replace_all(app_title, '"', "")) %>%
  mutate(project_hyperlink = paste0("<a href=\"", paste0(redcap_project_uri_base, project_id), "\">", app_title, "</a>")) %>%
  # turn values of all user_emailN columns into a single string, omitting blanks
  mutate(all_user_emails = apply(
    across(starts_with("user_email")),
    1,
    collapse_with_omit_blank
  )
  ) %>%
  group_by(project_id) %>%
  mutate(
    # calling collapse_with_omit_blank prevents ",foo@bar.com"
    emails = collapse_with_omit_blank(all_user_emails),
    users_with_design_rights = paste(sort(unique(username)), collapse = ", ")
  ) %>%
  select(project_id, app_title, link_to_project, project_hyperlink, emails, users_with_design_rights) %>%
  distinct(project_id, .keep_all = T) %>%
  ungroup()

send_alert_email <- function(row, email_subject = "") {
  msg <- mime_part(paste(row["email_text"]))
  ## Override content type.
  msg[["headers"]][["Content-Type"]] <- "text/html"
  # Sleep in case there is an email/s rate limiter
  Sys.sleep(1)
  result <- tryCatch(
    expr = {
      redcapcustodian::send_email(
        email_body = list(msg),
        email_subject = email_subject,
        email_to = row["emails"],
        ## email_cc = paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL")),
        email_from = "ctsit-redcap-reply@ad.ufl.edu"
      )
      my_response <- data.frame(
        recipients = row["emails"],
        project = row["project_id"],
        users_with_design_rights = row["users_with_design_rights"],
        error_message = "",
        row.names = NULL
      )
      return(my_response)
    },
    error = function(error_message) {
    my_error <- data.frame(
        recipients = row["emails"],
        project = row["project_id"],
        users_with_design_rights = row["users_with_design_rights"],
        error_message = as.character(error_message),
        row.names = NULL
      )
      return(my_error)
    }
  )
  return(result)
}

###############################################################################
#                            Please Fix processing                            #
###############################################################################

# these are projects that had their ownership data erased in the past 3 months
please_fix <- projects_with_unresolvable_ownership_issues %>%
  filter(is.na(sequestered) || sequestered == 0) %>%
  filter(get_script_run_time() - dmonths(3) > updated)

please_fix_email_template_text <- str_replace( "<p>Hello,<p>
You are being contacted about <app_title>,
<p><a href=\"<redcap_project_ownership_page>\">REDCap Project Ownership</a>.</p>
<users_with_design_rights>
<link_to_project>,",
"<redcap_project_ownership_page>",
redcap_project_ownership_page)

please_fix_contacts <- project_contact_information %>%
  filter(project_id %in% please_fix$project_id) %>%
  select(project_id, app_title, link_to_project, project_hyperlink, emails, users_with_design_rights)

please_fix_contacts %>%
  select(project_id, emails)

please_fix_email_df <- please_fix_contacts %>%
  rowwise() %>%
  mutate(email_text =
           str_replace(please_fix_email_template_text, "<app_title>", app_title) %>%
           str_replace("<link_to_project>", link_to_project) %>%
           str_replace("<users_with_design_rights>", users_with_design_rights)
         )
  # uncomment for local testing
  ## mutate(emails = paste(your_email1, your_email2, sep = " "))

send_please_fix_alert_email <- function(row) {
  return(send_alert_email(row, email_subject = "Please Fix"))
}

please_fix_log <- apply(
  please_fix_email_df,
  MARGIN = 1,
  FUN = send_please_fix_alert_email
) %>%
  # turn list into dataframe
  do.call("rbind", .) %>%
  mutate(reason = "please_fix")

###############################################################################
#                         Sequestered Today processing                        #
###############################################################################

# these are projects that were almost certainly sequestered this morning by sequester_orphans
sequestered_today <- projects_with_unresolvable_ownership_issues %>%
  filter(!is.na(sequestered) & sequestered == 1) %>%
  # updated this morning (i.e. today)
  filter(date(get_script_run_time()) == date(updated))

sequestered_today_email_template_text <- str_replace( "<p>Hello,<p>
You are being contacted about <app_title>,
<p><a href=\"<redcap_project_ownership_page>\">REDCap Project Ownership</a>.</p>
<link_to_project>,",
"<redcap_project_ownership_page>",
redcap_project_ownership_page)

sequestered_today_contacts <- project_contact_information %>%
  filter(project_id %in% sequestered_today$project_id) %>%
  select(project_id, app_title, link_to_project, project_hyperlink, emails)

sequestered_today_email_df <- sequestered_today_contacts %>%
  rowwise() %>%
  mutate(email_text =
           str_replace(sequestered_today_email_template_text, "<app_title>", app_title) %>%
           str_replace("<link_to_project>", link_to_project)
         ) %>%
  ungroup()
  # uncomment for local testing
  ## mutate(emails = paste(your_email1, your_email2, sep = " "))

send_sequestered_today_alert_email <- function(row) {
  return(send_alert_email(row, email_subject = "Sequestered Today"))
}

sequestered_today_log <- apply(
  sequestered_today_email_df,
  MARGIN = 1,
  FUN = send_sequestered_today_alert_email
  ) %>%
  # turn list into dataframe
  do.call("rbind", .) %>%
  mutate(reason = "sequestered_today")

###############################################################################
#                             Cleanup and logging                             #
###############################################################################


activity_log <- bind_rows(
  please_fix_log,
  sequestered_today_log
)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rc_conn)

Create initial version of request_correction_of_bad_ownership_data report
