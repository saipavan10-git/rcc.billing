CREATE TABLE `service_instance` (
  `service_instance_id` varchar(17) DEFAULT NULL,
  `service_type_code` double DEFAULT NULL,
  `service_identifier` varchar(15) DEFAULT NULL,
  `ctsi_study_id` double DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
