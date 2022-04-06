library(DBI)
library(rcc.billing)

table_name <- "service_instance"
conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

sqlite_schema <- convert_schema_to_sqlite(table_name = table_name)
create_table(
    conn = conn,
    schema = sqlite_schema
)
populate_table(
    conn = conn,
    table_name = table_name
)
