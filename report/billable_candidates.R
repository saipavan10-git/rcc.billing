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

billable_candidates <- get_billable_candidates(rc_conn, rcc_billing_conn)

basename = "billable_candidates"
billable_candidates_filename <- paste0(basename, "_", format(get_script_run_time(), "%Y%m%d%H%M%S"), ".xlsx")
billable_candidates_full_path <- here::here("output", billable_candidates_filename)
billable_candidates %>% writexl::write_xlsx(billable_candidates_full_path)

message = "The attached file provides about every** REDCap project in existence on REDCap Prod. \n\n\n**That's a lie. It does not show projects CTS-IT considers 'non-billable'. These are our own projects and those owned by customers with other CTS-IT contracts that cover the annual project cost."
redcapcustodian::send_email(
  email_body = list(message, sendmailR::mime_part(billable_candidates_full_path, name = billable_candidates_filename)),
  email_subject = "Billable candidates report",
  email_to = Sys.getenv("EMAIL_TO"),
  email_cc = paste(Sys.getenv("REDCAP_BILLING_L"), Sys.getenv("CSBT_EMAIL")),
  email_from = "please-do-not-reply@ufl.edu"
)

log_job_success("Sent billing candidates")
