# load cleanup_project_ownership_test_data into memory
load(file = testthat::test_path("cleanup_project_ownership", "cleanup_project_ownership_test_data.rda"))

testthat::test_that("service_type sqlite schema is created and correct test data is returned", {
    table_name <- "redcap_projects"
    test_data <- get0(paste0(table_name, "_test_data"))
    conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

    sqlite_schema <- convert_schema_to_sqlite(table_name = table_name)
    create_table(
        conn = conn,
        schema = sqlite_schema
    )
    results <- populate_table(
        conn = conn,
        table_name = table_name,
        use_test_data = T
    ) %>% fix_data_in_redcap_projects()

    DBI::dbDisconnect(conn)
    testthat::expect_equal(dplyr::as_tibble(results), test_data)
})

testthat::test_that("get_projects_needing_new_owners returns the correct vector of project IDs", {
  expected_result <- seq(from = 29, to = 33)
  testthat::expect_equal(
    get_projects_needing_new_owners(
      redcap_entity_project_ownership = cleanup_project_ownership_test_data$redcap_entity_project_ownership,
      redcap_user_information = cleanup_project_ownership_test_data$redcap_user_information
    ),
    expected_result
  )
})

testthat::test_that("get_projects_without_owners returns the correct vector of project IDs", {
  expected_result <- c(18,19,20,24)
  testthat::expect_equal(
    get_projects_without_owners(
      redcap_projects =
        cleanup_project_ownership_test_data$redcap_projects,
      redcap_entity_project_ownership =
        cleanup_project_ownership_test_data$redcap_entity_project_ownership
    ),
    expected_result
  )
})

testthat::test_that("get_project_pis returns the correct dataframe wth default returns", {
  expected_result <- tribble(
    ~project_id, ~project_pi_email, ~project_pi_firstname, ~project_pi_mi, ~project_pi_lastname, ~project_pi_username,
    28, "tfc@example.org", "Thomas", "F", "Chase", as.character(NA)
  )
  testthat::expect_equal(
    get_project_pis(redcap_projects = cleanup_project_ownership_test_data$redcap_projects),
    expected_result
  )

})

testthat::test_that("get_project_pis returns the correct dataframe with RCPO returns", {
  expected_result <- tribble(
    ~pid, ~email, ~firstname, ~lastname, ~username,
    28, "tfc@example.org", "Thomas", "Chase", as.character(NA)
  )
  testthat::expect_equal(
    get_project_pis(redcap_projects = cleanup_project_ownership_test_data$redcap_projects,
                    return_project_ownership_format = TRUE),
    expected_result
  )

})

testthat::test_that("get_creators returns unsuspended creators in RCPO format", {
  expected_result <- tribble(
    ~pid, ~username,
    29, "admin"
  )
  testthat::expect_equal(
    expected_result,
    get_creators(
      redcap_projects = cleanup_project_ownership_test_data$redcap_projects %>%
        dplyr::filter(project_id >= 28),
      redcap_user_information = cleanup_project_ownership_test_data$redcap_user_information,
      redcap_staff_employment_periods = ctsit_staff_employment_periods,
      return_project_ownership_format = T
    )
  )
})

testthat::test_that("get_creators returns any creator in RCPO format", {
  expected_result <- tribble(
    ~pid, ~username,
    29, "admin",
    33, "susan_suspended"
  )
  testthat::expect_equal(
    expected_result,
    get_creators(
      redcap_projects = cleanup_project_ownership_test_data$redcap_projects %>%
        dplyr::filter(project_id >= 28),
      redcap_user_information = cleanup_project_ownership_test_data$redcap_user_information,
      redcap_staff_employment_periods = ctsit_staff_employment_periods,
      include_suspended_users = T,
      return_project_ownership_format = T
    )
  )
})

testthat::test_that("get_privileged_user returns unsuspended, high-privilege users in RCPO format", {
  expected_result <- tribble(
    ~pid, ~username,
    29, "admin",
    30, "alice"
  )
  testthat::expect_equal(
    expected_result,
    get_privileged_user(
      redcap_projects = cleanup_project_ownership_test_data$redcap_projects %>%
        dplyr::filter(project_id >= 28),
      redcap_user_information = cleanup_project_ownership_test_data$redcap_user_information,
      redcap_staff_employment_periods = ctsit_staff_employment_periods,
      redcap_user_rights = cleanup_project_ownership_test_data$redcap_user_rights,
      redcap_user_roles = cleanup_project_ownership_test_data$redcap_user_roles,
      return_project_ownership_format = T
    )
  )
})

testthat::test_that("get_privileged_user returns unsuspended users with any privilege in RCPO format", {
  expected_result <- tribble(
    ~pid, ~username,
    29, "admin",
    30, "alice",
    31, "bob"
  )
  testthat::expect_equal(
    expected_result,
    get_privileged_user(
      redcap_projects = cleanup_project_ownership_test_data$redcap_projects %>%
        dplyr::filter(project_id >= 28),
      redcap_user_information = cleanup_project_ownership_test_data$redcap_user_information,
      redcap_staff_employment_periods = ctsit_staff_employment_periods,
      redcap_user_rights = cleanup_project_ownership_test_data$redcap_user_rights,
      redcap_user_roles = cleanup_project_ownership_test_data$redcap_user_roles,
      include_low_privilege_users = T,
      return_project_ownership_format = T
    )
  )
})


