library(rcc.billing)
library(tidyverse)
library(DBI)
library(RSQLite)


convert_schema_to_sqlite <- function(table_name) {
  # read original
  original_schema <- read_file(paste0("./schema/", table_name, ".sql"))

  # create temp file
  temp_file <- tempfile(fileext = "sql")

  # write to temp file
  write_file(x = original_schema, file = temp_file)

  # convert to sqlite
  cmd <- paste("cat", temp_file, "|" , "perl to_sqlite.pl", ">", paste0("./schema/", table_name, "_lite.sql"))

  system(cmd)
}

write_to_sqlite <- function(table_name) {
  # get test data
  test_data <- get0(paste0(table_name, "_test_data"))

  # read sqlite schema
  lite_schema <- read_file(paste0("./schema/", table_name, "_lite.sql"))

  # connect to sqlite db
  conn <- dbConnect(RSQLite::SQLite(), dbname = ":memory:")

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

convert_schema_to_sqlite("service_type")
data_written <- write_to_sqlite("service_type")
