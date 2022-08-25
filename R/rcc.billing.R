#' Connect to the rcc_billing DB
#'
#' @param drv, an object that inherits from DBIDriver (e.g. RMariaDB::MariaDB()), or an existing DBIConnection object (in order to clone an existing connection).
#' @param continue_on_error if TRUE then continue execution on error, if FALSE then quit non interactive sessions on error
#' @return An S4 object. Run ?dbConnect for more information
#' @examples
#'
#' \dontrun{
#' # connect to the RCC Billing database using RCCBILLING_* environment variables
#' con <- connect_to_rcc_billing_db()
#'
#' # connect to sqlite RCC Billing db
#' con <- connect_to_rcc_billing_db(drv = RSQLite::SQLite())
#' }
#' @export
connect_to_rcc_billing_db <- function(drv = RMariaDB::MariaDB(), continue_on_error = FALSE) {
  conn <- redcapcustodian::connect_to_db(drv = drv, prefix = "RCCBILLING", continue_on_error = continue_on_error)
  return(conn)
}
