CREATE TABLE redcap_projects_history LIKE redcap_projects;
ALTER TABLE redcap_projects_history MODIFY project_id int NOT NULL;
