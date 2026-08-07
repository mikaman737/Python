-- ================================================================
-- [튜토리얼] "틈(빈 시간)-소비" 가설 검증 — SQL 초보용 단계별 설명
-- 대상 DB: Aiven MySQL 8.4 (powerbirangers)
-- ----------------------------------------------------------------
-- 이 파일은 segment.sql에 적힌 분석 계획(연구 질문 3개, 가설 3개, 선행 확인
-- 15+2+2+3항목)을 실제로 실행 가능한 SELECT문으로 하나하나 풀어놓은 파일입니다.
-- 계획을 세운 사람이 아니어도 위에서부터 순서대로 실행하면서 주석을 읽으면
-- "왜 이 쿼리가 필요한지 → 무엇을 보는 쿼리인지 → 결과를 어떻게 해석해야
-- 하는지"를 따라올 수 있도록 최대한 잘게 쪼갰습니다.
--
-- 원본 계획: SQL/JeongTaeChoi/Read/segment.sql (주석으로 된 기획서)
-- 축약 로드맵: SQL/JeongTaeChoi/Read/segment_analysis_steps.sql
-- 이 파일 = 위 두 파일의 계획을 실제 쿼리로 구현한 것
--
-- 팀 원칙 안내 (노션 "데이터분석 보고 7원칙" 중 이 파일에 특히 중요한 것)
--   1. 데이터에 없는 사실은 지어내지 않는다 -> "선행 확인 사항"에는 SQL로
--      확인 불가능한 항목(문서 대조, 팀 논의 필요)도 있는데, 그런 항목은
--      쿼리를 억지로 만들지 않고 "SQL로 확인 불가"라고 주석으로만 남겼습니다.
--   3. 전처리 과정을 보고한다 -> 어떤 값을 왜 빼고 넣었는지 각 STEP 주석에 기록
--   5. 표본 개수와 시점을 밝힌다 -> 이 데이터는 2023년 수도권 자체 수집
--      표본이므로, 아래 모든 결과는 "이 표본 안에서는" 수준으로만 해석할 것
--
-- 전체 목차
--   STEP 0. 확정된 사실 요약 (이전 대화에서 이미 검증된 것들 — 재확인 쿼리 없이 인용만)
--   STEP 1. 공통 선행 확인 (계획서 0단계 "[공통]" 15개 항목)
--   STEP 2. 가설별 선행 확인 (계획서 0단계 "[가설1/2/3]" 항목)
--   STEP 3. 파생 변수 생성 (계획서 1단계)
--   STEP 4. 세그먼트 기초 통계 (계획서 2단계)
--   STEP 5. 가설별 검정 (계획서 3단계)
--   STEP 6. 특이 이벤트/이상치 재확인 (계획서 4단계)
--   STEP 7. 결과 종합 체크리스트 (계획서 5단계, 쿼리 없음)
-- ================================================================


-- ================================================================
-- STEP 0. 확정된 사실 요약 (재확인 쿼리 없음 — 이전 분석에서 이미 검증됨)
-- ----------------------------------------------------------------
-- 아래 내용은 segment_analysis_steps.sql / powerbirangers_gap_recommend*.sql
-- 작업 중 이미 쿼리로 확인된 사실입니다. 이 파일의 STEP 3부터는 이 사실들을
-- 전제로 깔고 진행하므로, 처음 보는 사람은 이 블록부터 읽으면 됩니다.
--   - tn_move_his는 "이동 한 건의 출발~도착"이 한 행에 같이 있는 구조가 아니라,
--     한 행에 START_DT_MIN(첫 방문지만) 또는 END_DT_MIN(그 외 전부) 중 하나만
--     채워지는 구조 -> 믿고 쓸 수 있는 값은 END_DT_MIN(도착시각)뿐
--   - gap_minutes(틈 근사치) = 연속 방문지의 도착시각(END_DT_MIN) 차이
--     -> 실제로는 "체류시간 + 이동시간 + 진짜 빈 시간"이 섞인 상한값
--   - RESIDENCE_TIME_MIN, gap_minutes 전부 30분 단위로만 기록됨
--     -> 30분 미만의 유휴시간은 원천적으로 관측 불가 (분석 결과의 근본적 한계)
--   - 숙소/역·터미널/집/지인집/사무실/기타(VISIT_AREA_TYPE_CD 9,12,21,22,23,24)는
--     체류시간이 다른 시계로 기록되어 gap-체류시간 계산이 깨짐 -> 틈 계산에서 제외
--   - 위 6개 유형 제외 후: 분석대상 여행 2,860건 중 틈이 1건이라도 있는 여행자
--     2,791명(97.6%) -> "틈 있음/없음" 이분법은 변별력이 없어 비중/총량으로 봐야 함
--   - 2023-07~08에 여행이 몰려 있고(여름휴가 성수기), 2023-08-26~27은
--     수원컨벤션센터 "제8회 렙타일페어 수원" 행사로 수원 방문이 유독 많았음
--     (특이 이벤트 예시 — STEP 6에서 이런 케이스를 일반적으로 찾는 쿼리를 다룸)
-- ================================================================


-- ================================================================
-- STEP 1. 공통 선행 확인 (계획서 0단계 "[공통]" 1~15순위)
-- ----------------------------------------------------------------
-- 정의가 확정되지 않은 채로 지표부터 계산하면 나중에 다시 계산해야 하므로,
-- 반드시 이 STEP을 먼저 실행하고 결과를 팀과 공유한 뒤 STEP 3으로 넘어갈 것.
-- ================================================================

-- ----------------------------------------------------------------
-- 1-1순위. 여행의 정의가 무엇인지? (SQL로 일부 확인 가능)
-- "여행 1건 = TRAVEL_ID 1개"라는 것은 스키마상 명확하지만(tn_travel의 PK),
-- "그 여행이 방문지를 최소 몇 곳 포함해야 유효한 여행으로 볼지"는 팀 정의가
-- 필요합니다. 우선 여행당 방문지 수 분포를 확인합니다.
-- ----------------------------------------------------------------
SELECT
    visit_cnt,
    COUNT(*) AS travel_cnt   -- 방문지 수가 visit_cnt개인 여행이 몇 건인지
FROM (
    SELECT TRAVEL_ID, COUNT(*) AS visit_cnt
    FROM tn_visit_area_info
    GROUP BY TRAVEL_ID
) t
GROUP BY visit_cnt
ORDER BY visit_cnt;
-- 해석 가이드: visit_cnt=1(방문지 1곳뿐)인 여행이 많다면, 그런 여행은애초에
-- "틈"이 발생할 수 없는(연속된 두 방문지가 없는) 여행이므로 가설1 검증
-- 모집단에서 자연스럽게 제외됩니다. 이 결과 자체가 "여행 정의"를 대신하지는
-- 않으니, 숫자를 팀과 공유하고 "방문지 1곳짜리도 여행으로 볼지"를 논의하세요.

