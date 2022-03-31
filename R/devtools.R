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

  # convert to sqlite
  cmd <- paste("cat", original_schema_file, "|", "perl", pl_to_sqlite)

  result <- system(cmd, intern = TRUE) %>% paste(collapse = "")
  return(result)
}

#' Creates a table for table_name.
#' A corresponding data set and sqlite schema are required in /data and /schema respectively.
#' Use \code{\link{convert_schema_to_sqlite}} to generate a sqlite schema from a mysql schema.
#'
#' @param conn, a DBI connection object
#' @param sqlite_schema, the ddl to execute against conn
#'
#' @examples
#' \dontrun{
#'  table_name <- "service_type"
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#'
#'  schema <- convert_schema_to_sqlite(table_name)
#'  create_table(conn = conn, sqlite_schema = schema)
#' }
#' @export
create_table <- function(conn, sqlite_schema) {
  # create table
  result <- DBI::dbSendQuery(conn, sqlite_schema)

  # close result set to avoid warning
  DBI::dbClearResult(result)
}

#' Populates table_name with the corresponding test data found in /data.
#'
#' @param conn, a DBI connection object
#' @param table_name, the table to populate with test data
#'
#' @examples
#' \dontrun{
#'  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#'  populate_table(conn = conn, table_name = "service_type")
#' }
#' @export
populate_table <- function(conn, table_name) {
  # get test data
  test_data <- get0(paste0(table_name, "_test_data"))

  # write sample data
  result <- DBI::dbAppendTable(
    conn = conn,
    name = table_name,
    value = test_data,
    overwrite = TRUE
  )

  data <- DBI::dbGetQuery(conn, paste("select * from", table_name))
  return(data)
}
