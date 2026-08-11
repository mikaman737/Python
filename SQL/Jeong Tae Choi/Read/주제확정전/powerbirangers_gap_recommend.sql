-- ============================================================
-- "틈" 시간 + 근처 방문지 후보 — 데이터 추출용 쿼리 (거리 매칭은 파이썬에서)
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ------------------------------------------------------------
-- 주의: 틈(약 15,000건) × 후보 풀(약 1,600건) 전체를 SQL에서 Haversine으로
--       직접 교차 계산하면 좌표에 인덱스가 없어 무료 티어 서버 임시 디스크가
--       부족해 실패한다(실제로 "No space left on device" 에러 발생, bounding box로
--       사전 필터링해도 동일하게 실패). 그래서 이 파일은 아래 두 결과셋만 뽑고,
--       거리 계산·매칭·랭킹은 python/gap_recommend_match.py에서 pandas/numpy로 처리한다.
-- ============================================================

-- ------------------------------------------------------------
-- 1) 틈(gap) 목록: 연속된 두 방문지 도착시각(END_DT_MIN) 차이를
--    "빈 시간의 근사치(상한값)"로 사용. 좌표 있는 것만.
-- ------------------------------------------------------------
WITH arrivals AS (
    SELECT
        v.TRAVEL_ID,                                                     -- 여행 식별자(복합키의 절반) — VISIT_AREA_ID와 함께일 때만 의미 있음
        v.VISIT_AREA_ID,                                                  -- 방문지 식별자(복합키의 나머지 절반), tn_move_his.TRIP_ID와 동일값
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS gap_candidate_key,  -- 이 틈이 발생한 자리 자체를 가리키는 키. candidate_pool의 candidate_key와 같은 규칙(POI_ID 우선, 없으면 이름)으로 만들어서, 나중에 "틈이 난 그 장소 자체를 추천에서 빼는" 매칭에 씀
        v.VISIT_AREA_NM AS gap_location_nm,                               -- 틈이 발생한 방문지 이름(사람이 읽을 표시용)
        v.X_COORD AS gap_x,                                               -- 틈 발생 위치의 경도 — 후보 풀과의 거리 계산 기준점
        v.Y_COORD AS gap_y,                                               -- 틈 발생 위치의 위도 — 후보 풀과의 거리 계산 기준점
        v.VISIT_ORDER,                                                    -- 하루/여행 내 방문 순서. END_DT_MIN이 도착시각만 있어서 이 순서로 다음 도착시각을 이어붙임(LEAD의 기준)
        m.END_DT_MIN AS arrive_dt,                                        -- 이 방문지에 도착한 시각(tn_move_his, 실측값). 틈의 시작점
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt  -- 같은 여행에서 바로 다음 방문지의 도착시각. 틈의 끝점(근사치 — 실제로는 활동시간+이동시간까지 포함된 상한값)
    FROM tn_visit_area_info v
    JOIN tn_move_his m
      ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
    WHERE m.END_DT_MIN IS NOT NULL
)
SELECT
    TRAVEL_ID,
    VISIT_AREA_ID,
    gap_candidate_key,
    gap_location_nm,
    gap_x,
    gap_y,
    arrive_dt,
    next_arrive_dt,
    TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) AS gap_minutes        -- 틈의 길이(분) = 다음 도착시각 − 이 도착시각. 이 값보다 체류시간이 짧은 후보만 추천에 쓸 수 있음
FROM arrivals
WHERE next_arrive_dt IS NOT NULL           -- 그 여행의 마지막 방문지는 다음 도착시각이 없어 틈을 계산할 수 없으므로 제외
  AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0  -- 음수/0분짜리는 시각 역전 등 데이터 이상치이므로 제외
  AND gap_x IS NOT NULL AND gap_y IS NOT NULL;               -- 좌표 없는 곳은 거리 계산이 불가능하므로 제외

