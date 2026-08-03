-- ============================================================
-- 컬럼 사전(tc_column_dictionary) 확장: 변수형태 / 변수척도 / 변수활용도 추가
-- 선행 조건: powerbirangers_column_dictionary.sql 먼저 실행되어 있어야 함
-- ------------------------------------------------------------
-- 분류 기준 (먼저 밝힘, 7원칙 2번)
--   1) 변수형태(var_type): 통계적 변수 구조
--      - 식별자      : PK/FK, 조인용 ID/SEQ/코드 (분석 대상 값 자체가 아님)
--      - 날짜/시간형 : YMD, DT_MIN 등 시각 컬럼
--      - 연속형      : 금액/체류시간/좌표 등 연속 수치
--      - 이산형      : 인원수/횟수 등 정수 카운트
--      - 순서형      : 연령대·학력·소득 구간, 1~5·1~7 점수 등 순서 있는 구간
--      - 범주형      : 순서 없는 구분값(성별, 코드 등)
--      - 텍스트형    : 자유기술/명칭 등 비정형 문자열
--   2) 변수척도(var_scale): Stevens의 4대 척도 + 식별자/비정형 구분
--      - 명목척도(식별자) / 명목척도 / 서열척도 / 등간척도 / 비율척도 / 해당없음(비정형)
--   3) 변수활용도(var_usage): 분석에서의 역할
--      - 조인키 / 보조 식별자 / 시스템 관리 변수 / 시간 계산용 / 위치 참고용 /
--        코드값(tc_codeb 참조 필요) / 세그먼트 변수 / 핵심 분석지표 /
--        부가 설명(자유기술) / 미디어 메타데이터
-- ------------------------------------------------------------
-- 주의: 컬럼명이 같으면 테이블이 달라도 동일 의미라는 전제로 컬럼명 단위 일괄 분류함
--       (데이터설명서 대조로 확인됨). 분류는 AI가 이름/타입 기준으로 판단한 것이므로
--       팀에서 특히 '세그먼트 변수' vs '핵심 분석지표' 경계는 분석 목적에 맞게 재검토 필요.
-- ============================================================

ALTER TABLE tc_column_dictionary
    ADD COLUMN var_type  VARCHAR(20) NULL AFTER column_nm_kr,
    ADD COLUMN var_scale VARCHAR(20) NULL AFTER var_type,
    ADD COLUMN var_usage VARCHAR(40) NULL AFTER var_scale;

-- tn_lodge_consume_his에 실제로 존재하지만 이전 사전에 없던 5개 컬럼 보강
-- (앞서 확인된 이상 케이스: tn_companion_info 컬럼이 그대로 붙어있음. 원인 미확인 상태로 등록만 함)
INSERT IGNORE INTO tc_column_dictionary (table_nm, table_nm_kr, column_nm, column_nm_kr) VALUES
('tn_lodge_consume_his','숙박소비내역','COMPANION_SEQ','동반자순번(※문서에 없는 컬럼, 원인 미확인)'),
('tn_lodge_consume_his','숙박소비내역','REL_CD','동반자관계코드(※문서에 없는 컬럼, 원인 미확인)'),
('tn_lodge_consume_his','숙박소비내역','COMPANION_GENDER','동반자성별(※문서에 없는 컬럼, 원인 미확인)'),
('tn_lodge_consume_his','숙박소비내역','COMPANION_AGE_GRP','동반자연령대(※문서에 없는 컬럼, 원인 미확인)'),
('tn_lodge_consume_his','숙박소비내역','COMPANION_SITUATION','동반자동반상황(※문서에 없는 컬럼, 원인 미확인)');

-- ------------------------------------------------------------
-- 1) 식별자 (조인키)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '식별자', var_scale = '명목척도(식별자)', var_usage = '조인키'
WHERE column_nm IN (
    'TRAVEL_ID','TRAVELER_ID','VISIT_AREA_ID','TRIP_ID','START_VISIT_AREA_ID','END_VISIT_AREA_ID',
    'POI_ID','PHOTO_FILE_ID','COMPANION_SEQ','ADV_SEQ','ACTIVITY_TYPE_SEQ','CONSUME_HIS_SEQ',
    'CONSUME_HIS_SNO','LODGING_PAYMENT_SEQ','PAYMENT_SEQ','TOUR_PHOTO_SEQ','SGG_CD'
);

