-- 고가치 고객의 방문지 수 및 방문지 다양성 비교
-- 전체

WITH visit_count AS (
    SELECT tvai.TRAVEL_ID, COUNT(tvai.VISIT_AREA_ID) AS visit_area_count, COUNT(DISTINCT tvai.VISIT_AREA_TYPE_CD) AS visit_area_type_count
    FROM tn_visit_area_info tvai
    GROUP BY tvai.TRAVEL_ID
), payment_ltv AS (
    WITH activity_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS activity_amt
        FROM tn_activity_consume_his
        GROUP BY TRAVEL_ID
    ),
    adv_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS adv_amt
        FROM tn_adv_consume_his
        GROUP BY TRAVEL_ID
    ),
    lodge_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS lodge_amt
        FROM tn_lodge_consume_his
        GROUP BY TRAVEL_ID
    ),
    mvmn_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS mvmn_amt
        FROM tn_mvmn_consume_his
        GROUP BY TRAVEL_ID
    ),
    travel_summary AS (
        SELECT
            t.TRAVEL_ID                                                                            AS travel_id,
            COALESCE(a.activity_amt, 0)
                + COALESCE(adv.adv_amt, 0)
                + COALESCE(l.lodge_amt, 0)
                + COALESCE(m.mvmn_amt, 0)                                                          AS payment_total,
            tm.TRAVEL_COMPANIONS_NUM + 1                                                            AS travel_companion_num,
            DATEDIFF(t.TRAVEL_END_YMD, t.TRAVEL_START_YMD)                                          AS travel_term
        FROM tn_travel t
        JOIN tn_traveller_master tm ON t.TRAVELER_ID = tm.TRAVELER_ID
        LEFT JOIN activity_sum a   ON t.TRAVEL_ID = a.TRAVEL_ID
        LEFT JOIN adv_sum adv      ON t.TRAVEL_ID = adv.TRAVEL_ID
        LEFT JOIN lodge_sum l      ON t.TRAVEL_ID = l.TRAVEL_ID
        LEFT JOIN mvmn_sum m       ON t.TRAVEL_ID = m.TRAVEL_ID
    )
    SELECT
        travel_id,
        payment_total,
        travel_companion_num,
        payment_total / travel_companion_num                                                      AS payment_per_companion,
        travel_term,
        (payment_total / travel_companion_num) / travel_term                                       AS payment_per_companion_per_day
    FROM travel_summary
)
SELECT
    vc.TRAVEL_ID                    AS travel_id,
    vc.visit_area_count,
    pl.payment_per_companion_per_day,
    vc.visit_area_type_count
FROM visit_count vc
JOIN payment_ltv pl ON vc.TRAVEL_ID = pl.travel_id
ORDER BY vc.TRAVEL_ID;

-- 중가치 고객의 방문지 수 및 방문지 다양성 비교
-- 숙박소비불포함여행

WITH visit_count AS (
    SELECT tvai.TRAVEL_ID, COUNT(tvai.VISIT_AREA_ID) AS visit_area_count, COUNT(DISTINCT tvai.VISIT_AREA_TYPE_CD) AS visit_area_type_count
    FROM tn_visit_area_info tvai
    GROUP BY tvai.TRAVEL_ID
), payment_ltv AS (
    WITH activity_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS activity_amt
        FROM tn_activity_consume_his
        GROUP BY TRAVEL_ID
    ),
    adv_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS adv_amt
        FROM tn_adv_consume_his
        GROUP BY TRAVEL_ID
    ),
    mvmn_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS mvmn_amt
        FROM tn_mvmn_consume_his
        GROUP BY TRAVEL_ID
    ),
    travel_summary AS (
        SELECT
            t.TRAVEL_ID                                                                            AS travel_id,
            COALESCE(a.activity_amt, 0)
                + COALESCE(adv.adv_amt, 0)
                + COALESCE(m.mvmn_amt, 0)                                                          AS payment_total,
            tm.TRAVEL_COMPANIONS_NUM + 1                                                            AS travel_companion_num,
            DATEDIFF(t.TRAVEL_END_YMD, t.TRAVEL_START_YMD)                                          AS travel_term
        FROM tn_travel t
        JOIN tn_traveller_master tm ON t.TRAVELER_ID = tm.TRAVELER_ID
        LEFT JOIN activity_sum a   ON t.TRAVEL_ID = a.TRAVEL_ID
        LEFT JOIN adv_sum adv      ON t.TRAVEL_ID = adv.TRAVEL_ID
        LEFT JOIN mvmn_sum m       ON t.TRAVEL_ID = m.TRAVEL_ID
        WHERE NOT EXISTS (
            SELECT 1 FROM tn_lodge_consume_his lc WHERE lc.TRAVEL_ID = t.TRAVEL_ID
        )
    )
    SELECT
        travel_id,
        payment_total,
        travel_companion_num,
        payment_total / travel_companion_num                                                      AS payment_per_companion,
        travel_term,
        (payment_total / travel_companion_num) / travel_term                                       AS payment_per_companion_per_day
    FROM travel_summary
)
SELECT
    vc.TRAVEL_ID                    AS travel_id,
    vc.visit_area_count,
    pl.payment_per_companion_per_day,
    vc.visit_area_type_count
FROM visit_count vc
JOIN payment_ltv pl ON vc.TRAVEL_ID = pl.travel_id
ORDER BY vc.TRAVEL_ID;

