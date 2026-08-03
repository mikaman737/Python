-- ============================================================
-- 컬럼 한글명 사전 (Data Dictionary)
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- 출처: Description/119-145_국내여행로그데이터(수도권)_데이터설명서.hwp
--       "4 여행로그 테이블 정의서" 표를 실제 DB 컬럼명(powerbirangers_Createtable.sql)에 맞춰 정리
-- ------------------------------------------------------------
-- 사용법:
--   1) 이 스크립트를 한 번 실행해서 tc_column_dictionary 테이블을 만든다.
--   2) 맨 아래 "전체 컬럼 한글명 조회" 쿼리로 DB의 모든 테이블/컬럼을
--      실제 스키마(INFORMATION_SCHEMA) 기준으로 한글명과 함께 확인한다.
--   3) 문서와 실제 DB 간 컬럼명이 다른 경우(예: RESIDENCE_SGG_CD vs
--      문서의 RESIDENCE_SGG_CODE)는 실제 DB 컬럼명 기준으로 맞춰놓았음.
--      다만 이는 AI가 이름 유사도로 매칭한 것이므로, 팀에서 한 번 대조 검증 필요.
-- ============================================================

DROP TABLE IF EXISTS `tc_column_dictionary`;
CREATE TABLE `tc_column_dictionary` (
    `table_nm`    VARCHAR(40)  NOT NULL,
    `table_nm_kr` VARCHAR(40)  NOT NULL,
    `column_nm`   VARCHAR(40)  NOT NULL,
    `column_nm_kr` VARCHAR(60) NOT NULL,
    PRIMARY KEY (`table_nm`, `column_nm`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `tc_column_dictionary` (`table_nm`, `table_nm_kr`, `column_nm`, `column_nm_kr`) VALUES
-- tc_codea (코드A)
('tc_codea','코드A','idx','idx'),
('tc_codea','코드A','cd_a','코드A'),
('tc_codea','코드A','cd_nm','코드A명'),
('tc_codea','코드A','cd_memo','메모'),
('tc_codea','코드A','cd_memo2','메모2'),
('tc_codea','코드A','del_flag','숨김여부'),
('tc_codea','코드A','order_num','순서'),
('tc_codea','코드A','perm_write','등록가능여부'),
('tc_codea','코드A','perm_edit','수정가능여부'),
('tc_codea','코드A','perm_delete','삭제가능여부'),
('tc_codea','코드A','ins_dt','등록일'),
('tc_codea','코드A','edit_dt','수정일'),

-- tc_codeb (코드B)
('tc_codeb','코드B','idx','idx'),
('tc_codeb','코드B','cd_a','코드A'),
('tc_codeb','코드B','cd_b','코드B'),
('tc_codeb','코드B','cd_nm','코드B명'),
('tc_codeb','코드B','cd_memo','메모'),
('tc_codeb','코드B','cd_memo2','메모2'),
('tc_codeb','코드B','del_flag','숨김여부'),
('tc_codeb','코드B','order_num','순서'),
('tc_codeb','코드B','ins_dt','등록일'),
('tc_codeb','코드B','edit_dt','수정일'),

-- tc_sgg (시군구)
('tc_sgg','시군구','SGG_CD','전체코드'),
('tc_sgg','시군구','SGG_CD1','시도코드'),
('tc_sgg','시군구','SGG_CD2','시군구코드'),
('tc_sgg','시군구','SGG_CD3','읍면동코드'),
('tc_sgg','시군구','SGG_CD4','리코드'),
('tc_sgg','시군구','SIDO_NM','시도명'),
('tc_sgg','시군구','SGG_NM','시군구명'),
('tc_sgg','시군구','DONG_NM','읍면동'),
('tc_sgg','시군구','RI_NM','리'),

-- tn_travel (여행)
('tn_travel','여행','TRAVEL_ID','여행ID'),
('tn_travel','여행','TRAVEL_NM','여행명'),
('tn_travel','여행','TRAVELER_ID','여행객ID'),
('tn_travel','여행','TRAVEL_PURPOSE','여행목적'),
('tn_travel','여행','TRAVEL_START_YMD','여행시작일자'),
('tn_travel','여행','TRAVEL_END_YMD','여행종료일자'),
('tn_travel','여행','MVMN_NM','주요이동수단'),
('tn_travel','여행','TRAVEL_PERSONA','페르소나'),
('tn_travel','여행','TRAVEL_MISSION','개별미션'),
('tn_travel','여행','TRAVEL_MISSION_CHECK','미션우선도'),

-- tn_traveller_master (여행객 Master)
('tn_traveller_master','여행객 Master','TRAVELER_ID','여행객ID'),
('tn_traveller_master','여행객 Master','RESIDENCE_SGG_CD','거주지시군구코드'),
('tn_traveller_master','여행객 Master','GENDER','성별'),
('tn_traveller_master','여행객 Master','AGE_GRP','연령대'),
('tn_traveller_master','여행객 Master','EDU_NM','최종학력'),
('tn_traveller_master','여행객 Master','EDU_FNSH_SE','최종학력이수여부'),
('tn_traveller_master','여행객 Master','MARR_STTS','혼인상태'),
('tn_traveller_master','여행객 Master','FAMILY_MEMB','가족현황'),
('tn_traveller_master','여행객 Master','JOB_NM','직업'),
('tn_traveller_master','여행객 Master','JOB_ETC','직업_기타'),
('tn_traveller_master','여행객 Master','INCOME','본인소득'),
('tn_traveller_master','여행객 Master','HOUSE_INCOME','가구소득'),
('tn_traveller_master','여행객 Master','TRAVEL_TERM','여행빈도_기간'),
('tn_traveller_master','여행객 Master','TRAVEL_NUM','여행빈도'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SIDO_1','선호여행_시도_1'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SGG_1','선호여행_시군구_1'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SIDO_2','선호여행_시도_2'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SGG_2','선호여행_시군구_2'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SIDO_3','선호여행_시도_3'),
('tn_traveller_master','여행객 Master','TRAVEL_LIKE_SGG_3','선호여행_시군구_3'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_1','여행스타일_1'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_2','여행스타일_2'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_3','여행스타일_3'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_4','여행스타일_4'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_5','여행스타일_5'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_6','여행스타일_6'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_7','여행스타일_7'),
('tn_traveller_master','여행객 Master','TRAVEL_STYL_8','여행스타일_8'),
('tn_traveller_master','여행객 Master','TRAVEL_STATUS_RESIDENCE','여행현황_거주지'),
('tn_traveller_master','여행객 Master','TRAVEL_STATUS_DESTINATION','여행현황_목적지'),
('tn_traveller_master','여행객 Master','TRAVEL_STATUS_ACCOMPANY','여행현황_동반현황'),
('tn_traveller_master','여행객 Master','TRAVEL_STATUS_YMD','여행현황_여행일자'),
('tn_traveller_master','여행객 Master','TRAVEL_MOTIVE_1','여행동기_1'),
('tn_traveller_master','여행객 Master','TRAVEL_MOTIVE_2','여행동기_2'),
('tn_traveller_master','여행객 Master','TRAVEL_MOTIVE_3','여행동기_3'),
('tn_traveller_master','여행객 Master','TRAVEL_COMPANIONS_NUM','여행동반자수'),

-- tn_visit_area_info (방문지정보)
('tn_visit_area_info','방문지정보','VISIT_AREA_ID','방문지ID'),
('tn_visit_area_info','방문지정보','TRAVEL_ID','여행ID'),
('tn_visit_area_info','방문지정보','VISIT_ORDER','진행순서'),
('tn_visit_area_info','방문지정보','VISIT_AREA_NM','방문지명'),
('tn_visit_area_info','방문지정보','VISIT_START_YMD','방문시작일자'),
('tn_visit_area_info','방문지정보','VISIT_END_YMD','방문종료일자'),
('tn_visit_area_info','방문지정보','ROAD_NM_ADDR','도로명주소'),
('tn_visit_area_info','방문지정보','LOTNO_ADDR','지번주소'),
('tn_visit_area_info','방문지정보','X_COORD','X좌표'),
('tn_visit_area_info','방문지정보','Y_COORD','Y좌표'),
('tn_visit_area_info','방문지정보','ROAD_NM_CD','도로명코드'),
('tn_visit_area_info','방문지정보','LOTNO_CD','지번코드'),
('tn_visit_area_info','방문지정보','POI_ID','POI ID'),
('tn_visit_area_info','방문지정보','POI_NM','POI명'),
('tn_visit_area_info','방문지정보','RESIDENCE_TIME_MIN','체류시간_분'),
('tn_visit_area_info','방문지정보','VISIT_AREA_TYPE_CD','방문지유형코드'),
('tn_visit_area_info','방문지정보','REVISIT_YN','재방문여부'),
('tn_visit_area_info','방문지정보','VISIT_CHC_REASON_CD','방문선택이유코드'),
('tn_visit_area_info','방문지정보','LODGING_TYPE_CD','숙소유형코드'),
('tn_visit_area_info','방문지정보','DGSTFN','만족도'),
('tn_visit_area_info','방문지정보','REVISIT_INTENTION','재방문의향'),
('tn_visit_area_info','방문지정보','RCMDTN_INTENTION','추천의향'),
('tn_visit_area_info','방문지정보','SGG_CD','시군구코드'),

-- tn_activity_his (활동내역)
('tn_activity_his','활동내역','TRAVEL_ID','여행ID'),
('tn_activity_his','활동내역','VISIT_AREA_ID','방문지ID'),
('tn_activity_his','활동내역','ACTIVITY_TYPE_CD','활동유형코드'),
('tn_activity_his','활동내역','ACTIVITY_TYPE_SEQ','활동유형순번'),
('tn_activity_his','활동내역','ACTIVITY_ETC','활동_기타'),
('tn_activity_his','활동내역','ACTIVITY_DTL','세부내역'),
('tn_activity_his','활동내역','RSVT_YN','예약여부'),
('tn_activity_his','활동내역','EXPND_SE','지출구분'),
('tn_activity_his','활동내역','ADMISSION_SE','입장료구분'),

-- tn_activity_consume_his (활동소비내역)
('tn_activity_consume_his','활동소비내역','TRAVEL_ID','여행ID'),
('tn_activity_consume_his','활동소비내역','VISIT_AREA_ID','방문지ID'),
('tn_activity_consume_his','활동소비내역','ACTIVITY_TYPE_CD','활동유형코드'),
('tn_activity_consume_his','활동소비내역','ACTIVITY_TYPE_SEQ','활동유형순번'),
('tn_activity_consume_his','활동소비내역','CONSUME_HIS_SEQ','소비내역순번'),
('tn_activity_consume_his','활동소비내역','CONSUME_HIS_SNO','소비내역부번'),
('tn_activity_consume_his','활동소비내역','PAYMENT_NUM','소비인원'),
('tn_activity_consume_his','활동소비내역','BRNO','사업자등록번호'),
('tn_activity_consume_his','활동소비내역','STORE_NM','상호명'),
('tn_activity_consume_his','활동소비내역','ROAD_NM_ADDR','도로명주소'),
('tn_activity_consume_his','활동소비내역','LOTNO_ADDR','지번주소'),
('tn_activity_consume_his','활동소비내역','ROAD_NM_CD','도로명코드'),
('tn_activity_consume_his','활동소비내역','LOTNO_CD','지번코드'),
('tn_activity_consume_his','활동소비내역','PAYMENT_DT','결제일시_분'),
('tn_activity_consume_his','활동소비내역','PAYMENT_MTHD_SE','결제방식구분'),
('tn_activity_consume_his','활동소비내역','PAYMENT_AMT_WON','결제금액_원'),
('tn_activity_consume_his','활동소비내역','PAYMENT_ETC','소비내역_기타'),
('tn_activity_consume_his','활동소비내역','SGG_CD','시군구코드'),

-- tn_adv_consume_his (사전소비내역)
('tn_adv_consume_his','사전소비내역','TRAVEL_ID','여행ID'),
('tn_adv_consume_his','사전소비내역','ADV_NM','구매내역'),
('tn_adv_consume_his','사전소비내역','ADV_SEQ','구매순번'),
('tn_adv_consume_his','사전소비내역','PAYMENT_NUM','소비인원'),
('tn_adv_consume_his','사전소비내역','BRNO','사업자등록번호'),
('tn_adv_consume_his','사전소비내역','STORE_NM','상호명'),
('tn_adv_consume_his','사전소비내역','ROAD_NM_ADDR','도로명주소'),
('tn_adv_consume_his','사전소비내역','LOTNO_ADDR','지번주소'),
('tn_adv_consume_his','사전소비내역','ROAD_NM_CD','도로명코드'),
('tn_adv_consume_his','사전소비내역','LOTNO_CD','지번코드'),
('tn_adv_consume_his','사전소비내역','PAYMENT_DT','결제일시_분'),
('tn_adv_consume_his','사전소비내역','PAYMENT_MTHD_SE','결제방식구분'),
('tn_adv_consume_his','사전소비내역','PAYMENT_AMT_WON','결제금액_원'),
('tn_adv_consume_his','사전소비내역','PAYMENT_ETC','소비내역_기타'),
('tn_adv_consume_his','사전소비내역','SGG_CD','시군구코드'),

-- tn_companion_info (동반자정보)
('tn_companion_info','동반자정보','COMPANION_SEQ','동반자순번'),
('tn_companion_info','동반자정보','TRAVEL_ID','여행ID'),
('tn_companion_info','동반자정보','REL_CD','동반자관계코드'),
('tn_companion_info','동반자정보','COMPANION_GENDER','동반자성별'),
('tn_companion_info','동반자정보','COMPANION_AGE_GRP','동반자연령대'),
('tn_companion_info','동반자정보','COMPANION_SITUATION','동반자동반상황'),

-- tn_lodge_consume_his (숙박소비내역)
('tn_lodge_consume_his','숙박소비내역','id','대체키(자연키 없음)'),
('tn_lodge_consume_his','숙박소비내역','TRAVEL_ID','여행ID'),
('tn_lodge_consume_his','숙박소비내역','LODGING_NM','숙소명'),
('tn_lodge_consume_his','숙박소비내역','LODGING_PAYMENT_SEQ','숙박경비순번'),
('tn_lodge_consume_his','숙박소비내역','LODGING_TYPE_CD','숙소유형코드'),
('tn_lodge_consume_his','숙박소비내역','RSVT_YN','예약여부'),
('tn_lodge_consume_his','숙박소비내역','CHK_IN_DT_MIN','체크인시간_분'),
('tn_lodge_consume_his','숙박소비내역','CHK_OUT_DT_MIN','체크아웃시간_분'),
('tn_lodge_consume_his','숙박소비내역','PAYMENT_NUM','소비인원'),
('tn_lodge_consume_his','숙박소비내역','BRNO','사업자등록번호'),
('tn_lodge_consume_his','숙박소비내역','STORE_NM','상호명'),
('tn_lodge_consume_his','숙박소비내역','ROAD_NM_ADDR','도로명주소'),
('tn_lodge_consume_his','숙박소비내역','LOTNO_ADDR','지번주소'),
('tn_lodge_consume_his','숙박소비내역','ROAD_NM_CD','도로명코드'),
('tn_lodge_consume_his','숙박소비내역','LOTNO_CD','지번코드'),
('tn_lodge_consume_his','숙박소비내역','PAYMENT_DT','결제일시_분'),
('tn_lodge_consume_his','숙박소비내역','PAYMENT_MTHD_SE','결제방식구분'),
('tn_lodge_consume_his','숙박소비내역','PAYMENT_AMT_WON','결제금액_원'),
('tn_lodge_consume_his','숙박소비내역','PAYMENT_ETC','소비내역_기타'),

-- tn_move_his (이동내역)
('tn_move_his','이동내역','TRAVEL_ID','여행ID'),
('tn_move_his','이동내역','TRIP_ID','Trip ID'),
('tn_move_his','이동내역','START_VISIT_AREA_ID','출발 방문지 ID'),
('tn_move_his','이동내역','END_VISIT_AREA_ID','도착 방문지 ID'),
('tn_move_his','이동내역','START_DT_MIN','출발시간_분'),
('tn_move_his','이동내역','END_DT_MIN','도착시간_분'),
('tn_move_his','이동내역','MVMN_CD_1','이동방법코드_1'),
('tn_move_his','이동내역','MVMN_CD_2','이동방법코드_2'),

-- tn_mvmn_consume_his (이동수단소비내역)
('tn_mvmn_consume_his','이동수단소비내역','id','대체키(자연키 없음)'),
('tn_mvmn_consume_his','이동수단소비내역','TRAVEL_ID','여행ID'),
('tn_mvmn_consume_his','이동수단소비내역','MVMN_SE','이동수단구분'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_SE','이용경비구분'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_SEQ','이용경비순번'),
('tn_mvmn_consume_his','이동수단소비내역','MVMN_SE_NM','이동수단구분명'),
('tn_mvmn_consume_his','이동수단소비내역','RSVT_YN','예약여부'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_NUM','포함인원'),
('tn_mvmn_consume_his','이동수단소비내역','BRNO','사업자등록번호'),
('tn_mvmn_consume_his','이동수단소비내역','STORE_NM','상호명'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_DT','결제일시_분'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_MTHD_SE','결제방식구분'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_AMT_WON','결제금액_원'),
('tn_mvmn_consume_his','이동수단소비내역','PAYMENT_ETC','소비내역_기타'),

-- tn_tour_photo (관광사진)
('tn_tour_photo','관광사진','TRAVEL_ID','여행ID'),
('tn_tour_photo','관광사진','VISIT_AREA_ID','방문지ID'),
('tn_tour_photo','관광사진','TOUR_PHOTO_SEQ','관광사진순번'),
('tn_tour_photo','관광사진','PHOTO_FILE_ID','사진파일ID'),
('tn_tour_photo','관광사진','PHOTO_FILE_NM','사진파일명'),
('tn_tour_photo','관광사진','PHOTO_FILE_FRMAT','사진파일포맷'),
('tn_tour_photo','관광사진','PHOTO_FILE_DT','사진파일촬영일시'),
('tn_tour_photo','관광사진','PHOTO_FILE_SAVE_PATH','사진파일저장경로'),
('tn_tour_photo','관광사진','PHOTO_FILE_RESOLUTION','사진파일해상도'),
('tn_tour_photo','관광사진','PHOTO_FILE_X_COORD','사진파일X좌표'),
('tn_tour_photo','관광사진','PHOTO_FILE_Y_COORD','사진파일Y좌표'),
('tn_tour_photo','관광사진','VISIT_AREA_NM','방문지명');

-- ============================================================
-- 전체 컬럼 한글명 조회 (핵심 쿼리)
-- 실제 DB 스키마(INFORMATION_SCHEMA) 기준으로 테이블·컬럼을 나열하고
-- 위에서 만든 사전과 조인해 한글명을 옆에 붙여서 전체 데이터 구조를 확인.
-- 사전에 매칭이 안 되는 컬럼은 column_nm_kr이 NULL로 나오므로 별도 확인 필요.
-- ============================================================
SELECT
    c.TABLE_NAME                        AS table_nm,
    d.table_nm_kr,
    c.ORDINAL_POSITION                  AS col_order,
    c.COLUMN_NAME                       AS column_nm,
    d.column_nm_kr,
    c.COLUMN_TYPE                       AS data_type,
    c.IS_NULLABLE                       AS is_nullable
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN tc_column_dictionary d
    ON d.table_nm = c.TABLE_NAME AND d.column_nm = c.COLUMN_NAME
WHERE c.TABLE_SCHEMA = DATABASE()
  AND c.TABLE_NAME <> 'tc_column_dictionary'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

-- 참고: 사전에 매칭 안 된(한글명 NULL) 컬럼만 따로 확인하고 싶으면 아래 실행
-- SELECT c.TABLE_NAME, c.COLUMN_NAME
-- FROM INFORMATION_SCHEMA.COLUMNS c
-- LEFT JOIN tc_column_dictionary d
--     ON d.table_nm = c.TABLE_NAME AND d.column_nm = c.COLUMN_NAME
-- WHERE c.TABLE_SCHEMA = DATABASE()
--   AND c.TABLE_NAME <> 'tc_column_dictionary'
--   AND d.column_nm_kr IS NULL;