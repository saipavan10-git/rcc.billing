% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/devtools.R
\name{create_and_load_test_table}
\alias{create_and_load_test_table}
\title{create_and_load_test_table}
\usage{
create_and_load_test_table(
  conn,
  table_name,
  load_test_data = TRUE,
  is_sqllite = FALSE
)
}
\arguments{
\item{conn, }{a DBI Connection object}

\item{table_name, }{the name of the table}

\item{load_test_data, }{a logical to indicate if test data should be loaded}

\item{is_sqllite, }{a logical to indicate if the DBI object is a a SQLLite DB}
}
\value{
The test data as read back from the new table or NULL
}
\description{
Create a named table for which we have stored schema and optionally load the stored test data into it
}
\examples{
conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")
result <- create_and_load_test_table(
  conn = conn,
  table_name = "invoice_line_item_communications",
  is_sqllite = TRUE
)
}
