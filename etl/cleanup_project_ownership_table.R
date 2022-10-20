library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("cleanup_project_ownership_table")

rc_con <- connect_to_redcap_db()

redcap_entity_project_ownership <- tbl(rc_con, "redcap_entity_project_ownership") %>%
  # ignore sequestered projects
  filter(sequestered != 0 | is.na(sequestered)) %>%
  collect()
redcap_user_information <- tbl(rc_con, "redcap_user_information") %>% collect()
redcap_projects <- tbl(rc_con, "redcap_projects") %>%
  # ignore deleted projects
  filter(is.na(date_deleted)) %>%
  collect()
redcap_user_rights <- tbl(rc_con, "redcap_user_rights") %>% collect()
redcap_user_roles <- tbl(rc_con, "redcap_user_roles") %>% collect()

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
  filter(project_id %in% projects_with_ownership_issues) %>%
  filter(get_script_run_time() - creation_time > years(1)) %>%
  filter(month(get_script_run_time()) == month(creation_time))

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
    target = redcap_entity_project_ownership,
    target_pk = "pid",
    insert = T,
    delete = F
  )

sync_activity <- redcapcustodian::sync_table(
  conn = rc_con,
  table_name = "redcap_entity_project_ownership",
  primary_key = "pid",
  data_diff_output = dataset_diff_for_rcepo,
  insert = T,
  update = T
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
  dataset_diff_for_rcepo_logging$insert_records %>% mutate(diff_type = "insert")
) %>%
  select(diff_type, reason, priority, everything())

log_job_success(jsonlite::toJSON(activity_log))