-- ----------------------------------------------------------------
-- 1-2순위. 표본을 어떤 방식으로 추출했는지?
-- -> SQL로 확인 불가 (DB에 표본설계 정보가 없음). Description/ 원본
--    데이터설명서(hwp)에서 "자체 수집"으로 이미 확인됨 (segment.sql 참고).
--    자체 수집 = 확률표본이 아닐 수 있으므로, 이후 모든 세그먼트 비교
--    결과는 "전 국민 대표성" 주장 없이 "이 표본 안에서" 수준으로만 서술할 것.
-- ----------------------------------------------------------------

-- ----------------------------------------------------------------
-- 1-3순위. 소비의 이상치와 결측을 확인
-- 소비 후보 4개 테이블(활동/사전/숙박/이동수단)의 PAYMENT_AMT_WON을
-- 한 번에 놓고 결측·0원·최댓값을 비교합니다. 이상치 여부는 이 결과를 보고
-- 팀이 판단(예: 상위 0.1%를 이상치로 볼지)하는 것이지, 이 쿼리가 자동으로
-- 걸러내지는 않습니다.
-- ----------------------------------------------------------------
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
-- 최대값이 평균+표준편차*10 같은 수준으로 튀는 유형이 있는지 눈으로 먼저 확인하고,
-- 필요하면 아래처럼 상위 N건을 직접 열어서 실제 이상치인지(오타/단위오류) 확인하세요.
SELECT * FROM tn_activity_consume_his ORDER BY PAYMENT_AMT_WON DESC LIMIT 20;

-- ----------------------------------------------------------------
-- 1-4~1-6순위. 숙박/이동/사전소비를 "소비"에 포함할지 (SQL로는 최종 결정 불가,
-- 대신 각 항목이 실제로 무엇을 기록한 데이터인지 샘플을 보여줘서 팀 판단을 돕습니다)
-- ----------------------------------------------------------------
-- 1-4. 숙박소비 샘플 (자연키 없음 -> 중복 존재 확인됨, 대체키 id 사용 중이라는 점 주의)
SELECT LODGING_NM, LODGING_TYPE_CD, PAYMENT_AMT_WON, PAYMENT_DT
FROM tn_lodge_consume_his
LIMIT 20;

-- 1-5. 이동수단소비 샘플 (대중교통/자차 요금 등으로 추정 — 실제 값으로 확인)
SELECT MVMN_SE_NM, PAYMENT_SE, PAYMENT_AMT_WON, PAYMENT_DT
FROM tn_mvmn_consume_his
LIMIT 20;

-- 1-6. 사전소비 샘플 (ADV_NM = 구매내역명 -> 여행 전 준비물/예약비용 추정, 실물로 확인)
SELECT ADV_NM, PAYMENT_AMT_WON, PAYMENT_DT
FROM tn_adv_consume_his
LIMIT 20;
-- 세 샘플을 보고 "이건 소비로 포함", "이건 성격이 달라서 제외"를 팀이 정하고
-- 그 근거를 트래커에 남기세요. (segment.sql 계획대로 활동+숙박+이동은 우선 포함,
-- 사전소비는 이 샘플을 보고 포함 여부 결정)

-- ----------------------------------------------------------------
-- 1-7순위. 여행 기간(박수/일수) 차이가 총소비·총틈시간을 부풀리는 교란요인인지
-- 확인하기 위해 먼저 기간 분포부터 봅니다.
-- ----------------------------------------------------------------
SELECT
    DATEDIFF(TRAVEL_END_YMD, TRAVEL_START_YMD) + 1 AS travel_days,  -- 여행 일수(당일치기=1)
    COUNT(*) AS travel_cnt
FROM tn_travel
WHERE TRAVEL_START_YMD IS NOT NULL AND TRAVEL_END_YMD IS NOT NULL
GROUP BY travel_days
ORDER BY travel_days;
-- 일수 분포가 넓게 퍼져 있다면(1박~여러 박 섞임), STEP 3~5의 소비·틈 지표를
-- "총량"과 "1일당(=총량/travel_days)" 두 버전으로 같이 만들어서 비교해야 합니다.
-- (이 판단을 위한 확인용 쿼리이며, 실제 1일당 지표 생성은 STEP 3-3에서 다룸)

-- ----------------------------------------------------------------
-- 1-8순위. 지역 물가에 따라 소비액이 달라질 수 있는지
-- -> DB 안에 물가 컬럼 자체가 없어 SQL로 확인 불가. 필요하면 KOSIS 등
--    외부 데이터를 지역(SGG_CD)에 조인해야 하며, 연동 전까지는
--    "데이터로는 알 수 없음"으로 남겨둠 (2차 검증용, 필수 아님).
-- ----------------------------------------------------------------

-- ----------------------------------------------------------------
-- 1-9순위. 여행 목적(TRAVEL_PURPOSE)이 현재 세그먼트 기준(성별·직업·소득·연령)에
-- 빠져 있음 -> 얼마나 다양한 목적이 있는지, 목적별 표본수부터 확인
-- ----------------------------------------------------------------
SELECT TRAVEL_PURPOSE, COUNT(*) AS travel_cnt
FROM tn_travel
GROUP BY TRAVEL_PURPOSE
ORDER BY travel_cnt DESC;
-- TRAVEL_PURPOSE는 자유기술/복수응답 텍스트일 수 있어(최대 60자) 그대로 세그먼트
-- 축으로 쓰기 어려울 수 있습니다. 결과를 보고 "주요 목적 몇 개로 묶을 수 있는지"
-- 팀이 판단한 뒤, 필요하면 STEP 4의 세그먼트 기준에 추가하세요.

-- ----------------------------------------------------------------
-- 1-10순위. 결측치가 무작위인지, 특정 세그먼트/지역에 편중돼 있는지
-- (편중돼 있으면 세그먼트 비교 자체가 왜곡되므로 중요)
-- 여기서는 "총소비 결측(=소비 기록이 아예 없는 여행)"이 성별/연령대별로
-- 고르게 퍼져 있는지 확인합니다.
-- ----------------------------------------------------------------
WITH travel_consume AS (
    SELECT c.TRAVEL_ID, SUM(c.PAYMENT_AMT_WON) AS total_amt
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
)
SELECT
    tm.GENDER,
    tm.AGE_GRP,
    COUNT(t.TRAVEL_ID) AS 전체_여행수,
    SUM(tc.TRAVEL_ID IS NULL) AS 소비기록_전혀없는_여행수,   -- LEFT JOIN 결과가 NULL이면 소비 기록 자체가 없다는 뜻
    ROUND(SUM(tc.TRAVEL_ID IS NULL) * 100.0 / COUNT(t.TRAVEL_ID), 1) AS 결측비율_퍼센트