-- 사업자등록번호는 조인 대상은 아니지만 개체 식별용 보조 식별자
UPDATE tc_column_dictionary
SET var_type = '식별자', var_scale = '명목척도(식별자)', var_usage = '보조 식별자'
WHERE column_nm = 'BRNO';

-- ------------------------------------------------------------
-- 2) 시스템/코드테이블 관리용
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '식별자', var_scale = '명목척도(식별자)', var_usage = '시스템 관리 변수'
WHERE column_nm IN ('idx','id');

UPDATE tc_column_dictionary
SET var_type = '범주형', var_scale = '명목척도', var_usage = '코드값(조인키)'
WHERE column_nm IN ('cd_a','cd_b');

UPDATE tc_column_dictionary
SET var_type = '텍스트형', var_scale = '해당없음(비정형)', var_usage = '부가 설명(자유기술)'
WHERE column_nm = 'cd_nm';

UPDATE tc_column_dictionary
SET var_type = '범주형', var_scale = '명목척도', var_usage = '시스템 관리 변수'
WHERE column_nm IN ('del_flag','perm_write','perm_edit','perm_delete');

UPDATE tc_column_dictionary
SET var_type = '이산형', var_scale = '비율척도', var_usage = '시스템 관리 변수'
WHERE column_nm = 'order_num';

UPDATE tc_column_dictionary
SET var_type = '날짜/시간형', var_scale = '등간척도', var_usage = '시스템 관리 변수'
WHERE column_nm IN ('ins_dt','edit_dt');

UPDATE tc_column_dictionary
SET var_type = '텍스트형', var_scale = '해당없음(비정형)', var_usage = '부가 설명(자유기술)'
WHERE column_nm IN ('cd_memo','cd_memo2');

-- ------------------------------------------------------------
-- 3) 날짜/시간형
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '날짜/시간형', var_scale = '등간척도', var_usage = '시간 계산용'
WHERE column_nm IN (
    'TRAVEL_START_YMD','TRAVEL_END_YMD','VISIT_START_YMD','VISIT_END_YMD',
    'START_DT_MIN','END_DT_MIN','CHK_IN_DT_MIN','CHK_OUT_DT_MIN','PAYMENT_DT','PHOTO_FILE_DT'
);

-- ------------------------------------------------------------
-- 4) 연속형 (금액/시간/좌표)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '연속형', var_scale = '비율척도', var_usage = '핵심 분석지표'
WHERE column_nm IN ('PAYMENT_AMT_WON','RESIDENCE_TIME_MIN');

UPDATE tc_column_dictionary
SET var_type = '연속형', var_scale = '비율척도', var_usage = '위치 참고용'
WHERE column_nm IN ('X_COORD','Y_COORD','PHOTO_FILE_X_COORD','PHOTO_FILE_Y_COORD');

-- ------------------------------------------------------------
-- 5) 이산형 (카운트)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '이산형', var_scale = '비율척도', var_usage = '핵심 분석지표'
WHERE column_nm IN ('PAYMENT_NUM','TRAVEL_NUM','TRAVEL_COMPANIONS_NUM');

UPDATE tc_column_dictionary
SET var_type = '이산형', var_scale = '비율척도', var_usage = '방문순서(시간 계산용)'
WHERE column_nm = 'VISIT_ORDER';

-- ------------------------------------------------------------
-- 6) 순서형 (서열척도)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '순서형', var_scale = '서열척도', var_usage = '세그먼트 변수'
WHERE column_nm IN (
    'AGE_GRP','COMPANION_AGE_GRP','EDU_NM','EDU_FNSH_SE','INCOME','HOUSE_INCOME','TRAVEL_TERM'
);

UPDATE tc_column_dictionary
SET var_type = '순서형', var_scale = '서열척도', var_usage = '세그먼트 변수(페르소나)'
WHERE column_nm IN (
    'TRAVEL_STYL_1','TRAVEL_STYL_2','TRAVEL_STYL_3','TRAVEL_STYL_4',
    'TRAVEL_STYL_5','TRAVEL_STYL_6','TRAVEL_STYL_7','TRAVEL_STYL_8'
);

UPDATE tc_column_dictionary
SET var_type = '순서형', var_scale = '서열척도', var_usage = '핵심 분석지표'
WHERE column_nm IN ('DGSTFN','REVISIT_INTENTION','RCMDTN_INTENTION');

