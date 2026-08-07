-- ================================================================
-- 재방문 의향(REVISIT_INTENTION) 상/하위 집단 특성 비교
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ----------------------------------------------------------------
-- 목적: "재방문 의향이 낮은 여행자군"과 "높은 여행자군"을 나눠서, 두 집단이
-- 세그먼트(성별·연령·직업·소득)와 여행 패턴(동반유형·틈비율·소비·방문지 성향)에서
-- 어떻게 다른지 확인한다. segment.sql 원래 가설2("재방문-소비")와는 다른 질문임을
-- 주의: 가설2는 "그 지역을 실제로 재방문했는가"(REVISIT_YN, 과거형)였고, 이 파일은
-- "다시 오고 싶은가"(REVISIT_INTENTION, 의향/미래형)를 다룬다 — 서로 다른 컬럼, 다른 개념.
--
-- 참고파일: segment_hypothesis_tutorial.sql(틈/소비 정의 재사용),
--          powerbirangers_segment_pattern_spending.ipynb(소비 정의·시각화 스타일 재사용)
-- ================================================================


-- ================================================================
-- STEP 1. 재방문 의향 점수 정의 확인
-- ----------------------------------------------------------------
-- REVISIT_INTENTION은 방문지(VISIT_AREA_ID) 단위 1~5점 응답이다. 여행(TRAVEL_ID)
-- 단위로 특성을 비교하려면 먼저 "여행 하나의 재방문 의향 점수"를 정의해야 한다.
-- ================================================================

-- 1-1. 원본 분포 확인 (방문지 단위, 5점 척도 맞는지 먼저 확인)
SELECT REVISIT_INTENTION, COUNT(*) AS cnt
FROM tn_visit_area_info
GROUP BY REVISIT_INTENTION
ORDER BY REVISIT_INTENTION;

-- 1-2. 여행 단위 평균으로 집계 (한 여행 안의 여러 방문지 점수를 평균)
SELECT
    TRAVEL_ID,
    ROUND(AVG(REVISIT_INTENTION), 2) AS revisit_score,
    COUNT(*) AS 방문지_평가건수
FROM tn_visit_area_info
WHERE REVISIT_INTENTION IS NOT NULL
GROUP BY TRAVEL_ID;
-- 이 값이 아래 STEP 2부터 "재방문 의향 점수"로 쓰인다.


-- ================================================================
-- STEP 2. 상/하위 집단 나누기
-- ----------------------------------------------------------------
-- 표본을 다 쓰기 위해 중앙값 기준 2등분(NTILE(2))을 기본으로 하되, 대비를 더
-- 뚜렷하게 보고 싶으면 STEP 2-2처럼 사분위 양 끝(상위 25% vs 하위 25%)만 비교한다.
-- ================================================================

-- 2-1. 중앙값 기준 2등분 (전체 표본 사용)
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
)
SELECT
    TRAVEL_ID,
    revisit_score,
    NTILE(2) OVER (ORDER BY revisit_score) AS half   -- 1=하위 50%(재방문의향 낮음), 2=상위 50%(높음)
FROM revisit
ORDER BY revisit_score;

-- 2-2. 사분위 양 끝 비교용 (더 뚜렷한 대비, 표본은 절반만 사용)
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
)
SELECT
    TRAVEL_ID,
    revisit_score,
    NTILE(4) OVER (ORDER BY revisit_score) AS q   -- 1=하위 25%, 4=상위 25% (2,3은 이번 비교에서 제외)
FROM revisit
ORDER BY revisit_score;


-- ================================================================
-- STEP 3. 그룹별 세그먼트 특성 비교 (성별·연령·직업·소득)
-- ----------------------------------------------------------------
-- STEP 2-1(중앙값 2등분)을 기준으로 삼아 traveller_master와 조인.
-- ================================================================
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
),
grouped AS (
    SELECT
        TRAVEL_ID,
        revisit_score,
        CASE WHEN NTILE(2) OVER (ORDER BY revisit_score) = 1 THEN '낮음' ELSE '높음' END AS revisit_group
    FROM revisit
)
SELECT
    g.revisit_group,
    tm.GENDER,
    COUNT(*) AS cnt
FROM grouped g
JOIN tn_travel t ON t.TRAVEL_ID = g.TRAVEL_ID
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
GROUP BY g.revisit_group, tm.GENDER
ORDER BY g.revisit_group, tm.GENDER;
-- 같은 패턴으로 GENDER 자리에 AGE_GRP / JOB_NM / INCOME을 넣어 반복 확인
-- (JOB_NM·INCOME은 숫자 코드이므로 tc_codeb LEFT JOIN으로 디코딩해서 볼 것 —
--  segment_hypothesis_tutorial.sql STEP 4와 동일 패턴)


