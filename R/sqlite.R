#' Converts a mysql schema to a sqlite schema for the provided table.
#' A corresponding schema file with the same name is required in /schema.
#'
#' @param table_name, the name of the table to convert
#'
#' @examples
#' \dontrun{
#' convert_schema_to_sqlite(table_name = "service_type")
#' }
#' @export
convert_schema_to_sqlite <- function(table_name) {
  schema_file_name <- paste0(table_name, ".sql")
  lite_schema_file_name <- paste0(table_name, "_lite.sql")

  # read original
  original_schema <- readr::read_file(file = system.file("schema", schema_file_name, package = "rcc.billing"))

  # create temp file
  temp_file <- tempfile(fileext = "sql")

  # write to temp file
  readr::write_file(x = original_schema, file = temp_file)

  # convert to sqlite
  cmd <- paste("cat", temp_file, "|", "perl to_sqlite.pl", ">", paste0("./schema/", lite_schema_file_name))

  system(cmd)
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
write_to_sqlite <- function(table_name) {
  schema_file_name <- paste0(table_name, "_lite.sql")

  # get test data
  test_data <- get0(paste0(table_name, "_test_data"))

  # read sqlite schema
  lite_schema <- readr::read_file(system.file("schema", schema_file_name, package = "rcc.billing"))

  # connect to sqlite db
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  # create table
  result <- DBI::dbSendQuery(conn, lite_schema)
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
