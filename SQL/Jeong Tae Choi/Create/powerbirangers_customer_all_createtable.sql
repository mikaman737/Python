-- ============================================================
-- tn_customer_all (원본: Excel/Data/전처리 완료 데이터/RAW/tn_customer_all.csv)
-- 13개 원본 로그 테이블이 아닌, 여행자(TRAVELER_ID) 단위 분석용 파생 마트 테이블.
-- Aiven MySQL 8.4 대상, utf8mb4 인코딩. 행수: 2,880 (TRAVELER_ID 1인 1행, 중복 없음 확인)
-- 코드형 컬럼(INCOME/MARR_STTS/JOB_NM/LODGING_TYPE_CD/TRAVEL_PURPOSE/TRAVEL_STYL_ALL/
-- TRAVEL_MOTIVE_ALL/COMPANION_AGE_GRP_n/COMPANION_GENDER_n)은 tc_codeb.cd_nm으로 치환된
-- 텍스트 값이 들어있어 원본 tn_* 테이블과 달리 코드가 아닌 한글 명칭 그대로 저장됨.
-- VARCHAR 길이는 CSV 실측 최대길이에 여유를 두어 지정, 임의 축소 없음.
-- ============================================================

DROP TABLE IF EXISTS `tn_customer_all`;
CREATE TABLE `tn_customer_all` (
  `TRAVELER_ID` VARCHAR(15) NOT NULL,                 -- 코드/키 컬럼→문자열 고정
  `GENDER` VARCHAR(10) NULL,
  `AGE_GRP` SMALLINT NULL,
  `INCOME` VARCHAR(40) NULL,                          -- cd_nm 치환, 최대길이 22자
  `RESIDENCE_SGG_CD` VARCHAR(10) NULL,                -- 코드/키 컬럼→문자열 고정, tc_sgg 참조
  `RESIDENCE_SIDO_NM` VARCHAR(15) NULL,
  `MARR_STTS` VARCHAR(10) NULL,                       -- cd_nm 치환
  `JOB_NM` VARCHAR(30) NULL,                          -- cd_nm 치환, 최대길이 17자
  `TRAVEL_NUM` SMALLINT NULL,
  `TRAVEL_DAYS_SUM` SMALLINT NULL,
  `VISIT_AREA_CNT` SMALLINT NULL,
  `RESIDENCE_TIME_MIN_AVG` DECIMAL(12,6) NULL,
  `PAYMENT_AMT_WON_PER_UNIT` DECIMAL(14,6) NULL,
  `PAYMENT_AMT_WON_SUM` INT NULL,
  `PAYMENT_AMT_WON_PER_PERSON` DECIMAL(14,6) NULL,    -- = PAYMENT_AMT_WON_SUM / TRAVEL_COMPANIONS_NUM
  `PAYMENT_AMT_WON_PER_DAY` DECIMAL(14,6) NULL,        -- = PAYMENT_AMT_WON_SUM / TRAVEL_DAYS_SUM
  `LODGE_PAYMENT_AMT_WON_SUM` INT NULL,
  `ACTIVITY_PAYMENT_AMT_WON_SUM` INT NULL,
  `MVMN_PAYMENT_AMT_WON_SUM` INT NULL,
  `LODGING_TYPE_CD` VARCHAR(60) NULL,                 -- cd_nm 치환(다중값 콤마결합), 최대길이 15자, 결측 2127건
  `LODGING_YN` VARCHAR(10) NULL,
  `ACTIVITY_TYPE_CD_CNT` SMALLINT NULL,                -- 결측 33건
  `MVMN_NM` VARCHAR(80) NULL,                          -- 최대길이 47자, 결측 231건
  `TRAVEL_PURPOSE` VARCHAR(320) NULL,                  -- cd_nm 치환(다중값 ';' 결합), 최대길이 261자
  `TRAVEL_COMPANION_TYPE` VARCHAR(30) NULL,            -- 최대길이 18자
  `TRAVEL_COMPANIONS_NUM` SMALLINT NULL,
  `VISIT_SIDO_SGG_NM` VARCHAR(120) NULL,               -- 최대길이 80자, 결측 2057건
  `DGSTFN_AVG` DECIMAL(10,6) NULL,
  `REVISIT_INTENTION_AVG` DECIMAL(10,6) NULL,
  `RCMDTN_INTENTION_AVG` DECIMAL(10,6) NULL,
  `TRAVEL_LIKE_SGG_1` VARCHAR(10) NULL,                -- 코드/키 컬럼→문자열 고정, tc_sgg 참조
  `TRAVEL_STYL_ALL` VARCHAR(120) NULL,                 -- cd_nm 치환(TSY 1~8 콤마결합), 최대길이 87자
  `TRAVEL_MOTIVE_ALL` VARCHAR(120) NULL,               -- cd_nm 치환(TMT 1~3 콤마결합), 최대길이 89자
  `COMPANION_AGE_GRP_1` VARCHAR(10) NULL,              -- cd_nm 치환
  `COMPANION_AGE_GRP_2` VARCHAR(10) NULL,
  `COMPANION_AGE_GRP_3` VARCHAR(10) NULL,
  `COMPANION_AGE_GRP_4` VARCHAR(10) NULL,
  `COMPANION_AGE_GRP_5` VARCHAR(10) NULL,
  `COMPANION_GENDER_1` VARCHAR(10) NULL,               -- cd_nm 치환
  `COMPANION_GENDER_2` VARCHAR(10) NULL,
  `COMPANION_GENDER_3` VARCHAR(10) NULL,
  `COMPANION_GENDER_4` VARCHAR(10) NULL,
  `COMPANION_GENDER_5` VARCHAR(10) NULL,
  `VALUE_SEGMENT` VARCHAR(5) NULL,
  `VALUE_SEGMENT_SUB` VARCHAR(5) NULL,
  PRIMARY KEY (`TRAVELER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
