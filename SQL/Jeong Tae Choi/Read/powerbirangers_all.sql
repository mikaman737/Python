/* 
    동반자수 검증, 
    나홀로 여행인 경우의 여행 목적이 어떻게 되는지?
*/ 

-- 전체 여행 2880건 중, 동반자수가 있는 여행 (2251건)
SELECT COUNT(DISTINCT tci.TRAVEL_ID)
FROM tn_companion_info AS tci;

-- 동반자 있는 여행 중, 모든 동반자에 대한 행수 (3977건)
SELECT COUNT(tci.TRAVEL_ID)
FROM tn_companion_info AS tci;

-- 여행자 테이블에서 동반자수를 더해 검증 (3977건)
SELECT SUM(TRAVEL_COMPANIONS_NUM)
    FROM tn_traveller_master AS ttm;

-- 여행자 테이블에서 나홀로 여행 수 검증 (692건)
SELECT TRAVEL_STATUS_ACCOMPANY, COUNT(TRAVEL_COMPANIONS_NUM)
    FROM tn_traveller_master
        WHERE TRAVEL_STATUS_ACCOMPANY = '나홀로 여행'
        GROUP BY TRAVEL_STATUS_ACCOMPANY;

-- 여행 목적지 별 개수 확인 
SELECT TRAVEL_STATUS_DESTINATION, COUNT(TRAVELER_ID)
    FROM tn_traveller_master
    GROUP BY TRAVEL_STATUS_DESTINATION



/* 
여행 목적지에 따른 여행현황_동반현황
-- 모든 지역 공통 -> 2인 여행(가족 외)의 비율이 가장 높음
-- 서울 -> 나홀로 여행 비율이 높음
-- 경기 -> 자녀 동반 여행 비율이 높음
-- 인천 -> 나홀로 여행 비율이 높음 
*/
SELECT
    TRAVEL_STATUS_ACCOMPANY,
    SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '서울' THEN 1 ELSE 0 END) AS 서울,
    SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '경기' THEN 1 ELSE 0 END) AS 경기,
    SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '인천' THEN 1 ELSE 0 END) AS 인천,
    COUNT(*) AS 전체
FROM tn_traveller_master
GROUP BY TRAVEL_STATUS_ACCOMPANY

WITH counts AS (
    SELECT
        TRAVEL_STATUS_ACCOMPANY,
        SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '서울' THEN 1 ELSE 0 END) AS 서울_건수,
        SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '경기' THEN 1 ELSE 0 END) AS 경기_건수,
        SUM(CASE WHEN TRAVEL_STATUS_DESTINATION = '인천' THEN 1 ELSE 0 END) AS 인천_건수,
        COUNT(*) AS 전체
    FROM tn_traveller_master
    GROUP BY TRAVEL_STATUS_ACCOMPANY
)
SELECT
    TRAVEL_STATUS_ACCOMPANY,
    ROUND(서울_건수 / SUM(서울_건수) OVER () * 100, 1) AS 서울_비율,
    ROUND(경기_건수 / SUM(경기_건수) OVER () * 100, 1) AS 경기_비율,
    ROUND(인천_건수 / SUM(인천_건수) OVER () * 100, 1) AS 인천_비율,
    전체
FROM counts;

/*
    전체 여행 2880건 중, 활동소비내역 2847건
    총 행수 13275건
*/
SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_activity_consume_his AS tach;

SELECT COUNT(TRAVEL_ID)
    FROM tn_activity_consume_his AS tach;

/*
    전체 여행 2880건 중, 활동내역 2880건
    총 행수 26805건
*/
SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_activity_his AS tah;

SELECT COUNT(TRAVEL_ID)
    FROM tn_activity_his AS tah;

/*
    전체 여행 2880건 중, 숙박소비내역이 있는 여행 2251건
    총 행수 7954건
*/

SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_lodge_consume_his AS tlch;

SELECT COUNT(TRAVEL_ID)
    FROM tn_lodge_consume_his AS tlch;


/*
    전체 여행 2880건 중, 이동내역이 있는 여행 2880건
    총 행수 24154건
*/

SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_move_his AS tmh;

