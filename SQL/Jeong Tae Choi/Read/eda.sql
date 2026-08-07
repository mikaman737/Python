
/*
    1. 여행의 기준
        "여행"은 GPS로 자동 판별된 게 아니라 응답자가 앱에서 스스로 선언·기록한 단위입니다. 
        STA(여행상태) 코드가 최초 로그인 → 예정여행지변경신청/승인 → 여행 중 → 여행 후(기록전) → 
        여행 기록 입력 중/완료 → 보완 요청/완료로 이어지는 걸 보면, 
        이건 응답자가 앱에 직접 로그인해서 "지금부터 여행 시작"이라고 스스로 신고하고, 
        사진을 올려 방문지를 인증(MET 코드: 사진업로드 전/승인 진행중/승인완료/승인거절)받는 
        자기기록형 다이어리 조사 구조입니다. TRAVEL_ID는 이 자기신고 단위 하나하나입니다.
    2. 데이터 기록 날짜
       2023-04-28 ~ 2023-09-17
    3. 집, 지하철역, 사무실 등 방문지유형을 제외해야할지?
*/

-- 방문지와 이동내역을 확인하여 틈(유휴시간)이 발생하는지 확인
SELECT tvai.TRAVEL_ID, tvai.VISIT_ORDER, tvai.VISIT_AREA_NM, tmh.START_DT_MIN, tmh.END_DT_MIN, tvai.RESIDENCE_TIME_MIN
FROM tn_visit_area_info tvai
LEFT JOIN tn_move_his tmh
ON tvai.VISIT_AREA_ID = tmh.TRIP_ID
AND tvai.TRAVEL_ID = tmh.TRAVEL_ID;

-- 전체 사람들의 소비 특성 이해
-- 이동 수단에 쓴 총 비용 91,485,299원
SELECT SUM(PAYMENT_AMT_WON)
FROM tn_mvmn_consume_his tmch;
-- 한 여행에서 쓴 이동 수단 평균 비용 18425원
-- 한 여행에서 쓴 이동 수단 최대 비용 368400원
-- 한 여행에서 쓴 이동 수단 최소 비용 200원
SELECT AVG(subquery.avg_payment_amt_won) AS avg_payment_amt_won
FROM (
    SELECT TRAVEL_ID, ROUND(AVG(PAYMENT_AMT_WON)) AS avg_payment_amt_won
    FROM tn_mvmn_consume_his tmch
    GROUP BY TRAVEL_ID
    ORDER BY avg_payment_amt_won DESC
) AS subquery;

-- 이동수단 소비
WITH move_sum AS (
    SELECT TRAVEL_ID, ROUND(SUM(PAYMENT_AMT_WON)) AS sum_payment_amt_won
    FROM tn_mvmn_consume_his tmch
    GROUP BY TRAVEL_ID
    ORDER BY sum_payment_amt_won DESC
),
move_avg AS (
    SELECT TRAVEL_ID, ROUND(AVG(PAYMENT_AMT_WON)) AS avg_payment_amt_won
    FROM tn_mvmn_consume_his tmch
    GROUP BY TRAVEL_ID
    ORDER BY avg_payment_amt_won DESC
), move_cnt AS(
    SELECT TRAVEL_ID, COUNT(*) AS cnt_payment_amt_won
    FROM tn_mvmn_consume_his tmch
    GROUP BY TRAVEL_ID
    ORDER BY cnt_payment_amt_won DESC
)SELECT ms.TRAVEL_ID, mc.cnt_payment_amt_won AS 이동수단건수, ms.sum_payment_amt_won AS 이동수단합계, ma.avg_payment_amt_won AS 이동수단평균
FROM move_sum ms
JOIN move_avg ma ON ms.TRAVEL_ID = ma.TRAVEL_ID
JOIN move_cnt mc ON ms.TRAVEL_ID = mc.TRAVEL_ID
;

-- 활동소비