-- ------------------------------------------------------------
-- 7) 범주형 - 코드값(별도 코드테이블 tc_codeb 참조 필요)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '범주형', var_scale = '명목척도', var_usage = '코드값(tc_codeb 참조 필요)'
WHERE column_nm IN (
    'VISIT_AREA_TYPE_CD','REVISIT_YN','VISIT_CHC_REASON_CD','LODGING_TYPE_CD','ACTIVITY_TYPE_CD',
    'RSVT_YN','EXPND_SE','ADMISSION_SE','PAYMENT_MTHD_SE','MVMN_CD_1','MVMN_CD_2','MVMN_SE',
    'PAYMENT_SE','REL_CD','COMPANION_SITUATION','TRAVEL_MOTIVE_1','TRAVEL_MOTIVE_2','TRAVEL_MOTIVE_3',
    'TRAVEL_PURPOSE','TRAVEL_MISSION','TRAVEL_MISSION_CHECK'
);

-- ------------------------------------------------------------
-- 8) 범주형 - 세그먼트/속성 변수 (코드테이블 참조 불필요, 값 자체가 의미)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '범주형', var_scale = '명목척도', var_usage = '세그먼트 변수'
WHERE column_nm IN (
    'GENDER','COMPANION_GENDER','MARR_STTS','JOB_NM','JOB_ETC','FAMILY_MEMB',
    'RESIDENCE_SGG_CD','SIDO_NM','SGG_NM','DONG_NM','RI_NM',
    'TRAVEL_LIKE_SIDO_1','TRAVEL_LIKE_SGG_1','TRAVEL_LIKE_SIDO_2','TRAVEL_LIKE_SGG_2',
    'TRAVEL_LIKE_SIDO_3','TRAVEL_LIKE_SGG_3',
    'TRAVEL_STATUS_RESIDENCE','TRAVEL_STATUS_DESTINATION','TRAVEL_STATUS_ACCOMPANY','TRAVEL_STATUS_YMD',
    'MVMN_NM','MVMN_SE_NM'
);

-- ------------------------------------------------------------
-- 9) 텍스트형 - 자유기술/명칭
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '텍스트형', var_scale = '해당없음(비정형)', var_usage = '부가 설명(자유기술)'
WHERE column_nm IN (
    'TRAVEL_NM','TRAVEL_PERSONA','VISIT_AREA_NM','POI_NM','ACTIVITY_ETC','ACTIVITY_DTL',
    'ADV_NM','STORE_NM','LODGING_NM','PAYMENT_ETC'
);

-- ------------------------------------------------------------
-- 10) 미디어(사진) 메타데이터
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '텍스트형', var_scale = '해당없음(비정형)', var_usage = '미디어 메타데이터'
WHERE column_nm IN (
    'PHOTO_FILE_NM','PHOTO_FILE_FRMAT','PHOTO_FILE_SAVE_PATH','PHOTO_FILE_RESOLUTION'
);

-- ------------------------------------------------------------
-- 11) 위치 참고용 (주소/코드)
-- ------------------------------------------------------------
UPDATE tc_column_dictionary
SET var_type = '텍스트형', var_scale = '해당없음(비정형)', var_usage = '위치 참고용'
WHERE column_nm IN ('ROAD_NM_ADDR','LOTNO_ADDR');

UPDATE tc_column_dictionary
SET var_type = '범주형', var_scale = '명목척도', var_usage = '위치 참고용'
WHERE column_nm IN ('ROAD_NM_CD','LOTNO_CD','SGG_CD1','SGG_CD2','SGG_CD3','SGG_CD4');

-- ============================================================
-- 검증: 분류 안 된 컬럼이 남아있는지 확인 (7원칙 1번 - 없는 것처럼 숨기지 않음)
-- ============================================================
SELECT table_nm, column_nm, column_nm_kr
FROM tc_column_dictionary
WHERE var_type IS NULL OR var_scale IS NULL OR var_usage IS NULL;

-- ============================================================
-- 최종 조회: 전체 컬럼 + 한글명 + 변수형태/척도/활용도
-- ============================================================
SELECT
    d.table_nm,
    d.table_nm_kr,
    d.column_nm,
    d.column_nm_kr,
    d.var_type,
    d.var_scale,
    d.var_usage
FROM tc_column_dictionary d
ORDER BY d.table_nm, d.column_nm;