-- ============================================================
-- 0단계: 컬럼/데이터 이해용 탐색 쿼리 (조인·계산 없이 테이블 하나씩 확인)
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ------------------------------------------------------------
-- 목적: 본격 분석(틈 계산 등) 전에 "이 테이블에 뭐가 들어있는지"를
--       눈으로 확인하는 단계. 순서대로 실행하면서 컬럼 값을 익힐 것.
-- 사용법: 아래 3개 핵심 테이블부터 시작. 나머지 테이블도 같은 패턴 반복.
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1. 테이블 구조 확인 (컬럼명/타입/NULL 허용 여부)
--          엑셀 데이터설명서와 실제 DB 스키마가 일치하는지 대조
-- ------------------------------------------------------------
DESCRIBE tn_travel;
DESCRIBE tn_traveller_master;
DESCRIBE tn_visit_area_info;

-- ------------------------------------------------------------
-- STEP 2. 행 수 확인 (테이블 규모 감 잡기)
-- ------------------------------------------------------------
SELECT 'tn_travel' AS table_nm, COUNT(*) AS row_cnt FROM tn_travel
UNION ALL
SELECT 'tn_traveller_master', COUNT(*) FROM tn_traveller_master
UNION ALL
SELECT 'tn_visit_area_info', COUNT(*) FROM tn_visit_area_info;

-- ------------------------------------------------------------
-- STEP 3. 샘플 데이터 확인 (실제 값이 어떻게 생겼는지)
--          LIMIT으로 몇 행만 눈으로 확인
-- ------------------------------------------------------------
SELECT * FROM tn_travel LIMIT 10;
SELECT * FROM tn_traveller_master LIMIT 10;
SELECT * FROM tn_visit_area_info LIMIT 10;

-- ------------------------------------------------------------
-- STEP 4. 핵심 코드성 컬럼의 실제 값 종류 확인
--          VARCHAR(10) 등으로 선언된 코드 컬럼은 값 포맷이 문서와
--          다를 수 있어(예: '남'/'여' vs 'M'/'F') 반드시 먼저 확인
-- ------------------------------------------------------------
SELECT GENDER, COUNT(*) AS cnt FROM tn_traveller_master GROUP BY GENDER;
SELECT AGE_GRP, COUNT(*) AS cnt FROM tn_traveller_master GROUP BY AGE_GRP ORDER BY AGE_GRP;
SELECT MARR_STTS, COUNT(*) AS cnt FROM tn_traveller_master GROUP BY MARR_STTS;

SELECT TRAVEL_PURPOSE, COUNT(*) AS cnt FROM tn_travel GROUP BY TRAVEL_PURPOSE ORDER BY cnt DESC;
SELECT MVMN_NM, COUNT(*) AS cnt FROM tn_travel GROUP BY MVMN_NM ORDER BY cnt DESC;

SELECT VISIT_AREA_TYPE_CD, COUNT(*) AS cnt FROM tn_visit_area_info GROUP BY VISIT_AREA_TYPE_CD ORDER BY cnt DESC;
SELECT LODGING_TYPE_CD, COUNT(*) AS cnt FROM tn_visit_area_info GROUP BY LODGING_TYPE_CD ORDER BY cnt DESC;
SELECT REVISIT_YN, COUNT(*) AS cnt FROM tn_visit_area_info GROUP BY REVISIT_YN;

-- ------------------------------------------------------------
-- STEP 5. 코드값 설명 테이블(tc_codea, tc_codeb) 구조/내용 확인
--          위 STEP 4에서 나온 코드(VISIT_AREA_TYPE_CD 등)의 실제 의미를
--          여기서 매핑해서 확인
-- ------------------------------------------------------------
DESCRIBE tc_codea;
DESCRIBE tc_codeb;
SELECT * FROM tc_codea LIMIT 20;
SELECT * FROM tc_codeb LIMIT 20;

-- ------------------------------------------------------------
-- STEP 6. 숫자형 컬럼 기본 통계 (min/max/avg로 이상치 감 잡기)
-- ------------------------------------------------------------
SELECT
    MIN(RESIDENCE_TIME_MIN) AS min_residence,
    MAX(RESIDENCE_TIME_MIN) AS max_residence,
    ROUND(AVG(RESIDENCE_TIME_MIN), 1) AS avg_residence
FROM tn_visit_area_info;

SELECT
    MIN(DGSTFN) AS min_satisfaction,
    MAX(DGSTFN) AS max_satisfaction,
    ROUND(AVG(DGSTFN), 2) AS avg_satisfaction
FROM tn_visit_area_info;

-- ------------------------------------------------------------
-- STEP 7. 컬럼별 결측(NULL) 건수 확인 (한 테이블 전체 컬럼 한 번에)
--          우선 핵심 3테이블만. 나머지 테이블은 같은 패턴으로 확장
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN TRAVEL_PURPOSE   IS NULL THEN 1 ELSE 0 END) AS null_purpose,
    SUM(CASE WHEN TRAVEL_START_YMD IS NULL THEN 1 ELSE 0 END) AS null_start_ymd,
    SUM(CASE WHEN TRAVEL_END_YMD   IS NULL THEN 1 ELSE 0 END) AS null_end_ymd,
    SUM(CASE WHEN MVMN_NM          IS NULL THEN 1 ELSE 0 END) AS null_mvmn_nm
FROM tn_travel;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN GENDER  IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN AGE_GRP IS NULL THEN 1 ELSE 0 END) AS null_age_grp,
    SUM(CASE WHEN INCOME  IS NULL THEN 1 ELSE 0 END) AS null_income
FROM tn_traveller_master;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN VISIT_START_YMD     IS NULL THEN 1 ELSE 0 END) AS null_start_ymd,
    SUM(CASE WHEN VISIT_END_YMD       IS NULL THEN 1 ELSE 0 END) AS null_end_ymd,
    SUM(CASE WHEN RESIDENCE_TIME_MIN  IS NULL THEN 1 ELSE 0 END) AS null_residence_time,
    SUM(CASE WHEN VISIT_AREA_TYPE_CD  IS NULL THEN 1 ELSE 0 END) AS null_area_type
FROM tn_visit_area_info;