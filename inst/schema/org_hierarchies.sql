CREATE TABLE `org_hierarchies` (
  `DEPT_ID` varchar(10) NOT NULL,
  `DEPT_NAME` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `parent_id` varchar(10) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  PRIMARY_KEY (`DEPT_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
