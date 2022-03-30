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
#' convert_schema_to_sqlite(table_name = "service_type")
#' }
#' @export
convert_schema_to_sqlite <- function(table_name) {
  schema_file_name <- paste0(table_name, ".sql")
  lite_schema_file_name <- paste0(table_name, "_lite.sql")
  pl_to_sqlite <- system.file("", "to_sqlite.pl", package = "rcc.billing")

  # read original
  original_schema_file = system.file("schema", schema_file_name, package = "rcc.billing")

  # convert to sqlite
  cmd <- paste("cat", original_schema_file, "|", "perl", pl_to_sqlite)

  result <- system(cmd, intern = TRUE) %>% paste(collapse = "")
}

#' Creates a table in sqlite for the provided table.
#' A corresponding data set and sqlite schema are required in /data and /schema respectively.
#' Use \code{\link{convert_schema_to_sqlite}} to generate a sqlite schema from a mysql schema.
#'
#' @param table_name, the name of the table to create in sqlite. A _test_data file in /data
#'
#' @examples
#' \dontrun{
#' write_to_sqlite(table_name = "service_type")
#' }
#' @export
write_to_sqlite <- function(table_name, sqlite_schema) {
  # get test data
  test_data <- get0(paste0(table_name, "_test_data"))

  # connect to sqlite db
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  # create table
  result <- DBI::dbSendQuery(conn, sqlite_schema)
  # close result set to avoid warning
  DBI::dbClearResult(result)

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
