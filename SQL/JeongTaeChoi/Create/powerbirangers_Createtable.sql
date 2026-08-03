-- 파워비레인저스123 학습용 DB 스키마
-- Aiven MySQL 8.4 대상, utf8mb4 인코딩
-- 코드/ID/SEQ 계열 컬럼은 전부 VARCHAR로 고정 (숫자 오버플로우/앞자리0 손실 방지)

-- ------------------------------------------------------------
-- tc_codea  (원본: tc_codea_코드A_merged.csv, 행수: 30)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tc_codea`;
CREATE TABLE `tc_codea` (
  `idx` SMALLINT NOT NULL,
  `cd_a` VARCHAR(10) NULL,
  `cd_nm` VARCHAR(20) NULL,
  `cd_memo` VARCHAR(30) NULL,
  `cd_memo2` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `del_flag` VARCHAR(10) NULL,
  `order_num` SMALLINT NULL,
  `perm_write` VARCHAR(10) NULL,
  `perm_edit` VARCHAR(10) NULL,
  `perm_delete` VARCHAR(10) NULL,
  `ins_dt` VARCHAR(25) NULL,
  `edit_dt` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tc_codeb  (원본: tc_codeb_코드B_merged.csv, 행수: 238)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tc_codeb`;
CREATE TABLE `tc_codeb` (
  `idx` SMALLINT NOT NULL,
  `cd_a` VARCHAR(10) NULL,
  `cd_b` VARCHAR(10) NULL,
  `cd_nm` VARCHAR(40) NULL,
  `cd_memo` VARCHAR(55) NULL,  -- 최대길이 48자
  `cd_memo2` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `del_flag` VARCHAR(10) NULL,
  `order_num` SMALLINT NULL,
  `ins_dt` VARCHAR(25) NULL,
  `edit_dt` VARCHAR(25) NULL,
  PRIMARY KEY (`idx`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tc_sgg  (원본: tc_sgg_시군구코드_merged.csv, 행수: 8075)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tc_sgg`;
CREATE TABLE `tc_sgg` (
  `SGG_CD` VARCHAR(20) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `SGG_CD1` SMALLINT NULL,
  `SGG_CD2` SMALLINT NULL,
  `SGG_CD3` SMALLINT NULL,
  `SGG_CD4` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `SIDO_NM` VARCHAR(15) NULL,
  `SGG_NM` VARCHAR(15) NULL,
  `DONG_NM` VARCHAR(15) NULL,
  `RI_NM` VARCHAR(15) NULL,
  PRIMARY KEY (`SGG_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_travel  (원본: tn_travel_여행_merged.csv, 행수: 2880)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_travel`;
CREATE TABLE `tn_travel` (
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `TRAVEL_NM` VARCHAR(10) NULL,
  `TRAVELER_ID` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `TRAVEL_PURPOSE` VARCHAR(60) NULL,  -- 최대길이 53자
  `TRAVEL_START_YMD` DATE NULL,
  `TRAVEL_END_YMD` DATE NULL,
  `MVMN_NM` VARCHAR(15) NULL,
  `TRAVEL_PERSONA` VARCHAR(50) NULL,  -- 최대길이 41자
  `TRAVEL_MISSION` VARCHAR(60) NULL,  -- 최대길이 53자
  `TRAVEL_MISSION_CHECK` VARCHAR(15) NULL,
  PRIMARY KEY (`TRAVEL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_traveller_master  (원본: tn_traveller_master_여행객_Master_merged.csv, 행수: 2880)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_traveller_master`;
CREATE TABLE `tn_traveller_master` (
  `TRAVELER_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `RESIDENCE_SGG_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `GENDER` VARCHAR(10) NULL,
  `AGE_GRP` SMALLINT NULL,
  `EDU_NM` SMALLINT NULL,
  `EDU_FNSH_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `MARR_STTS` SMALLINT NULL,
  `FAMILY_MEMB` SMALLINT NULL,
  `JOB_NM` SMALLINT NULL,
  `JOB_ETC` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `INCOME` SMALLINT NULL,
  `HOUSE_INCOME` SMALLINT NULL,
  `TRAVEL_TERM` SMALLINT NULL,
  `TRAVEL_NUM` SMALLINT NULL,
  `TRAVEL_LIKE_SIDO_1` SMALLINT NULL,
  `TRAVEL_LIKE_SGG_1` INT NULL,
  `TRAVEL_LIKE_SIDO_2` SMALLINT NULL,
  `TRAVEL_LIKE_SGG_2` INT NULL,
  `TRAVEL_LIKE_SIDO_3` SMALLINT NULL,
  `TRAVEL_LIKE_SGG_3` INT NULL,
  `TRAVEL_STYL_1` SMALLINT NULL,
  `TRAVEL_STYL_2` SMALLINT NULL,
  `TRAVEL_STYL_3` SMALLINT NULL,
  `TRAVEL_STYL_4` SMALLINT NULL,
  `TRAVEL_STYL_5` SMALLINT NULL,
  `TRAVEL_STYL_6` SMALLINT NULL,
  `TRAVEL_STYL_7` SMALLINT NULL,
  `TRAVEL_STYL_8` SMALLINT NULL,
  `TRAVEL_STATUS_RESIDENCE` VARCHAR(15) NULL,
  `TRAVEL_STATUS_DESTINATION` VARCHAR(15) NULL,
  `TRAVEL_STATUS_ACCOMPANY` VARCHAR(25) NULL,
  `TRAVEL_STATUS_YMD` VARCHAR(30) NULL,
  `TRAVEL_MOTIVE_1` SMALLINT NULL,
  `TRAVEL_MOTIVE_2` SMALLINT NULL,
  `TRAVEL_MOTIVE_3` SMALLINT NULL,
  `TRAVEL_COMPANIONS_NUM` SMALLINT NULL,
  PRIMARY KEY (`TRAVELER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_visit_area_info  (원본: tn_visit_area_info_방문지정보_merged.csv, 행수: 24154)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_visit_area_info`;
CREATE TABLE `tn_visit_area_info` (
  `VISIT_AREA_ID` VARCHAR(20) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `VISIT_ORDER` SMALLINT NULL,
  `VISIT_AREA_NM` VARCHAR(45) NULL,
  `VISIT_START_YMD` DATE NULL,
  `VISIT_END_YMD` DATE NULL,
  `ROAD_NM_ADDR` VARCHAR(145) NULL,  -- 최대길이 136자
  `LOTNO_ADDR` VARCHAR(35) NULL,
  `X_COORD` DECIMAL(10,7) NULL,  -- 좌표
  `Y_COORD` DECIMAL(10,7) NULL,  -- 좌표
  `ROAD_NM_CD` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `LOTNO_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `POI_ID` VARCHAR(25) NULL,  -- 코드/키 컬럼→문자열 고정
  `POI_NM` VARCHAR(55) NULL,  -- 최대길이 45자
  `RESIDENCE_TIME_MIN` SMALLINT NULL,
  `VISIT_AREA_TYPE_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `REVISIT_YN` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `VISIT_CHC_REASON_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `LODGING_TYPE_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `DGSTFN` TINYINT NULL,  -- 1~5 만족도 점수
  `REVISIT_INTENTION` TINYINT NULL,  -- 1~5 만족도 점수
  `RCMDTN_INTENTION` TINYINT NULL,  -- 1~5 만족도 점수
  `SGG_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  PRIMARY KEY (`VISIT_AREA_ID`, `TRAVEL_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_activity_his  (원본: tn_activity_his_활동내역_merged.csv, 행수: 26805)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_activity_his`;
CREATE TABLE `tn_activity_his` (
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `VISIT_AREA_ID` VARCHAR(20) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ACTIVITY_TYPE_CD` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ACTIVITY_TYPE_SEQ` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ACTIVITY_ETC` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `ACTIVITY_DTL` TEXT NULL,  -- 최대길이 366자
  `RSVT_YN` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `EXPND_SE` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `ADMISSION_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  PRIMARY KEY (`TRAVEL_ID`, `VISIT_AREA_ID`, `ACTIVITY_TYPE_CD`, `ACTIVITY_TYPE_SEQ`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_activity_consume_his  (원본: tn_activity_consume_his_활동소비내역_merged.csv, 행수: 13275)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_activity_consume_his`;
CREATE TABLE `tn_activity_consume_his` (
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `VISIT_AREA_ID` VARCHAR(20) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ACTIVITY_TYPE_CD` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ACTIVITY_TYPE_SEQ` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `CONSUME_HIS_SEQ` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `CONSUME_HIS_SNO` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_NUM` SMALLINT NULL,
  `BRNO` BIGINT NULL,  -- 실제 최대값 8,994,200,114 (INT32 초과)
  `STORE_NM` VARCHAR(50) NULL,
  `ROAD_NM_ADDR` VARCHAR(60) NULL,  -- 최대길이 54자
  `LOTNO_ADDR` VARCHAR(35) NULL,
  `ROAD_NM_CD` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `LOTNO_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_DT` DATETIME NULL,
  `PAYMENT_MTHD_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_AMT_WON` INT NULL,
  `PAYMENT_ETC` VARCHAR(145) NULL,  -- 최대길이 137자
  `SGG_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  PRIMARY KEY (`TRAVEL_ID`, `VISIT_AREA_ID`, `ACTIVITY_TYPE_CD`, `ACTIVITY_TYPE_SEQ`, `CONSUME_HIS_SEQ`, `CONSUME_HIS_SNO`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_adv_consume_his  (원본: tn_adv_consume_his_사전소비내역_merged.csv, 행수: 716)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_adv_consume_his`;
CREATE TABLE `tn_adv_consume_his` (
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `ADV_NM` VARCHAR(110) NULL,  -- 최대길이 100자
  `ADV_SEQ` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_NUM` SMALLINT NULL,
  `BRNO` BIGINT NULL,  -- 실제 최대값 8,998,702,113 (INT32 초과)
  `STORE_NM` VARCHAR(35) NULL,
  `ROAD_NM_ADDR` VARCHAR(55) NULL,  -- 최대길이 46자
  `LOTNO_ADDR` VARCHAR(35) NULL,
  `ROAD_NM_CD` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `LOTNO_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_DT` DATETIME NULL,
  `PAYMENT_MTHD_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_AMT_WON` INT NULL,
  `PAYMENT_ETC` VARCHAR(85) NULL,  -- 최대길이 75자
  `SGG_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  PRIMARY KEY (`TRAVEL_ID`, `ADV_SEQ`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_companion_info  (원본: tn_companion_info_동반자정보_merged.csv, 행수: 3977)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_companion_info`;
CREATE TABLE `tn_companion_info` (
  `COMPANION_SEQ` VARCHAR(10) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `REL_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `COMPANION_GENDER` SMALLINT NULL,
  `COMPANION_AGE_GRP` SMALLINT NULL,
  `COMPANION_SITUATION` SMALLINT NULL,
  PRIMARY KEY (`TRAVEL_ID`, `COMPANION_SEQ`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_lodge_consume_his  (원본: tn_lodge_consume_his_숙박소비내역_merged.csv, 행수: 843)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_lodge_consume_his`;
CREATE TABLE `tn_lodge_consume_his` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,  -- 자연키 없음(중복 존재 확인됨) -> 대체키
  `TRAVEL_ID` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `LODGING_NM` VARCHAR(35) NULL,
  `LODGING_PAYMENT_SEQ` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `LODGING_TYPE_CD` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `RSVT_YN` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `CHK_IN_DT_MIN` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `CHK_OUT_DT_MIN` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `PAYMENT_NUM` SMALLINT NULL,
  `BRNO` VARCHAR(20) NULL,  -- 데이터 없음(현재 전부 공백)
  `STORE_NM` VARCHAR(35) NULL,
  `ROAD_NM_ADDR` VARCHAR(40) NULL,
  `LOTNO_ADDR` VARCHAR(35) NULL,
  `ROAD_NM_CD` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `LOTNO_CD` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_DT` DATETIME NULL,
  `PAYMENT_MTHD_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_AMT_WON` INT NULL,
  `PAYMENT_ETC` VARCHAR(70) NULL  -- 최대길이 61자
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_move_his  (원본: tn_move_his_이동내역_merged.csv, 행수: 24154)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_move_his`;
CREATE TABLE `tn_move_his` (
  `TRAVEL_ID` VARCHAR(15) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `TRIP_ID` VARCHAR(20) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `START_VISIT_AREA_ID` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `END_VISIT_AREA_ID` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `START_DT_MIN` DATETIME NULL,
  `END_DT_MIN` DATETIME NULL,
  `MVMN_CD_1` SMALLINT NULL,
  `MVMN_CD_2` SMALLINT NULL,
  PRIMARY KEY (`TRAVEL_ID`, `TRIP_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_mvmn_consume_his  (원본: tn_mvmn_consume_his_이동수단소비내역_merged.csv, 행수: 4624)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_mvmn_consume_his`;
CREATE TABLE `tn_mvmn_consume_his` (
  `id` BIGINT AUTO_INCREMENT PRIMARY KEY,  -- 자연키 없음(중복 존재 확인됨) -> 대체키
  `TRAVEL_ID` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `MVMN_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_SEQ` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `MVMN_SE_NM` VARCHAR(25) NULL,
  `RSVT_YN` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_NUM` SMALLINT NULL,
  `BRNO` BIGINT NULL,  -- 실제 최대값 8,998,702,113 (INT32 초과)
  `STORE_NM` VARCHAR(25) NULL,
  `PAYMENT_DT` DATETIME NULL,
  `PAYMENT_MTHD_SE` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PAYMENT_AMT_WON` INT NULL,
  `PAYMENT_ETC` VARCHAR(25) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
-- tn_tour_photo  (원본: tn_tour_photo_관광사진_merged.csv, 행수: 16469)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `tn_tour_photo`;
CREATE TABLE `tn_tour_photo` (
  `TRAVEL_ID` VARCHAR(15) NULL,  -- 코드/키 컬럼→문자열 고정
  `VISIT_AREA_ID` VARCHAR(20) NULL,  -- 코드/키 컬럼→문자열 고정
  `TOUR_PHOTO_SEQ` VARCHAR(10) NULL,  -- 코드/키 컬럼→문자열 고정
  `PHOTO_FILE_ID` VARCHAR(25) NOT NULL,  -- 코드/키 컬럼→문자열 고정
  `PHOTO_FILE_NM` VARCHAR(30) NULL,
  `PHOTO_FILE_FRMAT` VARCHAR(10) NULL,
  `PHOTO_FILE_DT` VARCHAR(25) NULL,
  `PHOTO_FILE_SAVE_PATH` VARCHAR(15) NULL,
  `PHOTO_FILE_RESOLUTION` VARCHAR(20) NULL,
  `PHOTO_FILE_X_COORD` VARCHAR(25) NULL,
  `PHOTO_FILE_Y_COORD` VARCHAR(25) NULL,
  `VISIT_AREA_NM` VARCHAR(45) NULL,
  PRIMARY KEY (`PHOTO_FILE_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;