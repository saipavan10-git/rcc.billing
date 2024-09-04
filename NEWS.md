# rcc.billing 1.43.0 (released 2024-09-04)
- Fix doc formatting for service_request_time() (@pbchase)
- Add Sai's ORCID in DESCRIPTION (@pbchase)
- Add employees to ctsit_staff* data frames (@pbchase, #250)
- Refactor ctsit_staff.R to make it easier to maintain (@pbchase, #250)
- Update revenue_status_and_projections.qmd (@pbchase)
- Add 'REDCap consulting revenue' section to revenue_status_and_projections.qmd (@pbchase)
- Update vignettes (@pbchase)

# rcc.billing 1.42.1 (released 2024-08-26)
- Remove unsuspended_high_privilege_faculty from cleanup_project_ownership_table.R (@pbchase)

# rcc.billing 1.42.0 (released 2024-08-26)
- Add ORCIDs in package authors (@pbchase, #249)
- Add vignettes for most ETLs and reports (@pbchase, @saipavan10-git, #244, #245, #246, #247)

# rcc.billing 1.41.4 (released 2024-08-15)
- Update github workflows to allow R to correctly access the PAT (@saipavan10-git)
- Update description file to have a REMOTES section for ctsit packages (@saipavan10-git)
- Update dependency installation for pkgdown workflow (@saipavan10-git)

# rcc.billing 1.41.3 (released 2024-08-14)
- Update github workflows to address missing dependencies (@pbchase)

# rcc.billing 1.41.2 (released 2024-08-14)
- Update image version in run-tests.yaml (@pbchase)
- Resequence dependencies in pkgdown.yaml (@pbchase)

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

# rcc.billing 1.33.2 (released 2024-03-15)
- Fix NA in average_portion_paid in revenue_status_and_projections.qmd (@pbchase)

# rcc.billing 1.33.1 (released 2024-03-12)
- Fix bad collect() syntax (@pbchase)
- Fix crashes in sequester_unpaid_projects.R (@pbchase)

# rcc.billing 1.33.0 (released 2024-02-27)
- Add fiscal year reporting to revenue_status_and_projections.qmd (@pbchase)
- Add revenue_description to red_team_auxiliary_revenue_actuals_redcap_apb.csv output in revenue_status_and_projections.qmd (@pbchase)
- Control positioning in revenue_status_and_projections.qmd (@pbchase)

# rcc.billing 1.32.0 (released 2024-02-14)
- Add owner's org data to get_billable_candidates() output (@pbchase, @ChemiKyle)

# rcc.billing 1.31.1 (released 2024-02-12)
- Update update_invoice_line_items_with_invoicing_details.R to fix target table in service_instance_update.  (@pbchase)

# rcc.billing 1.31.0 (released 2024-02-08)
- Curate and use CTSI Study IDs (@pbchase)

# rcc.billing 1.30.0 (released 2024-01-12)
- Fix typos in text of revenue_status_and_projections.qmd (@pbchase)
- Update update_invoice_line_items_with_invoicing_details to handle do not bill reasons (@ChemiKyle)

# rcc.billing 1.29.1 (released 2023-12-08)
- Fix create_and_send_new_redcap_prod_per_project_line_items.R

# rcc.billing 1.29.0 (released 2023-11-21)
- Implement code changes required for the Fall 2023 rate increase (@pbchase)
- Update revenue_status_and_projections.qmd adding revenue_by_month_received (@pbchase, @ljwoodley)

# rcc.billing 1.28.0 (released 2023-11-01)
- Replace fig-revenue-by-month with fig-revenue-by-month-invoiced and fig-revenue-by-month-received in revenue_status_and_projections.qmd (@pbchase)
- Add bar labels to fig-revenue-by-month-* figures in revenue_status_and_projections.qmd (@pbchase)
- Adjust project revenue to use just the last 12 months and correct for the rate increase in revenue_status_and_projections.qmd (@pbchase)

# rcc.billing 1.27.0 (released 2023-10-31)
- Add delete_abandoned_projects.R (@ljwoodley)

# rcc.billing 1.26.0 (released 2023-10-24)
- Add export_project_data_with_owner_org.R (@pbchase)
- Change annual project price from $100 to $130 in warning communications (@ChemiKyle)

# rcc.billing 1.25.1 (released 2023-10-16)
- Update broken Update Project Ownership links (@ChemiKyle)
- Prevent sequestered projects from receiving billing warnings (@ChemiKyle)
- Fix typo in revenue_status_and_projections.qmd (@pbchase)
- Update broken link to document that details project deletion steps (@ChemiKyle)
- Update update_invoice_line_items_with_invoicing_details.R (@pbchase)
- Remove unused code from warn_owners_of_impending_bill.R (@pbchase)
- Update Roxygen version in DESCRIPTION (@pbchase)
- Update test-get_billable_candidates.R (@pbchase)
- Remove unused code from get_billable_candidates() (@pbchase)

# rcc.billing 1.25.0 (released 2023-08-29)
- Update revenue_status_and_projections (@pbchase)

# rcc.billing 1.24.0 (released 2023-08-23)
- Add write_uf_fiscal_orgs_to_person_org ETL (@ChemiKyle)
- add cron job for invoice line item creation (@ljwoodley)
- add test for df row count (@ljwoodley)
- Replace current_fiscal_year with fiscal_year_invoiced concept (@pbchase)
- create empty please_fix_log df (@ljwoodley)

# rcc.billing 1.23.0 (released 2023-08-04)
- Add reason to project sequestration messages (@pbchase)
- Add speed improvements to get_orphaned_projects (@pbchase)
- Replace NA character with NA string to prevent entire email from appearing as NA (@ChemiKyle)
- Refactor SQLite out of get_orphaned_projects and its tests (@pbchase)
- Update render report (@ljwoodley)

# rcc.billing 1.22.2 (released 2023-07-19)
- Accommodate very long project titles (@pbchase)

# rcc.billing 1.22.1 (released 2023-07-19)
- Accommodate very long project titles (@pbchase)
- Update revenue_status_and_projections.qmd (@pbchase)
- Update update_invoice_line_items_with_invoicing_details.R to handle non-rccbilling data (@pbchase)
- Update report_on_projects_by_dept.R (@pbchase)

# rcc.billing 1.22.0 (released 2023-06-23)
- Add cancel_invoice_line_items.R (@pbchase)
- Add ban_people_from_ownership.R (@pbchase)
- Add report_on_projects_by_dept.R (@pbchase)
- Add get_billable_candidates() (@pbchase)
- Silence long path warnings relating to request_correction_of_bad_ownership_data.R (@pbchase)
- Refactor billable_candidates.R to use get_billable_candidates() (@pbchase)

# rcc.billing 1.21.2 (released 2023-06-07)
- Update revenue_status_and_projections.qmd (@pbchase)

# rcc.billing 1.21.1 (released 2023-06-07)
- Update cron file for new render_report.R (@pbchase)

# rcc.billing 1.21.0 (released 2023-06-07)
- Update render_report.R to add Quarto support (@pbchase)
- Ban PIs who left UF in update_invoice_line_items_with_invoicing_details.R (@pbchase)

# rcc.billing 1.20.0 (released 2023-06-05)
- Add revenue_status_and_projections.qmd (@pbchase)
- Update email templates (@pbchase)

# rcc.billing 1.19.0 (released 2023-05-24)
- Add remind_owners_to_review_ownership.R (@pbchase)
- Update sequester_unpaid_projects.R (@pbchase)
- Add historic redcap admins to CTS-IT staff (@pbchase)

# rcc.billing 1.18.2 (released 2023-04-03)
- Filter out sequestered and deleted projects in sequester_unpaid_projects.R (@pbchase)

# rcc.billing 1.18.1 (released 2023-04-03)
- Fix NEWS.md (@pbchase)

# rcc.billing 1.18.0 (released 2023-04-03)
- Add sequester_unpaid_projects ETL (@ChemiKyle)
- Set date_sent when creating invoice line items (@pbchase)
- Fix cron for write_uf_fiscal_orgs_to_org_hierarchies.R again (@pbchase)

# rcc.billing 1.17.0 (released 2023-03-17)
- Add ETL to write to org_hierachies from VIVO Add schema for org_hierarchies (@ChemiKyle)
- Add cron'd runs of sequester_orphans.R (@pbchase)
- Simplify manual sequestration in sequester_orphans.R (@pbchase)

# rcc.billing 1.16.0 (released 2023-03-03)
- Add banned_owners rule to get_orphaned_projects function Add banned_owners schema (@ChemiKyle)
- Embrace subdirectories for db specific tables in testing data (@ChemiKyle)
- Rename *_conn to mem_*_conn in get_orphaned_projects test (@ChemiKyle)
- Prevent blank emails on new invoice line items (@pbchase)

# rcc.billing 1.15.0 (released 2023-02-27)
- Add unit test for get_orphaned_projects() (@pbchase)
- Add unresolvable_ownership_issues to get_orphans function (@ChemiKyle)
- Add request_correction_of_bad_ownership_data report (@ChemiKyle)
- Add erasure of project ownership identification columns to cleanup_project_ownership_table (@ChemiKyle)
- Use variable instead of hardcoding in send_alert_email (@ChemiKyle)
- Prevent emails RE: unresolvable_ownership_issues in sequester_orphans (@ChemiKyle)

# rcc.billing 1.14.0 (released 2023-01-27)
- Add complete_but_non_sequestered rule to get_orphaned_projects (@pbchase)
- Add warn_completers_of_impending_sequestration.R (@pbchase)
- Update version numbers in NEWS.md to conform to tagging error on 2022-12-19 (@pbchase)

# rcc.billing 1.13.0 (released 2023-01-24)
- Update get_orphaned_projects reducing the horizon from 12 to 11 months (@pbchase)
- Move warn_owners_of_impending_bill.R back to the default dates (@pbchase)
- Update update_invoice_line_items_with_invoicing_details.R (@pbchase)
- Revert error in sequester_orphans.R (@pbchase)
- Sync invoice_line_item table to RC DB during update_invoice_line_items_with_invoicing_details (@ChemiKyle)
- Mark CTSIT-owned projects as non-billable in update_project_billable_attribute.R (@pbchase)

# rcc.billing 1.12.1 (released 2022-12-19)
- Load rcc.billing library in cleanup_bad_email_addresses.R (@pbchase)

# rcc.billing 1.12.0 (released 2022-12-19)
- Port cleanup_bad_email_addresses from rcc.ctsit (@ChemiKyle)
- Create get_bad_emails_from_log (@ChemiKyle)
- Update billable_candidates.R (@pbchase)
- Ignore timestamp updates in update_invoice_line_items_with_invoicing_details.R (@pbchase)

# rcc.billing 0.11.1 (released 2022-12-07)
- Temporarily move warn_owners_of_impending_bill to the 3rd and 14th of the month (@pbchase)
- Add a comment to guide manual orphan sequestration (@pbchase)
- Fix new row IDs in create_and_send_new_redcap_prod_per_project_line_items.R (@pbchase)

# rcc.billing 0.11.0 (released 2022-11-14)
- Set invoice_line_item status conditionally based on date_of_pmt presence when loading data from CSBT (@ChemiKyle)

# rcc.billing 0.10.0 (released 2022-11-02)
- Include project_irb_number in report/billable_candidates (@ChemiKyle)
- Add invoice facts to billable candidates (@pbchase)
- Re-enable empty_and_inactive_projects in get_orphaned_projects (@pbchase)
- Adjust the id column in new_invoice_line_item_communications to avoid collisions (@pbchase)

# rcc.billing 0.9.1 (released 2022-10-28)
- Execute named lists construction with lst (@pbchase)

# rcc.billing 0.9.0 (released 2022-10-28)
- Add transform_invoice_line_items_for_ctsit (@ChemiKyle)
- Add update_invoice_line_items_with_invoicing_details (@ChemiKyle)
- Add rule inactive_projects_with_no_viable_users to get_orphaned_projects() (@pbchase)
- Add orphaned_projects to logged data in sequester_orphans.R (@pbchase)
- Show user_lastlogin in billable_candidates.R (@pbchase)
- Use full month name instead of abbreviation in create_and_send_new_redcap_prod_per_project_line_items (@ChemiKyle)
- Associate month_invoiced with project's birth month rather than script run month (@ChemiKyle)

# rcc.billing 0.8.1 (released 2022-10-21)
- Include GITHUB_PAT in docker build step (@pbchase)
- Pass project_id vector to sequester_projects (@pbchase)

# rcc.billing 0.8.0 (released 2022-10-21)
- Activate sequester_orphans.R (@pbchase)
- Add filter for no viable users to get_orphaned_projects (@ChemiKyle)
- Add get_user_rights_and_info (@pbchase)
- Install rcc.ctsit in Dockerfile using a GitHub PAT (@pbchase)
- Make PIs and faculty project owners (@pbchase)

# rcc.billing 0.7.1 (released 2022-10-04)
- Update create_and_send_new_redcap_prod_per_project_line_items.R (@pbchase)

# rcc.billing 0.7.0 (released 2022-10-04)
- Add get_orphaned_projects() (@pbchase)
- Add sequester_orphans (@pbchase)
- Add sequester_projects() (@pbchase)
- Fix service_type in service_type_test_data (@pbchase)
- Update csbt column output names CTSI IT ID -> CTSIT ID (@ChemiKyle)
- Filter out non-sequestered projects in create_and_send_new_redcap_prod_per_project_line_items (@ChemiKyle)
- Include project_ownership user identifiers in create_and_send_new_redcap_prod_per_project_line_items.R (@pbchase)

# rcc.billing 0.6.1 (released 2022-09-28)
- Run billable_candidates.R weekly (@pbchase)
- Fix subject, body, and from in billable_candidates.R (@pbchase)

# rcc.billing 0.6.0 (released 2022-09-28)
- Create billable_candidates report (@ChemiKyle)
- Add deleted projects filter and fix birthday_in_previous_month filter when creating invoice line items(@pbchase)

# rcc.billing 0.5.0 (released 2022-09-22)
- Run warn_owners_of_impending_bill.R on 1st and 23rd of the month (@pbchase)

# rcc.billing 0.4.0 (released 2022-09-07)
- Activate warn_owners_of_impending_bill.R (@pbchase)
- Add correct_project_pi_emails (@ChemiKyle)

# rcc.billing 0.3.1 (released 2022-09-06)
- Catch and log all errors and successes in warn_owners_of_impending_bill.R (@ChemiKyle, @pbchase)

# rcc.billing 0.3.0 (released 2022-09-01)
- Add warn_owners_of_impending_bill.R (@ChemiKyle, @pbchase)

# rcc.billing 0.2.0 (released 2022-08-30)
- Add warn_owners_of_impending_bill.R (@ChemiKyle)

# rcc.billing 0.1.2 (released 2022-08-26)
- Fix paths in cron files (@pbchase)
- Load rcc.billing in update_project_billable_attribute.R (@pbchase)

# rcc.billing 0.1.1 (released 2022-08-26)
- Build rcc.billing in Dockerfile (@pbchase)

# rcc.billing 0.1.0 (released 2022-08-25)
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

# rcc.billing 0.0.0 (released 2022-03-21)
- Initial commit of rcc.billing, an automated, data-driven service billing system implemented on REDCap Custodian (@pbchase)