FROM tn_travel t
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
LEFT JOIN travel_consume tc ON tc.TRAVEL_ID = t.TRAVEL_ID
GROUP BY tm.GENDER, tm.AGE_GRP
ORDER BY tm.GENDER, tm.AGE_GRP;
-- 특정 성별×연령대에서만 결측비율이 튀면, 그 세그먼트의 "낮은 평균소비"가
-- 실제 소비 성향이 아니라 결측 때문일 수 있으므로 STEP 4~5 해석 시 반드시 참고.

-- ----------------------------------------------------------------
-- 1-11순위. 세그먼트별 표본수가 통계적으로 비교 가능한 규모인지
-- (n이 너무 작으면 평균이 소수 극단값에 흔들리므로 결과 신뢰도가 낮음)
-- ----------------------------------------------------------------
SELECT GENDER, AGE_GRP, JOB_NM, COUNT(*) AS traveler_cnt
FROM tn_traveller_master
GROUP BY GENDER, AGE_GRP, JOB_NM
ORDER BY traveler_cnt ASC;   -- 표본수가 작은 세그먼트부터 보이도록 오름차순
-- traveler_cnt가 예: 30 미만인 조합은 STEP 4~5에서 "참고용"으로만 표시하고
-- 본문 결론에서는 제외하거나 더 큰 범주(예: 연령대를 10살 단위로 묶기)로
-- 합쳐서 다시 보는 것을 권장. (임계값 30은 예시이며 팀이 확정할 것)

-- ----------------------------------------------------------------
-- 1-12순위. 세그먼트별 소비 특성 이해
-- -> 이 항목은 그 자체로 STEP 4(세그먼트 기초 통계) 전체와 같으므로 여기서는
--    쿼리를 반복하지 않고 STEP 4로 넘김.
-- ----------------------------------------------------------------

-- ----------------------------------------------------------------
-- 1-13순위. 방문지정보와 숙박/사전/활동 소비내역의 주소(SGG_CD)가 같은지 확인
-- segment.sql 원본 쿼리(파일 맨 아래)를 정리한 버전. SGG_CD가 공백('')으로
-- 저장된 경우가 있어 그 비중부터 봅니다.
-- ----------------------------------------------------------------
SELECT '방문지정보' AS 테이블, COUNT(*) AS 전체행수, SUM(SGG_CD = '' OR SGG_CD IS NULL) AS SGG_CD_공백건수
FROM tn_visit_area_info
UNION ALL
SELECT '활동소비내역', COUNT(*), SUM(SGG_CD = '' OR SGG_CD IS NULL) FROM tn_activity_consume_his
UNION ALL
SELECT '사전소비내역', COUNT(*), SUM(SGG_CD = '' OR SGG_CD IS NULL) FROM tn_adv_consume_his;
-- 숙박소비내역(tn_lodge_consume_his)에는 SGG_CD 컬럼 자체가 없음(스키마 참고) ->
-- 주소 일치 확인이 필요하면 ROAD_NM_ADDR 문자열 비교로 대체해야 함(간단 비교 불가,
-- 별도 전처리 필요 — 여기서는 다루지 않음)

-- 방문지정보 기준으로, 같은 TRAVEL_ID+VISIT_AREA_ID에 연결된 활동소비내역의
-- SGG_CD가 실제로 같은지 표본으로 확인 (복합키 조인 — CLAUDE.md 규칙)
SELECT
    v.TRAVEL_ID, v.VISIT_AREA_ID, v.SGG_CD AS 방문지_SGG_CD, a.SGG_CD AS 활동소비_SGG_CD,
    CASE WHEN v.SGG_CD = a.SGG_CD THEN '일치' ELSE '불일치' END AS 일치여부
FROM tn_visit_area_info v
JOIN tn_activity_consume_his a
  ON a.TRAVEL_ID = v.TRAVEL_ID AND a.VISIT_AREA_ID = v.VISIT_AREA_ID
WHERE v.SGG_CD <> '' AND a.SGG_CD <> ''
LIMIT 50;
-- 불일치 건이 눈에 띄게 많으면, "물리적으로 다른 곳에서 결제"(예: 온라인 예약)
-- 가능성이 있다는 뜻이므로 ERD 문서와 대조해 원인을 팀이 직접 확인할 것
-- (CLAUDE.md 원칙: ERD-실데이터 불일치는 AI가 추측하지 않는다)

-- ----------------------------------------------------------------
-- 1-14순위. 완료된 여행만 포함하는지, 요일/계절 쏠림이 있는지
-- ----------------------------------------------------------------
-- 종료일자가 비어있는 여행 = "진행 중" 또는 데이터 누락으로 볼 수 있는 후보
SELECT
    SUM(TRAVEL_END_YMD IS NULL) AS 종료일자_결측_여행수,
    COUNT(*) AS 전체_여행수
FROM tn_travel;

-- 요일 쏠림 확인 (여행 시작 요일 기준)
SELECT DAYNAME(TRAVEL_START_YMD) AS 시작_요일, COUNT(*) AS travel_cnt
FROM tn_travel
WHERE TRAVEL_START_YMD IS NOT NULL
GROUP BY 시작_요일
ORDER BY travel_cnt DESC;

-- 계절(월) 쏠림 확인
SELECT MONTH(TRAVEL_START_YMD) AS 시작_월, COUNT(*) AS travel_cnt
FROM tn_travel
WHERE TRAVEL_START_YMD IS NOT NULL
GROUP BY 시작_월
ORDER BY 시작_월;
-- STEP 0에서 이미 확인됐듯 7~8월에 쏠려 있을 가능성이 높음(여름휴가 성수기).
-- 특정 요일/월에 쏠려 있다면 "1년 전체로 일반화 불가, 성수기 한정 결과"라고
-- 보고서에 명시할 것(팀 원칙 5).

-- ----------------------------------------------------------------
-- 1-15순위. 소비를 많이 한 이유의 특수성(특정 날짜 행사 등)이 있는지
-- -> 이 항목은 STEP 6(특이 이벤트/이상치 재확인)에서 "가설 검정 이후 영향이
--    컸던 여행을 역추적"하는 방식으로 다루는 게 더 정확함(순서상 나중이 맞음).
--    여기서는 계획서 0단계에 있던 대로, 날짜별로 특정 지역 방문이 튀는지
--    찾는 범용 쿼리만 먼저 만들어 둡니다(특정 날짜를 미리 지정하지 않음).
-- ----------------------------------------------------------------
SELECT
    v.VISIT_START_YMD,
    SUBSTRING_INDEX(v.ROAD_NM_ADDR, ' ', 1) AS 시도,
    SUBSTRING_INDEX(SUBSTRING_INDEX(v.ROAD_NM_ADDR, ' ', 2), ' ', -1) AS 시군구,
    COUNT(*) AS 방문건수
