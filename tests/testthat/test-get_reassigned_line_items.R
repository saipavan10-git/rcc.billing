testthat::test_that(
  "get_reassigned_line_items retuirns a df with project ownership data from redcap_entity_project_ownership",
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

    rc_conn <- conn
    rcc_billing_conn <- conn

    sent_line_items <-
      get_unpaid_redcap_prod_per_project_line_items(rcc_billing_conn) %>%
      mutate(
        pi_last_name = if_else(
          pi_last_name == "Chase",
          "reassign_project_ownership",
          pi_last_name
        ),
        pi_first_name = if_else(
          pi_first_name == "Joyce",
          "reassign_project_ownership",
          pi_first_name
        ),
        pi_email = if_else(
          pi_email == "tls@ufl.edu",
          "reassign_project_ownership",
          pi_email
        ),
        gatorlink = if_else(
          gatorlink == "estoffs",
          "reassign_project_ownership",
          gatorlink
        )
      )

    reassigned_line_items <-
      get_reassigned_line_items(sent_line_items, rc_conn) %>%
      select(pi_last_name, pi_first_name, pi_email, gatorlink) %>%
      arrange(desc(pi_last_name))

    redcap_entity_project_ownership <-
      tbl(rc_conn, "redcap_entity_project_ownership") %>%
      filter(pid %in% !!sent_line_items$project_id) %>%
      mutate_at("pid", as.character) %>%
      select(
        pi_last_name = lastname,
        pi_first_name = firstname,
        pi_email = email,
        gatorlink = username
      ) %>%
      arrange(desc(pi_last_name)) %>%
      collect()

    testthat::expect_equal(reassigned_line_items, redcap_entity_project_ownership)
  }
)
