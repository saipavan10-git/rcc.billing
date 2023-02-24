# read an RDS file from tests/testthat/<directory_under_test_path>/<table_name>.rds
#   and make a same-named table in conn
create_a_table_from_rds_test_data <- function(table_name, conn, directory_under_test_path) {
  readRDS(testthat::test_path(directory_under_test_path, paste0(table_name, ".rds"))) %>%
    DBI::dbWriteTable(conn = conn, name = table_name, value = .)
}

get_orphaned_projects_test_tables <- c(
  "redcap_projects",
  "redcap_entity_project_ownership",
  "redcap_user_information",
  "redcap_user_rights",
  "redcap_user_roles",
  "redcap_record_counts"
)