-- 고가치 고객의 방문지 수 및 방문지 다양성 비교
-- 숙박소비기록 있는 여행만

WITH visit_count AS (
    SELECT tvai.TRAVEL_ID, COUNT(tvai.VISIT_AREA_ID) AS visit_area_count, COUNT(DISTINCT tvai.VISIT_AREA_TYPE_CD) AS visit_area_type_count
    FROM tn_visit_area_info tvai
    GROUP BY tvai.TRAVEL_ID
), payment_ltv AS (
    WITH activity_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS activity_amt
        FROM tn_activity_consume_his
        GROUP BY TRAVEL_ID
    ),
    adv_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS adv_amt
        FROM tn_adv_consume_his
        GROUP BY TRAVEL_ID
    ),
    lodge_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS lodge_amt
        FROM tn_lodge_consume_his
        GROUP BY TRAVEL_ID
    ),
    mvmn_sum AS (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS mvmn_amt
        FROM tn_mvmn_consume_his
        GROUP BY TRAVEL_ID
    ),
    travel_summary AS (
        SELECT
            t.TRAVEL_ID                                                                            AS travel_id,
            COALESCE(a.activity_amt, 0)
                + COALESCE(adv.adv_amt, 0)
                + COALESCE(l.lodge_amt, 0)
                + COALESCE(m.mvmn_amt, 0)                                                          AS payment_total,
            tm.TRAVEL_COMPANIONS_NUM + 1                                                            AS travel_companion_num,
            DATEDIFF(t.TRAVEL_END_YMD, t.TRAVEL_START_YMD)                                          AS travel_term
        FROM tn_travel t
        JOIN tn_traveller_master tm ON t.TRAVELER_ID = tm.TRAVELER_ID
        LEFT JOIN activity_sum a   ON t.TRAVEL_ID = a.TRAVEL_ID
        LEFT JOIN adv_sum adv      ON t.TRAVEL_ID = adv.TRAVEL_ID
        LEFT JOIN lodge_sum l      ON t.TRAVEL_ID = l.TRAVEL_ID
        LEFT JOIN mvmn_sum m       ON t.TRAVEL_ID = m.TRAVEL_ID
        WHERE EXISTS (
            SELECT 1 FROM tn_lodge_consume_his lc WHERE lc.TRAVEL_ID = t.TRAVEL_ID
        )
    )
    SELECT
        travel_id,
        payment_total,
        travel_companion_num,
        payment_total / travel_companion_num                                                      AS payment_per_companion,
        travel_term,
        (payment_total / travel_companion_num) / travel_term                                       AS payment_per_companion_per_day
    FROM travel_summary
)
SELECT
    vc.TRAVEL_ID                    AS travel_id,
    vc.visit_area_count,
    pl.payment_per_companion_per_day,
    vc.visit_area_type_count
FROM visit_count vc
JOIN payment_ltv pl ON vc.TRAVEL_ID = pl.travel_id
ORDER BY vc.TRAVEL_ID;

/*
핵심 발견 3개
숙박소비가 있는 여행은 숙박소비가 없는 여행보다 방문지 수(7.2→11.6개)와 유형 다양성(4.3→6.2개)이 모두 높다. 
여행기간이 평균 1.1일→2.2일로 늘어난 만큼 물리적으로 더 많은 곳을 방문할 시간이 확보된 것과 함께 나타나는 패턴이다. 
반대 해석: 방문지가 많아서 숙박이 필요해진 것일 수도, 원래 여행 목적(다지역 탐방)이 두 변수를 동시에 밀어올린 것일 수도 있어 인과관계는 이 데이터만으로 판단 불가.
여행기간 분포가 뚜렷하게 갈린다 — 숙박소비 없음 그룹은 89.7%가 당일치기(1일), 숙박소비 있음 그룹은 77.8%가 1박(2일)에 몰려 있다. 두 그룹이 사실상 "당일치기"와 "1박 2일" 두 개의 서로 다른 여행 유형에 대응한다고 볼 수 있다.
반대 해석: 여행 계획 시점에 숙박 예약 여부가 먼저 정해지고 그에 따라 일정이 맞춰졌을 가능성도 있어, 기간이 숙박을 결정했다고 단정할 수 없다.
1인당·1일 기준으로도 숙박소비 있음 그룹의 소비액이 더 높다(중앙값 47,700원→75,800원, 약 1.6배). 
숙박비를 지출에 포함했음에도 일 단위로 정규화한 값이 여전히 높다는 것은, 숙박이 있는 여행이 활동/이동/사전예약 지출도 함께 늘어나는 "고관여 여행"일 가능성을 시사한다. 
반대 해석: 숙박비 자체가 1일 소비액을 밀어올리는 주된 요인일 수 있어(고정비 성격), 
숙박비를 제외한 나머지 항목만 다시 비교해봐야 이 해석이 유지되는지 확인 필요.

한계
표본은 2023년 수도권 여행로그 데이터 2,880건(당해 1개 연도, 1개 권역)에 한정되며, 다른 연도·지역으로 일반화할 수 없다.
payment_total이 0원인 이상치 1건이 확인되어(e_e011466) 별도 검증이 필요하고, 결측 소비내역은 모두 0으로 대체(COALESCE)한 전처리를 거쳤다.
*/