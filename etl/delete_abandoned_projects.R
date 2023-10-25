library(rcc.billing)
library(redcapcustodian)
library(RMariaDB)
library(DBI)
library(tidyverse)
library(lubridate)
library(dotenv)

init_etl("delete_abandoned_projects")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

twelve_months_ago <- today() - months(12)
fourteen_months_ago <- today() - months(14)

previously_deleted_projects <- tbl(rc_conn, "redcap_projects") |>
  filter(!is.na(date_deleted)) |>
  select(project_id) |>
  collect()

sent_invoices <- tbl(rcc_billing_conn, "invoice_line_item") %>%
  filter(status == "sent") %>%
  collect() |>
  filter(today() - as_date(date_sent) > 365)

if(nrow(sent_invoices) > 0) {
  unpaid_projects <- tbl(rc_conn, "redcap_entity_project_ownership") %>%
    filter(pid %in% local(sent_invoices$service_identifier) & sequestered == 1) |>
    select(pid) |>
    collect() |>
    mutate(reason = "unpaid project")
} else {
  unpaid_projects <- data.frame(pid = integer(), reason = character())
}

sequestered_orphans <- tbl(rcc_billing_conn, "rcc_job_log") %>%
  filter(
    script_name == "sequester_orphans" &
      level == "SUCCESS" &
      between(as_date(log_date), fourteen_months_ago, twelve_months_ago)
  ) |>
  collect()

if (nrow(sequestered_orphans) > 0) {
  orphaned_projects <- sequestered_orphans |>
    mutate(
      json_data_parsed = map(job_summary_data, ~ jsonlite::fromJSON(.x, flatten = TRUE)),
      project_ownership_sync_updates = map(json_data_parsed, "project_ownership_sync_updates")
    ) |>
    select(project_ownership_sync_updates) |>
    unnest(project_ownership_sync_updates) |>
    select(pid) |>
    mutate(reason = "orphaned project")
} else {
  orphaned_projects <- data.frame(pid = integer(), reason = character())
}

projects_to_delete <- unpaid_projects |>
  bind_rows(orphaned_projects) |>
  anti_join(previously_deleted_projects, by = c("pid" = "project_id"))

if (nrow(projects_to_delete) > 0){
  deleted_projects <- delete_project(projects_to_delete$pid, rc_conn)

  activity_log <- projects_to_delete |>
    left_join(deleted_projects$data, by = c("pid" = "project_id"))

} else {
  activity_log <- data.frame(pid = integer())
}

log_job_success(jsonlite::toJSON(activity_log))

dbDisconnect(rc_conn)
dbDisconnect(rcc_billing_conn)

