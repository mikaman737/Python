-- ================================================================
-- [튜토리얼] "틈(빈 시간)" 채우기 추천 로직 — SQL 초보용 단계별 설명
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ----------------------------------------------------------------
-- 이 파일은 완성된 로직을 한 번에 보여주지 않고, 작은 단계로 쪼개서
-- "왜 이렇게 짰는지"를 순서대로 설명합니다. 각 STEP은 그 자체로 실행 가능한
-- SELECT문이니, 위에서부터 하나씩 실행하면서 결과를 눈으로 확인하며 따라오면 됩니다.
--
-- 실제로 서비스/분석에 쓰는 "완성본"은 이 두 파일입니다.
--   - powerbirangers_gap_recommend.sql   (틈 목록 + 후보 풀, SQL)
--   - python/gap_recommend_match.py      (거리 계산·최종 매칭, Python)
-- 이 튜토리얼 파일은 그 완성본이 왜 그런 모양이 됐는지 이해하기 위한 학습용입니다.
--
-- 전체 그림 (목차)
--   STEP 0. 우리가 풀려는 문제
--   STEP 1. 원본 시간 데이터의 함정 확인
--   STEP 2. "틈(gap)" 목록 만들기        (2-1 → 2-2 → 2-3)
--   STEP 3. "추천 후보 풀" 만들기         (3-1 → 3-2 → 3-3 → 3-4)
--   STEP 4. 왜 마지막 거리 매칭은 SQL이 아니라 Python에서 하는가
-- ================================================================


-- ================================================================
-- STEP 0. 우리가 풀려는 문제
-- ----------------------------------------------------------------
-- "여행 일정 중 비어있는 시간(틈)에 근처 장소를 추천해주자"는 서비스 아이디어를
-- 검증하려면 최소한 이 두 가지가 필요합니다.
--   ① 틈: 언제, 어디서, 몇 분이나 비었는가
--   ② 후보: 그 틈에 채워 넣을 만한 "추천할 만한 장소" 목록
-- 이 둘을 각각 SQL로 만든 뒤, 위치(좌표)와 시간(체류시간)으로 짝을 지어주면 됩니다.
-- 실행할 SELECT문은 없고, 아래 STEP부터 실제 쿼리가 시작됩니다.
-- ================================================================


-- ================================================================
-- STEP 1. 원본 시간 데이터의 함정 확인
-- ----------------------------------------------------------------
-- "틈"을 계산하려면 각 방문지에 도착한 시각과 떠난 시각을 알아야 합니다.
-- 이동 기록 테이블 tn_move_his에 START_DT_MIN(출발시각), END_DT_MIN(도착시각)
-- 컬럼이 있어서 "이 둘을 빼면 되겠다"고 생각하기 쉬운데, 실제로 확인해보면
-- 그렇게 단순하지 않습니다. 먼저 그 함정을 직접 눈으로 확인합니다.
-- ================================================================

-- STEP 1-1. 두 컬럼이 "한 행"에 동시에 채워져 있는 경우가 있는지 확인
SELECT
    COUNT(*) AS 전체_행수,
    SUM(CASE WHEN START_DT_MIN IS NOT NULL AND END_DT_MIN IS NULL     THEN 1 ELSE 0 END) AS 출발시각만_있음,
    SUM(CASE WHEN START_DT_MIN IS NULL     AND END_DT_MIN IS NOT NULL THEN 1 ELSE 0 END) AS 도착시각만_있음,
    SUM(CASE WHEN START_DT_MIN IS NOT NULL AND END_DT_MIN IS NOT NULL THEN 1 ELSE 0 END) AS 둘다_있음
FROM tn_move_his;
-- 실행해보면 "둘다_있음"이 0으로 나옵니다.
-- 즉 tn_move_his는 "이동 하나의 출발~도착을 한 행에 같이 기록"하는 구조가 아니라,
-- 한 행에 둘 중 하나만 채워지는 구조입니다. (전체 24,154행 중 출발시각만 있는 행 2,883개,
-- 도착시각만 있는 행 21,271개)

-- STEP 1-2. 그럼 어떤 규칙으로 둘 중 하나만 기록되는지, 여행 1건을 예시로 확인
SELECT
    v.VISIT_ORDER,     -- 이 여행에서 몇 번째로 방문한 곳인지 (1, 2, 3, ...)
    v.VISIT_AREA_NM,   -- 방문지 이름
    m.START_DT_MIN,    -- 출발시각 (대부분 비어있을 것)
    m.END_DT_MIN       -- 도착시각 (대부분 여기에 값이 있을 것)
