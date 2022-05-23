library(dplyr)

invoice_line_item_reasons <- tibble::tribble(
  ~code, ~label,
  "new_item", "New item to be invoiced",
  "deleted", "Project deleted",
  "reassigned", "PI reassigned"
)

usethis::use_data(invoice_line_item_reasons, overwrite = TRUE)
