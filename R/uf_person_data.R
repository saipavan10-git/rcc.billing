#' is_faculty
#'
#' A test to identify faculty in a vector of Gatorlink IDs
#'
#' @param user_ids, a vector of non-unique strings that are mostly UF Gatorlink IDs
#'
#' @return a logical vector the length of user_ids indicating which user_ids belong to faculty
#' @export
#' @importFrom magrittr "%>%"
#' @importFrom rlang .data
#' @importFrom dplyr filter tibble
#' @importFrom rcc.ctsit get_uf_person_data_by_gatorlink
#'
#' @examples
#' \dontrun{
#' is_faculty(user_ids = c("pbc", "hoganwr", "cpb", "shapiroj", "pbc"))
#' [1] FALSE  TRUE FALSE  TRUE FALSE
#' }
is_faculty <- function(
    user_ids
    ) {
  faculty_user_ids <- rcc.ctsit::get_uf_person_data_by_gatorlink(
    user_ids = user_ids
  ) %>%
    filter(.data$UF_PRIMARY_AFFL == "F") %>%
    pull(.data$USERIDALIAS)

  result <- tibble(user_ids) %>%
    mutate(is_faculty = user_ids %in% faculty_user_ids) %>%
    pull(is_faculty)

  return(result)
}
