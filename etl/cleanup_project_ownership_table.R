library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("cleanup_project_ownership_table")

rc_conn <- connect_to_redcap_db()

required_tables <- c(
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_projects",
  "redcap_user_rights",
  "redcap_user_roles"
)

# Include this month and next two months
relevant_anniversary_months = c(
  month(get_script_run_time()),
  next_n_months(month(get_script_run_time()), 1),
  next_n_months(month(get_script_run_time()), 2)
)

sequestered_projects <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(sequestered == 1) %>%
  select(pid) %>%
  collect() %>%
  pull(pid)
non_billable_projects <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(billable == 0) %>%
  select(pid) %>%
  collect() %>%
  pull(pid)
redcap_user_information <- tbl(rc_conn, "redcap_user_information") %>% collect()
redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  # ignore deleted projects
  filter(is.na(date_deleted)) %>%
  collect() %>%
  mutate_columns_to_posixct(c("creation_time")) %>%
  filter(get_script_run_time() - creation_time > months(9)) %>%
  # process only this month's project anniversaries
  filter(month(creation_time) %in% relevant_anniversary_months) %>%
  # ignore sequestered projects
  filter(!project_id %in% sequestered_projects) %>%
  # ignore non-billable projects
  filter(!project_id %in% non_billable_projects)
redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  # include only the projects we care about
  filter(pid %in% !!redcap_projects$project_id) %>%
  # ignore sequestered projects
  filter(sequestered == 0 | is.na(sequestered)) %>%
  filter(billable == 1) %>%
  collect()
redcap_entity_project_ownership_all <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  collect()

redcap_user_rights <- tbl(rc_conn, "redcap_user_rights") %>% collect()
redcap_user_roles <- tbl(rc_conn, "redcap_user_roles") %>% collect()

projects_needing_new_owners <- get_projects_needing_new_owners(
  redcap_entity_project_ownership = redcap_entity_project_ownership,
  redcap_user_information = redcap_user_information
)

projects_without_owners <- get_projects_without_owners(
  redcap_projects = redcap_projects,
  redcap_entity_project_ownership = redcap_entity_project_ownership
)

research_projects_not_using_viable_pi_data <- get_research_projects_not_using_viable_pi_data(
  redcap_projects = redcap_projects,
  redcap_entity_project_ownership = redcap_entity_project_ownership,
  redcap_user_information = redcap_user_information
)

projects_with_ownership_issues <- unique(
  c(projects_needing_new_owners, projects_without_owners, research_projects_not_using_viable_pi_data)
)

redcap_projects_needing_correction <- redcap_projects %>%
  filter(project_id %in% projects_with_ownership_issues)

project_pis <- get_project_pis(
  redcap_projects = redcap_projects_needing_correction,
  return_project_ownership_format = T
) %>%
  mutate(
    reason = "project_pis",
    priority = 1
  )

unsuspended_high_privilege_faculty <- get_privileged_user(
  redcap_projects = redcap_projects_needing_correction,
  redcap_user_information = redcap_user_information,
  redcap_staff_employment_periods = ctsit_staff_employment_periods,
  redcap_user_rights = redcap_user_rights,
  redcap_user_roles = redcap_user_roles,
  filter_for_faculty = T,
  return_project_ownership_format = T
) %>%
  mutate(
    reason = "unsuspended_high_privilege_faculty",
    priority = 2
  )

unsuspended_high_privilege_user <- get_privileged_user(
  redcap_projects = redcap_projects_needing_correction,
  redcap_user_information = redcap_user_information,
  redcap_staff_employment_periods = ctsit_staff_employment_periods,
  redcap_user_rights = redcap_user_rights,
  redcap_user_roles = redcap_user_roles,
  return_project_ownership_format = T
) %>%
  mutate(
    reason = "unsuspended_high_privilege_user",
    priority = 3
  )

unsuspended_low_privilege_user <- get_privileged_user(
  redcap_projects = redcap_projects_needing_correction,
  redcap_user_information = redcap_user_information,
  redcap_staff_employment_periods = ctsit_staff_employment_periods,
  redcap_user_rights = redcap_user_rights,
  redcap_user_roles = redcap_user_roles,
  include_low_privilege_users = T,
  return_project_ownership_format = T
) %>%
  mutate(
    reason = "unsuspended_low_privilege_user",
    priority = 4
  )

project_ownership_updates <- bind_rows(
  project_pis,
  unsuspended_high_privilege_faculty,
  unsuspended_high_privilege_user,
  unsuspended_low_privilege_user
) %>%
  left_join(redcap_entity_project_ownership %>% select(pid, created), by = "pid") %>%
  mutate(updated = as.integer(get_script_run_time())) %>%
  mutate(created = coalesce(created, updated)) %>%
  arrange(priority) %>%
  group_by(pid) %>%
  filter(row_number() == 1) %>%
  ungroup()

dataset_diff_for_rcepo <-
  redcapcustodian::dataset_diff(
    source = project_ownership_updates %>%
      select(-reason, -priority),
    source_pk = "pid",
    target = redcap_entity_project_ownership_all,
    target_pk = "pid",
    insert = T,
    delete = F
  )

# erase the redcap_entity_project_ownership record for
# every project in projects_with_ownership_issues but not in project_ownership_updates.
project_ownership_records_with_issues_and_no_updates <-
  redcap_entity_project_ownership %>%
  filter(pid %in% projects_with_ownership_issues) %>%
  filter(!pid %in% project_ownership_updates$pid) %>%
  mutate(reason = "unresolvable_ownership_issues") %>%
  select(pid, reason, email, firstname, lastname, username, billable, sequestered, created, updated)

blanked_project_ownership_records_with_issues_and_no_updates <-
  project_ownership_records_with_issues_and_no_updates %>%
  select(-c(reason, billable, sequestered)) %>%
  mutate(
    email = NA_character_,
    firstname = NA_character_,
    lastname = NA_character_,
    username = NA_character_,
    updated = as.integer(get_script_run_time())
  )

dataset_diff_for_rcepo$update_records <- dataset_diff_for_rcepo$update_records %>%
  rbind(blanked_project_ownership_records_with_issues_and_no_updates)

sync_activity <- redcapcustodian::sync_table(
  conn = rc_conn,
  table_name = "redcap_entity_project_ownership",
  primary_key = "pid",
  data_diff_output = dataset_diff_for_rcepo,
  insert = T,
  update = T,
  delete = F
)

# create the data we want to log
dataset_diff_for_rcepo_logging <-
  redcapcustodian::dataset_diff(
    source = project_ownership_updates,
    source_pk = "pid",
    target = redcap_entity_project_ownership,
    target_pk = "pid",
    insert = T,
    delete = F
  )

activity_log <- bind_rows(
  dataset_diff_for_rcepo_logging$update_records %>% mutate(diff_type = "update"),
  dataset_diff_for_rcepo_logging$insert_records %>% mutate(diff_type = "insert"),
  project_ownership_records_with_issues_and_no_updates %>% mutate(diff_type = "erase")
) %>%
  select(diff_type, reason, priority, everything())

log_job_success(jsonlite::toJSON(activity_log))
