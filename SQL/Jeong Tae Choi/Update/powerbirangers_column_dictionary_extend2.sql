-- ============================================================
-- 컬럼 사전(tc_column_dictionary) 확장 2: 필수여부 / 범위 / 비고
-- 출처: Description/119-145_국내여행로그데이터(수도권)_데이터설명서.hwp
--       "4 여행로그 테이블 정의서" 표를 그대로 옮김 (임의 추정 없음, 7원칙 1번)
-- ------------------------------------------------------------
-- 방식: 문서 값을 임시 스테이징 테이블에 넣고 JOIN으로 일괄 UPDATE.
-- 주의:
--   - 문서 컬럼명과 실제 DB 컬럼명이 다른 곳은 실제 DB 이름 기준으로 매핑
--     (RESIDENCE_SGG_CD, LODGING_PAYMENT_SEQ 등 — 이전 사전 작업과 동일 기준)
--   - tn_lodge_consume_his의 id(대체키)와, 이전에 발견된 이상 컬럼 5개
--     (COMPANION_SEQ 등, 문서에 없는데 실제 DB에 존재)는 문서에 값이 없으므로
--     필수여부는 NULL로 남기고 비고에 '문서에 없음'을 명시함 (임의로 지어내지 않음)
-- ============================================================

ALTER TABLE tc_column_dictionary
    ADD COLUMN is_required VARCHAR(5)  NULL AFTER var_usage,   -- 필수여부 (Y/N)
    ADD COLUMN value_range VARCHAR(40) NULL AFTER is_required, -- 범위 (예: [1~5])
    ADD COLUMN remark      VARCHAR(80) NULL AFTER value_range; -- 비고 (코드명/날짜형식/단위 등)

