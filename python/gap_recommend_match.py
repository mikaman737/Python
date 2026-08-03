# %%
# "틈" 시간 + 근처 방문지 추천 매칭
# SQL/JeongTaeChoi/Read/powerbirangers_gap_recommend.sql의 두 결과셋(틈 목록, 후보 풀)을
# 받아서, 거리·시간 매칭은 여기서(pandas/numpy) 처리한다.
# 이유: 틈(약 15,000건) x 후보(약 1,600건) 전체를 SQL에서 Haversine으로 직접
#       교차 계산하면 좌표 인덱스가 없어 Aiven 무료 티어 서버 임시 디스크가
#       부족해 실패한다(실제로 "No space left on device" 에러 발생).
#       두 결과셋 크기는 로컬 벡터 연산으로는 가벼워서 여기서 처리하는 게 안전하다.
import os
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

env_path = os.path.join(os.path.dirname(__file__), ".env")
load_dotenv(env_path)
env_dir = os.path.dirname(env_path)

HOST = os.environ["AIVEN_HOST"]
PORT = int(os.environ["AIVEN_PORT"])
USER = os.environ["AIVEN_USER"]
PASSWORD = os.environ["AIVEN_PASSWORD"]
DB = os.environ["AIVEN_DB"]
CA_CERT_PATH = os.path.join(env_dir, os.environ["AIVEN_CA_CERT_PATH"])

engine = create_engine(
    f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}?charset=utf8mb4",
    connect_args={"ssl_ca": CA_CERT_PATH, "ssl_verify_cert": True},
)

# %%
# 1) 틈(gap) 목록 — powerbirangers_gap_recommend.sql의 첫 번째 쿼리와 동일
GAP_SQL = """
WITH arrivals AS (
    SELECT
        v.TRAVEL_ID,
        v.VISIT_AREA_ID,
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS gap_candidate_key,
        v.VISIT_AREA_NM AS gap_location_nm,
        v.X_COORD AS gap_x,
        v.Y_COORD AS gap_y,
        v.VISIT_ORDER,
        m.END_DT_MIN AS arrive_dt,
        LEAD(m.END_DT_MIN) OVER (PARTITION BY v.TRAVEL_ID ORDER BY v.VISIT_ORDER) AS next_arrive_dt
    FROM tn_visit_area_info v
    JOIN tn_move_his m
      ON m.TRAVEL_ID = v.TRAVEL_ID AND m.TRIP_ID = v.VISIT_AREA_ID
    WHERE m.END_DT_MIN IS NOT NULL
)
SELECT
    TRAVEL_ID, VISIT_AREA_ID, gap_candidate_key, gap_location_nm, gap_x, gap_y,
    arrive_dt, next_arrive_dt,
    TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) AS gap_minutes
FROM arrivals
WHERE next_arrive_dt IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, arrive_dt, next_arrive_dt) > 0
  AND gap_x IS NOT NULL AND gap_y IS NOT NULL
"""

# 2) 추천 후보 풀 — powerbirangers_candidate_pool.sql과 동일 로직
POOL_SQL = """
WITH base AS (
    SELECT
        v.*,
        COALESCE(NULLIF(v.POI_ID, ''), CONCAT('NM:', v.VISIT_AREA_NM)) AS candidate_key,
        cb.cd_nm AS type_nm
    FROM tn_visit_area_info v
    LEFT JOIN tc_codeb cb
           ON cb.cd_a = 'VIS' AND cb.cd_b = v.VISIT_AREA_TYPE_CD
    WHERE v.VISIT_AREA_TYPE_CD NOT IN ('9','12','21','22','23','24')
),
type_mode AS (
    SELECT
        candidate_key, type_nm,
        ROW_NUMBER() OVER (PARTITION BY candidate_key ORDER BY COUNT(*) DESC, type_nm) AS rn
    FROM base
    GROUP BY candidate_key, type_nm
)
SELECT
    b.candidate_key,
    MIN(b.VISIT_AREA_NM)                AS visit_area_nm,
    tm.type_nm                           AS visit_area_type_nm,
    COUNT(*)                             AS visit_cnt,
    ROUND(AVG(b.RESIDENCE_TIME_MIN), 1)  AS avg_residence_min,
    ROUND(AVG(b.DGSTFN), 2)              AS avg_satisfaction,
    ROUND(AVG(b.REVISIT_INTENTION), 2)   AS avg_revisit_intention,
    ROUND(AVG(b.RCMDTN_INTENTION), 2)    AS avg_recommend_intention,
    MIN(b.X_COORD)                       AS x_coord,
    MIN(b.Y_COORD)                       AS y_coord
FROM base b
JOIN type_mode tm ON tm.candidate_key = b.candidate_key AND tm.rn = 1
GROUP BY b.candidate_key, tm.type_nm
HAVING COUNT(*) >= 2
   AND MIN(b.X_COORD) IS NOT NULL AND MIN(b.Y_COORD) IS NOT NULL
"""

with engine.connect() as conn:
    gaps = pd.read_sql(text(GAP_SQL), conn)
    pool = pd.read_sql(text(POOL_SQL), conn)

print("gaps:", len(gaps), "pool:", len(pool))

