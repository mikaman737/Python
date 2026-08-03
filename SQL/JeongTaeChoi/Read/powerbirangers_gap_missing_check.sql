-- ============================================================
-- "틈"(여행 일정 빈 시간) 계산 가능 여부 확인용 결측률 쿼리
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ------------------------------------------------------------
-- 배경: tn_visit_area_info.VISIT_START_YMD/VISIT_END_YMD는 DATE형이라
--       시각(시:분) 정보가 없음. "틈" 계산에 쓸 수 있는 시간 정보는
--       ① tn_visit_area_info.RESIDENCE_TIME_MIN (방문지 체류시간, 분)
--       ② tn_move_his.START_DT_MIN / END_DT_MIN (이동 시작·도착 시각, DATETIME)
--       두 곳뿐이므로, 이 쿼리는 두 컬럼 세트의 결측 정도를 먼저 정량화한다.
-- 이 결과가 나오기 전까지는 "틈" 계산 로직(LAG/LEAD 등)에 들어가지 않는다.
-- ============================================================

-- 0. 원본 규모 확인 (표본 크기 파악용)
SELECT
    (SELECT COUNT(*)                 FROM tn_travel)          AS travel_total_cnt,
    (SELECT COUNT(DISTINCT TRAVEL_ID) FROM tn_visit_area_info) AS travel_with_visit_cnt,
    (SELECT COUNT(DISTINCT TRAVEL_ID) FROM tn_move_his)        AS travel_with_move_cnt;

-- 1. tn_visit_area_info 컬럼별 결측 건수/비율 (방문지 레코드 단위)
SELECT
    COUNT(*)                                                              AS total_rows,
    SUM(CASE WHEN VISIT_ORDER        IS NULL THEN 1 ELSE 0 END)           AS null_visit_order,
    SUM(CASE WHEN RESIDENCE_TIME_MIN IS NULL THEN 1 ELSE 0 END)           AS null_residence_time,
    SUM(CASE WHEN VISIT_START_YMD    IS NULL THEN 1 ELSE 0 END)           AS null_visit_start_ymd,
    SUM(CASE WHEN VISIT_END_YMD      IS NULL THEN 1 ELSE 0 END)           AS null_visit_end_ymd,
    ROUND(SUM(CASE WHEN RESIDENCE_TIME_MIN IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_residence_time
FROM tn_visit_area_info;

-- 2. tn_move_his 컬럼별 결측 건수/비율 (이동 레코드 단위)
SELECT
    COUNT(*)                                                          AS total_rows,
    SUM(CASE WHEN START_DT_MIN        IS NULL THEN 1 ELSE 0 END)      AS null_start_dt,
    SUM(CASE WHEN END_DT_MIN          IS NULL THEN 1 ELSE 0 END)      AS null_end_dt,
    SUM(CASE WHEN START_VISIT_AREA_ID IS NULL THEN 1 ELSE 0 END)      AS null_start_area_id,
    SUM(CASE WHEN END_VISIT_AREA_ID   IS NULL THEN 1 ELSE 0 END)      AS null_end_area_id,
    ROUND(SUM(CASE WHEN START_DT_MIN IS NULL OR END_DT_MIN IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_null_either_dt
FROM tn_move_his;

-- 3. TRAVEL_ID 단위 - 방문지 2개 이상 + RESIDENCE_TIME_MIN 전부 존재 (틈 계산 후보)
--    방문지가 1개뿐이면애초에 "사이 틈"이 존재할 수 없으므로 제외
SELECT
    TRAVEL_ID,
    COUNT(*)                                                    AS visit_cnt,
    SUM(CASE WHEN RESIDENCE_TIME_MIN IS NULL THEN 1 ELSE 0 END) AS null_residence_cnt
FROM tn_visit_area_info
GROUP BY TRAVEL_ID
HAVING COUNT(*) >= 2;

-- 4. TRAVEL_ID 단위 - 이동 기록의 시각이 전부 채워진 여행 비율
SELECT
    TRAVEL_ID,
    COUNT(*)                                                                    AS move_cnt,
    SUM(CASE WHEN START_DT_MIN IS NULL OR END_DT_MIN IS NULL THEN 1 ELSE 0 END) AS null_dt_cnt
FROM tn_move_his
GROUP BY TRAVEL_ID;

-- 5. 최종 요약 - "틈" 계산이 실제 가능한 TRAVEL_ID 비율
--    조건: 방문지 2개 이상 & 해당 방문지 전부 RESIDENCE_TIME_MIN 존재
--          & 그 TRAVEL_ID의 이동기록 START_DT_MIN/END_DT_MIN 전부 존재
WITH visit_ready AS (
    SELECT TRAVEL_ID
    FROM tn_visit_area_info
    GROUP BY TRAVEL_ID
    HAVING COUNT(*) >= 2
       AND SUM(CASE WHEN RESIDENCE_TIME_MIN IS NULL THEN 1 ELSE 0 END) = 0
),
move_ready AS (
    SELECT TRAVEL_ID
    FROM tn_move_his
    GROUP BY TRAVEL_ID
    HAVING SUM(CASE WHEN START_DT_MIN IS NULL OR END_DT_MIN IS NULL THEN 1 ELSE 0 END) = 0
)
SELECT
    (SELECT COUNT(*) FROM tn_travel)                                         AS travel_total_cnt,
    (SELECT COUNT(*) FROM visit_ready)                                       AS visit_ready_cnt,
    (SELECT COUNT(*) FROM move_ready)                                        AS move_ready_cnt,
    (SELECT COUNT(*) FROM visit_ready v JOIN move_ready m ON v.TRAVEL_ID = m.TRAVEL_ID) AS gap_calc_ready_cnt,
    ROUND(
        (SELECT COUNT(*) FROM visit_ready v JOIN move_ready m ON v.TRAVEL_ID = m.TRAVEL_ID) * 100.0
        / (SELECT COUNT(*) FROM tn_travel), 1
    ) AS pct_gap_calc_ready;