-- ------------------------------------------------------------
-- 2) 추천 후보 풀: powerbirangers_candidate_pool.sql과 동일 로직
--    (POI_ID 우선 그룹핑, 집/지인집/사무실/숙소/역·터미널 제외, 유형은 최빈값,
--     좌표 있는 것만)
-- ------------------------------------------------------------
-- 주의: 이 쿼리는 특정 여행자/여행(TRAVEL_ID)을 전혀 구분하지 않는다.
--       "여행자별 추천"이 아니라, 전체 방문 기록을 장소 단위로 모아
--       "추천에 쓸 수 있는 후보 장소 목록(풀)" 하나를 만드는 것뿐이다.
--       여행자별/틈별 추천은 이 결과를 python/gap_recommend_match.py에서
--       각 틈의 좌표·시간과 거리 매칭해야 나온다.
WITH base AS (
    SELECT
        v.*,                                                              -- tn_visit_area_info의 모든 원본 컬럼(TRAVEL_ID, VISIT_AREA_ID, 좌표, 만족도 등)을 그대로 가져옴
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS candidate_key,  -- 후보 장소를 구분하는 키. POI_ID가 있으면 그걸 쓰고(정확), 없으면(9% 결측) 이름으로 대체(동명이지만 다른 곳이 섞일 수 있는 한계 있음)
        cb.cd_nm AS type_nm                                                -- VISIT_AREA_TYPE_CD를 사람이 읽을 수 있는 유형명으로 변환(예: '11'→'식당/카페')
    FROM tn_visit_area_info v
    LEFT JOIN tc_codeb cb
           ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD           -- tc_codeb의 'VIS'(방문지유형코드) 그룹에서 코드→이름 매핑
    WHERE v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')       -- 역/터미널, 기타, 집/지인집/사무실/숙소는 추천 대상이 될 수 없어 제외
),
type_mode AS (
    -- 같은 장소(candidate_key)라도 응답자마다 VISIT_AREA_TYPE_CD를 다르게
    -- 분류한 경우가 있어서, 대표 유형은 최빈값(mode)으로 뽑는다.
    -- (단순 MIN(cd_nm)을 쓰면 최빈값이 아니라 알파벳순으로 먼저 오는 값이 잘못 뽑힘 — 실제로 겪은 오류)
    SELECT
        candidate_key,
        type_nm,
        ROW_NUMBER() OVER (
            PARTITION BY candidate_key
            ORDER BY COUNT(*) DESC, type_nm    -- 이 장소에서 이 유형으로 분류된 횟수가 많은 순 → 동률이면 이름순(재현성 확보용)
        ) AS rn                                -- rn=1이 그 장소의 최빈 유형
    FROM base
    GROUP BY candidate_key, type_nm
)
SELECT
    b.candidate_key,                                    -- 장소 식별자(그룹핑 기준)
    MIN(b.VISIT_AREA_NM)                       AS visit_area_nm,          -- 대표 장소명(그룹 내 아무 값이나 하나, 보통 다 동일)
    tm.type_nm                                  AS visit_area_type_nm,    -- 최빈 유형명(위 type_mode에서 rn=1로 뽑은 것)
    COUNT(*)                                    AS visit_cnt,             -- 이 장소가 전체 데이터에서 방문된 총 횟수(표본 크기)
    ROUND(AVG(b.RESIDENCE_TIME_MIN), 1)         AS avg_residence_min,     -- 평균 체류시간(분) — 틈 시간과 비교해 "이 틈 안에 들어가는지" 판단하는 기준값
    ROUND(AVG(b.DGSTFN), 2)                     AS avg_satisfaction,      -- 평균 전반적 만족도(1~5점)
    ROUND(AVG(b.REVISIT_INTENTION), 2)          AS avg_revisit_intention, -- 평균 재방문 의향(1~5점)
    ROUND(AVG(b.RCMDTN_INTENTION), 2)           AS avg_recommend_intention, -- 평균 추천 의향(1~5점)
    MIN(b.X_COORD)                              AS x_coord,               -- 대표 경도(거리 계산용)
    MIN(b.Y_COORD)                              AS y_coord                -- 대표 위도(거리 계산용)
FROM base b
JOIN type_mode tm
  ON tm.candidate_key = b.candidate_key AND tm.rn = 1     -- 장소별 최빈 유형 한 줄만 붙임(1:1 매칭)
GROUP BY b.candidate_key, tm.type_nm
HAVING COUNT(*) >= 2                                      -- 표본 1건짜리는 우연일 수 있어 최소 2회 이상 방문된 곳만 후보로 인정
   AND MIN(b.X_COORD) IS NOT NULL AND MIN(b.Y_COORD) IS NOT NULL;  -- 좌표 없으면 거리 계산이 불가능하므로 후보에서 제외