library(rcc.billing)

table_name <- "service_type"

convert_schema_to_sqlite(table_name =  table_name)
write_to_sqlite(table_name = table_name)
