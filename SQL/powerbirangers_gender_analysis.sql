-- ============================================================
-- 성별(GENDER)에 따른 지표 비교 쿼리 모음
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- 기준 컬럼: tn_traveller_master.GENDER
-- ------------------------------------------------------------
-- 먼저 GENDER 컬럼에 실제로 어떤 값이 들어있는지 확인하세요.
-- (예: '남'/'여' 또는 'M'/'F' 등, 스키마상 VARCHAR(10)이라 값 포맷이 고정되어 있지 않음)
-- ============================================================

-- 0. GENDER 값 확인 (다른 쿼리 실행 전 먼저 확인용)
SELECT GENDER, COUNT(*) AS cnt
FROM tn_traveller_master
GROUP BY GENDER;

-- 1. 성별 인원수 및 비율
SELECT
    GENDER,
    COUNT(*) AS traveler_cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM tn_traveller_master
GROUP BY GENDER;

-- 2. 성별 평균 연령대 / 소득 / 가구소득
SELECT
    GENDER,
    ROUND(AVG(AGE_GRP), 1)      AS avg_age_grp,
    ROUND(AVG(INCOME), 1)       AS avg_income,
    ROUND(AVG(HOUSE_INCOME), 1) AS avg_house_income
FROM tn_traveller_master
GROUP BY GENDER;

-- 3. 성별 평균 여행 횟수 / 여행 주기(TERM) / 동반 인원수
SELECT
    GENDER,
    ROUND(AVG(TRAVEL_NUM), 2)             AS avg_travel_num,
    ROUND(AVG(TRAVEL_TERM), 2)            AS avg_travel_term,
    ROUND(AVG(TRAVEL_COMPANIONS_NUM), 2)  AS avg_companions_num
FROM tn_traveller_master
GROUP BY GENDER;

-- 4. 성별 결혼상태(MARR_STTS) 분포
SELECT
    GENDER,
    MARR_STTS,
    COUNT(*) AS cnt
FROM tn_traveller_master
GROUP BY GENDER, MARR_STTS
ORDER BY GENDER, MARR_STTS;

-- 5. 성별 여행 스타일 지표(TRAVEL_STYL_1~8) 평균
--    각 축은 1~7 스펙트럼(예: 자연친화적 1 ~ 도시적 7 등, KTO 여행행태 스펙 참조)
SELECT
    GENDER,
    ROUND(AVG(TRAVEL_STYL_1), 2) AS styl_1,
    ROUND(AVG(TRAVEL_STYL_2), 2) AS styl_2,
    ROUND(AVG(TRAVEL_STYL_3), 2) AS styl_3,
    ROUND(AVG(TRAVEL_STYL_4), 2) AS styl_4,
    ROUND(AVG(TRAVEL_STYL_5), 2) AS styl_5,
    ROUND(AVG(TRAVEL_STYL_6), 2) AS styl_6,
    ROUND(AVG(TRAVEL_STYL_7), 2) AS styl_7,
    ROUND(AVG(TRAVEL_STYL_8), 2) AS styl_8
FROM tn_traveller_master
GROUP BY GENDER;

-- 6. 성별 주 이동수단(MVMN_NM) 분포 (tn_travel 조인)
SELECT
    tm.GENDER,
    t.MVMN_NM,
    COUNT(*) AS trip_cnt
FROM tn_travel t
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
GROUP BY tm.GENDER, t.MVMN_NM
ORDER BY tm.GENDER, trip_cnt DESC;

-- 7. 성별 평균 만족도 / 재방문의향 / 추천의향 (1~5점, 방문지 단위)
SELECT
    tm.GENDER,
    ROUND(AVG(v.DGSTFN), 2)             AS avg_satisfaction,
    ROUND(AVG(v.REVISIT_INTENTION), 2)  AS avg_revisit_intention,
    ROUND(AVG(v.RCMDTN_INTENTION), 2)   AS avg_recommend_intention
FROM tn_visit_area_info v
JOIN tn_travel t           ON t.TRAVEL_ID = v.TRAVEL_ID
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
GROUP BY tm.GENDER;

-- 8. 성별 평균 방문지 체류시간(분)
SELECT
    tm.GENDER,
    ROUND(AVG(v.RESIDENCE_TIME_MIN), 1) AS avg_residence_min
FROM tn_visit_area_info v
JOIN tn_travel t           ON t.TRAVEL_ID = v.TRAVEL_ID
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
GROUP BY tm.GENDER;

-- 9. 성별 총 소비액 / 여행(TRAVEL_ID)당 평균 소비액
--    활동+사전+숙박+이동수단 소비내역 4개 테이블 통합
SELECT
    tm.GENDER,
    COUNT(DISTINCT c.TRAVEL_ID)                             AS travel_cnt,
    SUM(c.PAYMENT_AMT_WON)                                  AS total_amt_won,
    ROUND(SUM(c.PAYMENT_AMT_WON) / COUNT(DISTINCT c.TRAVEL_ID), 0) AS avg_amt_per_travel
FROM (
    SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
    UNION ALL
    SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
    UNION ALL
    SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
    UNION ALL
    SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
) c
JOIN tn_travel t            ON t.TRAVEL_ID = c.TRAVEL_ID
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
GROUP BY tm.GENDER;

-- 10. 성별 주요 여행 동기(TRAVEL_MOTIVE_1) 코드 분포 (Top 5, 코드명은 tc_codeb 조인 필요시 추가)
SELECT
    tm.GENDER,
    tm.TRAVEL_MOTIVE_1,
    COUNT(*) AS cnt
FROM tn_traveller_master tm
GROUP BY tm.GENDER, tm.TRAVEL_MOTIVE_1
ORDER BY tm.GENDER, cnt DESC;
