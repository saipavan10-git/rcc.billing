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

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_record_counts"
)

orphaned_project_types <- tribble(
  ~reason, ~project_row, ~priority,
  "empty_and_inactive_with_no_viable_users", 1, 1,
  "inactive_with_no_viable_users", 2, 2,
  "empty_and_inactive", 3, 3,
  "complete_but_non_sequestered", 4, 4,
  "banned_owner", 5, 5,
  "banned_owner", 6, 5,
  "unresolvable_ownership_issues", 7, 6
)

# find 10 viable project_ids
provisional_redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  collect() %>%
  sample_n(size = 50) %>%
  arrange(project_id)

provisional_redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!provisional_redcap_projects$project_id) %>%
  collect()

provisional_redcap_user_rights <- tbl(rc_conn, "redcap_user_rights") %>%
  filter(project_id %in% !!provisional_redcap_entity_project_ownership$id) %>%
  collect()

redcap_projects <- tbl(rc_conn, "redcap_projects") %>%
  filter(is.na(date_deleted)) %>%
  filter(project_id %in% !!provisional_redcap_user_rights$project_id) %>%
  collect() %>%
  head(n = 10) %>%
  arrange(project_id) %>%
  mutate(creation_time = case_when(
    # ensure sequesterd projects are of proper age
    row_number() %in% seq(1, nrow(orphaned_project_types)) ~ get_script_run_time() - dyears(1),
    row_number() %in% seq(nrow(orphaned_project_types) + 1, 15) ~ get_script_run_time() - dyears(1) - dmonths(row_number())
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
project_ids_of_projects_with_banned_owners <- redcap_projects$project_id[c(5, 6)]
project_ids_of_projects_unresolvable_ownership_issues <- redcap_projects$project_id[7]

redcap_entity_project_ownership <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
  filter(pid %in% !!redcap_projects$project_id) %>%
  collect() %>%
  mutate(across(
    c("username", "email", "firstname", "lastname"),
    ~ if_else(pid %in% project_ids_of_projects_unresolvable_ownership_issues, NA_character_, .)
  )) %>%
  # add banned_owners cases
  mutate(
    username = case_when(
      pid == project_ids_of_projects_with_banned_owners[1] ~ "banned_user",
      pid == project_ids_of_projects_with_banned_owners[2] ~ NA_character_,
      T ~ username
    ),
    email = case_when(
      pid == project_ids_of_projects_with_banned_owners[1] ~ NA_character_,
      pid == project_ids_of_projects_with_banned_owners[2] ~ "banned_user@ufl.edu",
      T ~ email
    )
  ) %>%
  mutate(
    billable = 1,
    sequestered = case_when(
      row_number() %in% seq(1, nrow(orphaned_project_types)) ~ 0,
      row_number() %in% seq(nrow(orphaned_project_types) + 1, 15) ~ NA_real_
    )
  )

redcap_record_counts <- tbl(rc_conn, "redcap_record_counts") %>%
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
#     tbl(rc_conn, "redcap_user_rights") %>%
#       filter(design == 1) %>%
#       head(n = 1) %>%
#       mutate(username = "fakeuser") %>%
#       select(-project_id) %>%
#       collect(),
#     project_id
#   ) %>%
#   select(project_id, everything())

redcap_user_rights <- tbl(rc_conn, "redcap_user_rights") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  collect() %>%
  # bind_rows(fake_user_rights) %>%
  filter(!project_id %in% project_ids_of_projects_without_viable_permissions)

redcap_user_roles <- tbl(rc_conn, "redcap_user_roles") %>%
  filter(project_id %in% !!redcap_projects$project_id) %>%
  filter(!project_id %in% project_ids_of_projects_without_viable_permissions) %>%
  collect()

redcap_user_information <- tbl(rc_conn, "redcap_user_information") %>%
  filter(username %in% !!redcap_user_rights$username) %>%
  collect() %>%
  mutate(expiration = NA_POSIXct_) %>%
  mutate(user_lastlogin = get_script_run_time() - dmonths(2)) %>%
  mutate(across(starts_with("user_email"), ~ if_else(is.na(.), ., "bogus_user@ufl.edu")))

# Write rc db tables ##########################################################

write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("get_orphaned_projects", paste0(basename, ".rds")))
}

# write all of the test inputs
walk(test_tables, ~ write_to_testing_rds(get(.), .))

# Write rcc_billing db tables #################################################

banned_owners <- tbl(rcc_billing_conn, "banned_owners") %>%
  filter(FALSE) %>%
  collect() %>%
  add_row(
    id = 1,
    username = "banned_user",
    email = NA_character_,
    date_added = get_script_run_time() - dmonths(2),
    reason = "banned_username"
  ) %>%
  add_row(
    id = 2,
    username = NA_character_,
    email = "banned_user@ufl.edu",
    date_added = get_script_run_time() - dmonths(2),
    reason = "banned_email"
  )


write_to_testing_rds <- function(dataframe, basename) {
  dataframe %>% saveRDS(testthat::test_path("get_orphaned_projects/rcc_billing", paste0(basename, ".rds")))
}

walk(c("banned_owners"), ~write_to_testing_rds(get(.), .))
