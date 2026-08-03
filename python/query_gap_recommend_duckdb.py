# %%
# gap_recommend_result.csv를 DuckDB로 SQL 조회
# 공유 DB(Aiven)에는 올리지 않고, 로컬에서만 CSV를 SQL로 들여다보고 싶을 때 사용.
# gap_recommend_match.py를 먼저 실행해 CSV를 최신 상태로 만들어둔 뒤 이 스크립트를 쓴다.
import os
import duckdb

CSV_PATH = os.path.join(
    os.path.dirname(__file__), "..", "SQL", "JeongTaeChoi", "Result Query", "gap_recommend_result.csv"
)

con = duckdb.connect()
con.execute(f"CREATE VIEW gap_recommend AS SELECT * FROM read_csv_auto('{CSV_PATH}')")

# %%
# 특정 여행(TRAVEL_ID) 하나를 골라 틈 순서대로 추천을 확인하는 예시 쿼리
sample_travel_id = con.execute(
    "SELECT TRAVEL_ID FROM gap_recommend GROUP BY TRAVEL_ID HAVING COUNT(*) >= 5 LIMIT 1"
).fetchone()[0]

df = con.execute(f"""
    SELECT
        gap_location_nm,
        arrive_dt,
        gap_minutes,
        rank_in_gap,
        visit_area_nm,
        visit_area_type_nm,
        distance_km,
        avg_satisfaction
    FROM gap_recommend
    WHERE TRAVEL_ID = '{sample_travel_id}'
    ORDER BY arrive_dt, rank_in_gap
""").df()

print("sample TRAVEL_ID:", sample_travel_id)
print(df.to_string(index=False))

# %%
# 여행 전체 기준 요약 통계(추천 없는 틈 비율, 평균 추천 개수 등)도 SQL로 바로 확인 가능
summary = con.execute("""
    SELECT
        COUNT(DISTINCT TRAVEL_ID || '_' || VISIT_AREA_ID || '_' || arrive_dt) AS gap_cnt,
        SUM(CASE WHEN candidate_key IS NULL THEN 1 ELSE 0 END)               AS rows_without_recommend,
        ROUND(AVG(distance_km), 2)                                            AS avg_distance_km
    FROM gap_recommend
""").df()
print(summary)