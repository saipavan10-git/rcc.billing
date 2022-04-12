library(DBI)
library(rcc.billing)

table_name <- "ctsit_staff"
conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

sqlite_schema <- convert_schema_to_sqlite(table_name = table_name)
create_table(
    conn = conn,
    schema = sqlite_schema
)
result <- populate_table(
    conn = conn,
    table_name = table_name
)
