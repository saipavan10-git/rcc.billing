SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE TABLE `invoice_line_item` (
  `id` double NOT NULL,
  `service_identifier` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `service_type_code` double DEFAULT NULL,
  `service_instance_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `ctsi_study_id` double DEFAULT NULL,
  `name_of_service` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `other_system_invoicing_comments` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `cost_of_service` double DEFAULT NULL,
  `qty_provided` double DEFAULT NULL,
  `amount_due` double DEFAULT NULL,
  `fiscal_year` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `month_invoiced` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pi_last_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pi_first_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pi_email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `gatorlink` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `status` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


ALTER TABLE `invoice_line_item`
  ADD PRIMARY KEY (`id`),
  ADD KEY `service_identifier` (`service_identifier`),
  ADD KEY `service_type_code` (`service_type_code`),
  ADD KEY `service_instance_id` (`service_instance_id`),
  ADD KEY `ctsi_study_id` (`ctsi_study_id`),
  ADD KEY `fiscal_year` (`fiscal_year`),
  ADD KEY `month_invoiced` (`month_invoiced`),
  ADD KEY `gatorlink` (`gatorlink`),
  ADD KEY `pi_email` (`pi_email`),
  ADD KEY `pi_last_name` (`pi_last_name`),
  ADD KEY `pi_first_name` (`pi_first_name`),
  ADD KEY `status` (`status`),
  ADD KEY `created` (`created`),
  ADD KEY `updated` (`updated`),
  ADD KEY `reason` (`reason`);
