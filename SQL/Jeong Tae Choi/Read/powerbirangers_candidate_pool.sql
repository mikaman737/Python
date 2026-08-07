-- ============================================================
-- "틈" 채우기 추천 후보 풀(candidate pool) 쿼리 — 내부 데이터만 사용
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ------------------------------------------------------------
-- 배경: 틈 시간에 추천할 "장소 리스트"가 필요함.
--   내부 데이터에서 후보 풀로 쓸 수 있는 건 tn_visit_area_info뿐이며,
--   이는 "실제 설문 응답자가 방문한 장소"의 로그이지 일반 POI DB가 아님
--   → 근처에 있지만 아무도 안 간 곳은 후보에 잡히지 않는다는 한계가 있음.
--
-- VISIT_AREA_TYPE_CD 코드 매핑(tc_codeb, cd_a='VIS') 확인 결과,
-- 아래 유형은 "틈 시간에 추천할 대상"이 될 수 없어 후보에서 제외한다.
--   21 집, 22 친구/친지집, 23 사무실, 24 숙소, 9 역/터미널/고속도로 휴게소
-- (숙소는 이미 예약된 곳이라 "빈 시간 채우기" 추천 대상이 아님)
--
-- 그룹핑 키: POI_ID는 전체로 보면 31% 결측이지만, 그 결측의 대부분(64%)이
--            지금 제외한 유형(집/지인집/사무실/숙소/역·터미널)에 몰려 있었다.
--            제외 유형을 뺀 후보 대상만 보면 POI_ID 결측률이 9.0%로 떨어져
--            (유형별 5.5~17.5%) 그룹핑 키로 쓸 만하다고 판단, POI_ID를 우선 사용.
--            POI_ID가 없는 9%는 VISIT_AREA_NM으로 대체(fallback)한다.
--            → 동명이지만 다른 곳(POI_ID 없는 동명 매장 등)이 섞일 수 있는 잔여
--              한계는 남아있음.
--
-- 지역 정보: SGG_CD는 75%가 결측이라(tc_sgg 조인 시 유명 관광지도 다 빠짐,
--            예: 에버랜드도 SGG_CD 공란) 사실상 못 쓴다.
--            대신 결측이 14%뿐인 ROAD_NM_ADDR(없으면 LOTNO_ADDR)을 지역 표시로 쓰고,
--            주소 첫 토큰(시도명)만 SUBSTRING_INDEX로 뽑아 참고용 컬럼을 추가한다.
--
-- 대표 유형(visit_area_type_nm): 같은 장소도 응답자마다 VISIT_AREA_TYPE_CD를
--            다르게 분류한 경우가 있어(예: 더 현대 서울 → 상업지구/문화시설 등 혼재),
--            단순 MIN()을 쓰면 최빈값이 아니라 알파벳상 먼저 오는 값이 뽑히는 오류가
--            생긴다. 그룹 내 최빈값(mode)을 골라야 대표 유형이 실제와 맞는다.
-- ============================================================

WITH base AS (
    SELECT
        v.*,
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS candidate_key,
        cb.cd_nm AS type_nm
    FROM tn_visit_area_info v
    LEFT JOIN tc_codeb cb
           ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD
    WHERE v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')  -- 역/터미널, 기타, 집/지인집/사무실/숙소 제외
),
type_mode AS (
    SELECT
        candidate_key,
        type_nm,
        ROW_NUMBER() OVER (
            PARTITION BY candidate_key
            ORDER BY COUNT(*) DESC, type_nm
        ) AS rn
    FROM base
    GROUP BY candidate_key, type_nm
)
SELECT
    b.candidate_key,
    MIN(b.VISIT_AREA_NM)                       AS sample_visit_area_nm,
    tm.type_nm                                 AS visit_area_type_nm,   -- 그룹 내 최빈 유형
    SUBSTRING_INDEX(
        MIN(COALESCE(NULLIF(b.ROAD_NM_ADDR, ''), NULLIF(b.LOTNO_ADDR, ''))),
        ' ', 1)                                AS sido_guess,           -- 주소 첫 토큰(참고용, 오탐 가능)
    MIN(COALESCE(NULLIF(b.ROAD_NM_ADDR, ''), NULLIF(b.LOTNO_ADDR, ''))) AS sample_addr,
    COUNT(*)                                   AS visit_cnt,            -- 표본 개수(방문 횟수)
    COUNT(DISTINCT b.TRAVEL_ID)                AS traveler_trip_cnt,    -- 서로 다른 여행 수
    ROUND(AVG(b.RESIDENCE_TIME_MIN), 1)        AS avg_residence_min,
    ROUND(AVG(b.DGSTFN), 2)                    AS avg_satisfaction,     -- 1~5점
    ROUND(AVG(b.REVISIT_INTENTION), 2)         AS avg_revisit_intention,
    ROUND(AVG(b.RCMDTN_INTENTION), 2)          AS avg_recommend_intention,
    MIN(b.X_COORD)                             AS sample_x_coord,       -- 참고용(결측 있음)
    MIN(b.Y_COORD)                             AS sample_y_coord
FROM base b
JOIN type_mode tm
  ON tm.candidate_key = b.candidate_key AND tm.rn = 1
GROUP BY b.candidate_key, tm.type_nm
HAVING COUNT(*) >= 2   -- 표본 1건짜리는 우연일 수 있어 최소 2회 이상 방문된 곳만
ORDER BY visit_cnt DESC, avg_satisfaction DESC;

-- ------------------------------------------------------------
-- 참고: 제외한 유형별 건수 확인용 (왜 빠졌는지 팀 공유용)
-- ------------------------------------------------------------
SELECT
    v.VISIT_AREA_TYPE_CD,
    cb.cd_nm,
    COUNT(*) AS cnt
FROM tn_visit_area_info v
LEFT JOIN tc_codeb cb
       ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD
WHERE v.VISIT_AREA_TYPE_CD IN ('9','12','21','22','23','24')
GROUP BY v.VISIT_AREA_TYPE_CD, cb.cd_nm
ORDER BY cnt DESC;