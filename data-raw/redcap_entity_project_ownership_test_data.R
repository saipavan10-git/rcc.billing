# Create redcap_entity_project_ownership_test_data from redcap_projects_test_data

library(rcc.billing)
library(tidyverse)
library(lubridate)

redcap_entity_project_ownership_test_data <-
  redcap_projects_test_data %>%
  select(
    project_id,
    creation_time,
    starts_with("project_pi_"),
    date_deleted
  ) %>%
  mutate(id = row_number()) %>%
  mutate(created = as.numeric(creation_time)) %>%
  mutate(updated = created) %>%
  rename(pid = project_id) %>%
  mutate(username = as.character(NA)) %>%
  rename(email = project_pi_email) %>%
  rename(firstname = project_pi_firstname) %>%
  rename(lastname = project_pi_lastname) %>%
  # Make one project that has a PI who is a redcap user
  mutate(username = if_else(pid == 3456, gsub("@.*", "", email), username)) %>%
  mutate(email = if_else(pid == 3456, as.character(NA), email)) %>%
  mutate(firstname = if_else(pid == 3456, as.character(NA), firstname)) %>%
  mutate(lastname = if_else(pid == 3456, as.character(NA), lastname)) %>%
  # ToDo: we will need to add a project to redcap_projects_test_data--
  #  and this table--that is not billable.
  #  This is is a small job that must be done before we go into production.
  mutate(billable = 1) %>%
  # ToDo we need to add a sequestered project to lots of test datasets. That is a large project that
  #   SHOULD NOT BE DONE UNTIL AFTER NORMAL BILLING IS IN PRODUCTION. --pbc
  mutate(sequestered = 0) %>%
  # HACK make a project suitable for testing update_billable_by_ownerhip
  mutate(username = if_else(pid == 6490, gsub("@.*", "", email), username)) %>%
  mutate(billable = if_else(pid == 6490, NA_real_, billable)) %>%
  mutate(billable = if_else(pid == 2345, NA_real_, billable)) %>%
  select(id, created, updated, pid, username, email, firstname, lastname, billable, sequestered)

usethis::use_data(redcap_entity_project_ownership_test_data, overwrite = T)