FROM tn_visit_area_info v
WHERE v.ROAD_NM_ADDR IS NOT NULL AND TRIM(v.ROAD_NM_ADDR) <> ''
GROUP BY v.VISIT_START_YMD, 시도, 시군구
HAVING COUNT(*) >= 20        -- 하루·한 지역에 방문이 몰린 경우만 보이도록(임계값은 조정 가능)
ORDER BY 방문건수 DESC
LIMIT 30;
-- 여기서 눈에 띄는 날짜·지역이 나오면(예: 8/26 수원처럼), 그 날짜에 실제로
-- 무슨 행사가 있었는지는 SQL이 아니라 뉴스/지자체 자료로 팀이 직접 확인해야
-- 합니다(AI가 지어내지 않음 — 8/26 수원 사례도 팀이 외부 검색으로 확인한 것).


-- ================================================================
-- STEP 2. 가설별 선행 확인 (계획서 0단계 "[가설1/2/3]" 항목)
-- ================================================================

-- ----------------------------------------------------------------
-- [가설1] 2-1. 빈 시간의 정의: RESIDENCE_TIME_MIN이 정말 30분 단위로만
-- 찍히는지 직접 확인 (계획서에 적힌 관찰을 재현)
-- ----------------------------------------------------------------
SELECT
    RESIDENCE_TIME_MIN % 30 AS 나머지,   -- 30으로 나눈 나머지가 전부 0이면 "30분 단위"가 맞다는 뜻
    COUNT(*) AS cnt
FROM tn_visit_area_info
WHERE RESIDENCE_TIME_MIN IS NOT NULL
GROUP BY 나머지
ORDER BY cnt DESC;
-- 나머지=0인 행이 절대다수라면 30분 단위 절사가 사실로 확인된 것이며,
-- 이는 "30분 미만 유휴시간은 원천적으로 못 본다"는 한계를 뒷받침하는 근거가 됩니다.

-- 방문지 유형 코드의 실제 의미 확인 (tc_codeb, cd_a='VIS' — powerbirangers_gap_recommend*.sql에서 이미 확인된 값)
SELECT cd_b AS 코드값, cd_nm AS 유형명
FROM tc_codeb
WHERE cd_a = 'VIS'
ORDER BY cd_b;
-- 9(역/터미널/휴게소), 12(기타), 21(집), 22(친지집), 23(사무실), 24(숙소)는
-- 체류시간이 "일상 시계"로 찍혀 gap 계산이 깨지므로 틈 계산 대상에서 제외
-- (아래 STEP 3-1에서 이 6개 코드를 WHERE 조건으로 실제로 제외함)

-- ----------------------------------------------------------------
-- [가설1] 2-2. 이동수단 유형(MVMN_CD_1)에 따라 "틈"의 성격이 다를 수 있음
-- (대중교통 대기시간은 불가피한 틈일 수 있음) -> 먼저 값 분포만 확인
-- ----------------------------------------------------------------
SELECT MVMN_CD_1, COUNT(*) AS cnt
FROM tn_move_his
GROUP BY MVMN_CD_1
ORDER BY cnt DESC;
-- MVMN_CD_1이 코드값이라 이름을 알아야 해석 가능합니다. tc_codea에서
-- 이 코드가 속한 cd_a 그룹명을 먼저 찾아보세요(아래 쿼리로 후보를 좁힘).
SELECT cd_a, cd_nm
FROM tc_codea
ORDER BY cd_a;
-- 위 결과에서 "이동수단"류로 보이는 cd_a 값을 찾은 뒤, 그 값으로
-- tc_codeb를 조회(WHERE cd_a = '찾은값')하면 MVMN_CD_1의 실제 이름을 알 수 있음.
-- (VIS 코드처럼 'MVM' 등 3~4글자 축약형일 가능성이 높음 — 추측하지 않고
-- 위 조회 결과로 직접 확인할 것)

-- ----------------------------------------------------------------
-- [가설2] 2-3. 데이터 구조 확인: TRAVELER_ID 1명이 TRAVEL_ID를 여러 개
-- 갖는지(=재방문 여부를 계산할 수 있는 구조인지), 아니면 1인당 1회뿐인
-- 단면 데이터인지 -> 가설2 자체의 검증 가능 여부를 가르는 가장 중요한 확인
-- ----------------------------------------------------------------
SELECT
    travel_per_traveler,
    COUNT(*) AS traveler_cnt
FROM (
    SELECT TRAVELER_ID, COUNT(*) AS travel_per_traveler
    FROM tn_travel
    GROUP BY TRAVELER_ID
) t
GROUP BY travel_per_traveler
ORDER BY travel_per_traveler;
-- 해석 가이드 (실행 결과에 따라 둘 중 하나로 결론):
--   - travel_per_traveler가 전부(또는 거의) 1이면 -> 이 데이터는 단면 데이터.
--     "동일 여행자의 재방문"은 계산 불가하므로, 가설2는 "같은 사람이 다시 왔는가"
--     대신 "같은 여행 안에서 같은 지역을 두 번 이상 방문했는가"(REVISIT_YN
--     컬럼 또는 STEP 2-4 방식)로 정의를 바꿔야 함 -> 반드시 팀 합의 필요.
--   - 2 이상인 사람이 다수라면 -> 원래 계획대로 TRAVELER_ID 기준 재방문 계산 가능.

-- ----------------------------------------------------------------
-- [가설2] 2-4. 재방문을 어느 기준으로 볼지 후보 비교
-- 후보 A: 방문지 자체 응답값 REVISIT_YN (설문에서 "여기 재방문이냐"고 직접 물은 값)
-- ----------------------------------------------------------------
SELECT REVISIT_YN, COUNT(*) AS cnt
FROM tn_visit_area_info
GROUP BY REVISIT_YN;
-- 후보 B: 동일 TRAVELER_ID가 동일 SGG_CD(시군구)를 여러 TRAVEL_ID에 걸쳐
-- 방문한 적이 있는지로 재계산 (2-3에서 travel_per_traveler>=2가 확인된 경우에만 의미 있음)
SELECT
    same_sgg_travel_cnt,
    COUNT(*) AS traveler_cnt
FROM (
    SELECT
        t.TRAVELER_ID,
        v.SGG_CD,
        COUNT(DISTINCT v.TRAVEL_ID) AS same_sgg_travel_cnt   -- 이 사람이 이 시군구를 방문한 서로 다른 여행 건수
    FROM tn_visit_area_info v
    JOIN tn_travel t ON t.TRAVEL_ID = v.TRAVEL_ID
    WHERE v.SGG_CD IS NOT NULL AND v.SGG_CD <> ''
    GROUP BY t.TRAVELER_ID, v.SGG_CD
) x
GROUP BY same_sgg_travel_cnt
ORDER BY same_sgg_travel_cnt;
-- same_sgg_travel_cnt >= 2인 조합이 있으면 그 사람은 "그 지역 재방문자"로
-- 정의할 수 있음. 후보 A(설문 응답)와 후보 B(데이터 재계산) 중 무엇을 쓸지,
-- 또는 둘을 교차검증할지 팀이 정할 것(계획서 원문 그대로 "기준 확정 필요").

