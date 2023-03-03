library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)
library(sendmailR)
library(tableHTML)

init_etl("sequester_orphans")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

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

# identify orphans created in the current month
orphaned_projects <- get_orphaned_projects(
  rc_conn = rc_conn,
  rcc_billing_conn = rcc_billing_conn,
  months_previous = 0
)

uoi_pids <- orphaned_projects %>%
  filter(reason == "unresolvable_ownership_issues") %>%
  pull(project_id)

# If you want to manually sequester a set of projects,
#   set their project_ids in a tibble.
# orphaned_projects <- tribble(
#   ~project_id,
#  9314,
#  11039,
#  11041
# )

email_info <-
  tbl(rc_conn, "redcap_projects") %>%
  # NOTE: Emails for unresolvable issues are handled in request_correction_of_bad_ownership_data
  filter(!project_id %in% local(uoi_pids)) %>%
  filter(project_id %in% local(orphaned_projects$project_id)) %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership"),
    by = c("project_id" = "pid")
  )  %>%
  # join with user to ensure correct email
  left_join(
    tbl(rc_conn, "redcap_user_information") %>%
      select(username, user_firstname, user_lastname, user_email, user_email2, user_email3, user_suspended_time),
    by = "username"
  ) %>%
  mutate(
    project_owner_firstname = coalesce(firstname, user_firstname),
    project_owner_lastname = coalesce(lastname, user_lastname),
    project_owner_full_name = paste(project_owner_firstname, project_owner_lastname),
    project_owner_email = coalesce(email, user_email, user_email2, user_email3)
  ) %>%
  mutate(link_to_project = paste0(redcap_project_uri_base, project_id)) %>%
  collect() %>%
  mutate(app_title = str_replace_all(app_title, '"', "")) %>%
  mutate(project_hyperlink = paste0("<a href=\"", paste0(redcap_project_uri_base, project_id), "\">", app_title, "</a>")) %>%
  filter(!is.na(project_owner_email)) %>%
  select(project_owner_email, project_owner_full_name, user_suspended_time, project_id, app_title, project_hyperlink, creation_time, last_logged_event)

# Sequester the orphans
result <- sequester_projects(
  conn = rc_conn,
  project_ids = orphaned_projects$project_id
)

# email every owner who had a project sequestered
email_template_text <- str_replace( "<p><owner_name>,<p>
<p>The REDCap projects listed here have been sequestered to help CTS-IT assess if they are still needed. These projects were sequestered because they appear to have been abandoned. We are happy to unsequester the project if that assessment is incorrect. If you still need access to them, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a> telling us which project(s) need to be unsequestered. These are your projects sequestered today:</p>

<table_of_owned_projects_due_to_be_billed>

<p>If you take no action, these project(s) will remain inaccessible. If they are still sequestered one year from now, they will be deleted at that time.</p>

<p>If a project is still in use, but you are no longer responsible for it, you can change the ownership to the new owner after it is unsequestered. There is a guide to assist you in this process at <a href=\"https://www.ctsi.ufl.edu/files/2018/04/How-to-Update-Project-Ownership-Info-PI-Information-and-IRB-Number.pdf\">Update Project Ownership, PI Name & Email and IRB Number in REDCap</a>.</p>

<p>If you are curious to review the other projects you own, you can see all of them at <a href=\"<redcap_project_ownership_page>\">REDCap Project Ownership</a>.</p>

<p>If you want more information about project sequestration or the REDCap annual billing policy, please review our <a href=\"https://redcap.ctsi.ufl.edu/ctsit/redcap_project_billing_faq.pdf\">FAQ</a> about the billing policy.</p>

<p>Regards,</p>
<p>REDCap Support</p>

<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>",
                                    "<redcap_project_ownership_page>", redcap_project_ownership_page)
email_tables <- email_info %>%
  filter(project_id %in% result$project_ids_updated) %>%
  select(-c(creation_time, last_logged_event, user_suspended_time)) %>%
  group_by(project_owner_email) %>%
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
  distinct(project_owner_email, detail_table, .keep_all = T)

email_df <- email_tables %>%
  rowwise() %>%
  mutate(email_text =
           str_replace(email_template_text, "<owner_name>", project_owner_full_name) %>%
           str_replace("<table_of_owned_projects_due_to_be_billed>", detail_table) %>%
           htmltools::HTML()
  ) %>%
  ungroup()

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
        email_subject = "REDCap projects sequestered",
        email_to = row["project_owner_email"],
        email_cc = paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL")),
        email_from = "ctsit-redcap-reply@ad.ufl.edu"
      )
      my_response <- data.frame(
        recipient = row["project_owner_email"],
        projects = row["projects"],
        error_message = "",
        row.names = NULL
      )
      return(my_response)
    },
    error = function(error_message) {
      my_error <- data.frame(
        recipient = row["project_owner_email"],
        projects = row["projects"],
        error_message = as.character(error_message),
        row.names = NULL
      )
      return(my_error)
    }
  )
  return(result)
}

# send the emails here
billing_alert_log_list <- apply(email_df,
                                # %>% mutate(project_owner_email = "pbc@ufl.edu"),
                                MARGIN = 1,
                                FUN = send_billing_alert_email
)

billing_alert_log <- do.call("rbind", billing_alert_log_list)

activity_log <- append(
  result,
  lst(billing_alert_log, orphaned_projects)
)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rc_conn)
dbDisconnect(rcc_billing_conn)
