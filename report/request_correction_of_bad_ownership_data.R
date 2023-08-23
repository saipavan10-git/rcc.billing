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

# For testing, run the script tests/testhat/request_correction_of_bad_ownership/load_test_data.R
#   That script loads data generated and saved by tests/testhat/request_correction_of_bad_ownership/make_test_data.R
# Then run this line:
# rc_conn <- conn
# ...and the rcui line below

rcp <- tbl(rc_conn, "redcap_projects")
rcpo <- tbl(rc_conn, "redcap_entity_project_ownership")
rcur <- tbl(rc_conn, "redcap_user_rights")
rcui <- tbl(rc_conn, "redcap_user_information")
# Run the line below when testing to make email go to you instead of bouncing
# rcui <- tbl(rc_conn, "redcap_user_information") %>%
#    mutate(across(starts_with("user_email"), ~ if_else(is.na(.), ., paste0(Sys.getenv("USER"), "@ufl.edu"))))

redcap_version <- tbl(rc_conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect(value) %>%
  pull()

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
  filter(is.na(username) || username == "") %>%
  collect() %>%
  mutate_columns_to_posixct("updated") %>%
  filter(get_script_run_time() - ddays(120) < updated)

# ["foo", "", NA, "bar", NA] -> "foo,bar"
# https://stackoverflow.com/a/49201394/7418735
collapse_with_omit_blank <- function(x, sep = " ") paste(x[!is.na(x) & x != ""], collapse = sep)

project_contact_information <- rcur %>%
  filter(project_id %in% local(projects_with_unresolvable_ownership_issues$project_id)) %>%
  inner_join(rcp, by = "project_id") %>%
  inner_join(rcui, by = "username") %>%
  select(project_id, username, user_firstname, user_lastname, starts_with("user_email"), app_title, design) %>%
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
  filter(is.na(sequestered) | sequestered == 0) %>%
  filter(get_script_run_time() - dmonths(3) < updated)

please_fix_email_template_text <- "<p>Hello,</p>
<p>The REDCap project listed below has been identified as having out-of-date PI or owner information. Emails to PI/Owner listed on this project have been bouncing. We have erased those bad emails addresses, but a correct email address is needed to address billing issues. Please go into the Main Project Settings and update the PI/ownership information at <project_hyperlink>. </p>

<p>If this is not corrected within the next 30 days, the project will be sequestered and you will no longer have access to it. If the project is still sequestered one year from now, the project will be deleted at that time.</p>

<p>We are sending this email to everyone who has design rights on this REDCap project. Please confer with them if you are unsure who the Owner/PI is. Those people are:</p>

<users_with_design_rights>

<p>If you no longer need or use this REDCap project, we encourage you to export your project design and your project data, and delete the project. To delete a project, access its project link above then follow the instructions in <a href=\"https://www.ctsi.ufl.edu/files/2018/04/How-to-Delete-a-Project-in-REDCap.pdf\">Deleting a Project in REDCap</a>.</p>
<p>Instructions on how to update the PI/Owner can be found at <a href=\"https://www.ctsi.ufl.edu/files/2018/04/How-to-Update-Project-Ownership-Info-PI-Information-and-IRB-Number.pdf\">Update Project Ownership, PI Name & Email and IRB Number in REDCap</a>.</p>

<p>Regards,<br>REDCap Support</p>
<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>"

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
           str_replace("<project_hyperlink>", project_hyperlink) %>%
           str_replace("<project_id>", as.character(project_id)) %>%
           str_replace("<users_with_design_rights>", users_with_design_rights)
         )

send_please_fix_alert_email <- function(row) {
  return(send_alert_email(row, email_subject = "Please fix the PI or Ownership of this REDCap Project"))
}

if (nrow(please_fix_email_df) > 0){
please_fix_log <- apply(
  please_fix_email_df,
  MARGIN = 1,
  FUN = send_please_fix_alert_email
) %>%
  # turn list into dataframe
  do.call("rbind", .) %>%
  mutate(reason = "please_fix")
} else {
  please_fix_log <- data.frame(
    recipients = character(),
    project = character(),
    users_with_design_rights = character(),
    error_message = character(),
    reason = character(),
    stringsAsFactors = FALSE
  )
}

###############################################################################
#                         Sequestered Today processing                        #
###############################################################################

# these are projects that were almost certainly sequestered this morning by sequester_orphans
sequestered_today <- projects_with_unresolvable_ownership_issues %>%
  filter(!is.na(sequestered) & sequestered == 1) %>%
  # updated this morning (i.e. today)
  filter(date(get_script_run_time()) == date(updated))

sequestered_today_email_template_text <- "<p>Hello,<p>
<p>The REDCap project, <i><app_title></i> with project ID <i><project_id></i>, has been sequestered because it appears to have been abandoned. We are happy to unsequester the project if that assessment is incorrect. If you still need access to it, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a> telling us which project(s) need to be unsequestered. Please also provide updated PI/ownership information for the project. The PI/Owner is the person who can approve payment for fees related to this project.

<p>If you take no action, this project will remain inaccessible. If it is still sequestered one year from now, it will be deleted at that time.</p>

<p>Regards,<br>REDCap Support</p>
<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>"

sequestered_today_contacts <- project_contact_information %>%
  filter(project_id %in% sequestered_today$project_id) %>%
  select(project_id, app_title, link_to_project, project_hyperlink, emails)

sequestered_today_email_df <- sequestered_today_contacts %>%
  rowwise() %>%
  mutate(email_text =
           str_replace(sequestered_today_email_template_text, "<app_title>", app_title) %>%
           str_replace("<project_hyperlink>", project_hyperlink) %>%
           str_replace("<project_id>", as.character(project_id)) %>%
           str_replace("<link_to_project>", link_to_project)
         ) %>%
  ungroup()

send_sequestered_today_alert_email <- function(row) {
  return(send_alert_email(row, email_subject = "REDCap project sequestered"))
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
