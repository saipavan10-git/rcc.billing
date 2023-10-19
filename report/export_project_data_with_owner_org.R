library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("export_project_data_with_owner_org")

rcc_billing_conn <- connect_to_rcc_billing_db()
rc_conn <- connect_to_redcap_db()

# Identify a department's project
person_org <- tbl(rcc_billing_conn, "person_org") |> collect()
org_hierarchies <- tbl(rcc_billing_conn, "org_hierarchies") |> collect()

projects <- tbl(rc_conn, "redcap_projects") %>% collect()
ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>% collect()
users <- tbl(rc_conn, "redcap_user_information") %>% collect()

owner_user <- ownership %>%
  left_join(users %>% select(
    username,
    user_email,
    user_firstname,
    user_lastname,
    user_suspended_time
  ), by = c("username")) %>%
  mutate(
    email = coalesce(email, user_email),
    firstname = coalesce(firstname, user_firstname),
    lastname = coalesce(lastname, user_lastname),
    username = if_else(username == "", NA_character_, username)
  ) %>%
  select(
    pid,
    username,
    email,
    firstname,
    lastname,
    billable,
    sequestered,
    user_suspended_time
  )

projects_with_orgs <-
  bind_rows(
    projects %>%
      left_join(owner_user, by = c("project_id" = "pid")) %>%
      filter(!is.na(username)) %>%
      left_join(person_org %>% select(-email), by = c("username" = "user_id")),
    projects %>%
      left_join(owner_user, by = c("project_id" = "pid")) %>%
      filter(is.na(username)) %>%
      left_join(person_org, by = c("email"))
  ) %>%
  filter(is.na(date_deleted) & is.na(completed_time)) %>%
  select(
    project_id,
    app_title,
    status,
    creation_time,
    production_time,
    inactive_time,
    billable,
    ufid,
    username,
    email,
    firstname,
    lastname,
    uf_work_title,
    primary_uf_fiscal_org,
    primary_uf_fiscal_org_2nd_level
  ) %>%
  left_join(org_hierarchies %>% select(primary_uf_fiscal_org = DEPT_ID, primary_uf_fiscal_org_name = DEPT_NAME), by = "primary_uf_fiscal_org")

projects_with_orgs %>% writexl::write_xlsx(here::here("output", "projects_with_orgs.xlsx"))

# # How many projects have no org data?
# projects_with_orgs %>%
#   count(is.na(primary_uf_fiscal_org))

# # who might need an external rate ?
# projects_with_orgs %>%
#   mutate(is_external = case_when(
#     str_detect(primary_uf_fiscal_org_name, "DSO-SHANDS") ~ T,
#     T ~ F
#   )) %>%
#   filter(today() >= creation_time + lubridate::years(1)) %>%
#   filter(billable == 1 | is.na(billable)) %>%
#   count(is.na(primary_uf_fiscal_org), is_external)

# # who are these people with no org data?
# projects_with_orgs %>%
#   mutate(is_external = case_when(
#     str_detect(primary_uf_fiscal_org_name, "DSO-SHANDS") ~ T,
#     T ~ F
#   )) %>%
#   filter(today() >= creation_time + lubridate::years(1)) %>%
#   filter(billable == 1 | is.na(billable)) %>%
#   filter(is.na(primary_uf_fiscal_org)) %>%
#   select(-c(
#     uf_work_title,
#     starts_with("primary_uf_fiscal_org"),
#     is_external,
#     ufid
#   )) %>%
#   arrange(desc(creation_time))

# # How do we find one dept by name?
# projects_with_orgs %>% filter(
#   str_detect(primary_uf_fiscal_org_name, "PULM")
# )
