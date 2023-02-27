# make_get_orphaned_projects_test_data.R

library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

dotenv::load_dot_env("prod.env")
set_script_run_time(ymd_hms("2023-04-01 12:00:00"))

conn <- connect_to_redcap_db()

test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_record_counts"
)

# find 10 viable project_ids
provisional_redcap_projects <- tbl(conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  collect() %>%
  sample_n(size = 50) %>%
  arrange(project_id)

provisional_redcap_entity_project_ownership <- tbl(conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!provisional_redcap_projects$project_id) %>%
  collect()

provisional_redcap_user_rights <- tbl(conn, "redcap_user_rights") %>%
  filter(project_id %in% !!provisional_redcap_entity_project_ownership$id) %>%
  collect()

redcap_projects <- tbl(conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  filter(project_id %in% !!provisional_redcap_user_rights$project_id) %>%
  collect() %>%
  head(size = 10) %>%
  arrange(project_id) %>%
  mutate(creation_time = case_when(
    row_number() %in% seq(1, 5) ~ get_script_run_time() - dyears(1),
    row_number() %in% seq(6, 15) ~ get_script_run_time() - dyears(1) - dmonths(row_number())
  )) %>%
  mutate(last_logged_event = case_when(
    row_number() %in% c(1, 2, 3) ~ get_script_run_time() - dyears(1) - dmonths(2),
    T ~ get_script_run_time() - dmonths(row_number())
  )) %>%
  mutate(completed_time = case_when(
    row_number() == c(4) ~ get_script_run_time() - dmonths(3),
    T ~ NA_POSIXct_
  )) %>%
  mutate(completed_by = case_when(
    row_number() == c(4) ~ "marked completed by make_get_orphaned_projects_test_data.R",
    T ~ NA_character_
  )) %>%
  mutate(project_pi_email = if_else(!is.na(project_pi_email) | project_pi_email == "",
    "bogus_user@ufl.edu",
    project_pi_email
  ))

project_ids_of_projects_without_viable_permissions <- redcap_projects$project_id[c(1, 2)]
project_ids_of_projects_unresolvable_ownership_issues <- redcap_projects$project_id[5]

redcap_entity_project_ownership <- tbl(conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() %>%
  mutate(across(
    c("username", "email", "firstname", "lastname"),
    ~ if_else(pid %in% project_ids_of_projects_unresolvable_ownership_issues, NA_character_, .)
  )) %>%
  mutate(
    billable = 1,
    sequestered = case_when(
      row_number() %in% seq(1, 7) ~ 0,
      row_number() %in% seq(8, 14) ~ NA_real_,
      row_number() %in% 15 ~ NA_real_
    )
  )

orphaned_project_types <- tribble(
  ~reason, ~project_row, ~priority,
  "empty_and_inactive_with_no_viable_users", 1, 1,
  "inactive_with_no_viable_users", 2, 2,
  "empty_and_inactive", 3, 3,
  "complete_but_non_sequestered", 4, 4,
  "unresolvable_ownership_issues", 5, 5
)

redcap_record_counts <- tbl(conn, "redcap_record_counts") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  collect() %>%
  mutate(record_count = case_when(
    row_number() %in% c(1, 3) ~ 0,
    T ~ 1000 + row_number()
  )) %>%
  left_join(redcap_projects %>% select(project_id, last_logged_event), by = "project_id") %>%
  mutate(time_of_count = last_logged_event + days(2)) %>%
  select(-last_logged_event)

# project_id <- redcap_projects$project_id
#
# fake_user_rights <-
#   tibble(
#     tbl(conn, "redcap_user_rights") %>%
#       filter(design == 1) %>%
#       head(n = 1) %>%
#       mutate(username = "fakeuser") %>%
#       select(-project_id) %>%
#       collect(),
#     project_id
#   ) %>%
#   select(project_id, everything())

redcap_user_rights <- tbl(conn, "redcap_user_rights") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  collect() %>%
  # bind_rows(fake_user_rights) %>%
  filter(!project_id %in% project_ids_of_projects_without_viable_permissions)

redcap_user_roles <- tbl(conn, "redcap_user_roles") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  filter(!project_id %in% project_ids_of_projects_without_viable_permissions) %>%
  collect()

redcap_user_information <- tbl(conn, "redcap_user_information") %>%
  filter(username %in% !!redcap_user_rights$username) %>%
  collect() %>%
  mutate(expiration = NA_POSIXct_) %>%
  mutate(user_lastlogin = get_script_run_time() - dmonths(2)) %>%
  mutate(across(starts_with("user_email"), ~ if_else(is.na(.), ., "bogus_user@ufl.edu")))

write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("get_orphaned_projects", paste0(basename, ".rds")))
}

# write all of the test inputs
walk(test_tables, ~ write_to_testing_rds(get(.), .))

