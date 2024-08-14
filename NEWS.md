# rcc.billing 1.41.1 (released 2024-08-14)
- Add dependencies in pkgdown.yaml (@pbchase)

# rcc.billing 1.41.0 (released 2024-08-13)
- Add first vignette, cleanup_bad_email_addresses (@pbchase)

# rcc.billing 1.40.0 (released 2024-08-13)
- Initialize pkgdown with usethis::use_pkgdown_github_pages() (@pbchase)
- Update README.md (@pbchase)
- Add schema upgrade scripts for release 1.39.0 (@pbchase)

# rcc.billing 1.39.1 (released 2024-08-13)
- Add return_all_records param to get_service_request_lines() (@pbchase, #239)

# rcc.billing 1.39.0 (released 2024-08-13)
- Add fiscal_contact details to invoice_line_item (@saipavan10-git, @pbchase, #237, #238)  

# rcc.billing 1.38.1 (released 2024-08-01)
- Read always_bill in update_probono_service_request_records.R (@pbchase)

# rcc.billing 1.38.0 (released 2024-08-01)
- Deactivate create_and_send_new_invoice_line_items (@pbchase)
- Add support for always_bill in get_probono_service_request_updates() (@pbchase, #236)
- Fix duckdb disconnect warnings caused by tests (@pbchase, #235)
- Create and send service_request_line_items in create_and_send_new_invoice_line_items (@saipavan10-git, @pbchase, #235)
- Add get_service_request_lines() (@saipavan10-git, @pbchase, #233)
- Add get_service_request_line_items() (@saipavan10-git, @pbchase, #233)
- Add tests for get_project_details_for_billing() (@pbchase, #233)
- Fix tests for get_target_projects_to_invoice() (@pbchase, #233)
- Update docs for get_new_project_invoice_line_items() (@pbchase, #233)

# rcc.billing 1.37.2 (released 2024-07-22)
- Refactor create_and_send_new_redcap_prod_per_project_line_items.R (@pbchase, #228, #230)
- Add get_new_project_invoice_line_items() (@pbchase, #228, #230).
- Add get_new_project_service_instances() (@pbchase, #228, #230).
- Add get_target_projects_to_invoice() (@pbchase, #228, #230).

# rcc.billing 1.37.1 (released 2024-07-01)
- Fix bugs in revenue_status_and_projections.qmd (@pbchase)

# rcc.billing 1.37.0 (released 2024-06-26)
- Adjust run times for update_probono_service_request_records (@pbchase)
- Add update_free_support_time_remaining.R and a schema file for the empty table it needs (@pbchase, #224)
- Add people_with_rights_to_unpaid_invoice_line_items.R, get_project_flags(), and get_user_rights_and_info() (@pbchase, #220)
- Rename get_user_rights_and_info() to get_user_rights_and_info_v1() (@pbchase)

# rcc.billing 1.36.1 (released 2024-06-20)
- Mount the credentials volume in cron/update_probono_service_request_records (@pbchase)

# rcc.billing 1.36.0 (released 2024-06-20)
- Add single-use/backfill_billable_rate_in_service_request_records.R (@pbchase)
- Modernize_imports_and_conform_to_tidyselect (@pbchase, #223)
- Add get_service_request_lines() (@ljwoodley, @pbchase, #219, #205)
- Add update_invoice_line_items_to_correct_fiscal_year.R a script we used once in August 2023 (@pbchase)
- Add get_probono_service_request_records() (@ljwoodley, @pbchase, #218, #207)

# rcc.billing 1.35.0 (released 2024-05-23)
- Set custom CC when running revenue_status_and_projections (@pbchase)
- Revise input file search and management in update_invoice_line_items_with_invoicing_details.R (@pbchase)
- Add get_ctsi_study_id_to_project_id_map (@ljwoodley, @pbchase, @ChemiKyle, #212)
- Reflow make_test_data_for_get_billable_candidates.R (@pbchase)

# rcc.billing 1.34.0 (released 2024-04-26)
- Add draft_reports.qmd (@pbchase)
- Add get_project_details_for_billing (@ljwoodley)
- Add 'REDCap consulting' service_type to test data (@pbchase)
- CC REDCAP_BILLING_L in request_correction_of_bad_ownership_data.R (@pbchase)
- Update create_and_send_new_redcap_prod_per_project_line_items.R to prevent duplicates (@pbchase)
- Update revenue_status_and_projections.qmd (@pbchase)
  - Add a note to Figure 3. 'REDCap APB Revenue by FY with 12 months of projected revenue.'    
  - Add more aging brackets.
  - Fix chit-chat about historic payment rate.
  - Remove 'Possible revenue opportunities'.
  - Remove 'Projecting income from extant billable projects' section    
  - Remove 'Payments Rates and Projections' section.
  - Remove 'Report summary' section.


## [1.33.2] - 2024-03-15
### Changed
- Fix NA in average_portion_paid in revenue_status_and_projections.qmd (@pbchase)


## [1.33.1] - 2024-03-12
### Changed
- Fix bad collect() syntax (@pbchase)
- Fix crashes in sequester_unpaid_projects.R (@pbchase)


## [1.33.0] - 2024-02-27
### Added
- Add fiscal year reporting to revenue_status_and_projections.qmd (@pbchase)

### Changed
- Add revenue_description to red_team_auxiliary_revenue_actuals_redcap_apb.csv output in revenue_status_and_projections.qmd (@pbchase)
- Control positioning in revenue_status_and_projections.qmd (@pbchase)


## [1.32.0] - 2024-02-14
### Added
- Add owner's org data to get_billable_candidates() output (@pbchase, @ChemiKyle)


## [1.31.1] - 2024-02-12
### Changed
Update update_invoice_line_items_with_invoicing_details.R to fix target table in service_instance_update.  (@pbchase)


## [1.31.0] - 2024-02-08
### Added
- Curate and use CTSI Study IDs (@pbchase)


## [1.30.0] - 2024-01-12
### Added
- Fix typos in text of revenue_status_and_projections.qmd (@pbchase)

### Changed
- Update update_invoice_line_items_with_invoicing_details to handle do not bill reasons (@ChemiKyle)


## [1.29.1] - 2023-12-08
### Changed
- Fix create_and_send_new_redcap_prod_per_project_line_items.R


## [1.29.0] - 2023-11-21
### Changed
- Implement code changes required for the Fall 2023 rate increase (Philip Chase)
- Update revenue_status_and_projections.qmd adding revenue_by_month_received (Philip Chase, Laurence James-Woodley)


## [1.28.0] - 2023-11-01
### Changed
- Replace fig-revenue-by-month with fig-revenue-by-month-invoiced and fig-revenue-by-month-received in revenue_status_and_projections.qmd (Philip Chase)
- Add bar labels to fig-revenue-by-month-* figures in revenue_status_and_projections.qmd (Philip Chase)
- Adjust project revenue to use just the last 12 months and correct for the rate increase in revenue_status_and_projections.qmd (Philip Chase)


## [1.27.0] - 2023-10-31
### Added
- Add delete_abandoned_projects.R (Laurence James-Woodley)


## [1.26.0] - 2023-10-24
### Added
- Add export_project_data_with_owner_org.R (Philip Chase)

### Changed
- Change annual project price from $100 to $130 in warning communications (Kyle Chesney)


## [1.25.1] - 2023-10-16
### Changed
- Update broken Update Project Ownership links (Kyle Chesney)
- Prevent sequestered projects from receiving billing warnings (Kyle Chesney)
- Fix typo in revenue_status_and_projections.qmd (Philip Chase)
- Update broken link to document that details project deletion steps (Kyle Chesney)
- Update update_invoice_line_items_with_invoicing_details.R (Philip Chase)
- Remove unused code from warn_owners_of_impending_bill.R (Philip Chase)
- Update Roxygen version in DESCRIPTION (Philip Chase)
- Update test-get_billable_candidates.R (Philip Chase)
- Remove unused code from get_billable_candidates() (Philip Chase)


## [1.25.0] - 2023-08-29
### Changed
- Update revenue_status_and_projections (Philip Chase)


## [1.24.0] - 2023-08-23
### Added
- Add write_uf_fiscal_orgs_to_person_org ETL (Kyle Chesney)
- add cron job for invoice line item creation (Laurence James-Woodley)
- add test for df row count (Laurence James-Woodley)

### Changed
- Replace current_fiscal_year with fiscal_year_invoiced concept (Philip Chase)
- create empty please_fix_log df (Laurence James-Woodley)


## [1.23.0] - 2023-08-04
### Added
- Add reason to project sequestration messages (Philip Chase)

### Changed
- Add speed improvements to get_orphaned_projects (Philip Chase)
- Replace NA character with NA string to prevent entire email from appearing as NA (Kyle Chesney)
- Refactor SQLite out of get_orphaned_projects and its tests (Philip Chase)
- Update render report (Laurence James-Woodley)


## [1.22.2] - 2023-07-19
### Changed
- Accommodate very long project titles (Philip Chase)


## [1.22.1] - 2023-07-19
### Changed
- Accommodate very long project titles (Philip Chase)
- Update revenue_status_and_projections.qmd (Philip Chase)
- Update update_invoice_line_items_with_invoicing_details.R to handle non-rccbilling data (Philip Chase)
- Update report_on_projects_by_dept.R (Philip Chase)


## [1.22.0] - 2023-06-23
### Added
- Add cancel_invoice_line_items.R (Philip Chase)
- Add ban_people_from_ownership.R (Philip Chase)
- Add report_on_projects_by_dept.R (Philip Chase)
- Add get_billable_candidates() (Philip Chase)

### Changed
- Silence long path warnings relating to request_correction_of_bad_ownership_data.R (Philip Chase)
- Refactor billable_candidates.R to use get_billable_candidates() (Philip Chase)


## [1.21.2] - 2023-06-07
### Changed
- Update revenue_status_and_projections.qmd (Philip Chase)


## [1.21.1] - 2023-06-07
### Changed
- Update cron file for new render_report.R (Philip Chase)


## [1.21.0] - 2023-06-07
### Changed
- Update render_report.R to add Quarto support (Philip Chase)
- Ban PIs who left UF in update_invoice_line_items_with_invoicing_details.R (Philip Chase)


## [1.20.0] - 2023-06-05
### Added
- Add revenue_status_and_projections.qmd (Philip Chase)

### Changed
- Update email templates (Philip Chase)


## [1.19.0] - 2023-05-24
### Added
- Add remind_owners_to_review_ownership.R (Philip Chase)

### Changed
- Update sequester_unpaid_projects.R (Philip Chase)
- Add historic redcap admins to CTS-IT staff (Philip Chase)


## [1.18.2] - 2023-04-03
### Changed
- Filter out sequestered and deleted projects in sequester_unpaid_projects.R (Philip Chase)


## [1.18.1] - 2023-04-03
### Added
- Fix NEWS.md (Philip Chase)


## [1.18.0] - 2023-04-03
### Added
- Add sequester_unpaid_projects ETL (Kyle Chesney)

### Changed
- Set date_sent when creating invoice line items (Philip Chase)
- Fix cron for write_uf_fiscal_orgs_to_org_hierarchies.R again (Philip Chase)


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