FROM tn_visit_area_info v
JOIN tn_move_his m
  ON m.TRAVEL_ID = v.TRAVEL_ID       -- 여행 식별자로 연결
 AND m.TRIP_ID   = v.VISIT_AREA_ID   -- tn_move_his의 TRIP_ID는 tn_visit_area_info의 VISIT_AREA_ID와 같은 값
WHERE v.TRAVEL_ID = 'e_e000004'      -- 예시로 여행 1건만 골라서 봄
ORDER BY v.VISIT_ORDER;
-- 결과 패턴:
--   VISIT_ORDER=1(맨 처음 방문지)      → START_DT_MIN에만 값 있음 ("여기서 출발했다")
--   VISIT_ORDER=2 이후(그 다음부터)     → END_DT_MIN에만 값 있음   ("여기 도착했다")
-- 즉 이 테이블은 "각 방문지에 도착한 시각"을 기록한 것에 가깝고, 예외적으로 맨
-- 처음 방문지 하나만 "출발시각"이 대신 기록돼 있습니다.
--
-- 결론: "틈"을 계산할 때 믿고 쓸 수 있는 값은 END_DT_MIN(도착시각) 뿐입니다.
-- 연속된 두 방문지의 도착시각 차이를 틈으로 보되, 그 안에는 실제 활동시간+이동시간도
-- 섞여 있다는 걸 감안해야 합니다(그래서 "근사치/상한값"이라고 부릅니다).


-- ================================================================
-- STEP 2. "틈(gap)" 목록 만들기
-- ----------------------------------------------------------------
-- 목표: 각 여행에서, 연속된 두 방문지의 도착시각 차이를 구해서 "틈"으로 삼는다.
-- 세 단계로 나눠서 만듭니다. (2-1: 도착시각 붙이기 → 2-2: 다음 도착시각 가져오기
-- → 2-3: 틈 시간 계산 + 이상치 제거)
-- ================================================================

-- STEP 2-1. 방문지마다 "도착시각"을 붙인다 (아직 틈 계산은 안 함)
-- tn_visit_area_info(방문지 정보)와 tn_move_his(이동 기록, 도착시각이 들어있음)를
-- TRAVEL_ID + VISIT_AREA_ID(=TRIP_ID)로 조인한다. (복합키 조인 — CLAUDE.md 규칙)
SELECT
    v.TRAVEL_ID,
    v.VISIT_AREA_ID,
    v.VISIT_ORDER,
    v.VISIT_AREA_NM,
    m.END_DT_MIN AS arrive_dt   -- 이 방문지에 도착한 시각
FROM tn_visit_area_info v
JOIN tn_move_his m
  ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
WHERE m.END_DT_MIN IS NOT NULL   -- 도착시각이 있는 행만 (VISIT_ORDER=1은 여기서 자연스럽게 빠짐)
  AND v.TRAVEL_ID = 'e_e000004'  -- 예시 여행 1건만 (실제로는 이 조건 없이 전체 실행)
ORDER BY v.VISIT_ORDER;
-- 결과: 방문 순서대로 "도착시각"이 한 줄씩 나옵니다.
-- 아직은 "틈"이 아니라 그냥 "몇 번째 방문지에 몇 시에 도착했다"는 목록일 뿐입니다.

-- STEP 2-2. 방문 순서대로 "다음 방문지의 도착시각"을 같은 줄에 가져다 붙인다
-- 여기서 쓰는 LEAD()가 "윈도우 함수"입니다. 한 줄 한 줄을 각각 계산하는 게 아니라,
-- "같은 TRAVEL_ID 안에서, VISIT_ORDER 순서로 정렬했을 때 바로 다음 줄의 값"을
-- 지금 이 줄에 가져다 붙여줍니다. (PARTITION BY = 여행 단위로 끊어서 계산,
-- ORDER BY = 그 안에서 방문 순서대로 정렬)
SELECT
    v.TRAVEL_ID,
    v.VISIT_ORDER,
    v.VISIT_AREA_NM,
    m.END_DT_MIN AS arrive_dt,
    LEAD(m.END_DT_MIN) OVER (
        PARTITION BY v.TRAVEL_ID   -- 여행별로 따로 계산
        ORDER BY v.VISIT_ORDER     -- 방문 순서 기준으로 "다음"을 판단
    ) AS next_arrive_dt            -- 바로 다음 방문지의 도착시각
FROM tn_visit_area_info v
JOIN tn_move_his m
  ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
WHERE m.END_DT_MIN IS NOT NULL
  AND v.TRAVEL_ID = 'e_e000004'
