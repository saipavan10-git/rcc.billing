library(tidyverse)
library(rcc.billing)
library(lubridate)
library(REDCapR)
library(DBI)
library(dotenv)
library(redcapcustodian)
library(sendmailR)
library(tableHTML)

init_etl("remind_owners_to_review_ownership")

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

target_projects <- tbl(rc_conn, "redcap_projects") %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership"),
    by = c("project_id" = "pid")
  ) %>%
  filter(is.na(date_deleted)) %>%
  filter(is.na(completed_time)) %>%
  # project at least 1 year old
  filter(creation_time <= local(add_with_rollback(ceiling_date(get_script_run_time(), unit = "month"), -months(5)))) %>%
  # birthday this month, comment this line out for consistent local testing
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
  filter(!is.na(project_owner_email)) %>%
  select(project_owner_email, project_owner_full_name, user_suspended_time, project_id, app_title, project_hyperlink, creation_time, last_logged_event)
  # uncomment for local testing
  ## mutate( project_owner_email = case_when(
  ##   !is.na(project_owner_email) ~ "your_primary_email",
  ##   is.na(project_owner_email) ~ "your_secondary_email",
  ##   T ~ project_owner_email
  ## )
  ## )

email_template_text <- "<p><owner_name>,<p>
<p>You are listed as the owner or Principal Investigator (PI) on the REDCap projects listed here:

<table_of_owned_projects_due_to_be_billed>

<p>If a project is still in use, but you are no longer responsible for it, please change the ownership data and/or PI data to reflect the current  ownership and research details by clicking any of the project links above. There is a guide to assist you in this process at <a href=\"https://www.ctsi.ufl.edu/wordpress/files/2023/07/How-to-Update-Change-Project-Ownership-Info-PI-Name-and-IRB-Number.pdf\">Update Project Ownership, PI Name & Email and IRB Number in REDCap</a>.</p>

<p>If the project is no longer is in use, we encourage you to export your project design and your project data, and delete the project. To delete a project, access its project link above then follow the instructions in <a href=\"https://www.ctsi.ufl.edu/wordpress/files/2023/07/How-to-Delete-a-Project-in-REDCap_new.pdf\">Deleting a Project in REDCap</a>.</p>

<h3>Why are we asking?</h3>

<p>The UF REDCap team uses the PI and Ownership data to decide who should get the annual bill for services. This should be someone with a valid email address at UF who can approve the payment for the project.</p>

<p>Correct ownership and IRB data is the best way to assure invoices are routed correctly. Deleting unused projects is the best way to assure no one is invoiced for projects no one wants.</p>

<p>Regards,</p>
<p>REDCap Support</p>

<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>"

email_tables <- email_info %>%
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
  ungroup() %>%
  # TEST_METHOD_B: uncomment to test.
  # Set the email address to your own
  # mutate(project_owner_email = Sys.getenv("MY_EMAIL")) %>% slice_sample(n=3) %>%
  select(everything())

send_html_email <- function(row) {
  recipient <- row["project_owner_email"]
  email_cc <- ""
  email_from <- "ctsit-redcap-reply@ad.ufl.edu"
  email_subject <- "Quarterly review of your REDCap projects"

  msg <- mime_part(paste(row["email_text"]))
  ## Override content type.
  msg[["headers"]][["Content-Type"]] <- "text/html"
  email_body <- list(msg)

  # Sleep in case there is an email/s rate limiter
  Sys.sleep(1)

  result <- tryCatch(
    expr = {
      redcapcustodian::send_email(
        email_body = email_body,
        email_subject = email_subject,
        email_to = recipient,
        email_cc = email_cc,
        email_from = email_from
      )
      my_response <- data.frame(
        recipient = recipient,
        projects = row["projects"],
        error_message = "",
        row.names = NULL
      )
      return(my_response)
    },
    error = function(error_message) {
    my_error <- data.frame(
        recipient = recipient,
        projects = row["projects"],
        error_message = as.character(error_message),
        row.names = NULL
      )
      return(my_error)
    }
  )
  return(result)
}

email_log_list <- apply(email_df,
  MARGIN = 1,
  FUN = send_html_email
)

email_log <- do.call("rbind", email_log_list)

activity_log <- list(
  email_log = email_log
)

log_job_success(jsonlite::toJSON(activity_log))
