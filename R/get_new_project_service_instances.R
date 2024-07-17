#' Get new service instances that need to be created given a dataframe of
#' projects_to_invoice and a dataframe of the initial service_instance records.
#'
#' @param projects_to_invoice - the projects for which we will need to create invoice line items
#' @param initial_service_instance - a dataframe of the existing service instance table
#'
#' @return a dataframe of new service_instance rows
#' @export
#'
#' @examples
#' \dontrun{
#'   get_new_project_service_instances(projects_to_invoice, initial_service_instance)
#' }
get_new_project_service_instances <- function(
    projects_to_invoice,
    initial_service_instance) {

  new_service_instances <- projects_to_invoice |>
    dplyr::mutate(
      service_type_code = 1,
      service_identifier = as.character(.data$project_id),
      service_instance_id = paste(.data$service_type_code, .data$service_identifier, sep = "-"),
      active = 1,
      ctsi_study_id = as.numeric(NA)
    ) |>
    dplyr::anti_join(initial_service_instance, by = c("service_instance_id")) |>
    dplyr::select(
      "service_type_code",
      "service_identifier",
      "service_instance_id",
      "active",
      "ctsi_study_id"
    )

  return(new_service_instances)
}
