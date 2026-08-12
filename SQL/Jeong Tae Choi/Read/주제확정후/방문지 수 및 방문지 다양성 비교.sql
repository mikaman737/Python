-- 고가치 고객의 방문지 수 및 방문지 다양성 비교
-- 숙박소비포함여행

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
