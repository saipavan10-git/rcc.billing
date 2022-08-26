# Change Log
All notable changes to the rcc.billing package and its contained scripts will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).


## [0.1.1] - 2022-08-26
### Changed
- Build rcc.billing in Dockerfile (Philip Chase)


## [0.1.0] - 2022-08-25
### Added
 - Add function connect_to_rcc_billing_db
 - Add function convert_schema_to_sqlite
 - Add function create_and_load_test_table
 - Add function create_table
 - Add function draft_communication_record_from_line_item
 - Add function fix_data_in_invoice_line_item
 - Add function fix_data_in_invoice_line_item_communication
 - Add function fix_data_in_redcap_log_event
 - Add function fix_data_in_redcap_projects
 - Add function fix_data_in_redcap_user_information
 - Add function get_creators
 - Add function get_last_project_user
 - Add function get_privileged_user
 - Add function get_project_pis
 - Add function get_projects_needing_new_owners
 - Add function get_projects_without_owners
 - Add function get_reassigned_line_items
 - Add function get_unpaid_redcap_prod_per_project_line_items
 - Add function invoice_line_item_df_from
 - Add function mutate_columns_to_posixct
 - Add function populate_table
 - Add function transform_invoice_line_items_for_csbt
 - Add function update_billable_by_ownership
 - Add ETL cancel_redcap_prod_per_project_line_item.R
 - Add ETL cleanup_project_ownership_table.R
 - Add ETL create_and_send_new_redcap_prod_per_project_line_items.R
 - Add ETL deploy_initial_rcc_billing_db.R
 - Add ETL fix_bad_activity_and_login_dates.R
 - Add ETL reassign_redcap_prod_per_project_line_item.R
 - Add ETL receive_payments.R
 - Add ETL update_ctsi_study_ids.R
 - Add ETL update_project_billable_attribute.R
 - Add dataset cleanup_project_ownership_test_data
 - Add dataset csbt_column_names
 - Add dataset ctsit_staff
 - Add dataset ctsit_staff_employment_periods
 - Add dataset fiscal_years
 - Add dataset invoice_line_item_communications_test_data
 - Add dataset invoice_line_item_reasons
 - Add dataset invoice_line_item_statuses
 - Add dataset invoice_line_item_test_data
 - Add dataset one_deleted_project_record
 - Add dataset projects_table_fragment
 - Add dataset redcap_entity_project_ownership_test_data
 - Add dataset redcap_log_event_test_data
 - Add dataset redcap_projects_test_data
 - Add dataset redcap_user_information_test_data
 - Add dataset service_instance_test_data
 - Add dataset service_type_test_data


## [0.0.0] - 2022-03-21
### Added
- Initial commit of rcc.billing, an automated, data-driven service billing system implemented on REDCap Custodian (Philip Chase)