-- ================================================================
-- STEP 4. 그룹별 여행 패턴 비교 (동반유형·틈비율·소비·여행일수)
-- ----------------------------------------------------------------
-- 이번 세션에서 확정한 정의를 그대로 재사용:
--   - 소비 = 활동+사전+숙박+이동수단 합계 (segment_hypothesis_tutorial.sql STEP 3-3)
--   - 틈비율 = gap_minutes 상한값 - RESIDENCE_TIME_MIN이 양수인 구간의 비율,
--     VISIT_AREA_TYPE_CD 9,12,21,22,23,24 제외 (STEP 3-1/3-2)
--   - 동반유형 = tn_companion_info 인원수 기준 나홀로/2인/3인이상 (STEP 3-5)
-- ================================================================
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
),
grouped AS (
    SELECT
        TRAVEL_ID,
        CASE WHEN NTILE(2) OVER (ORDER BY revisit_score) = 1 THEN '낮음' ELSE '높음' END AS revisit_group
    FROM revisit
),
travel_total_consume AS (
    SELECT c.TRAVEL_ID, SUM(c.PAYMENT_AMT_WON) AS total_amt_won
    FROM (
        SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
        UNION ALL
        SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
        UNION ALL
        SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
        UNION ALL
        SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
    ) c
    GROUP BY c.TRAVEL_ID
),
travel_companion AS (
    SELECT t.TRAVEL_ID, COALESCE(cc.companion_cnt, 0) + 1 AS person_cnt
    FROM tn_travel t
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = t.TRAVEL_ID
),
arrivals AS (
    SELECT
        v.TRAVEL_ID, v.VISIT_AREA_TYPE_CD, v.RESIDENCE_TIME_MIN, v.VISIT_ORDER,
        m.END_DT_MIN AS arrive_dt,
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt
    FROM tn_visit_area_info v
    JOIN tn_move_his m ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
    WHERE m.END_DT_MIN IS NOT NULL
      AND v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
),
gap_ratio AS (
    SELECT
        TRAVEL_ID,
        SUM((TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) - RESIDENCE_TIME_MIN) > 0) * 1.0 / COUNT(*) AS gap_ratio
    FROM arrivals
    WHERE next_arrive_dt IS NOT NULL
      AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
    GROUP BY TRAVEL_ID
)
SELECT
    g.revisit_group,
    COUNT(DISTINCT t.TRAVEL_ID) AS 표본_여행수,
    ROUND(AVG(tc.total_amt_won / tco.person_cnt), 0) AS 평균_인당소비,
    ROUND(AVG(DATEDIFF(t.TRAVEL_END_YMD, t.TRAVEL_START_YMD) + 1), 1) AS 평균_여행일수,
    ROUND(AVG(gr.gap_ratio), 3) AS 평균_틈비율
FROM grouped g
JOIN tn_travel t ON t.TRAVEL_ID = g.TRAVEL_ID
LEFT JOIN travel_total_consume tc ON tc.TRAVEL_ID = g.TRAVEL_ID
LEFT JOIN travel_companion tco ON tco.TRAVEL_ID = g.TRAVEL_ID
LEFT JOIN gap_ratio gr ON gr.TRAVEL_ID = g.TRAVEL_ID
GROUP BY g.revisit_group;

-- 동반유형 분포는 별도로 (그룹 x 동반유형 교차표)
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
),
grouped AS (
    SELECT
        TRAVEL_ID,
        CASE WHEN NTILE(2) OVER (ORDER BY revisit_score) = 1 THEN '낮음' ELSE '높음' END AS revisit_group
    FROM revisit
),
companion AS (
    SELECT t.TRAVEL_ID, COALESCE(cc.companion_cnt, 0) AS companion_cnt
    FROM tn_travel t
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = t.TRAVEL_ID
)
SELECT
    g.revisit_group,
    CASE
        WHEN c.companion_cnt = 0 THEN '나홀로'
        WHEN c.companion_cnt = 1 THEN '2인 동반'
        ELSE '3인 이상 동반'
    END AS 동반유형,
    COUNT(*) AS cnt
FROM grouped g
JOIN companion c ON c.TRAVEL_ID = g.TRAVEL_ID
GROUP BY g.revisit_group, 동반유형
ORDER BY g.revisit_group, cnt DESC;


-- ================================================================
-- STEP 5. 그룹별 방문지유형·활동·이동수단 성향 비교
-- ----------------------------------------------------------------
-- 낮은 집단과 높은 집단이 "어디를, 무엇을 하며, 어떻게 다녔는지" 비교.
-- 방문지유형은 21집/22친지집/23사무실/24숙소를 제외(의미 없는 유형).
-- ================================================================
WITH revisit AS (
    SELECT TRAVEL_ID, AVG(REVISIT_INTENTION) AS revisit_score
    FROM tn_visit_area_info
    WHERE REVISIT_INTENTION IS NOT NULL
    GROUP BY TRAVEL_ID
),
grouped AS (
    SELECT
        TRAVEL_ID,
        CASE WHEN NTILE(2) OVER (ORDER BY revisit_score) = 1 THEN '낮음' ELSE '높음' END AS revisit_group
    FROM revisit
)
SELECT
    g.revisit_group,
    cb.cd_nm AS 방문지유형,
    COUNT(*) AS cnt
FROM grouped g
JOIN tn_visit_area_info v ON v.TRAVEL_ID = g.TRAVEL_ID
LEFT JOIN tc_codeb cb ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD
WHERE v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
GROUP BY g.revisit_group, cb.cd_nm
ORDER BY g.revisit_group, cnt DESC;


-- ================================================================
-- STEP 6. 한계
-- ----------------------------------------------------------------
-- - REVISIT_INTENTION은 방문지 단위 자기보고 의향 점수(1~5)이며, 여행 단위로는
--   여러 방문지 점수의 평균으로 근사한 것 — 실제 재방문 행동과 다를 수 있음
-- - NTILE(2) 중앙값 분할은 "낮음/높음" 경계 근처 점수가 사실상 큰 차이가 없는데도
--   서로 다른 그룹으로 갈릴 수 있음 (STEP 2-2의 사분위 양끝 비교로 보완 가능)
-- - 표본은 2023년 수도권 자체 수집 데이터, 전국·타 연도 일반화 불가
-- - 세그먼트·여행패턴 차이는 상관관계 수준이며, "재방문 의향을 높이면 이런 특성이
--   생긴다"는 인과관계로 해석하면 안 됨(반대로 특성이 의향에 영향을 준 것일 수도,
--   둘 다 제3의 요인 때문일 수도 있음)
-- ================================================================
