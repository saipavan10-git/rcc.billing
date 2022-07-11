library(dotenv)
library(DBI)
library(RMariaDB)
library(redcapcustodian)
library(lubridate)
library(tidyverse)

load_dot_env("prod.env")
init_etl("fix_bad_activity_and_login_dates")

rc_conn <- connect_to_redcap_db()

# get the data
redcap_user_information <- tbl(rc_conn, "redcap_user_information") %>%
  collect() %>%
  filter(!ui_id %in% c(1,2))

users_who_should_have_been_suspended <- redcap_user_information %>%
  filter(is.na(user_suspended_time)) %>%
  filter(user_lastlogin == user_lastactivity) %>%
  filter(user_lastactivity <= now() - ddays(180))

distribution_of_age_in_months <- users_who_should_have_been_suspended %>%
  mutate(months_old = round((now() - user_lastactivity)/ddays(30))) %>%
  count(months_old)

users_to_suspend_without_a_second_thought <-
  users_who_should_have_been_suspended %>%
  filter(user_lastactivity <= now() - ddays(270)) %>%
  mutate(user_lastactivity = user_lastlogin - ddays(1)) %>%
  mutate(reason = "users_to_suspend_without_a_second_thought") %>%
  select(reason, ui_id, user_lastactivity, user_lastlogin)

users_who_deserve_some_grace <- users_who_should_have_been_suspended %>%
  anti_join(users_to_suspend_without_a_second_thought, by = "ui_id") %>%
  rowwise() %>%
  mutate(user_lastlogin = now()  - ddays(180)
         + ddays(sample(seq(4, 17, by = 1), size = 1, replace = TRUE))) %>%
  ungroup() %>%
  mutate(reason = "users_who_deserve_some_grace") %>%
  select(reason, ui_id, user_lastactivity, user_lastlogin)

active_users_who_need_an_activity_tweak <-
  redcap_user_information %>%
  filter(is.na(user_suspended_time)) %>%
  anti_join(users_to_suspend_without_a_second_thought, by = "ui_id") %>%
  anti_join(users_who_deserve_some_grace, by = "ui_id") %>%
  filter(user_lastlogin == user_lastactivity) %>%
  mutate(user_lastactivity = user_lastlogin - dhours(1)) %>%
  mutate(reason = "active_users_who_need_an_activity_tweak") %>%
  select(reason, ui_id, user_lastactivity, user_lastlogin)

all_revisions <- bind_rows(
  users_to_suspend_without_a_second_thought,
  users_who_deserve_some_grace,
  active_users_who_need_an_activity_tweak
)

all_dataset_diff <- dataset_diff(
  source = all_revisions %>% select(-reason),
  source_pk = "ui_id",
  target = redcap_user_information,
  target_pk = "ui_id",
  insert = F,
  delete = F
)

update_n <- sync_table(
  conn = rc_conn,
  table_name = "redcap_user_information",
  primary_key = "ui_id",
  data_diff_output = all_dataset_diff
)

if (nrow(all_dataset_diff$update_records) == update_n) {
  log_job_success(jsonlite::toJSON(all_dataset_diff))
} else {
  log_job_failure(jsonlite::toJSON(all_dataset_diff))
}
