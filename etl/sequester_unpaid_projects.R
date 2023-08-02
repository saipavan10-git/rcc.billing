library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)
library(sendmailR)
library(tableHTML)

init_etl("sequester_unpaid_projects")

if (day(get_script_run_time()) > 7) {
  activity_log <- list(
    error = tribble(~message, "Exiting because this is not one of the first 7 days of the month")
  )
  redcapcustodian::log_job_failure(jsonlite::toJSON(activity_log))
  quit()
}

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

non_deleted_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  select(project_id) %>%
  collect(project_id) %>%
  pull(project_id)

non_completed_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(completed_time)) %>%
  select(project_id) %>%
  collect(project_id) %>%
  pull(project_id)

non_sequestered_projects <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter((sequestered == 0 | is.na(sequestered)) |
          (sequestered == 1 & pid %in% local(non_completed_projects))) %>%
  select(pid) %>%
  collect() %>%
  pull(pid)

projects_to_sequester_invoices <-
  tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(status == "invoiced" & !is.na(date_sent) & service_type_code == 1) %>%
  filter(service_identifier %in% non_deleted_projects) %>%
  filter(service_identifier %in% non_sequestered_projects) %>%
  collect() %>%
  filter(get_script_run_time() - date_sent > days(101)) %>%
  mutate(project_id = as.integer(service_identifier)) %>%
  collect()

project_ids_to_sequester <- projects_to_sequester_invoices %>%
  pull(service_identifier)

email_info <-
  tbl(rc_conn, "redcap_projects") %>%
  # NOTE: Emails for unresolvable issues are handled in request_correction_of_bad_ownership_data
  filter(project_id %in% local(project_ids_to_sequester)) %>%
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
  left_join(
    projects_to_sequester_invoices,
    by = "project_id"
  ) %>%
  select(
    project_owner_email,
    project_owner_full_name,
    user_suspended_time,
    project_id,
    app_title,
    project_hyperlink,
    creation_time,
    last_logged_event,
    invoice_number
    ) %>%
  mutate(
    month_created = as.character(month(creation_time, label = T, abbr = F))
  )

email_info <- email_info %>%
  mutate(
    month_created = as.character(month(creation_time, label = T, abbr = F))
  )

# sequester the projects
result <- sequester_projects(
  conn = rc_conn,
  project_id = project_ids_to_sequester,
  reason = "unpaid_after_90_days"
)

email_template_text <- str_replace( "<p><owner_name>,</p>

<p>The REDCap project listed below has been sequestered (made inaccessible) due to an outstanding invoice that is over 90 days past due. The invoice ID <invoice_number> was sent to the project's owner, <owner_name>, in early <month_created></p>

<p>To pay for the project, please provide the payment information, i.e., chartfields,
along with the invoice ID, in an email to CTSI-SvcBillingTeam@ad.ufl.edu.</p>

<p>We are happy to unsequester the project if you will make a good faith effort to pay the outstanding invoice as soon as possible. If you still need access to this project, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L&service_type=2&project_id=<project_id>&project_name=<app_title>\">REDCap Service/Consultation Request</a> telling us which project needs to be unsequestered. Please include this project ID and project name in your request. This is the project sequestered today:</p>

<table_of_owned_projects_due_to_be_sequestered>

<p>If the project is unsequestered by the REDCap Team and a payment has not been made by the first Tuesday of the next month, the project will be resequestered.</p>

<p>If you take no action, this project will remain inaccessible. If it is still
sequestered one year from the invoice date, it will be deleted at that time. Note
that neither sequestration nor deletion voids the invoice. Once an invoice is generated,
the project PI is responsible for paying the invoice regardless of project status.</p>

<p>If this project is still in use, but you are no longer responsible for it, you can
change the ownership to the new owner AFTER it is unsequestered. There is a guide to
assist you in this process at
<a href=\"https://www.ctsi.ufl.edu/files/2018/04/How-to-Update-Project-Ownership-Info-PI-Information-and-IRB-Number.pdf\">Update Project Ownership, PI Name & Email and IRB Number in REDCap</a>.
Outstanding invoices can be transferred to the new project owner.</p>

<p>If you are curious to review the other projects you own, you can see all of them at <a href=\"<redcap_project_ownership_page>\">REDCap Project Ownership</a>.</p>

<p>If you want more information about project sequestration or the REDCap annual billing policy, please review our <a href=\"https://redcap.ctsi.ufl.edu/ctsit/redcap_project_billing_faq.pdf\">FAQ</a> about the billing policy.</p>

<p>Regards,</p>
<p>REDCap Support</p>

<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L&service_type=2&project_id=<project_id>&project_name=<app_title>\">REDCap Service/Consultation Request</a>.</p>",
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
           str_replace_all(email_template_text, "<owner_name>", project_owner_full_name) %>%
           str_replace("<table_of_owned_projects_due_to_be_sequestered>", detail_table) %>%
           str_replace_all("<app_title>", app_title) %>%
           str_replace_all("<project_id>", as.character(project_id)) %>%
           str_replace_all("<invoice_number>", invoice_number) %>%
           str_replace_all("<month_created>", month_created) %>%
           htmltools::HTML()
  ) %>%
  ungroup()

send_sequester_alert_email <- function(row) {
  msg <- mime_part(paste(row["email_text"]))
  ## Override content type.
  msg[["headers"]][["Content-Type"]] <- "text/html"
  # Sleep in case there is an email/s rate limiter
  Sys.sleep(1)
  result <- tryCatch(
    expr = {
      redcapcustodian::send_email(
        email_body = list(msg),
        email_subject = "Unpaid REDCap projects sequestered",
        email_to = if_else(
          interactive(),
          Sys.getenv("MY_EMAIL"),
          row["project_owner_email"]
        ),
        email_cc = if_else(
          interactive(),
          Sys.getenv("MY_EMAIL"),
          paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL"))
        ),
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
                                MARGIN = 1,
                                FUN = send_sequester_alert_email
)

billing_alert_log <- do.call("rbind", billing_alert_log_list)

activity_log <- append(
  result,
  billing_alert_log
)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rc_conn)
dbDisconnect(rcc_billing_conn)
