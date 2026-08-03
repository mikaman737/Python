-- ============================================================
-- 1단계: 테이블 간 연결 관계 감 잡기
-- ------------------------------------------------------------
-- 배경: DDL에 FOREIGN KEY 제약이 선언되어 있지 않음(PK만 존재).
--       따라서 "무엇이 무엇과 연결되는지"는 문서/사전이 아니라
--       실제 데이터로 검증해야 함. 이 스크립트는 그 확인 절차.
-- 순서: STEP1 연결 지도 개관 → STEP2 규모 비교 → STEP3 고아레코드 →
--       STEP4 복합키 조인 검증 → STEP5 이동내역-방문지 연결 확인
-- ============================================================

-- ------------------------------------------------------------
-- STEP 1. 조인키로 태깅된 컬럼이 어느 테이블들에 걸쳐 있는지 개관
--          (tc_column_dictionary의 var_usage='조인키' 활용)
--          한 컬럼명이 여러 테이블에 걸쳐 있을수록 "허브" 역할
-- ------------------------------------------------------------
SELECT
    column_nm,
    COUNT(*) AS table_cnt,
    GROUP_CONCAT(table_nm ORDER BY table_nm SEPARATOR ', ') AS tables
FROM tc_column_dictionary
WHERE var_usage = '조인키'
GROUP BY column_nm
ORDER BY table_cnt DESC;

-- ------------------------------------------------------------
-- STEP 2. TRAVEL_ID 기준 - 테이블별 규모 비교
--          tn_travel 전체 여행 수 대비, 각 테이블에 TRAVEL_ID가
--          몇 개나 걸쳐 있는지(=몇 개 여행이 이 테이블에 기록을 남겼는지)
-- ------------------------------------------------------------
SELECT 'tn_travel(기준)'        AS table_nm, COUNT(*)                    AS travel_id_cnt FROM tn_travel
UNION ALL SELECT 'tn_visit_area_info',        COUNT(DISTINCT TRAVEL_ID)  FROM tn_visit_area_info
UNION ALL SELECT 'tn_move_his',               COUNT(DISTINCT TRAVEL_ID)  FROM tn_move_his
UNION ALL SELECT 'tn_activity_his',           COUNT(DISTINCT TRAVEL_ID)  FROM tn_activity_his
UNION ALL SELECT 'tn_activity_consume_his',   COUNT(DISTINCT TRAVEL_ID)  FROM tn_activity_consume_his
UNION ALL SELECT 'tn_adv_consume_his',        COUNT(DISTINCT TRAVEL_ID)  FROM tn_adv_consume_his
UNION ALL SELECT 'tn_lodge_consume_his',      COUNT(DISTINCT TRAVEL_ID)  FROM tn_lodge_consume_his
UNION ALL SELECT 'tn_mvmn_consume_his',       COUNT(DISTINCT TRAVEL_ID)  FROM tn_mvmn_consume_his
UNION ALL SELECT 'tn_companion_info',         COUNT(DISTINCT TRAVEL_ID)  FROM tn_companion_info
UNION ALL SELECT 'tn_tour_photo',             COUNT(DISTINCT TRAVEL_ID)  FROM tn_tour_photo;

-- ------------------------------------------------------------
-- STEP 3. 고아 레코드(orphan) 확인 - 참조무결성 검증
--          자식 테이블에는 있는데 tn_travel(부모)에는 없는 TRAVEL_ID가
--          있는지 확인. 있으면 데이터 품질 이슈로 보고해야 함(추정 금지).
-- ------------------------------------------------------------
SELECT 'tn_visit_area_info' AS table_nm, COUNT(*) AS orphan_cnt
FROM tn_visit_area_info v
LEFT JOIN tn_travel t ON t.TRAVEL_ID = v.TRAVEL_ID
WHERE t.TRAVEL_ID IS NULL

UNION ALL
SELECT 'tn_move_his', COUNT(*)
FROM tn_move_his m
LEFT JOIN tn_travel t ON t.TRAVEL_ID = m.TRAVEL_ID
WHERE t.TRAVEL_ID IS NULL

UNION ALL
SELECT 'tn_companion_info', COUNT(*)
FROM tn_companion_info c
LEFT JOIN tn_travel t ON t.TRAVEL_ID = c.TRAVEL_ID
WHERE t.TRAVEL_ID IS NULL;

-- ------------------------------------------------------------
-- STEP 4. 복합키 조인 검증 - TRAVEL_ID + VISIT_AREA_ID
--          CLAUDE.md 규칙: 방문지 조인은 반드시 이 두 컬럼을 함께 써야 함.
--          여기서는 tn_visit_area_info(부모, 방문지 1건) 대비
--          tn_activity_his(자식, 방문지당 활동 여러 건)의 카디널리티를 확인
-- ------------------------------------------------------------
-- 4-1. 방문지 1건당 활동내역이 몇 건씩 붙는지 분포 (1:N 관계 확인)
SELECT
    activity_cnt,
    COUNT(*) AS visit_area_cnt
FROM (
    SELECT
        v.TRAVEL_ID, v.VISIT_AREA_ID,
        COUNT(a.ACTIVITY_TYPE_SEQ) AS activity_cnt
    FROM tn_visit_area_info v
    LEFT JOIN tn_activity_his a
        ON a.TRAVEL_ID = v.TRAVEL_ID AND a.VISIT_AREA_ID = v.VISIT_AREA_ID
    GROUP BY v.TRAVEL_ID, v.VISIT_AREA_ID
) x
GROUP BY activity_cnt
ORDER BY activity_cnt;

-- 4-2. VISIT_AREA_ID만 단독으로 조인했을 때 오류가 나는지 확인
--      (CLAUDE.md 경고 검증용: 단독 조인 시 중복 발생 여부)
SELECT
    v.VISIT_AREA_ID,
    COUNT(DISTINCT v.TRAVEL_ID) AS travel_id_variation_cnt
FROM tn_visit_area_info v
GROUP BY v.VISIT_AREA_ID
HAVING COUNT(DISTINCT v.TRAVEL_ID) > 1
LIMIT 20;

-- ------------------------------------------------------------
-- STEP 5. 이동내역(tn_move_his) ↔ 방문지(tn_visit_area_info) 연결 확인
--          START_VISIT_AREA_ID / END_VISIT_AREA_ID가 실제 방문지 ID와
--          매칭되는지 확인 (이동경로 = 방문지 간 이동으로 이어지는 구조인지)
-- ------------------------------------------------------------
SELECT
    COUNT(*)                                                                  AS move_total,
    SUM(CASE WHEN v1.VISIT_AREA_ID IS NULL THEN 1 ELSE 0 END)                 AS start_area_unmatched,
    SUM(CASE WHEN v2.VISIT_AREA_ID IS NULL THEN 1 ELSE 0 END)                 AS end_area_unmatched
FROM tn_move_his m
LEFT JOIN tn_visit_area_info v1
    ON v1.TRAVEL_ID = m.TRAVEL_ID AND v1.VISIT_AREA_ID = m.START_VISIT_AREA_ID
LEFT JOIN tn_visit_area_info v2
    ON v2.TRAVEL_ID = m.TRAVEL_ID AND v2.VISIT_AREA_ID = m.END_VISIT_AREA_ID;