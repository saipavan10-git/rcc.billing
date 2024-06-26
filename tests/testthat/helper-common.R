# create session-persistent salt value for hashing with
#   digest::digest(paste0(datum, salt), algo = "sha1")
salt <- redcapcustodian::get_package_scope_var("salt")
if (is.null(salt)) {
  redcapcustodian::set_package_scope_var("salt", paste0(runif(1), runif(1), runif(1)))
  salt <- redcapcustodian::get_package_scope_var("salt")
}

# Create a hashing function that uses the salt
my_hash <- function(x) {
  salt <- redcapcustodian::get_package_scope_var("salt")
  if (is.na(x)) {
    result <- x
  } else {
    result <- stringr::str_sub(digest::digest(paste0(x, salt), algo = "sha1"), start = 1, end = 8)
  }
  return(result)
}

append_fake_email_domain <- function(x) {
  if (is.na(x)) {
    result <- x
  } else {
    result <- paste0(x, "@example.org")
  }
  return(result)
}

# read an RDS file from tests/testthat/<directory_under_test_path>/<table_name>.rds
#   and make a same-named table in conn
create_a_table_from_rds_test_data <- function(table_name, conn, directory_under_test_path) {
  readRDS(testthat::test_path(directory_under_test_path, paste0(table_name, ".rds"))) %>%
    DBI::dbWriteTable(conn = conn, name = table_name, value = .)
}

create_a_table_from_rds <- function(path, conn) {
  table_name <- stringr::str_replace_all(path, c(".*/" =  "", ".rds" = ""))

  readRDS(path) %>%
    DBI::dbWriteTable(conn = conn, name = table_name, value = .)
}

# write a dataframe, referenced by 'table_name' to tests/testthat/directory_under_test_path
write_rds_to_test_dir <- function(table_name, directory_under_test_path) {
  get(table_name) |> saveRDS(testthat::test_path(directory_under_test_path, paste0(table_name, ".rds")))
}
