# %%
import os
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

try:
    import google.colab  # noqa: F401
    IN_COLAB = True
except ImportError:
    IN_COLAB = False

# Jupyter 커널의 cwd가 워크스페이스 루트일 때 find_dotenv()가
# python/.env(하위 폴더)를 못 찾는 문제가 있어, cwd 기준으로
# 후보 경로를 직접 탐색한다.
def _find_env_file():
    cwd = Path.cwd()
    search_roots = [cwd, *cwd.parents]
    candidates = [root / rel for root in search_roots for rel in (".env", "python/.env")]
    for candidate in candidates:
        if candidate.is_file():
            return candidate

    if IN_COLAB:
        # 코랩 호스팅 런타임은 로컬 PC와 별개의 VM이라 위 경로 탐색으로는
        # .env를 찾을 수 없다. 구글 드라이브를 마운트해서 프로젝트가 있는
        # "파워BI레인저/Python" 아래의 python/.env를 찾는다.
        from google.colab import drive
        drive.mount("/content/drive")
        matches = sorted(Path("/content/drive/MyDrive").glob("파워BI레인저/**/python/.env"))
        if matches:
            return matches[0]

    raise FileNotFoundError(".env 파일을 찾을 수 없습니다. python/.env가 존재하는지 확인하세요.")

env_path = _find_env_file()
load_dotenv(env_path)
env_dir = env_path.parent

HOST = os.environ["AIVEN_HOST"]
PORT = int(os.environ["AIVEN_PORT"])
USER = os.environ["AIVEN_USER"]
PASSWORD = os.environ["AIVEN_PASSWORD"]
DB = os.environ["AIVEN_DB"]
CA_CERT_PATH = os.path.join(env_dir, os.environ["AIVEN_CA_CERT_PATH"])

engine = create_engine(
    f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DB}",
    connect_args={"ssl_ca": CA_CERT_PATH, "ssl_verify_cert": True}
)

# 연결 테스트
df = pd.read_sql("SELECT COUNT(*) AS cnt FROM tn_travel", engine)
print(df)

# %%
import matplotlib.pyplot as plt
import matplotlib.font_manager as fm

font_path = "C:/Windows/Fonts/malgun.ttf"
fm.fontManager.addfont(font_path)
font_name = fm.FontProperties(fname=font_path).get_name()

plt.rcParams["font.family"] = font_name
plt.rcParams["font.sans-serif"] = [font_name]
plt.rcParams["axes.unicode_minus"] = False

print("등록된 폰트:", font_name)

# 텍스트/데이터프레임 출력 테스트
test_df = pd.DataFrame({
    "month": ["1월", "2월", "3월", "4월", "5월"],
    "visitors": [120, 150, 90, 200, 170]
})
print(test_df)
test_df

# %%
# 그래프 출력 테스트
plt.figure(figsize=(6, 4))
plt.plot(test_df["month"], test_df["visitors"], marker="o")
plt.title("월별 방문자 수 (테스트)")
plt.xlabel("월")
plt.ylabel("방문자 수")
plt.show()

# %%
# TRAVEL_START_YMD별 여행 시작 건수(cnt) 조회
query = """
SELECT tt.TRAVEL_START_YMD, COUNT(tt.TRAVEL_START_YMD) AS cnt
FROM tn_travel tt
GROUP BY TRAVEL_START_YMD
ORDER BY cnt DESC;
"""
cnt_df = pd.read_sql(query, engine)

# %%
# 표: cnt 기초 통계량 + 상/하위 날짜
print(f"표본 개수(날짜 수): {len(cnt_df)}")
print(cnt_df["cnt"].describe())
print("\ncnt 상위 5개 날짜")
print(cnt_df.head())
print("\ncnt 하위 5개 날짜")
print(cnt_df.sort_values("cnt").head())

# %%
# 차트: cnt 값 자체의 분포(히스토그램) - Y축 0부터 시작
plt.figure(figsize=(8, 5))
plt.hist(cnt_df["cnt"], bins=30, color="#4C72B0", edgecolor="white")
plt.title("일별 여행 시작 건수(cnt)의 분포")
plt.xlabel("cnt (TRAVEL_START_YMD 하루당 여행 시작 건수)")
plt.ylabel("해당 cnt를 가진 날짜 수")
plt.ylim(bottom=0)
plt.show()
