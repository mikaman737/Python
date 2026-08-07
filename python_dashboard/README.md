# 2023년 수도권 여행로그 EDA 대시보드

원본 CSV를 읽어 여행·소비·방문지·동선·만족도와 데이터 품질을 빠르게 확인하는 한국어 Streamlit 대시보드입니다. 원본 CSV와 HWP는 읽기 전용으로 다루며 수정·이동·삭제하지 않습니다.

## 설치와 실행

PowerShell에서 현재 프로젝트 폴더를 기준으로 실행합니다.

```powershell
py -m pip install -r python_dashboard/requirements.txt
streamlit run python_dashboard/app.py
```

`python` 명령을 사용 중인 환경이라면 첫 줄을 아래처럼 바꿔도 됩니다.

```powershell
python -m pip install -r python_dashboard/requirements.txt
```

브라우저가 자동으로 열리지 않으면 터미널에 표시된 `Local URL`을 엽니다.

## 원본 파일 위치와 인코딩

아래 12개 CSV를 현재 프로젝트 폴더 또는 그 하위 폴더에 둡니다. 앱은 모든 CSV를 다음 옵션으로 읽습니다.

```python
pd.read_csv(path, encoding="utf-8-sig", dtype=str, keep_default_na=False)
```

따라서 ID와 `ACTIVITY_DTL`, `=`로 시작하는 텍스트를 문자열로 보존합니다. 금액·날짜·체류시간에 한해서만 별도의 분석용 숫자/날짜 열을 만듭니다.

현재 프로젝트 폴더에 CSV가 없고 `여행데이터통합문서_20260730.xlsx`가 있으면, 앱은 이 통합문서의 원본 테이블 시트를 자동 연결합니다. CSV가 발견되면 CSV가 우선입니다. 두 경우 모두 원본 파일을 변경하지 않습니다.

## 생성 산출물

정상 적재 뒤 `python_dashboard/output/`에 아래 분석 테이블을 UTF-8-SIG CSV로 생성합니다.

- `fact_spend.csv`: 사전·활동·숙박·이동 소비를 세로로 통합한 소비 사실 테이블
- `travel_summary.csv`: 여행 단위 지표 및 소비 요약
- `visit_summary.csv`: `TRAVEL_ID|VISIT_AREA_ID` 방문지 단위 요약
- `data_quality_summary.csv`: 파일별 행·열·결측·키 중복·금액 이상 현황

## 조인 안전장치

- 방문지는 `TRAVEL_ID|VISIT_AREA_ID` 복합키만 사용합니다.
- 활동과 활동소비는 `TRAVEL_ID`, `VISIT_AREA_ID`, `ACTIVITY_TYPE_CD`, `ACTIVITY_TYPE_SEQ` 네 개 키를 각각 집계한 뒤 `one_to_one`으로 결합합니다.
- 소비·활동·사진·이동 이력을 직접 한 번에 병합하지 않고, 먼저 여행 또는 방문지 단위로 집계합니다.
- 모든 병합에는 pandas `validate`를 사용합니다. 왼쪽 조인에서 행 수가 증가하거나 키 검증이 실패하면 해당 병합을 즉시 중단합니다.
- 데이터 품질 탭에서 병합 전후 행 수, 양쪽 중복 키, 참조키 미매칭 수를 확인할 수 있습니다.

## 참고

이 작업 폴더에 지정 CSV가 없으면 앱은 어떤 원본도 생성·수정하지 않고 누락 파일 목록만 표시합니다. CSV를 배치한 뒤 페이지를 새로고침하면 분석을 실행합니다.
