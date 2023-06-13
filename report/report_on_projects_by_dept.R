library(tidyverse)
library(rcc.billing)
library(lubridate)
library(DBI)
library(dotenv)
library(redcapcustodian)
library(sendmailR)

init_etl("report_on_projects_by_dept")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

billable_candidates <- get_billable_candidates(rc_conn, rcc_billing_conn)

basename <- "billable_candidates"

# billable_candidates %>% str()
dept_file <- "~/Downloads/EM Staff List REDCap Request.xlsx"
timestamp <- format(get_script_run_time(), "%Y-%m-%d_%H%M%S")
output_file <- str_replace(dept_file, ".xlsx", paste0("_projects_", timestamp, "\\0"))
dept_data <- readxl::read_xlsx(dept_file) %>%
  janitor::clean_names() %>%
  rename(
    name = employee_name,
    email = email_address,
    ufid = employee_id
  ) %>%
  mutate(username = if_else(
    str_detect(email, "@ufl.edu"),
    str_replace(email, "@ufl.edu", ""),
    NA_character_
  )) %>%
  select(
    name,
    email,
    username,
    ufid
  )

dept_projects <-
  bind_rows(
    billable_candidates %>%
      filter(!is.na(project_owner_email)) %>%
      inner_join(dept_data, by = c("project_owner_email" = "email")),
    billable_candidates %>%
      filter(!is.na(project_owner_username)) %>%
      inner_join(dept_data, by = c("project_owner_username" = "username"))
  ) %>%
  distinct() %>%
  select(name, username, ufid, email, everything()) %>%
  arrange(name)

dept_projects %>% writexl::write_xlsx(path = output_file)
