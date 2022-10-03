#' previous_month
#'
#' Return the month number that would occur before the integer in `month`
#'
#' @param month - an integer month number
#'
#' @return the previous month number
#' @export
#'
#' @examples
#' previous_month(9)
#' previous_month(1)
previous_month <- function(month) {
  result = dplyr::case_when(
    month == 1 ~ 12,
    2 <= month & month <= 12 ~ month - 1,
    TRUE ~ as.numeric(NA)
  )

  return(result)
}

#' previous_n_months
#'
#' Return the month number that would occur n months before the integer in `month`
#'
#' @param month - an integer month number
#' @param n - the number of months to subtract from current month (default = 1)
#'
#' @importFrom dplyr if_else
#' @importFrom lubridate add_with_rollback ceiling_date years month
#' @return the nth previous month number as in integer
#' @export
#'
#' @examples
#' previous_n_months(9, 2)
#' previous_n_months(1, 1)
previous_n_months <- function(month, n = 1) {

  result = month - n %% 12
  result = if_else(result <= 0, result + 12, result)

  return(result)
}