ORDER BY v.VISIT_ORDER;
-- 결과: 각 줄에 "이번 도착시각"과 "다음 도착시각"이 나란히 붙습니다.
-- 이 둘의 차이가 곧 "이번 방문지에서 다음 이동을 시작하기 전까지 쓸 수 있는 시간"이고,
-- 그 안에 활동시간+이동시간+진짜 빈 시간이 섞여 있습니다.
-- 맨 마지막 방문지는 "다음"이 없어서 next_arrive_dt가 NULL로 나옵니다(정상).

-- STEP 2-3. 틈 시간을 계산하고, 말이 안 되는 값(이상치)을 걸러낸다
-- TIMESTAMPDIFF(MINUTE, A, B)는 "A부터 B까지 몇 분 차이인지"를 구하는 함수입니다.
WITH arrivals AS (
    SELECT
        v.TRAVEL_ID,
        v.VISIT_AREA_ID,
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS gap_candidate_key,
        v.VISIT_AREA_NM AS gap_location_nm,
        v.X_COORD AS gap_x,   -- 이 방문지의 경도 (나중에 거리 계산용)
        v.Y_COORD AS gap_y,   -- 이 방문지의 위도 (나중에 거리 계산용)
        v.VISIT_ORDER,
        m.END_DT_MIN AS arrive_dt,
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt
    FROM tn_visit_area_info v
    JOIN tn_move_his m
      ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
    WHERE m.END_DT_MIN IS NOT NULL
)
SELECT
    TRAVEL_ID,
    VISIT_AREA_ID,
    gap_candidate_key,   -- 이 틈이 발생한 자리 자체를 가리키는 값 (나중에 "그 자리 자체는 추천 제외"할 때 씀)
    gap_location_nm,
    gap_x,
    gap_y,
    arrive_dt,
    next_arrive_dt,
    TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) AS gap_minutes   -- 틈의 길이(분)
FROM arrivals
WHERE next_arrive_dt IS NOT NULL                                  -- 마지막 방문지(다음이 없음)는 틈을 계산할 수 없으니 제외
  AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0         -- 0분 이하(시각이 거꾸로 되어있는 등 이상치)는 제외
  AND gap_x IS NOT NULL AND gap_y IS NOT NULL                      -- 좌표가 없으면 나중에 거리 계산이 불가능하므로 제외
ORDER BY TRAVEL_ID, arrive_dt;
-- 이게 바로 "틈 목록"입니다. gap_minutes가 클수록 더 많이 비어있었다는 뜻입니다.
-- (전체로 실행하면 약 14,940건이 나옵니다 — WHERE TRAVEL_ID = ... 조건을 빼고 실행해보세요.)


-- ================================================================
-- STEP 3. "추천 후보 풀" 만들기
-- ----------------------------------------------------------------
-- 목표: 틈에 채워 넣을 만한 "장소 목록"을 만든다. 재료는 tn_visit_area_info
-- (모든 여행자가 실제로 방문했던 기록) 하나뿐입니다. 네 단계로 나눠서 만듭니다.
-- ================================================================

-- STEP 3-1. 추천 후보에서 아예 제외해야 하는 유형부터 정한다
-- VISIT_AREA_TYPE_CD는 코드값이라 그 자체로는 무슨 뜻인지 알 수 없습니다.
-- tc_codeb(코드B) 테이블에서 cd_a='VIS'(방문지유형코드) 그룹을 보면 이름을 알 수 있습니다.
SELECT cd_b AS 코드값, cd_nm AS 유형명
FROM tc_codeb
WHERE cd_a = 'VIS'
ORDER BY cd_b;
-- 결과를 보면 21(집), 22(친구/친지집), 23(사무실), 24(숙소), 9(역/터미널/휴게소) 같은
-- 유형이 섞여 있습니다. 이런 곳은 "틈 시간에 추천할 장소"가 될 수 없으므로
-- (남의 집이나 사무실을 추천할 순 없으니까) 후보 풀을 만들 때 아예 제외해야 합니다.

-- STEP 3-2. 장소를 어떤 기준으로 묶어야 할지 확인 (POI_ID vs 이름)
-- 같은 장소를 여러 사람이 방문했으니, "장소 단위"로 묶어서 통계를 내야 합니다.
-- POI_ID(장소 고유번호)가 있으면 제일 정확하지만, 결측이 있어서 결측률부터 봅니다.
SELECT
    COUNT(*) AS 전체_행수,
    SUM(POI_ID IS NULL OR POI_ID = '') AS POI_ID_결측,
    ROUND(SUM(POI_ID IS NULL OR POI_ID = '') * 100.0 / COUNT(*), 1) AS 결측률_퍼센트
