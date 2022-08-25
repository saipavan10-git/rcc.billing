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
  pl_to_sqlite <- system.file("", "to_sqlite.pl", package = "rcc.billing")

  # read original
  original_schema_file <- system.file("schema", schema_file_name, package = "rcc.billing")

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
#' table_name <- "service_type"
#' conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#'
#' schema <- convert_schema_to_sqlite(table_name)
#' create_table(conn = conn, schema = schema)
#' }
#' @export
create_table <- function(conn, schema) {
  schemata <- stringr::str_split(schema, pattern = ";\n+")[[1]]
  schemata <- schemata[schemata != ""]

  for (schema in schemata) {
    # create table
    result <- DBI::dbSendQuery(conn, schema)
    # close result set to avoid warning
    DBI::dbClearResult(result)
  }
}

#' Populates table_name with the corresponding test data found in /data.
#'
#' @param conn, a DBI connection object
#' @param table_name, the table to populate with test data
#' @param use_test_data, whether to use "_test_data"
#'
#' @examples
#' \dontrun{
#' conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#' populate_table(conn = conn, table_name = "service_type")
#' }
#' @export
populate_table <- function(conn, table_name, use_test_data = FALSE) {
  data_ref <- table_name

  if (isTRUE(use_test_data)) {
    data_ref <- paste0(data_ref, "_test_data")
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

#' create_and_load_test_table
#'
#' Create a named table for which we have stored schema and optionally load the stored test data into it
#'
#' @param conn, a DBI Connection object
#' @param table_name, the name of the table
#' @param load_test_data, a logical to indicate if test data should be loaded
#' @param is_sqllite, a logical to indicate if the DBI object is a a SQLLite DB
#'
#' @return The test data as read back from the new table or NULL
#' @export
#'
#' @examples
#' conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
#' result <- create_and_load_test_table(
#'   conn = conn,
#'   table_name = "invoice_line_item_communications",
#'   is_sqllite = TRUE
#' )
create_and_load_test_table <- function(conn, table_name, load_test_data = TRUE, is_sqllite = FALSE) {
  schema_file_name <- paste0(table_name, ".sql")
  original_schema_file <- system.file("schema", schema_file_name, package = "rcc.billing")
  schema <- dplyr::if_else(is_sqllite,
    convert_schema_to_sqlite(table_name = table_name),
    readr::read_file(original_schema_file)
  )
  create_table(
    conn = conn,
    schema = schema
  )
  if (load_test_data) {
    populate_table(
      conn = conn,
      table_name = table_name,
      use_test_data = T
    )
  }
}
