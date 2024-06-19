get_orphaned_projects_test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_record_counts"
)

get_billable_candidates_test_tables <- c(
  "redcap_config", # lives in redcap DB
  "redcap_projects", # ibid
  "redcap_entity_project_ownership", # ibid
  "redcap_user_information", # ibid
  "redcap_record_counts", # ibid
  "invoice_line_item", # lives in rcc_billing DB
  "person_org", # lives in rcc_billing DB
  "org_hierarchies" # lives in rcc_billing DB
)

get_user_rights_and_info_test_tables <- c(
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles"
)