FROM tn_visit_area_info
WHERE VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24');  -- 3-1에서 정한 제외 유형은 빼고 봄
-- 제외 유형을 뺀 상태로 보면 결측률이 9%대로 낮습니다(전체로 보면 31%였는데,
-- 결측의 대부분이 "집"처럼 애초에 POI_ID가 없는 장소 유형에 몰려 있었기 때문).
-- 그래서 POI_ID가 있으면 그걸 쓰고, 없는 9%만 장소 이름으로 대신 묶기로 합니다.

-- STEP 3-3. 같은 장소인데 사람마다 유형을 다르게 분류한 경우 처리
-- 예를 들어 "더 현대 서울"을 어떤 응답자는 "상업지구"로, 어떤 응답자는
-- "문화시설"로 분류했을 수 있습니다. 이럴 때 그냥 아무 값이나 하나 고르면
-- (예: 문자열 최솟값) 실제와 다른 유형이 뽑힐 수 있으므로, "가장 많이 선택된
-- 유형(최빈값)"을 대표 유형으로 골라야 합니다.
WITH base AS (
    SELECT
        COALESCE(NULLIF(POI_ID, ''), CONCAT('NM:', VISIT_AREA_NM)) AS candidate_key,
        VISIT_AREA_TYPE_CD
    FROM tn_visit_area_info
    WHERE VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
)
SELECT
    b.candidate_key,
    cb.cd_nm AS type_nm,
    COUNT(*) AS 이_유형으로_분류된_횟수
FROM base b
LEFT JOIN tc_codeb cb ON cb.cd_a = 'VIS' AND cb.cd_b = b.VISIT_AREA_TYPE_CD
GROUP BY b.candidate_key, cb.cd_nm
HAVING b.candidate_key = 'POI01000TR013273V'  -- 예시: 더 현대 서울의 POI_ID
ORDER BY 이_유형으로_분류된_횟수 DESC;
-- 이렇게 장소별 유형 분류 횟수를 세워두고, 가장 큰 값(1등)을 대표 유형으로 쓰면 됩니다.
-- (실제 구현은 STEP 3-4에서 ROW_NUMBER()로 자동화합니다.)

-- STEP 3-4. 위 세 가지를 다 반영해서 최종 "추천 후보 풀"을 만든다
WITH base AS (
    SELECT
        v.*,
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS candidate_key,  -- 3-2: POI_ID 우선, 없으면 이름
        cb.cd_nm AS type_nm
    FROM tn_visit_area_info v
    LEFT JOIN tc_codeb cb
           ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD
    WHERE v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')  -- 3-1: 집/지인집/사무실/숙소/역·터미널 제외
),
type_mode AS (
    -- 3-3: 장소별로 유형 분류 횟수를 세고, 가장 많이 나온 유형에 순번 1을 매김
    SELECT
        candidate_key,
        type_nm,
        ROW_NUMBER() OVER (
            PARTITION BY candidate_key
            ORDER BY COUNT(*) DESC, type_nm   -- 횟수 많은 순, 동률이면 이름순(결과 재현성 확보)
        ) AS rn
    FROM base
    GROUP BY candidate_key, type_nm
)
SELECT
    b.candidate_key,
    MIN(b.VISIT_AREA_NM)               AS visit_area_nm,          -- 대표 장소명
    tm.type_nm                          AS visit_area_type_nm,     -- 최빈 유형 (rn=1인 것만 붙임)
    COUNT(*)                            AS visit_cnt,              -- 이 장소를 방문한 총 횟수(표본 크기)
    ROUND(AVG(b.RESIDENCE_TIME_MIN), 1) AS avg_residence_min,      -- 평균 체류시간(분) — 틈 시간과 비교할 기준값
    ROUND(AVG(b.DGSTFN), 2)             AS avg_satisfaction,       -- 평균 만족도(1~5점)
    ROUND(AVG(b.REVISIT_INTENTION), 2)  AS avg_revisit_intention,  -- 평균 재방문의향(1~5점)
    ROUND(AVG(b.RCMDTN_INTENTION), 2)   AS avg_recommend_intention,-- 평균 추천의향(1~5점)
    MIN(b.X_COORD)                      AS x_coord,                -- 대표 경도(거리 계산용)
    MIN(b.Y_COORD)                      AS y_coord                 -- 대표 위도(거리 계산용)
FROM base b
JOIN type_mode tm
  ON tm.candidate_key = b.candidate_key AND tm.rn = 1   -- 최빈 유형 한 줄만 붙임