test_that("update_billable_by_ownership", {
  expected_result <- tribble(
    ~pid, ~username, ~billable,
    2345, NA, 1,
    6490, "tls", 0
  )
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  # populate project ownership table
  po_table_name <- "redcap_entity_project_ownership"
  po_test_data <- get0(paste0(po_table_name, "_test_data"))
  po_sqlite_schema <- convert_schema_to_sqlite(table_name = po_table_name)
  create_table(
    conn = conn,
    schema = po_sqlite_schema
  )
  populate_table(
    conn = conn,
    table_name = po_table_name,
    use_test_data = T
  )

  rcp_table_name <- "redcap_projects"
  rcp_test_data <- get0(paste0(rcp_table_name, "_test_data"))
  rcp_sqlite_schema <- convert_schema_to_sqlite(table_name = rcp_table_name)
  create_table(
    conn = conn,
    schema = rcp_sqlite_schema
  )
  populate_table(
    conn = conn,
    table_name = rcp_table_name,
    use_test_data = T
  )

  output <- update_billable_by_ownership(conn)
  results <- output$update_records %>%
    dplyr::select(pid, username, billable)

  DBI::dbDisconnect(conn)
  testthat::expect_equal(dplyr::as_tibble(results), expected_result)
})


test_that("update_billable_if_owned_by_ctsit", {
  expected_result <- tribble(
    ~pid, ~username, ~billable,
    6490, "tls", 0
  )
  conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

  # populate project ownership table
  po_table_name <- "redcap_entity_project_ownership"
  po_test_data <- get0(paste0(po_table_name, "_test_data"))
  po_sqlite_schema <- convert_schema_to_sqlite(table_name = po_table_name)
  create_table(
    conn = conn,
    schema = po_sqlite_schema
  )
  populate_table(
    conn = conn,
    table_name = po_table_name,
    use_test_data = T
  )

  # hack the data for tls show that the project show owns is billable
  sql = "update redcap_entity_project_ownership set billable = 1 where username = 'tls'"
  DBI::dbExecute(
    conn = conn,
    statement = sql
    )

  rcp_table_name <- "redcap_projects"
  rcp_test_data <- get0(paste0(rcp_table_name, "_test_data"))
  rcp_sqlite_schema <- convert_schema_to_sqlite(table_name = rcp_table_name)
  create_table(
    conn = conn,
    schema = rcp_sqlite_schema
  )
  populate_table(
    conn = conn,
    table_name = rcp_table_name,
    use_test_data = T
  )

  output <- update_billable_if_owned_by_ctsit(conn)
  results <- output$update_records %>%
    dplyr::select(pid, username, billable)

  DBI::dbDisconnect(conn)
  testthat::expect_equal(dplyr::as_tibble(results), expected_result)
})


testthat::test_that(
  "get_reassigned_line_items returns a df with project ownership data from redcap_entity_project_ownership",
  {
    table_names <-
      c("redcap_entity_project_ownership", "invoice_line_item")

    conn <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")

    for (table_name in table_names) {
      create_and_load_test_table(
        table_name = table_name,
        conn = conn,
        load_test_data = T,
        is_sqllite = T
      )
    }

    sent_line_items <-
      get_unpaid_redcap_prod_per_project_line_items(conn) %>%
      dplyr::mutate(
        pi_last_name = dplyr::if_else(
          pi_last_name == "Chase",
          "reassign_project_ownership",
          pi_last_name
        ),
        pi_first_name = dplyr::if_else(
          pi_first_name == "Joyce",
          "reassign_project_ownership",
          pi_first_name
        ),
        pi_email = dplyr::if_else(
          pi_email == "tls@ufl.edu",
          "reassign_project_ownership",
          pi_email
        ),
        gatorlink = dplyr::if_else(
          gatorlink == "estoffs",
          "reassign_project_ownership",
          gatorlink
        )
      )

    reassigned_line_items <-
      get_reassigned_line_items(sent_line_items, conn) %>%
      dplyr::select(pi_last_name, pi_first_name, pi_email, gatorlink) %>%
      dplyr::arrange(dplyr::desc(pi_last_name))

    expected_result <-
      dplyr::tbl(conn, "redcap_entity_project_ownership") %>%
      dplyr::filter(pid %in% !!sent_line_items$project_id) %>%
      dplyr::mutate_at("pid", as.character) %>%
      dplyr::select(
        pi_last_name = lastname,
        pi_first_name = firstname,
        pi_email = email,
        gatorlink = username
      ) %>%
      dplyr::arrange(dplyr::desc(pi_last_name)) %>%
      dplyr::collect()

    DBI::dbDisconnect(conn)

    testthat::expect_equal(reassigned_line_items, expected_result)
  }
)

testthat::test_that("get_research_projects_not_using_viable_pi_data can detect a project with non-viable PI data", {
  redcap_projects <-
    cleanup_project_ownership_test_data$redcap_projects %>%
    mutate(purpose = 2) %>%
    mutate(project_pi_email = if_else(
      project_id %in% c(21, 22, 25),
      "you@example.org",
      project_pi_email
    ))

  redcap_entity_project_ownership <-
    cleanup_project_ownership_test_data$redcap_entity_project_ownership %>%
    mutate(username = if_else(pid %in% c(22,25), as.character(NA), username)) %>%
    mutate(email = if_else(pid == 22, "you@example.org", email)) %>%
    mutate(email = if_else(pid == 25, "not_the_pi@example.org", email))

  redcap_user_information <-
    cleanup_project_ownership_test_data$redcap_user_information

  project_ids_with_issues <- get_research_projects_not_using_viable_pi_data(
    redcap_projects = redcap_projects,
    redcap_entity_project_ownership = redcap_entity_project_ownership,
    redcap_user_information = redcap_user_information
  )

  expected_result <- c(15, 16, 17, 25, 26, 27, 28, 29, 30, 31, 32, 33)

  testthat::expect_equal(project_ids_with_issues, expected_result)

})

