-- 1-3순위. 소비의 이상치와 결측을 확인
-- 소비 후보 4개 테이블(활동/사전/숙박/이동수단)의 PAYMENT_AMT_WON을
-- 한 번에 놓고 결측·0원·최댓값을 비교합니다. 이상치 여부는 이 결과를 보고
-- 팀이 판단(예: 상위 0.1%를 이상치로 볼지)하는 것이지, 이 쿼리가 자동으로
-- 걸러내지는 않습니다.

SELECT '활동소비' AS 소비유형, COUNT(*) AS 전체행수,
       SUM(PAYMENT_AMT_WON IS NULL) AS 결측건수,
       SUM(PAYMENT_AMT_WON = 0)     AS 0원건수,
       MIN(PAYMENT_AMT_WON) AS 최소값, MAX(PAYMENT_AMT_WON) AS 최대값,
       ROUND(AVG(PAYMENT_AMT_WON), 0) AS 평균값, ROUND(STDDEV(PAYMENT_AMT_WON), 0) AS 표준편차
FROM tn_activity_consume_his
UNION ALL
SELECT '사전소비', COUNT(*), SUM(PAYMENT_AMT_WON IS NULL), SUM(PAYMENT_AMT_WON = 0),
       MIN(PAYMENT_AMT_WON), MAX(PAYMENT_AMT_WON),
       ROUND(AVG(PAYMENT_AMT_WON), 0), ROUND(STDDEV(PAYMENT_AMT_WON), 0)
FROM tn_adv_consume_his
UNION ALL
SELECT '숙박소비', COUNT(*), SUM(PAYMENT_AMT_WON IS NULL), SUM(PAYMENT_AMT_WON = 0),
       MIN(PAYMENT_AMT_WON), MAX(PAYMENT_AMT_WON),
       ROUND(AVG(PAYMENT_AMT_WON), 0), ROUND(STDDEV(PAYMENT_AMT_WON), 0)
FROM tn_lodge_consume_his
UNION ALL
SELECT '이동수단소비', COUNT(*), SUM(PAYMENT_AMT_WON IS NULL), SUM(PAYMENT_AMT_WON = 0),
       MIN(PAYMENT_AMT_WON), MAX(PAYMENT_AMT_WON),
       ROUND(AVG(PAYMENT_AMT_WON), 0), ROUND(STDDEV(PAYMENT_AMT_WON), 0)
FROM tn_mvmn_consume_his;

