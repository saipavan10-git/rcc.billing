# Change Log
All notable changes to the rcc.billing package and its contained scripts will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).


## [1.17.0] - 2023-03-17
### Added
- Add ETL to write to org_hierachies from VIVO Add schema for org_hierarchies (Kyle Chesney)

### Changed
- Add cron'd runs of sequester_orphans.R (Philip Chase)
- Simplify manual sequestration in sequester_orphans.R (Philip Chase)


## [1.16.0] - 2023-03-03
### Added
- Add banned_owners rule to get_orphaned_projects function Add banned_owners schema (Kyle Chesney)

### Changed 
- Embrace subdirectories for db specific tables in testing data (Kyle Chesney)
- Rename *_conn to mem_*_conn in get_orphaned_projects test (Kyle Chesney)
- Prevent blank emails on new invoice line items (Philip Chase)


## [1.15.0] - 2023-02-27
### Added
- Add unit test for get_orphaned_projects() (Philip Chase)
- Add unresolvable_ownership_issues to get_orphans function (Kyle Chesney)
- Add request_correction_of_bad_ownership_data report (Kyle Chesney)
- Add erasure of project ownership identification columns to cleanup_project_ownership_table (Kyle Chesney)

### Changed
- Use variable instead of hardcoding in send_alert_email (Kyle Chesney)
- Prevent emails RE: unresolvable_ownership_issues in sequester_orphans (Kyle Chesney)


## [1.14.0] - 2023-01-27
### Added
- Add complete_but_non_sequestered rule to get_orphaned_projects (Philip Chase)
- Add warn_completers_of_impending_sequestration.R (Philip Chase)

### Changed
- Update version numbers in NEWS.md to conform to tagging error on 2022-12-19 (Philip Chase)


## [1.13.0] - 2023-01-24
### Changed
- Update get_orphaned_projects reducing the horizon from 12 to 11 months (Philip Chase)
- Move warn_owners_of_impending_bill.R back to the default dates (Philip Chase)
- Update update_invoice_line_items_with_invoicing_details.R (Philip Chase)
- Revert error in sequester_orphans.R (Philip Chase)
- Sync invoice_line_item table to RC DB during update_invoice_line_items_with_invoicing_details (Kyle Chesney)
- Mark CTSIT-owned projects as non-billable in update_project_billable_attribute.R (Philip Chase)


## [1.12.1] - 2022-12-19
### Changed
- Load rcc.billing library in cleanup_bad_email_addresses.R (Philip Chase)


## [1.12.0] - 2022-12-19
### Added
- Port cleanup_bad_email_addresses from rcc.ctsit (Kyle Chesney)
- Create get_bad_emails_from_log (Kyle Chesney)

### Changed
- Update billable_candidates.R (Philip Chase)
- Ignore timestamp updates in update_invoice_line_items_with_invoicing_details.R (Philip Chase)


## [0.11.1] - 2022-12-07
### Changed
- Temporarily move warn_owners_of_impending_bill to the 3rd and 14th of the month (Philip Chase)
- Add a comment to guide manual orphan sequestration (Philip Chase)
- Fix new row IDs in create_and_send_new_redcap_prod_per_project_line_items.R (Philip Chase)


## [0.11.0] - 2022-11-14
### Added
- Set invoice_line_item status conditionally based on date_of_pmt presence when loading data from CSBT (Kyle Chesney)


## [0.10.0] - 2022-11-02
### Added
- Include project_irb_number in report/billable_candidates (Kyle Chesney)
- Add invoice facts to billable candidates (Philip Chase)
- Re-enable empty_and_inactive_projects in get_orphaned_projects (Philip Chase)

### Changed
- Adjust the id column in new_invoice_line_item_communications to avoid collisions (Philip Chase)


## [0.9.1] - 2022-10-28
### Changed
- Execute named lists construction with lst (Philip Chase)


## [0.9.0] - 2022-10-28
### Added
- Add transform_invoice_line_items_for_ctsit (Kyle Chesney)
- Add update_invoice_line_items_with_invoicing_details (Kyle Chesney)
- Add rule inactive_projects_with_no_viable_users to get_orphaned_projects() (Philip Chase)
- Add orphaned_projects to logged data in sequester_orphans.R (Philip Chase)

### Changed
- Show user_lastlogin in billable_candidates.R (Philip Chase)
- Use full month name instead of abbreviation in create_and_send_new_redcap_prod_per_project_line_items (Kyle Chesney)
- Associate month_invoiced with project's birth month rather than script run month (Kyle Chesney)


## [0.8.1] - 2022-10-21
### Changed
- Include GITHUB_PAT in docker build step (Philip Chase)
- Pass project_id vector to sequester_projects (Philip Chase)


## [0.8.0] - 2022-10-21
### Added
- Activate sequester_orphans.R (Philip Chase)
- Add filter for no viable users to get_orphaned_projects (Kyle Chesney)
- Add get_user_rights_and_info (Philip Chase)
- Install rcc.ctsit in Dockerfile using a GitHub PAT (Philip Chase)

### Changed
- Make PIs and faculty project owners (Philip Chase)


## [0.7.1] - 2022-10-04
### Changed
- Update create_and_send_new_redcap_prod_per_project_line_items.R (Philip Chase)


## [0.7.0] - 2022-10-04
### Added
- Add get_orphaned_projects() (Philip Chase)
- Add sequester_orphans (Philip Chase)
- Add sequester_projects() (Philip Chase)

### Changed
- Fix service_type in service_type_test_data (Philip Chase)
- Update csbt column output names CTSI IT ID -> CTSIT ID (Kyle Chesney)
- Filter out non-sequestered projects in create_and_send_new_redcap_prod_per_project_line_items (Kyle Chesney)
- Include project_ownership user identifiers in create_and_send_new_redcap_prod_per_project_line_items.R (Philip Chase)


## [0.6.1] - 2022-09-28
### Added
- Run billable_candidates.R weekly (Philip Chase)

### Changed
- Fix subject, body, and from in billable_candidates.R (Philip Chase)


## [0.6.0] - 2022-09-28
### Added
- Create billable_candidates report (Kyle Chesney)
- Add deleted projects filter and fix birthday_in_previous_month filter when creating invoice line items(Philip Chase)


## [0.5.0] - 2022-09-22
### Added
- Run warn_owners_of_impending_bill.R on 1st and 23rd of the month (Philip Chase)


## [0.4.0] - 2022-09-07
### Added
- Activate warn_owners_of_impending_bill.R (Philip Chase)
- Add correct_project_pi_emails (Kyle Chesney)


## [0.3.1] - 2022-09-06
### Added
- Catch and log all errors and successes in warn_owners_of_impending_bill.R (Kyle Chesney, Philip Chase)


## [0.3.0] - 2022-09-01
### Added
- Add warn_owners_of_impending_bill.R (Kyle Chesney, Philip Chase)


## [0.2.0] - 2022-08-30
### Added
- Add warn_owners_of_impending_bill.R (Kyle Chesney)


## [0.1.2] - 2022-08-26
### Changed
- Fix paths in cron files (Philip Chase)
- Load rcc.billing in update_project_billable_attribute.R (Philip Chase)


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