GROUP BY b.candidate_key, tm.type_nm
HAVING COUNT(*) >= 2                                    -- 표본 1건짜리는 우연일 수 있어 제외
   AND MIN(b.X_COORD) IS NOT NULL AND MIN(b.Y_COORD) IS NOT NULL  -- 좌표 없으면 거리 계산 불가하므로 제외
ORDER BY visit_cnt DESC, avg_satisfaction DESC;
-- 이게 "추천 후보 풀"입니다. (전체로 실행하면 약 1,600곳이 나옵니다.)


-- ================================================================
-- STEP 4. 왜 마지막 거리 매칭은 SQL이 아니라 Python에서 하는가
-- ----------------------------------------------------------------
-- STEP 2에서 만든 "틈 목록"(약 15,000건)과 STEP 3에서 만든 "후보 풀"(약 1,600건)을
-- 짝지으려면, 모든 조합(약 15,000 × 1,600 ≒ 2,400만 개)의 거리를 계산해야 합니다.
-- 좌표(X_COORD, Y_COORD)에는 인덱스가 없어서, 이걸 SQL 조인으로 한 번에 계산하면
-- 서버(Aiven 무료 티어)의 임시 디스크가 부족해서 실패합니다.
-- ("No space left on device" 에러 — 실제로 이 프로젝트에서 겪은 에러입니다.)
--
-- 그래서 이 정도 규모의 "모든 조합 계산"은 SQL 대신 파이썬(pandas/numpy)에서
-- 벡터 연산으로 처리합니다. 대신 SQL에서는 아래처럼 "작은 예시 하나"만 보여줄 수 있습니다.
-- (WHERE로 딱 1건의 틈만 골라서, 그 틈과 후보 풀 전체의 거리만 계산 — 이 정도 규모는 안전함)
-- ================================================================

-- STEP 4 예시. 틈 1건만 골라서 거리 계산 원리를 확인 (전체로 확장 금지!)
WITH one_gap AS (
    -- STEP 2-3과 같은 틈 목록 쿼리에서, 딱 1건만 예시로 고름
    SELECT
        '수원 화성 화홍문' AS gap_location_nm,
        127.017626 AS gap_x,   -- 예시 좌표 (tn_visit_area_info에서 직접 조회한 값)
        37.287546  AS gap_y,
        120 AS gap_minutes      -- 이 틈의 길이(분)
),
pool_sample AS (
    -- STEP 3-4와 같은 후보 풀 쿼리 (지면상 집계 없이 간단히 재현)
    SELECT
        COALESCE(NULLIF(POI_ID, ''), CONCAT('NM:', VISIT_AREA_NM)) AS candidate_key,
        VISIT_AREA_NM,
        AVG(RESIDENCE_TIME_MIN) AS avg_residence_min,
        AVG(X_COORD) AS x_coord,
        AVG(Y_COORD) AS y_coord
    FROM tn_visit_area_info
    WHERE VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
      AND X_COORD IS NOT NULL AND Y_COORD IS NOT NULL
    GROUP BY candidate_key, VISIT_AREA_NM
    HAVING COUNT(*) >= 2
)
SELECT
    p.VISIT_AREA_NM,
    p.avg_residence_min,
    -- Haversine 공식: 지구를 구로 보고 위경도 두 점 사이의 실제 거리(km)를 구하는 공식
    ROUND(
        6371 * ACOS(
            LEAST(1, GREATEST(-1,
                COS(RADIANS(g.gap_y)) * COS(RADIANS(p.y_coord)) * COS(RADIANS(p.x_coord) - RADIANS(g.gap_x))
                + SIN(RADIANS(g.gap_y)) * SIN(RADIANS(p.y_coord))
            ))
        ), 2
    ) AS distance_km
FROM one_gap g
JOIN pool_sample p
  ON p.avg_residence_min <= g.gap_minutes   -- 틈 시간 안에 들어가는 곳만
ORDER BY distance_km
LIMIT 5;
-- 실행해보면 1등이 "수원 화성 화홍문" 자기 자신(distance_km=0)으로 나올 겁니다.
-- 이 튜토리얼에서는 원리만 보여주려고 "틈이 발생한 그 자리 자체는 추천에서
-- 빼는" 조건을 일부러 생략했습니다. 실전 완성본(gap_recommend_match.py)에서는
-- gap_candidate_key <> candidate_key 조건으로 이걸 걸러냅니다.
--
-- 원리는 이렇게 간단하지만, 이걸 틈 15,000건 전체에 대해 하면 안 됩니다(위 설명 참고).
-- 전체 규모의 최종 매칭은 python/gap_recommend_match.py를 실행하세요.
-- 그 결과가 SQL/JeongTaeChoi/Result Query/gap_recommend_result.csv 에 저장됩니다.


