library(tidyverse)
library(dotenv)
library(DBI)
library(redcapcustodian)
library(rcc.ctsit)
library(rcc.billing)

init_etl("write_uf_fiscal_orgs_to_org_hierarchies")

rcc_billing_conn <- connect_to_rcc_billing_db()

# NOTE: to fetch vivo data, must have access to network UF VPN, not UF Health
college_hierarchy <- get_college_hierarchy()
normalized_uf_fiscal_orgs <- get_normalized_uf_fiscal_orgs(college_hierarchy)

original_org_hierarchy <- tbl(rcc_billing_conn, "org_hierarchies") %>%
  collect()

syn_table_result <- sync_table_2(
  conn = rcc_billing_conn,
  table_name = "org_hierarchies",
  source = normalized_uf_fiscal_orgs,
  source_pk = "DEPT_ID",
  target = original_org_hierarchy,
  target_pk = "DEPT_ID",
  insert = T
)

log_job_success(jsonlite::toJSON(sync_table_result))

dbDisconnect(rcc_billing_conn)