-- ----------------------------------------------------------------
-- [가설3] 2-5. tn_companion_info 실제 값 구조 확인
-- ----------------------------------------------------------------
-- 동반자 관계 코드(REL_CD) 분포
SELECT REL_CD, COUNT(*) AS cnt
FROM tn_companion_info
GROUP BY REL_CD
ORDER BY cnt DESC;
-- 위 STEP 2-2와 같은 방식으로 tc_codea에서 REL_CD가 속한 cd_a를 찾아
-- tc_codeb로 이름을 붙이면 "나홀로/커플/가족/친구" 같은 실제 카테고리명을 알 수 있음.

-- 여행(TRAVEL_ID)당 동반자 수 분포 (본인 제외 인원수)
SELECT
    companion_cnt,
    COUNT(*) AS travel_cnt
FROM (
    SELECT TRAVEL_ID, COUNT(*) AS companion_cnt
    FROM tn_companion_info
    GROUP BY TRAVEL_ID
) c
GROUP BY companion_cnt
ORDER BY companion_cnt;
-- 주의: tn_companion_info에 아예 행이 없는 TRAVEL_ID는 이 결과에 안 잡힙니다.
-- "동반자 정보 미기재"인지 "정말 혼자 간 여행이라 기록할 동반자가 없는"인지
-- 구분이 안 되므로, 아래 STEP 2-6에서 그 규모부터 확인합니다.

-- ----------------------------------------------------------------
-- [가설3] 2-6. tn_companion_info에 행이 아예 없는 TRAVEL_ID 규모 확인
-- (1인당 소비 분모를 정할 때 "혼자 간 것" vs "결측"을 구분해야 함)
-- ----------------------------------------------------------------
SELECT
    COUNT(*) AS 전체_여행수,
    SUM(c.TRAVEL_ID IS NULL) AS 동반자정보_없는_여행수,
    ROUND(SUM(c.TRAVEL_ID IS NULL) * 100.0 / COUNT(*), 1) AS 비율_퍼센트
FROM tn_travel t
LEFT JOIN (SELECT DISTINCT TRAVEL_ID FROM tn_companion_info) c
       ON c.TRAVEL_ID = t.TRAVEL_ID;
-- 이 비율이 크면(예: 나홀로 여행이 원래 많은 데이터일 수도, 혹은 기록 누락일
-- 수도 있음) tn_traveller_master.TRAVEL_STATUS_ACCOMPANY(여행현황_동반현황,
-- 자유기술)를 보조로 대조해서 "정말 나홀로"인지 확인할 것을 권장합니다.
SELECT TRAVEL_STATUS_ACCOMPANY, COUNT(*) AS cnt
FROM tn_traveller_master
GROUP BY TRAVEL_STATUS_ACCOMPANY
ORDER BY cnt DESC
LIMIT 20;


-- ================================================================
-- STEP 3. 파생 변수 생성 (계획서 1단계)
-- ----------------------------------------------------------------
-- STEP 1~2에서 확인한 정의를 실제 컬럼으로 만드는 단계. 이후 STEP 4~5에서는
-- 이 STEP에서 만든 CTE(WITH 절)를 그대로 재사용합니다.
-- ================================================================

-- ----------------------------------------------------------------
-- 3-1. 방문지 단위 틈(gap) 산출
-- 로직 출처: powerbirangers_gap_recommend_tutorial.sql STEP 2 (동일 로직,
-- 여기서는 "추천용 좌표"가 아니라 "가설 검정용 잔여시간(residual)"이 목적이라
-- gap_minutes에서 체류시간을 뺀 residual_minutes까지 계산하는 점이 다름)
-- ----------------------------------------------------------------
WITH arrivals AS (
    SELECT
        v.TRAVEL_ID,
        v.VISIT_AREA_ID,
        v.VISIT_AREA_TYPE_CD,
        v.RESIDENCE_TIME_MIN,
        v.VISIT_ORDER,
        m.END_DT_MIN AS arrive_dt,
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt
    FROM tn_visit_area_info v
    JOIN tn_move_his m
      ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID   -- 복합키 조인
    WHERE m.END_DT_MIN IS NOT NULL
      AND v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')  -- STEP 2-1에서 확정한 제외 유형
)
SELECT
    TRAVEL_ID,
    VISIT_AREA_ID,
    RESIDENCE_TIME_MIN,
    TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) AS gap_minutes,
    -- residual_minutes = 틈(상한값) - 체류시간. 이 방문지에서 "체류시간 이후
    -- 남는 시간"으로, 실제 유휴시간에 가장 가까운 근사치.
    TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) - RESIDENCE_TIME_MIN AS residual_minutes
FROM arrivals
WHERE next_arrive_dt IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
ORDER BY TRAVEL_ID, arrive_dt;
-- residual_minutes <= 0인 경우는 "유휴시간이 0분"이 아니라 "30분 단위 측정
-- 해상도 안에서 잔여시간이 관측되지 않음"으로 표기할 것(segment_analysis_steps.sql
-- Step1-3 규칙). 이 쿼리 결과가 STEP 3-2, STEP 5-1의 재료가 됩니다.

-- ----------------------------------------------------------------
-- 3-2. 여행(TRAVEL_ID) 단위 틈 요약 지표
-- 위 3-1 쿼리를 CTE로 감싸서, 여행 단위로 "틈 발생 비율"과 "틈 총량"을 계산
-- ----------------------------------------------------------------
WITH arrivals AS (
    SELECT
        v.TRAVEL_ID, v.VISIT_AREA_ID, v.VISIT_AREA_TYPE_CD, v.RESIDENCE_TIME_MIN, v.VISIT_ORDER,
        m.END_DT_MIN AS arrive_dt,
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt
    FROM tn_visit_area_info v
    JOIN tn_move_his m ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
    WHERE m.END_DT_MIN IS NOT NULL
      AND v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
),
gaps AS (
    SELECT
        TRAVEL_ID,
        TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) - RESIDENCE_TIME_MIN AS residual_minutes
    FROM arrivals
    WHERE next_arrive_dt IS NOT NULL
      AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
)
SELECT
    TRAVEL_ID,
    COUNT(*) AS gap_구간수,                                             -- 이 여행에서 틈 계산 대상이 된 구간(방문지 전환) 수
    SUM(residual_minutes > 0) AS 틈있는_구간수,
    ROUND(SUM(residual_minutes > 0) * 1.0 / COUNT(*), 3) AS 틈발생비율,   -- 계획서의 "방문지 단위 틈 비율"
    SUM(GREATEST(residual_minutes, 0)) AS 틈총량_분                       -- residual이 음수인 구간은 0으로 취급해 합산(총량이 음수로 상쇄되지 않도록)