SELECT COUNT(TRAVEL_ID)
    FROM tn_move_his AS tmh;
/*
    전체 여행 2880건 중, 이동수단소비내역이 있는 여행 2649건
    총 행수 4624건
*/

SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_mvmn_consume_his AS tmch;

SELECT COUNT(TRAVEL_ID)
    FROM tn_mvmn_consume_his AS tmch; 

/*
    전체 여행 2880건 중, 관광사진이 있는 여행 2880건
    총 행수 16469
*/

SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_tour_photo AS ttp;

SELECT COUNT(TRAVEL_ID)
    FROM tn_tour_photo AS ttp;

/*
    전체 2880건 중, 사전 소비가 있는 여행 619건
    총 행수 716건
*/


SELECT COUNT(DISTINCT TRAVEL_ID)
    FROM tn_adv_consume_his AS tach;

SELECT COUNT(TRAVEL_ID)
    FROM tn_adv_consume_his AS tach;

/*

    방문지 중에서 주 여행지를 어떻게 판단할 것인지?
    숙박지 기준으로 하게되면 당일치기 여행엔 적용이 안될 수 있음
    각 방문지를 추천할거면 최종적으로 POI_NM을 추천해야하나? -> POI에 서울역, 아파트명 같은 데이터가 있음
    그러면 근처 어디까지 추천할 것인지?
    방문지별 만족도, 체류시간, 추천의향, 재방문의향 및 여부를 종합해서 점수를 매겨
    최대한 가려는 핏에 맞는 방문지를 추천한다. 
    순위를 정하면 좋을 것 같음

    여행 재방문자에게는 -> 재방문의향이 높은 방문지를 추천
    여행 첫방문자에게는 -> 체류시간이 길고, 만족도가 높은 방문지를 추천
    
    목적
    여행지에서의 만족도를 높이기 위해서, 여행자에게 맞는 방문지를 추천한다.
    1. 전체 여행자들이 실제로 방문한 장소들 추천
    2. 카카오맵 장소검색(PlayMCP로 연결돼 있음)처럼 외부 POI 데이터를 더해서 후보 풀을 넓히는 방법
    타겟
    1. 재방문, 첫방문 구분
    2. 여행 목적에 따른 구분 (관광, 휴양, 레저, 체험, 문화, 역사 등)
    3. 여행자 유형 (나홀로, 가족, 친구, 연인 등)
    중요도 파악
    1. 거리
    2. 체류시간
    3. 추천의향
    4. 재방문의향
    확인 필요사항
    1. 현재 위치를 파악할 수가 없음 -> 실시간 데이터로 가정하고 분석할 것인지?
    2. 아니면 최근 방문한 방문지 정보를 파악하여 최근 방문지를 기준으로 추천할 것인지?
    3. 여행 목적에 따른 점수 설정이 필요한가?

    
*/

-- 전체 여행 2880건 중, 방문지가 있는 여행 2880건.
SELECT COUNT(DISTINCT tvai.TRAVEL_ID)
FROM tn_visit_area_info AS tvai;

-- 총 행수 24154건
SELECT COUNT(tvai.TRAVEL_ID)
FROM tn_visit_area_info AS tvai;




/*
    이동이력의 START_DT_MIN/END_DT_MIN은 
    이동 하나의 출발과 도착을 같이 기록하는 구조가 아니라, 테이블 자체가 방문지 1개당 1행이고
    대부분 방문지에 도착한 시각만 기록한다. 
    연속된 두 방문지의 도착시각(END_DT_MIN) 차이 자체를 그대로 "틈 후보"로 쓰는 것
    1→2번째 방문지는 START_DT_MIN 그대로 사용
    2→3번째 이후는 연속된 두 방문지의 도착시각(END_DT_MIN) 차이를 사용
*/

/*
    
*/

-- 전체 여행 2880건 중, 이동 이력이 있는 여행 2880건
SELECT COUNT(DISTINCT TRAVEL_ID)
FROM tn_move_his AS tmh;

-- 전체 행 수 24154건
SELECT COUNT(TRAVEL_ID)
FROM tn_move_his AS tmh;

-- 
SELECT *
FROM tn_visit_area_info AS tvai;













