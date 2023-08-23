library(tidyverse)
library(dotenv)
library(DBI)
library(redcapcustodian)
library(rcc.ctsit)
library(rcc.billing)

init_etl("write_uf_fiscal_orgs_to_person_org")

rc_conn <- connect_to_redcap_db()
rcc_billing_conn <- connect_to_rcc_billing_db()

rcui_df <- tbl(rc_conn, "redcap_user_information") %>%
  select(username, user_email) %>%
  filter(!is.na(user_email) & user_email != "") %>%
  collect()

###############################################################################
#                               REDCap Usernames                              #
###############################################################################

redcap_usernames <- rcui_df %>%
  pull(username)

person_data_from_usernames <- rcc.ctsit::get_uf_person_data_by_gatorlink(redcap_usernames) %>%
    janitor::clean_names() %>%
    select(
      user_id,
      ufid,
      email,
      uf_display_nm,
      uf_work_title,
      uf_phone_country_code = uf_uf_p_ctry_cd,
      uf_phone_area_code = uf_uf_p_area_cd,
      uf_phone = uf_uf_p_phone
      )

# TODO: decide what to do with this
# TODO: remove "site_admin" before using this
redcap_usernames_without_person_data <- redcap_usernames[!redcap_usernames %in% person_data_from_usernames$user_id]
# NOTE: many of these usernames are actually an email address

###############################################################################
#             PI emails not found as primary email in RCUI                    #
###############################################################################

pi_emails_not_in_rcui <- tbl(rc_conn, "redcap_projects") %>%
  select(project_pi_email) %>%
  filter(!is.na(project_pi_email) & project_pi_email != "") %>%
  filter(!project_pi_email %in% local(rcui_df$user_email)) %>%
  collect() %>%
  unique() %>%
  # get everything before "@"
  mutate(email_prefix = str_extract(project_pi_email, "[^@]+"))
  # NOTE: ~200 email prefixes are redcap user names, i.e.:
  ## filter(email_prefix %in% rcui_df$username)

pi_user_email_prefixes_not_in_rcui <- pi_emails_not_in_rcui %>%
  # NOTE: 17 primary emails are shared across 34 redcap users
  pull(email_prefix)

pi_prefix_person_data <- rcc.ctsit::get_uf_person_data_by_gatorlink(pi_user_email_prefixes_not_in_rcui) %>%
  janitor::clean_names() %>%
  select(
    user_id,
    ufid,
    email,
    uf_display_nm,
    uf_work_title,
    uf_phone_country_code = uf_uf_p_ctry_cd,
    uf_phone_area_code = uf_uf_p_area_cd,
    uf_phone = uf_uf_p_phone
  )

# TODO: decide what to do with this
# NOTE: this represents over half of the cohort
pi_prefixes_with_no_person_data <- pi_emails_not_in_rcui %>%
  filter(!email_prefix %in% pi_prefix_person_data$user_id)

###############################################################################
#                  Combine person data with VIVO fiscal data                  #
###############################################################################

redcap_person_data <- bind_rows(
  person_data_from_usernames,
  pi_prefix_person_data
) %>%
  unique()

vconn <- connect_to_vivo_db()

staff_departments <- dplyr::tbl(vconn, "staff_departments")

ufid_to_fiscal_org <- staff_departments %>%
  filter(ufid %in% local(redcap_person_data$ufid)) %>%
  select(
    ufid,
    primary_uf_fiscal_org = department_id
  ) %>%
  collect()

new_person_org_data <- inner_join(
  redcap_person_data,
  ufid_to_fiscal_org,
  by = "ufid"
) %>%
  # NOTE: assume department-level org is current org with last 4 digits replaced with 0
  mutate(primary_uf_fiscal_org_2nd_level = gsub(".{4}$", "0000", primary_uf_fiscal_org))

# TODO: decide what to do with this
# NOTE: this represents roughly 30% of redcap_person_data
redcap_person_data_without_org_data <- redcap_person_data %>%
  filter(!ufid %in% new_person_org_data$ufid)

original_person_org <- tbl(rcc_billing_conn, "person_org") %>%
  collect()

sync_table_result <- sync_table_2(
  conn = rcc_billing_conn,
  table_name = "person_org",
  source = new_person_org_data,
  source_pk = "ufid",
  target = original_person_org,
  target_pk = "ufid",
  insert = T,
  update = T
)

log_job_success(jsonlite::toJSON(sync_table_result))

dbDisconnect(rc_conn)
dbDisconnect(rcc_billing_conn)
dbDisconnect(vconn)
