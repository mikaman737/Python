# %%
import os
import pandas as pd
from dotenv import load_dotenv, find_dotenv
from sqlalchemy import create_engine

env_path = find_dotenv()
load_dotenv(env_path)
env_dir = os.path.dirname(env_path)

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
