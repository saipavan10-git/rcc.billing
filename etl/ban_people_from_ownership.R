library(dotenv)
load_dot_env("prod.env")

library(redcapcustodian)
library(rcc.billing)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("ban_people_from_ownership")

rcc_billing_conn <- connect_to_rcc_billing_db()

banned_owners <- tbl(rcc_billing_conn, "banned_owners") %>%
  collect()

max_id <- banned_owners %>%
  summarise(max_id = max(id)) %>%
  pull()

insert <- tribble(
  ~username, ~email,
  "oliverb", "oliverb@phhp.ufl.edu",
  "s.sheffield", "s.sheffield@phhp.ufl.edu"
) %>%
  # ignore anyone already in the table
  anti_join(banned_owners, by = "email") %>%
  anti_join(banned_owners, by = "username") %>%
  mutate(
    id = max_id + row_number(),
    date_added = now(),
    reason = "They left UF"
  )

DBI::dbAppendTable(
  conn = rcc_billing_conn,
  name = "banned_owners",
  value = insert
)

activity_log <- lst(insert)

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rcc_billing_conn)
