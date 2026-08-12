-- 여행별 총 소비내역(활동+사전+숙박+이동) 합산 조회
-- Join Key: 1) TRAVEL_ID (소비내역 4종 → tn_travel)  2) TRAVELER_ID (tn_travel → tn_traveller_master)
-- 주의: 4개 소비내역 테이블은 TRAVEL_ID당 여러 행이 존재하므로,
--       바로 JOIN하여 SUM하면 fan-out으로 중복 합산이 발생함 -> TRAVEL_ID 단위로 먼저 각각 집계 후 LEFT JOIN으로 결합

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
)
SELECT
    t.TRAVEL_ID                                                                            AS travel_id,
    COALESCE(a.activity_amt, 0)
        + COALESCE(adv.adv_amt, 0)
        + COALESCE(l.lodge_amt, 0)
        + COALESCE(m.mvmn_amt, 0)                                                          AS payment_total,
    tm.TRAVEL_COMPANIONS_NUM + 1                                                            AS travel_companion_num,
    tm.TRAVEL_TERM                                                                          AS travel_term
FROM tn_travel t
JOIN tn_traveller_master tm ON t.TRAVELER_ID = tm.TRAVELER_ID
LEFT JOIN activity_sum a   ON t.TRAVEL_ID = a.TRAVEL_ID
LEFT JOIN adv_sum adv      ON t.TRAVEL_ID = adv.TRAVEL_ID
LEFT JOIN lodge_sum l      ON t.TRAVEL_ID = l.TRAVEL_ID
LEFT JOIN mvmn_sum m       ON t.TRAVEL_ID = m.TRAVEL_ID
ORDER BY t.TRAVEL_ID;