FROM gaps
GROUP BY TRAVEL_ID;
-- 이 결과가 STEP 4(세그먼트별 평균 틈 비율)와 STEP 5-1(가설1 검정)의 핵심 재료.

-- ----------------------------------------------------------------
-- 3-3. 소비액 정의: 여행(TRAVEL_ID) 단위 총소비 + 1인당 소비
-- 활동+숙박+이동+사전소비 4종을 모두 포함(2026-08-06 대화에서 사전소비도
-- 포함하기로 결정 — STEP 1-4~1-6 샘플 확인 후 최종 확정은 팀 트래커에 기록할 것).
-- ----------------------------------------------------------------
WITH travel_total_consume AS (
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
travel_companion_cnt AS (
    -- STEP 2-6에서 확인했듯 companion_info에 행이 없으면 나홀로 여행으로 간주(0명)
    SELECT t.TRAVEL_ID, COALESCE(cc.companion_cnt, 0) AS companion_cnt
    FROM tn_travel t
    LEFT JOIN (
        SELECT TRAVEL_ID, COUNT(*) AS companion_cnt
        FROM tn_companion_info
        GROUP BY TRAVEL_ID
    ) cc ON cc.TRAVEL_ID = t.TRAVEL_ID
)
SELECT
    tc.TRAVEL_ID,
    tc.total_amt_won,
    tcc.companion_cnt + 1 AS 인원수,                                       -- 본인 포함
    ROUND(tc.total_amt_won / (tcc.companion_cnt + 1), 0) AS 인당_소비액
FROM travel_total_consume tc
JOIN travel_companion_cnt tcc ON tcc.TRAVEL_ID = tc.TRAVEL_ID;
-- 주의(전처리 근거 기록): tn_lodge_consume_his는 자연키가 없어 중복 존재가
-- 확인된 테이블입니다(Createtable.sql 주석). 위 SUM은 중복 제거 없이 그대로
-- 합산했으므로, 숙박비가 실제보다 부풀려졌을 가능성이 있습니다. 중복 판단
-- 기준(TRAVEL_ID+LODGING_NM+PAYMENT_DT+PAYMENT_AMT_WON 조합 등)을 팀이
-- 정한 뒤 GROUP BY로 먼저 중복 제거하는 CTE를 앞에 추가할 것(STEP 1-4 연결).

-- ----------------------------------------------------------------
-- 3-4. 재방문 여부 플래그 (STEP 2-4에서 정한 기준 중 "동일 시군구 재방문"
-- 방식을 예시로 구현. 설문 응답 REVISIT_YN 기준으로 쓰려면 이 단계 생략하고
-- v.REVISIT_YN을 바로 사용하면 됨)
-- ----------------------------------------------------------------
WITH traveler_sgg_visits AS (
    SELECT
        t.TRAVELER_ID,
        v.SGG_CD,
        t.TRAVEL_ID,
        t.TRAVEL_START_YMD,
        ROW_NUMBER() OVER (
            PARTITION BY t.TRAVELER_ID, v.SGG_CD
            ORDER BY t.TRAVEL_START_YMD
        ) AS 이_지역_방문_순번   -- 같은 사람이 같은 시군구를 몇 번째로 방문했는지(시간순)
    FROM tn_visit_area_info v
    JOIN tn_travel t ON t.TRAVEL_ID = v.TRAVEL_ID
    WHERE v.SGG_CD IS NOT NULL AND v.SGG_CD <> ''
    GROUP BY t.TRAVELER_ID, v.SGG_CD, t.TRAVEL_ID, t.TRAVEL_START_YMD  -- 여행 내 여러 방문지가 같은 SGG_CD면 한 번으로 묶음
)
SELECT
    TRAVEL_ID,
    TRAVELER_ID,
    SGG_CD,
    CASE WHEN 이_지역_방문_순번 = 1 THEN '첫방문' ELSE '재방문' END AS 재방문여부
FROM traveler_sgg_visits
ORDER BY TRAVELER_ID, SGG_CD, 이_지역_방문_순번;
-- 한 여행(TRAVEL_ID) 안에서 지역을 여러 곳 방문했다면 이 결과에 TRAVEL_ID가
-- 여러 줄 나올 수 있습니다. STEP 5-2(가설2 검정)에서는 "그 여행에 재방문
-- 지역이 하나라도 있으면 재방문 여행으로 볼지" 등 집계 규칙을 한 번 더
-- 정해야 하며, 이는 팀 합의 사항입니다(계획서 원문 그대로).

-- ----------------------------------------------------------------
-- 3-5. 동반유형 그룹화
-- STEP 2-5/2-6에서 확인한 companion_cnt를 이용해 "나홀로/2인/3인이상"으로
-- 우선 분류(가장 객관적인 기준). REL_CD 최빈값은 참고용으로 같이 붙임.
-- ----------------------------------------------------------------
WITH companion_summary AS (
    SELECT TRAVEL_ID, COUNT(*) AS companion_cnt
    FROM tn_companion_info
    GROUP BY TRAVEL_ID
),
rel_mode AS (
    -- 같은 여행 안에 동반자가 여러 명이면 REL_CD가 여러 개일 수 있어 최빈값을 대표값으로 사용
    -- (powerbirangers_gap_recommend_tutorial.sql STEP 3-3의 최빈값 패턴과 동일)
    SELECT TRAVEL_ID, REL_CD,
           ROW_NUMBER() OVER (PARTITION BY TRAVEL_ID ORDER BY COUNT(*) DESC, REL_CD) AS rn
    FROM tn_companion_info
    GROUP BY TRAVEL_ID, REL_CD
)
SELECT
    t.TRAVEL_ID,
    COALESCE(cs.companion_cnt, 0) AS companion_cnt,
    rm.REL_CD AS 대표_동반자관계코드,
    CASE
        WHEN COALESCE(cs.companion_cnt, 0) = 0 THEN '나홀로'
        WHEN cs.companion_cnt = 1 THEN '2인 동반'
        ELSE '3인 이상 동반'
    END AS 동반유형
FROM tn_travel t
LEFT JOIN companion_summary cs ON cs.TRAVEL_ID = t.TRAVEL_ID
LEFT JOIN rel_mode rm ON rm.TRAVEL_ID = t.TRAVEL_ID AND rm.rn = 1;
-- '나홀로/2인/3인이상'은 계획서의 "나홀로/커플/가족/친구"보다 거친 분류입니다.
-- STEP 2-5에서 REL_CD 코드명을 확인한 뒤, "2인 동반"을 REL_CD로 다시
-- '커플'/'부모자녀' 등으로 세분화할 수 있으면 CASE문에 조건을 추가하세요.


-- ================================================================
-- STEP 4. 세그먼트 기초 통계 (계획서 2단계)
-- ----------------------------------------------------------------
-- "이 세그먼트는 원래 소비가 낮다/높다"는 특성부터 분리해서 봐야, STEP 5의
-- 틈-소비 상관관계가 세그먼트 특성 때문인지 틈 때문인지 구분할 수 있습니다.
-- JOB_NM/INCOME은 숫자 코드(tc_codeb)이므로, 먼저 어느 cd_a 그룹인지
-- STEP 2-2에서 확인한 값으로 아래 'JOB'/'INC' 자리를 채우세요
-- (미확인 상태의 임시값이며, segment_analysis_steps.sql 3-2에 남겨진
-- 추정치를 그대로 사용했습니다 — 실행 전 팀 확인 필수).
-- ================================================================
WITH travel_total_consume AS (
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
)
SELECT
    tm.GENDER,
    tm.AGE_GRP,
    jb.cd_nm AS 직업명,     -- STEP 2-2에서 확인한 실제 cd_a 값으로 'JOB' 교체 필요
    inc.cd_nm AS 소득구간명, -- STEP 2-2에서 확인한 실제 cd_a 값으로 'INC' 교체 필요
    COUNT(DISTINCT t.TRAVEL_ID) AS 표본_여행수,
    ROUND(AVG(ttc.total_amt_won), 0) AS 평균_여행당_총소비
FROM tn_travel t
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
LEFT JOIN travel_total_consume ttc ON ttc.TRAVEL_ID = t.TRAVEL_ID
LEFT JOIN tc_codeb jb  ON jb.cd_a = 'JOB' AND jb.cd_b = CAST(tm.JOB_NM AS CHAR)
LEFT JOIN tc_codeb inc ON inc.cd_a = 'INC' AND inc.cd_b = CAST(tm.INCOME AS CHAR)
GROUP BY tm.GENDER, tm.AGE_GRP, jb.cd_nm, inc.cd_nm
HAVING 표본_여행수 >= 30   -- STEP 1-11에서 정한 최소표본 기준 적용(예시값, 팀이 확정)
ORDER BY tm.GENDER, tm.AGE_GRP;

-- 세그먼트별 평균 틈 비율 (STEP 3-2 결과를 재사용)
WITH arrivals AS (
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
        SUM((TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) - RESIDENCE_TIME_MIN) > 0) * 1.0 / COUNT(*) AS 틈발생비율
    FROM arrivals
    WHERE next_arrive_dt IS NOT NULL
      AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
    GROUP BY TRAVEL_ID
)
SELECT
    tm.GENDER,
    tm.AGE_GRP,
    COUNT(DISTINCT t.TRAVEL_ID) AS 표본_여행수,
    ROUND(AVG(gr.틈발생비율), 3) AS 평균_틈발생비율