# %%
# 벡터화 Haversine 거리 (km) — gaps(N) x pool(M) 전체 거리 행렬을 한 번에 계산
EARTH_RADIUS_KM = 6371.0


def haversine_matrix(lat1, lon1, lat2, lon2):
    lat1 = np.radians(lat1)[:, None]
    lon1 = np.radians(lon1)[:, None]
    lat2 = np.radians(lat2)[None, :]
    lon2 = np.radians(lon2)[None, :]
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = np.sin(dlat / 2) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon / 2) ** 2
    return 2 * EARTH_RADIUS_KM * np.arcsin(np.sqrt(np.clip(a, 0, 1)))


DIST_LIMIT_KM = 5.0   # 도보/짧은 이동 범위로 임의 설정 — 팀 논의로 조정 필요
TOP_N = 5             # 틈 하나당 추천 개수

dist = haversine_matrix(
    gaps["gap_y"].to_numpy(dtype=float), gaps["gap_x"].to_numpy(dtype=float),
    pool["y_coord"].to_numpy(dtype=float), pool["x_coord"].to_numpy(dtype=float),
)  # shape (n_gaps, n_pool)

# %%
# 매칭 조건: 거리 <= 5km, 체류시간 <= 틈 시간, 틈이 난 그 자리 자체는 제외
gap_minutes = gaps["gap_minutes"].to_numpy(dtype=float)[:, None]          # (n_gaps, 1)
avg_residence = pool["avg_residence_min"].to_numpy(dtype=float)[None, :]  # (1, n_pool)

same_place = (
    gaps["gap_candidate_key"].to_numpy()[:, None] == pool["candidate_key"].to_numpy()[None, :]
)

valid = (dist <= DIST_LIMIT_KM) & (avg_residence <= gap_minutes) & (~same_place)

gap_idx, pool_idx = np.where(valid)

# VISIT_AREA_ID: 같은 TRAVEL_ID에서 동명 방문지가 두 번 나올 경우
# gap_location_nm만으로는 구분이 안 돼서 식별용으로 추가
matched = pd.DataFrame({
    "TRAVEL_ID": gaps["TRAVEL_ID"].to_numpy()[gap_idx],
    "VISIT_AREA_ID": gaps["VISIT_AREA_ID"].to_numpy()[gap_idx],
    "gap_location_nm": gaps["gap_location_nm"].to_numpy()[gap_idx],
    "arrive_dt": gaps["arrive_dt"].to_numpy()[gap_idx],
    "gap_minutes": gaps["gap_minutes"].to_numpy()[gap_idx],
    "candidate_key": pool["candidate_key"].to_numpy()[pool_idx],
    "visit_area_nm": pool["visit_area_nm"].to_numpy()[pool_idx],
    "visit_area_type_nm": pool["visit_area_type_nm"].to_numpy()[pool_idx],
    "visit_cnt": pool["visit_cnt"].to_numpy()[pool_idx],
    "avg_residence_min": pool["avg_residence_min"].to_numpy()[pool_idx],
    "avg_satisfaction": pool["avg_satisfaction"].to_numpy()[pool_idx],
    "avg_revisit_intention": pool["avg_revisit_intention"].to_numpy()[pool_idx],
    "avg_recommend_intention": pool["avg_recommend_intention"].to_numpy()[pool_idx],
    "distance_km": dist[gap_idx, pool_idx],
})

print("matched rows:", len(matched))

# %%
# 틈(gap)당 상위 TOP_N개만 (거리 가까운 순 → 만족도 높은 순)
GAP_KEY = ["TRAVEL_ID", "VISIT_AREA_ID", "gap_location_nm", "arrive_dt"]

matched = matched.sort_values(
    GAP_KEY + ["distance_km", "avg_satisfaction"],
    ascending=[True, True, True, True, True, False],
)
matched["rank_in_gap"] = matched.groupby(GAP_KEY).cumcount() + 1

recommend = matched[matched["rank_in_gap"] <= TOP_N].reset_index(drop=True)
print("gaps with at least 1 recommendation:", recommend.groupby(GAP_KEY).ngroups)
recommend.head(20)

# %%
# 틈 목록(gaps) 전체 + 추천 결과를 합쳐서 팀 공유용 CSV로 저장.
# gaps에는 있지만 추천이 하나도 없는 틈(반경 5km 안에 조건 맞는 후보가 없는 경우)도
# 남기기 위해 LEFT JOIN 형태로 합친다(7원칙: 표본 누락 없이 그대로 보고).
gaps_with_recommend = gaps.merge(
    recommend.drop(columns=["gap_minutes"]), on=GAP_KEY, how="left"
)

result_dir = os.path.join(os.path.dirname(__file__), "..", "SQL", "JeongTaeChoi", "Result Query")
out_path = os.path.join(result_dir, "gap_recommend_result.csv")
gaps_with_recommend.to_csv(out_path, index=False, encoding="utf-8-sig")
print("saved:", out_path, "rows:", len(gaps_with_recommend))
print(
    "추천 없는 틈:", gaps_with_recommend["candidate_key"].isna().sum(),
    "/", len(gaps),
    f"({gaps_with_recommend['candidate_key'].isna().sum() / len(gaps) * 100:.1f}%)",
)