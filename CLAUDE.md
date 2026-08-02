# 파워BI레인저 팀 프로젝트

국내 여행로그 데이터(한국관광공사, 2023년 수도권 기준)를 분석해 여행 관련 서비스를 기획하는 5인 팀 프로젝트. 프로젝트 기간 2026-07-24 ~ 2026-09-04. 진행 상황과 회의록은 팀 노션 워크스페이스("파워Bi레인저 대시보드")에 기록되며, Claude Code에서 Notion MCP 커넥터로 조회 가능하다.

## 팀 구성

| 역할 | 담당 |
|---|---|
| 조장 | 김소영 |
| 일정관리 | 최정태 |
| 서기 | 이혜정 |
| 총무 | 정재윤 |
| 데이터마스터 | 최우진 |

## 현재 방향

- 원본 데이터는 국내 여행 "로그" 데이터라 일반 매출 데이터와 성격이 다름 — 할 수 있는 분석과 할 수 없는 분석을 구분해야 한다.
- 임시 컨셉: **"틈"** — 여행 일정의 예약된 칸이 아니라 비어있는 시간(빈 칸)을 채워주는 개인화 추천 앱.
- 접근 순서: 문제 정의를 먼저 하지 않고, EDA → 가설 → 페르소나(100개 생성 후 랜덤 추출) → 문제 정의 순으로 진행하기로 합의됨. 페르소나 설정·만다라트도 EDA의 일부로 취급한다.
- 핵심 KPI 후보: 매출(결제금액) 최우선, 세부 KPI(예약률/재구매율 등)는 로직트리로 추가 정리 예정.
- 다음 회의: 8/4(화) 오전 10시.

## 데이터 스키마 핵심 규칙

- **방문자 식별 조인은 반드시 `TRAVEL_ID` + `VISIT_AREA_ID` 복합키를 사용**한다 (단독 컬럼으로 조인 금지).
- Power BI에서는 TRAVELER_ID ↔ TRIP_ID를 두 번 조인해야 하는 구조.
- `VISIT_AREA_ID`는 `연월일000순서` 형식이며 `TRAVEL_ID`와 함께일 때만 의미가 있다.
- 코드/ID/SEQ 계열 컬럼은 숫자 오버플로우·앞자리 0 손실을 막기 위해 전부 `VARCHAR`로 고정한다([SQL/powerbirangers_Createtable.sql](SQL/powerbirangers_Createtable.sql) 참고).
- 결측치·0원 소비·이중 기록(숙소 등) 등 데이터 품질 이슈가 다수 있음 — 전처리 시 근거를 남기고 임의로 추정하지 않는다.

## 디렉터리 구조

- `Description/` — 원본 데이터설명서(hwp), ERD 이미지
- `Excel/Data/2023/` — 국내 여행로그 데이터 원본 CSV/XLSX (13종 테이블: tn_traveller_master, tn_travel, tn_visit_area_info, tn_activity_his, tn_activity_consume_his, tn_move_his, tn_mvmn_consume_his, tn_lodge_consume_his, tn_adv_consume_his, tn_companion_info, tn_tour_photo, tc_sgg, tc_codea, tc_codeb)
- `SQL/` — Aiven MySQL 8.4용 DDL(`powerbirangers_Createtable.sql`), 통합 쿼리(`powerbirangers_all.sql`), 분석 쿼리(예: `powerbirangers_gender_analysis.sql`), `Result Query/`에 쿼리 결과 CSV
- `python/` — `powerbirangers.py` (DB 연결 및 EDA 스크립트), `.env`(Aiven 접속정보, 커밋 금지)
- `PowerBI/` — .pbix 리포트
- `Service/` — 서비스 기획 관련 자료

## 기술 스택

- **DB**: Aiven MySQL 8.4, utf8mb4. `python/.env`에 접속정보(AIVEN_HOST/PORT/USER/PASSWORD/DB/CA_CERT_PATH) 저장, SSL 인증서 필수.
- **Python**: pandas, sqlalchemy(pymysql), matplotlib, python-dotenv. `python/powerbirangers.py`는 `# %%` 셀 단위로 구성된 스크립트(Jupyter 인터랙티브 실행 전제).
- **BI**: Power BI (.pbix)
- **DB 접속 시 반드시 `python/.env`와 CA 인증서 경로를 통해서만 연결한다. 자격 증명을 코드에 하드코딩하지 않는다.**

## 팀 운영 원칙 (노션 "규칙 사항 및 원칙" 기준)

- **git 훅 활성화 (클론 후 최초 1회 필수)**: `git config core.hooksPath .githooks` 실행. origin에 아직 받지 않은 새 커밋이 있으면 커밋·푸시가 막히고 pull을 안내한다(브랜치 없이 main에 바로 커밋하는 방식이므로 이 안전장치가 필요).
- 회의는 최소 주 2회(월·금), 진행 상황은 수시 공유.
- 각자 개인 이름 채팅방에서 분석 질문 진행, 공용 채팅방은 의사결정 전용.
- 단일 파일 80MB 초과 시 프로젝트 직접 업로드 불가 → 구글 드라이브 업로드 후 연동 참조.
- **데이터분석 보고 7원칙**(모든 분석 응답에 적용):
  1. 데이터에 없는 사실은 지어내지 않고 "데이터로는 알 수 없음"이라 답한다.
  2. 숫자 계산 시 산식·기준·기간을 먼저 밝힌다.
  3. 전처리(빈칸/이상치/중복 처리) 과정을 보고한다.
  4. 인과관계를 단정하지 않고 근거를 나눠 제시한다.
  5. 표본 개수와 시점을 밝히고 함부로 일반화하지 않는다.
  6. 결론마다 반대 해석을 1개 덧붙인다.
  7. 출력은 표 → 차트 → 핵심발견 3개 → 한계 2줄 순서로 고정, 차트 Y축은 0부터 시작.
- 개인별 트래커는 날짜별이 아닌 버전(v1→v2→…) 누적 방식(새 요약을 최상단에 추가).
- ERD와 실제 데이터 파일 간 불일치는 AI가 추측하지 않고 팀이 직접 대조 검증한다.
- 비밀번호·API 키 등은 노션/드라이브에 평문 기록 금지.

## 참고

- 노션 대시보드: "파워Bi레인저 대시보드" (KPI, 프로젝트, 할일, 체크리스트, 마일스톤, 회의록, 자료, 데이터분석 트래커 DB 포함)
- 추가 외부 데이터 후보: KOSIS 국민여행조사(여행소비금액), 한국관광데이터랩