FROM tn_travel t
JOIN tn_traveller_master tm ON tm.TRAVELER_ID = t.TRAVELER_ID
JOIN gap_ratio gr ON gr.TRAVEL_ID = t.TRAVEL_ID
GROUP BY tm.GENDER, tm.AGE_GRP
HAVING 표본_여행수 >= 30
ORDER BY tm.GENDER, tm.AGE_GRP;


-- ================================================================
-- STEP 5. 가설별 검정 (계획서 3단계)
-- ----------------------------------------------------------------
-- 아래 세 쿼리는 전부 "평균 비교" 수준입니다. t-test/분산분석 같은 통계적
-- 유의성 검정은 SQL만으로는 어려우므로(표준 함수 없음), 이 결과를 CSV로
-- 내보내 python(scipy.stats)에서 검정하는 것을 권장합니다. 여기서는 그
-- 검정에 넣을 "그룹별 평균·표본수"까지만 SQL로 준비합니다.
-- ================================================================

-- ----------------------------------------------------------------
-- 5-1. 가설1(틈-소비): 틈 비율 사분위 그룹 간 1인당 소비 비교
-- ----------------------------------------------------------------
WITH arrivals AS (
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
        SUM((TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) - RESIDENCE_TIME_MIN) > 0) * 1.0 / COUNT(*) AS 틈발생비율
    FROM arrivals
    WHERE next_arrive_dt IS NOT NULL
      AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
    GROUP BY TRAVEL_ID
),
per_person AS (
    SELECT
        tc.TRAVEL_ID,
        ROUND(tc.total_amt_won / (COALESCE(cc.companion_cnt, 0) + 1), 0) AS 인당_소비액
    FROM (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS total_amt_won
        FROM (
            SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
        ) c GROUP BY TRAVEL_ID
    ) tc
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = tc.TRAVEL_ID
),
quartile AS (
    SELECT
        gr.TRAVEL_ID,
        gr.틈발생비율,
        pp.인당_소비액,
        NTILE(4) OVER (ORDER BY gr.틈발생비율) AS 틈비율_사분위   -- 1=틈 가장 적은 25%, 4=틈 가장 많은 25%
    FROM gap_ratio gr
    JOIN per_person pp ON pp.TRAVEL_ID = gr.TRAVEL_ID
)
SELECT
    틈비율_사분위,
    COUNT(*) AS 표본_여행수,
    ROUND(MIN(틈발생비율), 3) AS 구간_최소_틈비율,
    ROUND(MAX(틈발생비율), 3) AS 구간_최대_틈비율,
    ROUND(AVG(인당_소비액), 0) AS 평균_인당소비액
FROM quartile
GROUP BY 틈비율_사분위
ORDER BY 틈비율_사분위;
-- 가설1("틈 비율이 낮을수록 소비가 많다")이 맞다면 사분위 1(틈 적음)의
-- 평균_인당소비액이 사분위 4(틈 많음)보다 커야 합니다. 반대로 나올 수도
-- 있으니 결과를 있는 그대로 보고하고, 반대 해석(여유롭게 다니는 사람이
-- 원래 돈을 덜 쓰는 성향일 수 있음, segment.sql 한계 항목 참고)을 함께 적을 것.

-- ----------------------------------------------------------------
-- 5-2. 가설2(재방문-소비): 첫방문 vs 재방문 그룹 간 1인당 소비 비교
-- (STEP 2-3에서 단면 데이터로 확인됐다면 이 쿼리의 TRAVELER_ID 기준 대신
-- REVISIT_YN 기준으로 바꿔야 함 — 아래는 REVISIT_YN 기준 버전)
-- ----------------------------------------------------------------
WITH travel_revisit AS (
    -- 여행 안에서 REVISIT_YN='Y'인 방문지가 하나라도 있으면 그 여행을 "재방문 포함 여행"으로 봄
    SELECT TRAVEL_ID, MAX(REVISIT_YN = 'Y') AS has_revisit
    FROM tn_visit_area_info
    GROUP BY TRAVEL_ID
),
per_person AS (
    SELECT
        tc.TRAVEL_ID,
        ROUND(tc.total_amt_won / (COALESCE(cc.companion_cnt, 0) + 1), 0) AS 인당_소비액
    FROM (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS total_amt_won
        FROM (
            SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
        ) c GROUP BY TRAVEL_ID
    ) tc
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = tc.TRAVEL_ID
)
SELECT
    CASE WHEN tr.has_revisit = 1 THEN '재방문 포함 여행' ELSE '첫방문만 있는 여행' END AS 그룹,
    COUNT(*) AS 표본_여행수,
    ROUND(AVG(pp.인당_소비액), 0) AS 평균_인당소비액