DROP TEMPORARY TABLE IF EXISTS tc_column_meta_stage;
CREATE TEMPORARY TABLE tc_column_meta_stage (
    table_nm    VARCHAR(40) NOT NULL,
    column_nm   VARCHAR(40) NOT NULL,
    is_required VARCHAR(5)  NULL,
    value_range VARCHAR(40) NULL,
    remark      VARCHAR(80) NULL,
    PRIMARY KEY (table_nm, column_nm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tc_column_meta_stage (table_nm, column_nm, is_required, value_range, remark) VALUES
-- tc_codea
('tc_codea','idx','Y',NULL,NULL),
('tc_codea','cd_a','Y',NULL,NULL),
('tc_codea','cd_nm','Y',NULL,NULL),
('tc_codea','cd_memo','N',NULL,NULL),
('tc_codea','cd_memo2','N',NULL,NULL),
('tc_codea','del_flag','Y',NULL,NULL),
('tc_codea','order_num','Y',NULL,NULL),
('tc_codea','perm_write','Y','[Y, N]',NULL),
('tc_codea','perm_edit','Y','[Y, N]',NULL),
('tc_codea','perm_delete','Y','[Y, N]',NULL),
('tc_codea','ins_dt','Y',NULL,'YYYY-MM-DD HH:MI:SS'),
('tc_codea','edit_dt','N',NULL,'YYYY-MM-DD HH:MI:SS'),

-- tc_codeb
('tc_codeb','idx','Y',NULL,NULL),
('tc_codeb','cd_a','Y',NULL,NULL),
('tc_codeb','cd_b','Y',NULL,NULL),
('tc_codeb','cd_nm','Y',NULL,NULL),
('tc_codeb','cd_memo','N',NULL,NULL),
('tc_codeb','cd_memo2','N',NULL,NULL),
('tc_codeb','del_flag','Y',NULL,NULL),
('tc_codeb','order_num','Y',NULL,NULL),
('tc_codeb','ins_dt','Y',NULL,'YYYY-MM-DD HH:MI:SS'),
('tc_codeb','edit_dt','N',NULL,'YYYY-MM-DD HH:MI:SS'),

-- tc_sgg
('tc_sgg','SGG_CD','Y',NULL,NULL),
('tc_sgg','SGG_CD1','N',NULL,NULL),
('tc_sgg','SGG_CD2','N',NULL,NULL),
('tc_sgg','SGG_CD3','N',NULL,NULL),
('tc_sgg','SGG_CD4','N',NULL,NULL),
('tc_sgg','SIDO_NM','Y',NULL,NULL),
('tc_sgg','SGG_NM','N',NULL,NULL),
('tc_sgg','DONG_NM','N',NULL,NULL),
('tc_sgg','RI_NM','N',NULL,NULL),

-- tn_travel
('tn_travel','TRAVEL_ID','Y',NULL,NULL),
('tn_travel','TRAVEL_NM','N',NULL,NULL),
('tn_travel','TRAVELER_ID','Y',NULL,NULL),
('tn_travel','TRAVEL_PURPOSE','N',NULL,'코드 ''MIS'''),
('tn_travel','TRAVEL_START_YMD','N',NULL,'YYYY-MM-DD'),
('tn_travel','TRAVEL_END_YMD','N',NULL,'YYYY-MM-DD'),
('tn_travel','MVMN_NM','N',NULL,NULL),
('tn_travel','TRAVEL_PERSONA','Y',NULL,NULL),
('tn_travel','TRAVEL_MISSION','N','[1~13, 21~28]','코드 ''MIS'''),
('tn_travel','TRAVEL_MISSION_CHECK','N','[1~13, 21~28]','코드 ''MIS'''),

-- tn_traveller_master
('tn_traveller_master','TRAVELER_ID','Y',NULL,NULL),
('tn_traveller_master','RESIDENCE_SGG_CD','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','GENDER','N',NULL,NULL),
('tn_traveller_master','AGE_GRP','N',NULL,NULL),
('tn_traveller_master','EDU_NM','N','[1~8]','코드 ''EDU'''),
('tn_traveller_master','EDU_FNSH_SE','N','[1~5]','코드 ''EFS'''),
('tn_traveller_master','MARR_STTS','N','[1~5]','코드 ''MAR'''),
('tn_traveller_master','FAMILY_MEMB','N',NULL,NULL),
('tn_traveller_master','JOB_NM','N','[1~13]','코드 ''JOB'''),
('tn_traveller_master','JOB_ETC','N','[1~3]','코드 ''JOE'''),
('tn_traveller_master','INCOME','N','[1~12]','코드 ''INC'''),
('tn_traveller_master','HOUSE_INCOME','N','[1~12]','코드 ''INC'''),
('tn_traveller_master','TRAVEL_TERM','N','[1~4]','코드 ''TTM'''),
('tn_traveller_master','TRAVEL_NUM','N',NULL,NULL),
('tn_traveller_master','TRAVEL_LIKE_SIDO_1','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_LIKE_SGG_1','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_LIKE_SIDO_2','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_LIKE_SGG_2','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_LIKE_SIDO_3','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_LIKE_SGG_3','N',NULL,'tc_sgg 참조'),
('tn_traveller_master','TRAVEL_STYL_1','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_2','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_3','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_4','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_5','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_6','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_7','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STYL_8','N','[1~7]','코드 ''TSY'''),
('tn_traveller_master','TRAVEL_STATUS_RESIDENCE','N',NULL,NULL),
('tn_traveller_master','TRAVEL_STATUS_DESTINATION','N',NULL,NULL),
('tn_traveller_master','TRAVEL_STATUS_ACCOMPANY','N',NULL,NULL),
('tn_traveller_master','TRAVEL_STATUS_YMD','N',NULL,NULL),
('tn_traveller_master','TRAVEL_MOTIVE_1','N','[1~10]','코드 ''TMT'''),
('tn_traveller_master','TRAVEL_MOTIVE_2','N','[1~10]','코드 ''TMT'''),
('tn_traveller_master','TRAVEL_MOTIVE_3','N','[1~10]','코드 ''TMT'''),
('tn_traveller_master','TRAVEL_COMPANIONS_NUM','N',NULL,NULL),

-- tn_visit_area_info
('tn_visit_area_info','VISIT_AREA_ID','Y',NULL,NULL),
('tn_visit_area_info','TRAVEL_ID','Y',NULL,NULL),
('tn_visit_area_info','VISIT_ORDER','Y',NULL,NULL),
('tn_visit_area_info','VISIT_AREA_NM','Y',NULL,NULL),
('tn_visit_area_info','VISIT_START_YMD','N',NULL,'YYYY-MM-DD'),
('tn_visit_area_info','VISIT_END_YMD','N',NULL,'YYYY-MM-DD'),
('tn_visit_area_info','ROAD_NM_ADDR','N',NULL,NULL),
('tn_visit_area_info','LOTNO_ADDR','N',NULL,NULL),
('tn_visit_area_info','X_COORD','N',NULL,NULL),
('tn_visit_area_info','Y_COORD','N',NULL,NULL),
('tn_visit_area_info','ROAD_NM_CD','N',NULL,NULL),
('tn_visit_area_info','LOTNO_CD','N',NULL,NULL),
('tn_visit_area_info','POI_ID','N',NULL,NULL),
('tn_visit_area_info','POI_NM','N',NULL,NULL),
('tn_visit_area_info','RESIDENCE_TIME_MIN','N',NULL,'단위 : 분'),
('tn_visit_area_info','VISIT_AREA_TYPE_CD','N','[1~13, 21~24]','코드 ''VIS'''),
('tn_visit_area_info','REVISIT_YN','N',NULL,NULL),
('tn_visit_area_info','VISIT_CHC_REASON_CD','N','[1~11]','코드 ''REN'''),
('tn_visit_area_info','LODGING_TYPE_CD','N','[1~12]','코드 ''HTY'''),
('tn_visit_area_info','DGSTFN','N','[1~5]','코드 ''DGS'''),
('tn_visit_area_info','REVISIT_INTENTION','N','[1~5]','코드 ''REP'''),
('tn_visit_area_info','RCMDTN_INTENTION','N','[1~5]','코드 ''REC'''),
('tn_visit_area_info','SGG_CD','N',NULL,'tc_sgg 참조'),

-- tn_activity_his
('tn_activity_his','TRAVEL_ID','Y',NULL,NULL),
('tn_activity_his','VISIT_AREA_ID','Y',NULL,NULL),
('tn_activity_his','ACTIVITY_TYPE_CD','Y','[1~7, 99]','코드 ''ACT'''),
('tn_activity_his','ACTIVITY_TYPE_SEQ','Y',NULL,NULL),
('tn_activity_his','ACTIVITY_ETC','N',NULL,'직접입력'),
('tn_activity_his','ACTIVITY_DTL','N',NULL,NULL),
('tn_activity_his','RSVT_YN','N',NULL,NULL),
('tn_activity_his','EXPND_SE','N','[1~5]','코드 ''EXP'''),
('tn_activity_his','ADMISSION_SE','N','[1~2]','코드 ''AMS'''),

-- tn_activity_consume_his
('tn_activity_consume_his','TRAVEL_ID','Y',NULL,NULL),
('tn_activity_consume_his','VISIT_AREA_ID','Y',NULL,NULL),
('tn_activity_consume_his','ACTIVITY_TYPE_CD','Y','[1~7, 99]','코드 ''ACT'''),
('tn_activity_consume_his','ACTIVITY_TYPE_SEQ','Y',NULL,NULL),
('tn_activity_consume_his','CONSUME_HIS_SEQ','Y',NULL,NULL),
('tn_activity_consume_his','CONSUME_HIS_SNO','Y',NULL,NULL),
('tn_activity_consume_his','PAYMENT_NUM','N',NULL,'단위 : 명'),
('tn_activity_consume_his','BRNO','N',NULL,NULL),
('tn_activity_consume_his','STORE_NM','N',NULL,NULL),
('tn_activity_consume_his','ROAD_NM_ADDR','N',NULL,NULL),
('tn_activity_consume_his','LOTNO_ADDR','N',NULL,NULL),
('tn_activity_consume_his','ROAD_NM_CD','N',NULL,NULL),
('tn_activity_consume_his','LOTNO_CD','N',NULL,NULL),
('tn_activity_consume_his','PAYMENT_DT','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_activity_consume_his','PAYMENT_MTHD_SE','N','[1~5]','코드 ''PAY'''),
('tn_activity_consume_his','PAYMENT_AMT_WON','N',NULL,NULL),
('tn_activity_consume_his','PAYMENT_ETC','N',NULL,NULL),
('tn_activity_consume_his','SGG_CD','N',NULL,'tc_sgg 참조'),

-- tn_adv_consume_his
('tn_adv_consume_his','TRAVEL_ID','Y',NULL,NULL),
('tn_adv_consume_his','ADV_NM','Y',NULL,NULL),
('tn_adv_consume_his','ADV_SEQ','Y',NULL,NULL),
('tn_adv_consume_his','PAYMENT_NUM','N',NULL,'단위 : 명'),
('tn_adv_consume_his','BRNO','N',NULL,NULL),
('tn_adv_consume_his','STORE_NM','N',NULL,NULL),
('tn_adv_consume_his','ROAD_NM_ADDR','N',NULL,NULL),
('tn_adv_consume_his','LOTNO_ADDR','N',NULL,NULL),
('tn_adv_consume_his','ROAD_NM_CD','N',NULL,NULL),
('tn_adv_consume_his','LOTNO_CD','N',NULL,NULL),
('tn_adv_consume_his','PAYMENT_DT','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_adv_consume_his','PAYMENT_MTHD_SE','N','[1~5]','코드 ''PAY'''),
('tn_adv_consume_his','PAYMENT_AMT_WON','N',NULL,NULL),
('tn_adv_consume_his','PAYMENT_ETC','N',NULL,NULL),
('tn_adv_consume_his','SGG_CD','N',NULL,'tc_sgg 참조'),

-- tn_companion_info
('tn_companion_info','COMPANION_SEQ','Y',NULL,NULL),
('tn_companion_info','TRAVEL_ID','Y',NULL,NULL),
('tn_companion_info','REL_CD','N','[1~11]','코드 ''TCR'''),
('tn_companion_info','COMPANION_GENDER','N','[1~2]','코드 ''GEN'''),
('tn_companion_info','COMPANION_AGE_GRP','N','[1~8]','코드 ''AGE'''),
('tn_companion_info','COMPANION_SITUATION','N','[1~3]','코드 ''CST'''),

-- tn_lodge_consume_his
('tn_lodge_consume_his','id','Y',NULL,'문서에 없는 대체키(자연키 없음)'),
('tn_lodge_consume_his','TRAVEL_ID','Y',NULL,NULL),
('tn_lodge_consume_his','LODGING_NM','Y',NULL,NULL),
('tn_lodge_consume_his','LODGING_PAYMENT_SEQ','Y',NULL,NULL),
('tn_lodge_consume_his','LODGING_TYPE_CD','N','[1~12]','코드 ''HTY'''),
('tn_lodge_consume_his','RSVT_YN','N',NULL,NULL),
('tn_lodge_consume_his','CHK_IN_DT_MIN','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_lodge_consume_his','CHK_OUT_DT_MIN','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_lodge_consume_his','PAYMENT_NUM','N',NULL,'단위 : 명'),
('tn_lodge_consume_his','BRNO','N',NULL,NULL),
('tn_lodge_consume_his','STORE_NM','N',NULL,NULL),
('tn_lodge_consume_his','ROAD_NM_ADDR','N',NULL,NULL),
('tn_lodge_consume_his','LOTNO_ADDR','N',NULL,NULL),
('tn_lodge_consume_his','ROAD_NM_CD','N',NULL,NULL),
('tn_lodge_consume_his','LOTNO_CD','N',NULL,NULL),
('tn_lodge_consume_his','PAYMENT_DT','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_lodge_consume_his','PAYMENT_MTHD_SE','N','[1~5]','코드 ''PAY'''),
('tn_lodge_consume_his','PAYMENT_AMT_WON','N',NULL,NULL),
('tn_lodge_consume_his','PAYMENT_ETC','N',NULL,NULL),
-- 아래 5개는 문서에 없는데 실제 DB에 존재(이전 단계에서 발견된 이상 케이스). 값을 지어내지 않고 명시만 함.
('tn_lodge_consume_his','COMPANION_SEQ',NULL,NULL,'문서에 없는 컬럼(원인 미확인)'),
('tn_lodge_consume_his','REL_CD',NULL,NULL,'문서에 없는 컬럼(원인 미확인)'),
('tn_lodge_consume_his','COMPANION_GENDER',NULL,NULL,'문서에 없는 컬럼(원인 미확인)'),
('tn_lodge_consume_his','COMPANION_AGE_GRP',NULL,NULL,'문서에 없는 컬럼(원인 미확인)'),
('tn_lodge_consume_his','COMPANION_SITUATION',NULL,NULL,'문서에 없는 컬럼(원인 미확인)'),

-- tn_move_his
('tn_move_his','TRAVEL_ID','Y',NULL,NULL),
('tn_move_his','TRIP_ID','Y',NULL,NULL),
('tn_move_his','START_VISIT_AREA_ID','N',NULL,NULL),
('tn_move_his','END_VISIT_AREA_ID','N',NULL,NULL),
('tn_move_his','START_DT_MIN','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_move_his','END_DT_MIN','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_move_his','MVMN_CD_1','N','[1~16, 50]','코드 ''MOV'''),
('tn_move_his','MVMN_CD_2','N','[1~16, 50]','코드 ''MOV'''),

-- tn_mvmn_consume_his
('tn_mvmn_consume_his','id','Y',NULL,'문서에 없는 대체키(자연키 없음)'),
('tn_mvmn_consume_his','TRAVEL_ID','Y',NULL,NULL),
('tn_mvmn_consume_his','MVMN_SE','Y','[1~16, 50]','코드 ''MOV'''),
('tn_mvmn_consume_his','PAYMENT_SE','Y',NULL,NULL),
('tn_mvmn_consume_his','PAYMENT_SEQ','Y',NULL,NULL),
('tn_mvmn_consume_his','MVMN_SE_NM','N',NULL,NULL),
('tn_mvmn_consume_his','RSVT_YN','N',NULL,'"Y" 또는 "N" (문서상 유사 컬럼 기준 추정)'),
('tn_mvmn_consume_his','PAYMENT_NUM','N',NULL,NULL),
('tn_mvmn_consume_his','BRNO','N',NULL,NULL),
('tn_mvmn_consume_his','STORE_NM','N',NULL,NULL),
('tn_mvmn_consume_his','PAYMENT_DT','N',NULL,'YYYY-MM-DD HH:MI'),
('tn_mvmn_consume_his','PAYMENT_MTHD_SE','N','[1~5]','코드 ''PAY'''),
('tn_mvmn_consume_his','PAYMENT_AMT_WON','N',NULL,NULL),
('tn_mvmn_consume_his','PAYMENT_ETC','N',NULL,NULL),

-- tn_tour_photo
('tn_tour_photo','TRAVEL_ID','Y',NULL,NULL),
('tn_tour_photo','VISIT_AREA_ID','Y',NULL,NULL),
('tn_tour_photo','TOUR_PHOTO_SEQ','Y',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_ID','N',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_NM','N',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_FRMAT','N',NULL,'JPG'),
('tn_tour_photo','PHOTO_FILE_DT','N',NULL,'YYYY-MM-DD HH:MI:SS'),
('tn_tour_photo','PHOTO_FILE_SAVE_PATH','N',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_RESOLUTION','N',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_X_COORD','N',NULL,NULL),
('tn_tour_photo','PHOTO_FILE_Y_COORD','N',NULL,NULL),
('tn_tour_photo','VISIT_AREA_NM','N',NULL,NULL);

-- 일괄 반영
UPDATE tc_column_dictionary d
JOIN tc_column_meta_stage s
    ON s.table_nm = d.table_nm AND s.column_nm = d.column_nm
SET d.is_required = s.is_required,
    d.value_range = s.value_range,
    d.remark      = s.remark;

DROP TEMPORARY TABLE IF EXISTS tc_column_meta_stage;

-- ============================================================
-- 검증: 스테이징에 값이 없어 채워지지 않은 컬럼 확인
--       (이상 케이스 5개만 나와야 정상 — 그 외 나오면 매핑 누락)
-- ============================================================
SELECT table_nm, column_nm, column_nm_kr, remark
FROM tc_column_dictionary
WHERE is_required IS NULL;

-- ============================================================
-- 최종 조회
-- ============================================================
SELECT
    table_nm, table_nm_kr, column_nm, column_nm_kr,
    var_type, var_scale, var_usage,
    is_required, value_range, remark
FROM tc_column_dictionary
ORDER BY table_nm, column_nm;