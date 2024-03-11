library(tidyverse)
library(rcc.billing)
library(lubridate)
library(REDCapR)
library(DBI)
library(dotenv)
library(redcapcustodian)
library(sendmailR)
library(tableHTML)

init_etl("warn_owners_of_impending_bill")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

redcap_version <- tbl(rc_conn, "redcap_config") %>%
  filter(field_name == "redcap_version") %>%
  collect() %>%
  pull(value)
# Local testing override
## redcap_version <- "11.3.4"

redcap_project_uri_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/ProjectSetup/index.php?pid=")

redcap_project_uri_home_base <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("redcap_v", redcap_version, "/index.php?pid=")

redcap_project_ownership_page <- str_remove(Sys.getenv("URI"), "/api") %>%
  paste0("index.php?action=project_ownership")

next_month_name <- month(ceiling_date(get_script_run_time(), unit = "month"), label = T, abbr = F) %>% as.character()

initial_invoice_line_item <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  collect() %>%
  # HACK: when testing, in-memory data for redcap_projects is converted to int upon collection
  mutate_columns_to_posixct(c("created", "updated"))

target_projects <- tbl(rc_conn, "redcap_projects") %>%
  inner_join(
    tbl(rc_conn, "redcap_entity_project_ownership") %>%
    filter(is.na(sequestered) || sequestered == 0) %>%
      filter(billable == 1),
    by = c("project_id" = "pid")
  ) %>%
  filter(is.na(date_deleted)) %>%
  # project at least 1 year old
  filter(creation_time <= local(add_with_rollback(ceiling_date(get_script_run_time(), unit = "month"), -years(1)))) %>%
  # birthday this month, comment this line out for consistent local testing
  filter(0 == month(local(get_script_run_time())) - month(creation_time)) %>%
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

project_record_counts <- tbl(rc_conn, "redcap_record_counts") %>%
  filter(project_id %in% local(target_projects$project_id)) %>%
  select(project_id, record_count) %>%
  collect()

next_projects_to_be_billed <- email_info %>%
  mutate(app_title = writexl::xl_hyperlink(paste0(redcap_project_uri_home_base, project_id), app_title)) %>%
  left_join(project_record_counts, by = "project_id") %>%
  select(project_owner_email, project_owner_full_name, user_suspended_time, project_id, creation_time, record_count, last_logged_event, app_title)
basename = "next_projects_to_be_billed"
next_projects_to_be_billed_filename <- paste0(basename, "_", format(get_script_run_time(), "%Y%m%d%H%M%S"), ".xlsx")
next_projects_to_be_billed_full_path <- here::here("output", next_projects_to_be_billed_filename)
next_projects_to_be_billed %>% writexl::write_xlsx(next_projects_to_be_billed_full_path)

message = "The attached file describes the REDCap project invoice line items we expect to be sent out on the first of next month."
redcapcustodian::send_email(
  email_body = list(message, sendmailR::mime_part(next_projects_to_be_billed_full_path, name = next_projects_to_be_billed_filename)),
  email_subject = "Impending REDCap project invoice line items",
  email_to = Sys.getenv("EMAIL_TO"),
  email_cc = paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL")),
  email_from = "ctsit-redcap-reply@ad.ufl.edu"
)


email_template_text <- str_replace( "<p><owner_name>,<p>
<p>The REDCap projects you own, listed below, are due to be billed on <next_month> 1st. If you take no action, you will receive an invoice from the CTSI Service Billing Team charging you $130 for the past year of service for <b>each</b> of the projects listed here:</p>

<table_of_owned_projects_due_to_be_billed>

<p>If you no longer need or use one or more of these REDCap projects, we encourage you to export your project design and your project data, and delete the project before the first of next month. Projects deleted <i>before</i> annual invoicing will not be charged the annual fee of $130. To delete a project, access its project link above then follow the instructions in <a href=\"https://www.ctsi.ufl.edu/wordpress/files/2023/07/How-to-Delete-a-Project-in-REDCap_new.pdf\">Deleting a Project in REDCap</a>.</p>

<p>Alternatively, if a project is still in use, but you are no longer responsible for it, you can change the ownership to the new owner by clicking any of the project links above. There is a guide to assist you in this process at <a href=\"https://www.ctsi.ufl.edu/wordpress/files/2023/07/How-to-Update-Change-Project-Ownership-Info-PI-Name-and-IRB-Number.pdf\">Update Project Ownership, PI Name & Email and IRB Number in REDCap</a>.</p>

<p>The projects listed above are the ones scheduled to be invoiced <i>this</i> month. You can see all of the projects you own at <a href=\"<redcap_project_ownership_page>\">REDCap Project Ownership</a>.</p>

<p>Invoiced projects that remain unpaid after 90-days will be automatically sequestered.
This will take the project offline, denying access to project users and taking any open
surveys offline. Any project not brought out of sequestration is assumed abandoned and
will be automatically deleted a year after the original invoice. Note that neither
sequestration nor deletion voids the invoice. Once an invoice is generated,
the project PI is responsible for paying the invoice regardless of project status.</p>

<p>If your project is sequestered while you still need access to the project, please
contact the REDCap support team by opening a
<a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>
so we can briefly restore your access. This will give you an opportunity to complete
your business with the REDCap project. Unpaid projects will be re-sequestered at
the end of each month. Sequestered projects will be deleted one year after the
original invoice. None of these actions void the invoice.</p>

<p>If you want more information about these changes, please review our <a href=\"https://redcap.ctsi.ufl.edu/ctsit/redcap_project_billing_faq.pdf\">FAQ</a> about the billing policy.</p>

<p>Regards,</p>
<p>REDCap Support</p>

<p>This message was sent from an unmonitored mailbox. If you have questions, please open a <a href=\"https://redcap.ctsi.ufl.edu/redcap/surveys/?s=DUPrXGmx3L\">REDCap Service/Consultation Request</a>.</p>",
"<redcap_project_ownership_page>", redcap_project_ownership_page) %>%
  str_replace("<next_month>", next_month_name)

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
  ungroup()
  # TEST_METHOD_B: uncomment to test.
  # Set the email address to your own
  # %>% mutate(project_owner_email = "YOUR_EMAIL_ADDRESS_HERE") %>% slice_sample(n=3)

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
        email_subject = "Expected charges for REDCap services",
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

billing_alert_log_list <- apply(email_df,
  MARGIN = 1,
  FUN = send_billing_alert_email
)

billing_alert_log <- do.call("rbind", billing_alert_log_list)

activity_log <- list(
  billing_alert_log = billing_alert_log
)

log_job_success(jsonlite::toJSON(activity_log))
