#' previous_month
#'
#' Return the month number that would occur before the integer in `month`
#'
#' @param month - and integer month number
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
