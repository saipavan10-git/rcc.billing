-- upgrade for release 1.39.0
alter table invoice_line_item
  add column `fiscal_contact_fn` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `gatorlink`,
  add column `fiscal_contact_ln` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_fn`,
  add column `fiscal_contact_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_ln`,
  add column `fiscal_contact_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_name`
;

alter table invoice_line_item_communications
  add column `fiscal_contact_fn` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `gatorlink`,
  add column `fiscal_contact_ln` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_fn`,
  add column `fiscal_contact_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_ln`,
  add column `fiscal_contact_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL AFTER `fiscal_contact_name`
;
