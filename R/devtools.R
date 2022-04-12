#' Locates a MySQL schema file for table_name, converts it to a sqlite schema
#' and returns that schema.
#'
#' @param table_name, the name of the table to convert
#'
#' @returns sqlite schema for table_name
#' @importFrom magrittr "%>%"
#'
#' @examples
#' \dontrun{
#'  convert_schema_to_sqlite(table_name = "service_type")
#' }
#' @export
convert_schema_to_sqlite <- function(table_name) {
  schema_file_name <- paste0(table_name, ".sql")
  pl_to_sqlite <- system.file("", "to_sqlite.pl", package = "rcc.billing")

  # read original
  original_schema_file = system.file("schema", schema_file_name, package = "rcc.billing")

  if (original_schema_file == "") {
    stop(paste("Schema file does not exist for", table_name))
  }

  # convert to sqlite
  cmd <- paste("cat", original_schema_file, "|", "perl", pl_to_sqlite)

  result <- system(cmd, intern = TRUE) %>% paste(collapse = "")
  return(result)
}

#' Creates a table based on a schema.
#'
#' @param conn, a DBI connection object
#' @param schema, the ddl to execute against conn
#'
#' @examples
#' \dontrun{
#'  table_name <- "service_type"
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#'
#'  schema <- convert_schema_to_sqlite(table_name)
#'  create_table(conn = conn, schema = schema)
#' }
#' @export
create_table <- function(conn, schema) {
  # create table
  result <- DBI::dbSendQuery(conn, schema)

  # close result set to avoid warning
  DBI::dbClearResult(result)
}

#' Populates table_name with the corresponding test data found in /data.
#'
#' @param conn, a DBI connection object
#' @param table_name, the table to populate with test data
#' @param use_test_data, whether to use "_test_data"
#'
#' @examples
#' \dontrun{
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#'  populate_table(conn = conn, table_name = "service_type")
#' }
#' @export
populate_table <- function(conn, table_name, use_test_data = FALSE) {
  data_ref <- table_name

  if (isTRUE(use_test_data)) {
    data_ref <-  paste0(data_ref, "_test_data")
  }

  # get test data
  data <- get0(data_ref)

  # write sample data
  result <- DBI::dbAppendTable(
    conn = conn,
    name = table_name,
    value = data,
    overwrite = TRUE
  )

  result <- DBI::dbGetQuery(conn, paste("select * from", table_name))
  return(result)
}
