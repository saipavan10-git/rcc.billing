library(dplyr)

invoice_line_item_reasons <- tibble::tribble(
  ~code, ~label,
  "new_item", "New item to be invoiced",
  "deleted", "Project deleted",
  "reassigned", "PI reassigned",
  "seeking_voucher", "seeking voucher",
  # values from do not bill reason
  "17", "17. Withdrawn/Canceled",
  "21", "21. Duplicate Charge",
  "24", "24. Project/Data deleted after invoice creation.",
  "27", "27. PI no longer with UF",
  "41", "41. Write-Off (True Write-Off, not billing issues)",
  "45", "45. PI Left UF and project should have been sequestered/not invoiced.",
  "46", "46. Did not meet billing criteria.",
  "47", "47. Reassigned to new project owner who decided to delete within 30 days."
)

usethis::use_data(invoice_line_item_reasons, overwrite = TRUE)

invoice_line_item_statuses <- tribble(
  ~status, ~description,
  "draft", "draft invoices line items that have not yet been sent",
  "sent", "the invoice line item has been sent to CSBT",
  "canceled", "the invoice line item does not need to be paid",
  "unreconciled", "CSBT says the line item is paid, but this has not yet been verified by CTS-IT",
  "paid", "CTS-IT has verified the line item has been paid"
)

usethis::use_data(invoice_line_item_statuses, overwrite = TRUE)