FROM travel_revisit tr
JOIN per_person pp ON pp.TRAVEL_ID = tr.TRAVEL_ID
GROUP BY 그룹;
-- REVISIT_YN은 응답자의 "체감" 재방문 여부(자기보고)라는 한계가 있습니다.
-- STEP 3-4에서 만든 "데이터로 재계산한 재방문"과 결과가 다르면 두 정의의
-- 차이를 보고서에 반드시 명시할 것.

-- ----------------------------------------------------------------
-- 5-3. 가설3(동반유형-소비): 동반유형별 1인당 소비 비교
-- ----------------------------------------------------------------
WITH companion_type AS (
    SELECT
        t.TRAVEL_ID,
        CASE
            WHEN COALESCE(cs.companion_cnt, 0) = 0 THEN '나홀로'
            WHEN cs.companion_cnt = 1 THEN '2인 동반'
            ELSE '3인 이상 동반'
        END AS 동반유형
    FROM tn_travel t
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cs
           ON cs.TRAVEL_ID = t.TRAVEL_ID
),
per_person AS (
    SELECT
        tc.TRAVEL_ID,
        ROUND(tc.total_amt_won / (COALESCE(cc.companion_cnt, 0) + 1), 0) AS 인당_소비액
    FROM (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS total_amt_won
        FROM (
            SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
        ) c GROUP BY TRAVEL_ID
    ) tc
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = tc.TRAVEL_ID
)
SELECT
    ct.동반유형,
    COUNT(*) AS 표본_여행수,
    ROUND(AVG(pp.인당_소비액), 0) AS 평균_인당소비액,
    ROUND(STDDEV(pp.인당_소비액), 0) AS 표준편차_인당소비액
FROM companion_type ct
JOIN per_person pp ON pp.TRAVEL_ID = ct.TRAVEL_ID
GROUP BY ct.동반유형
ORDER BY 평균_인당소비액 DESC;
-- 가설3("나홀로가 가족 동반보다 1인당 소비가 크다")을 검정하려면 '나홀로'
-- 행의 평균_인당소비액과 '3인 이상 동반'(가족 근사치) 행을 비교하면 됩니다.
-- '2인 동반'이 커플인지 부모자녀인지는 STEP 2-5의 REL_CD로 더 쪼개서 봐야 정확함.


-- ================================================================
-- STEP 6. 특이 이벤트/이상치 재확인 (계획서 4단계)
-- ----------------------------------------------------------------
-- STEP 5에서 특정 그룹의 평균을 크게 흔든 여행(TRAVEL_ID)이 있는지 확인.
-- "평균을 흔든다"는 것은 그 그룹 평균에서 표준편차 대비 많이 벗어난 값이라는 뜻.
-- ================================================================
WITH per_person AS (
    SELECT
        tc.TRAVEL_ID,
        ROUND(tc.total_amt_won / (COALESCE(cc.companion_cnt, 0) + 1), 0) AS 인당_소비액
    FROM (
        SELECT TRAVEL_ID, SUM(PAYMENT_AMT_WON) AS total_amt_won
        FROM (
            SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_activity_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_adv_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_lodge_consume_his
            UNION ALL SELECT TRAVEL_ID, PAYMENT_AMT_WON FROM tn_mvmn_consume_his
        ) c GROUP BY TRAVEL_ID
    ) tc
    LEFT JOIN (SELECT TRAVEL_ID, COUNT(*) AS companion_cnt FROM tn_companion_info GROUP BY TRAVEL_ID) cc
           ON cc.TRAVEL_ID = tc.TRAVEL_ID
),
stats AS (
    SELECT AVG(인당_소비액) AS 전체평균, STDDEV(인당_소비액) AS 전체표준편차 FROM per_person
)
SELECT
    t.TRAVEL_ID,
    t.TRAVEL_START_YMD,
    t.TRAVEL_END_YMD,
    pp.인당_소비액,
    ROUND((pp.인당_소비액 - s.전체평균) / NULLIF(s.전체표준편차, 0), 2) AS 표준화_편차   -- 절대값이 클수록 전체 평균에서 많이 벗어난 이상치
FROM per_person pp
JOIN tn_travel t ON t.TRAVEL_ID = pp.TRAVEL_ID
CROSS JOIN stats s
ORDER BY ABS((pp.인당_소비액 - s.전체평균) / NULLIF(s.전체표준편차, 0)) DESC
LIMIT 20;
-- 위에서 나온 TRAVEL_ID를 아래처럼 직접 열어서 "그 날짜에 무슨 일이
-- 있었는지"(방문지, 소비내역)를 확인하고, STEP 1-15의 방식으로 날짜·지역
-- 쏠림과 겹치는지 대조하세요.
SELECT VISIT_ORDER, VISIT_AREA_NM, VISIT_START_YMD, VISIT_AREA_TYPE_CD
FROM tn_visit_area_info
WHERE TRAVEL_ID = '여기에_위에서_나온_TRAVEL_ID_입력'
ORDER BY VISIT_ORDER;


-- ================================================================
-- STEP 7. 결과 종합 체크리스트 (계획서 5단계 — 쿼리 없음, 보고 형식 안내)
-- ----------------------------------------------------------------
-- STEP 5의 결과를 노션 트래커에 정리할 때, 데이터분석 보고 7원칙 순서를
-- 그대로 따를 것:
--   1) 표: STEP 5-1/5-2/5-3의 그룹별 평균·표본수 표를 그대로 붙여넣기
--   2) 차트: 위 표를 막대그래프로(Y축 0부터 시작 — 원칙 7)
--   3) 핵심발견 3개: 세 가설 각각에 대해 "그룹 간 차이가 있었다/없었다"를
--      숫자와 함께 서술 (인과 단정 금지 — 원칙 4, "상관관계 수준" 표현 사용)
--   4) 한계 2줄: 최소한 "① 2023년 수도권 자체 수집 표본, 전국/타 연도
--      일반화 불가" + "② RESIDENCE_TIME_MIN·gap_minutes가 30분 단위로만
--      기록돼 30분 미만 유휴시간은 관측 불가"는 반드시 포함
--   5) 결론마다 반대 해석 1개: segment.sql 파일 맨 아래 "한계 및 반대 해석"
--      문단을 참고해 각 가설 결론 옆에 한 줄씩 추가
-- ================================================================
