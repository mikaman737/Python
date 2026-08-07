"""2023년 수도권 여행로그 탐색용 Streamlit 대시보드.

원본은 읽기 전용으로 취급하며, 이 파일이 생성하는 산출물은 output/에만 둔다.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any
import re

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st


st.set_page_config(page_title="2023 수도권 여행로그 EDA", page_icon="🧭", layout="wide")

BASE_DIR = Path(__file__).resolve().parent
DATA_ROOT = BASE_DIR.parent
OUTPUT_DIR = BASE_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

FILES = {
    "여행객": "tn_traveller_master_여행객 Master_E.csv",
    "여행": "tn_travel_여행_E.csv",
    "방문지": "tn_visit_area_info_방문지정보_E.csv",
    "활동": "tn_activity_his_활동내역_E.csv",
    "활동 소비": "tn_activity_consume_his_활동소비내역_E.csv",
    "사전 소비": "tn_adv_consume_his_사전소비내역_E.csv",
    "숙박 소비": "tn_lodge_consume_his_숙박소비내역_E.csv",
    "이동 소비": "tn_mvmn_consume_his_이동수단소비내역_E.csv",
    "이동 이력": "tn_move_his_이동내역_E.csv",
    "동반자": "tn_companion_info_동반자정보_E.csv",
    "관광사진": "tn_tour_photo_관광사진_E.csv",
    "시군구 코드": "tc_sgg_시군구코드.csv",
}

# 현재 폴더의 통합문서 시트명에도 대응한다. CSV가 있으면 CSV를 항상 우선한다.
EXCEL_SHEET_TOKENS = {
    "여행객": "tn_traveller_master", "여행": "tn_travel_", "방문지": "tn_visit_area_info",
    "활동": "tn_activity_his", "활동 소비": "tn_activity_consume_his",
    "사전 소비": "tn_adv_consume_his", "숙박 소비": "tn_lodge_consume_his",
    "이동 소비": "tn_mvmn_consume_his", "이동 이력": "tn_move_his",
    "동반자": "tn_companion_info", "관광사진": "tn_tour_photo", "시군구 코드": "tc_codea",
}

# 실제 배포본의 열 이름이 조금 달라도 대시보드가 동작하도록 후보를 둔다.
CANDIDATES = {
    "travel_id": ["TRAVEL_ID", "여행ID", "여행_ID"],
    "traveller_id": ["TRAVELER_ID", "TRAVELLER_ID", "USER_ID", "여행객ID", "여행객_ID"],
    "visit_id": ["VISIT_AREA_ID", "방문지ID", "방문지_ID"],
    "activity_type": ["ACTIVITY_TYPE_CD", "ACTIVITY_TYPE", "활동유형코드"],
    "activity_seq": ["ACTIVITY_TYPE_SEQ", "ACTIVITY_SEQ", "활동유형순번", "활동순번"],
    "amount": ["PAYMENT_AMT", "PAYMENT_AMT_WON", "SPEND_AMT", "CONSUME_AMT", "COST_AMT", "AMT", "결제금액", "소비금액", "금액"],
    "payment_dt": ["PAYMENT_DT", "PAYMENT_YMD", "PAYMENT_DATE", "결제일자", "결제일"],
    "payment_mthd": ["PAYMENT_MTHD_SE", "PAYMENT_METHOD", "결제수단구분", "결제수단"],
    "store": ["STORE_NM", "STORE_NAME", "SHOP_NM", "상호명", "소비처명", "가맹점명"],
    "sgg": ["SGG_CD", "SGG_CODE", "시군구코드"],
    "start_dt": ["TRAVEL_START_YMD", "TRAVEL_START_DT", "TRAVEL_START_DATE", "여행시작일", "여행시작일자"],
    "end_dt": ["TRAVEL_END_YMD", "TRAVEL_END_DT", "TRAVEL_END_DATE", "여행종료일", "여행종료일자"],
    "purpose": ["TRAVEL_PURPOSE", "TRAVEL_MOTIVE", "TRAVEL_MISSION", "여행목적", "여행목적코드"],
    "gender": ["GENDER", "SEX", "성별"],
    "age": ["AGE_GRP", "AGE_GROUP", "AGE", "연령대", "연령"],
    "income": ["INCOME", "INCOME_GRP", "소득", "소득수준"],
    "visit_order": ["VISIT_ORDER", "VISIT_SEQ", "방문순서", "방문순번"],
    "visit_name": ["VISIT_AREA_NM", "VISIT_AREA_NAME", "방문지명"],
    "visit_type": ["VISIT_AREA_TYPE_CD", "VISIT_AREA_TYPE", "방문지유형", "방문지유형코드"],
    "stay": ["STAY_TM", "STAY_TIME", "STAY_MIN", "체류시간", "체류시간분"],
    "satisfaction": ["SATISFACTION", "SATISFACTION_SCORE", "만족도"],
    "revisit": ["REVISIT_INTENTION", "REVISIT_YN", "재방문의향"],
    "recommend": ["RECOMMEND_INTENTION", "RECOMMEND_YN", "추천의향"],
    "move_type": ["MVMN_TYPE_CD", "MOVE_TYPE_CD", "TRANSPORT_TYPE", "이동수단", "이동수단코드"],
    "origin": ["START_AREA_NM", "ORIGIN_NM", "출발지명", "출발지"],
    "destination": ["END_AREA_NM", "DEST_NM", "도착지명", "도착지"],
}


def find_col(df: pd.DataFrame, name: str) -> str | None:
    """후보명 우선, 그 다음 공백/대소문자를 무시해 컬럼을 찾는다."""
    cols = list(df.columns)
    norm = {re.sub(r"[\s_\-]", "", str(c)).upper(): c for c in cols}
    for c in CANDIDATES[name]:
        if c in df.columns:
            return c
        hit = norm.get(re.sub(r"[\s_\-]", "", c).upper())
        if hit:
            return hit
    return None


def s_col(df: pd.DataFrame, name: str, default: str = "") -> pd.Series:
    col = find_col(df, name)
    return df[col].astype(str) if col else pd.Series(default, index=df.index, dtype="object")


def num_col(df: pd.DataFrame, name: str) -> pd.Series:
    raw = s_col(df, name, "")
    # 원본 문자열은 그대로 두고 분석용 열만 숫자로 변환한다.
    return pd.to_numeric(raw.str.replace(",", "", regex=False).str.replace("원", "", regex=False), errors="coerce")


def date_col(df: pd.DataFrame, name: str) -> pd.Series:
    raw = s_col(df, name, "")
    return pd.to_datetime(raw.str.strip(), errors="coerce")


def key_count(df: pd.DataFrame, cols: list[str]) -> int:
    if not cols or any(c not in df for c in cols):
        return 0
    return int(df.duplicated(cols, keep=False).sum())


def audited_merge(
    left: pd.DataFrame, right: pd.DataFrame, *, on: list[str] | str,
    how: str, validate: str, name: str, audit: list[dict[str, Any]],
) -> pd.DataFrame:
    keys = [on] if isinstance(on, str) else on
    before = len(left)
    duplicate_left = key_count(left, keys)
    duplicate_right = key_count(right, keys)
    unmatched = int((~left[keys].merge(right[keys].drop_duplicates(), on=keys, how="left", indicator=True)["_merge"].eq("both")).sum())
    try:
        result = left.merge(right, on=keys, how=how, validate=validate)
    except Exception as exc:
        audit.append({"병합": name, "병합 전 행 수": before, "병합 후 행 수": np.nan,
                      "왼쪽 중복 키": duplicate_left, "오른쪽 중복 키": duplicate_right,
                      "참조키 미매칭": unmatched, "상태": f"중단: {exc}"})
        raise ValueError(f"안전하지 않은 병합({name})을 중단했습니다: {exc}") from exc
    # left join 기준으로 행 증가가 허용되지 않는 검증(집계 테이블은 1:1 또는 m:1만 사용).
    if how == "left" and len(result) > before:
        audit.append({"병합": name, "병합 전 행 수": before, "병합 후 행 수": len(result),
                      "왼쪽 중복 키": duplicate_left, "오른쪽 중복 키": duplicate_right,
                      "참조키 미매칭": unmatched, "상태": "중단: 행 수 증가"})
        raise ValueError(f"조인으로 행 수가 증가하여 병합을 중단했습니다: {name}")
    audit.append({"병합": name, "병합 전 행 수": before, "병합 후 행 수": len(result),
                  "왼쪽 중복 키": duplicate_left, "오른쪽 중복 키": duplicate_right,
                  "참조키 미매칭": unmatched, "상태": "성공"})
    return result


def locate_files() -> tuple[dict[str, tuple[Path, str | None]], list[str]]:
    """CSV 우선 탐색, 없으면 현재 폴더의 통합 XLSX 시트를 원본으로 연결한다."""
    found, missing = {}, []
    for label, fname in FILES.items():
        direct = DATA_ROOT / fname
        candidates = [direct] if direct.exists() else list(DATA_ROOT.rglob(fname))
        # output 디렉터리는 다시 입력으로 읽지 않는다.
        candidates = [p for p in candidates if OUTPUT_DIR not in p.parents]
        found[label] = (candidates[0], None) if candidates else None
        if not candidates:
            missing.append(fname)
    if not missing:
        return found, []

    workbooks = [p for p in DATA_ROOT.rglob("*.xlsx") if OUTPUT_DIR not in p.parents and not p.name.startswith("~$")]
    if not workbooks:
        return found, missing
    # pandas/openpyxl로 시트 목록만 읽으며 통합문서와 원본을 변경하지 않는다.
    try:
        book = pd.ExcelFile(workbooks[0], engine="openpyxl")
        sheet_lookup = {str(s).lower(): s for s in book.sheet_names}
        excel_found: dict[str, tuple[Path, str | None]] = {}
        excel_missing = []
        for label, token in EXCEL_SHEET_TOKENS.items():
            sheet = next((original for normalized, original in sheet_lookup.items() if token.lower() in normalized), None)
            if sheet is None:
                excel_missing.append(FILES[label])
            else:
                excel_found[label] = (workbooks[0], sheet)
        if not excel_missing:
            return excel_found, []
    except Exception:
        pass
    return found, missing


@st.cache_data(show_spinner="원본 데이터를 안전하게 읽는 중입니다…")
def read_sources(file_items: tuple[tuple[str, str, str], ...]) -> dict[str, pd.DataFrame]:
    result: dict[str, pd.DataFrame] = {}
    books: dict[str, pd.ExcelFile] = {}
    for label, raw_path, sheet_name in file_items:
        # 요구된 옵션을 모든 CSV에 동일하게 적용한다. ID/ACTIVITY_DTL은 문자열 유지.
        if sheet_name:
            if raw_path not in books:
                books[raw_path] = pd.ExcelFile(raw_path, engine="openpyxl")
            result[label] = pd.read_excel(books[raw_path], sheet_name=sheet_name, dtype=str, keep_default_na=False)
        else:
            result[label] = pd.read_csv(raw_path, encoding="utf-8-sig", dtype=str, keep_default_na=False)
    return result


def visit_key(df: pd.DataFrame) -> pd.Series:
    return s_col(df, "travel_id") + "|" + s_col(df, "visit_id")


def activity_key_frame(df: pd.DataFrame) -> pd.DataFrame:
    return pd.DataFrame({
        "TRAVEL_ID": s_col(df, "travel_id"), "VISIT_AREA_ID": s_col(df, "visit_id"),
        "ACTIVITY_TYPE_CD": s_col(df, "activity_type"), "ACTIVITY_TYPE_SEQ": s_col(df, "activity_seq"),
    })


def require_fields(df: pd.DataFrame, label: str, fields: list[str]) -> None:
    """핵심 조인 키를 추정하지 않는다. 없으면 잘못된 집계를 만들지 않고 중단한다."""
    missing = ["/".join(CANDIDATES[x][:2]) for x in fields if not find_col(df, x)]
    if missing:
        raise ValueError(f"{label} 테이블의 필수 키 컬럼을 찾지 못했습니다: {', '.join(missing)}")


def make_fact_spend(src: dict[str, pd.DataFrame]) -> pd.DataFrame:
    frames = []
    for label, category in [("사전 소비", "사전 소비"), ("활동 소비", "활동 소비"),
                            ("숙박 소비", "숙박 소비"), ("이동 소비", "이동 소비")]:
        df = src[label]
        fact = pd.DataFrame({
            "TRAVEL_ID": s_col(df, "travel_id"), "SPEND_CATEGORY": category,
            "PAYMENT_DT": date_col(df, "payment_dt"), "PAYMENT_AMT_WON": num_col(df, "amount"),
            "PAYMENT_MTHD_SE": s_col(df, "payment_mthd"), "STORE_NM": s_col(df, "store"),
            "SGG_CD": s_col(df, "sgg"),
        })
        for col, semantic in [("VISIT_AREA_ID", "visit_id"), ("ACTIVITY_TYPE_CD", "activity_type"),
                              ("ACTIVITY_TYPE_SEQ", "activity_seq")]:
            if find_col(df, semantic):
                fact[col] = s_col(df, semantic)
        frames.append(fact)
    return pd.concat(frames, ignore_index=True)


def aggregate_data(src: dict[str, pd.DataFrame]) -> tuple[dict[str, pd.DataFrame], pd.DataFrame, list[dict[str, Any]], pd.DataFrame]:
    """이력별로 먼저 집계하고, 검증된 병합만 수행한다."""
    audit: list[dict[str, Any]] = []
    travel, traveller, visit = src["여행"].copy(), src["여행객"].copy(), src["방문지"].copy()
    require_fields(travel, "여행", ["travel_id"])
    require_fields(visit, "방문지", ["travel_id", "visit_id"])
    require_fields(src["활동"], "활동", ["travel_id", "visit_id", "activity_type", "activity_seq"])
    require_fields(src["활동 소비"], "활동 소비", ["travel_id", "visit_id", "activity_type", "activity_seq"])
    for spend_label in ["사전 소비", "활동 소비", "숙박 소비", "이동 소비"]:
        require_fields(src[spend_label], spend_label, ["travel_id"])
    fact = make_fact_spend(src)

    # 방문지: 복합키가 유일한 단위이다. 중복 행은 같은 복합키로 안전하게 하나로 집계한다.
    v = pd.DataFrame({
        "TRAVEL_ID": s_col(visit, "travel_id"), "VISIT_AREA_ID": s_col(visit, "visit_id"),
        "TRAVEL_VISIT_KEY": visit_key(visit), "방문 순서": num_col(visit, "visit_order"),
        "방문지명": s_col(visit, "visit_name"), "시군구": s_col(visit, "sgg"),
        "방문지 유형": s_col(visit, "visit_type"), "체류시간(분)": num_col(visit, "stay"),
        "만족도": num_col(visit, "satisfaction"), "재방문 의향": num_col(visit, "revisit"), "추천 의향": num_col(visit, "recommend"),
    })
    visit_summary = v.groupby(["TRAVEL_ID", "VISIT_AREA_ID", "TRAVEL_VISIT_KEY"], as_index=False).agg({
        "방문 순서": "min", "방문지명": "first", "시군구": "first", "방문지 유형": "first",
        "체류시간(분)": "sum", "만족도": "mean", "재방문 의향": "mean", "추천 의향": "mean",
    })

    # 활동-활동소비는 명시된 4개 복합키로 각자 집계한 뒤 1:1 병합한다.
    a_raw, ac_raw = src["활동"], src["활동 소비"]
    a = activity_key_frame(a_raw)
    a["TRAVEL_VISIT_KEY"] = a["TRAVEL_ID"] + "|" + a["VISIT_AREA_ID"]
    a["활동 유형"] = s_col(a_raw, "activity_type")
    a_agg = a.groupby(["TRAVEL_ID", "VISIT_AREA_ID", "ACTIVITY_TYPE_CD", "ACTIVITY_TYPE_SEQ", "TRAVEL_VISIT_KEY", "활동 유형"], as_index=False).size().rename(columns={"size": "활동 수"})
    ac = activity_key_frame(ac_raw)
    ac["활동 소비"] = num_col(ac_raw, "amount")
    ac_agg = ac.groupby(["TRAVEL_ID", "VISIT_AREA_ID", "ACTIVITY_TYPE_CD", "ACTIVITY_TYPE_SEQ"], as_index=False, dropna=False)["활동 소비"].sum(min_count=1)
    activity_joined = audited_merge(a_agg, ac_agg, on=["TRAVEL_ID", "VISIT_AREA_ID", "ACTIVITY_TYPE_CD", "ACTIVITY_TYPE_SEQ"], how="left", validate="one_to_one", name="활동-활동소비(4개 복합키)", audit=audit)
    activity_joined["활동 소비"] = activity_joined["활동 소비"].fillna(0)
    activity_visit = activity_joined.groupby("TRAVEL_VISIT_KEY", as_index=False).agg({"활동 수": "sum", "활동 소비": "sum"})
    visit_summary = audited_merge(visit_summary, activity_visit, on="TRAVEL_VISIT_KEY", how="left", validate="one_to_one", name="방문지-활동 집계", audit=audit)

    photo = src["관광사진"]
    p = pd.DataFrame({"TRAVEL_ID": s_col(photo, "travel_id"), "VISIT_AREA_ID": s_col(photo, "visit_id")})
    p["TRAVEL_VISIT_KEY"] = p["TRAVEL_ID"] + "|" + p["VISIT_AREA_ID"]
    photo_visit = p.groupby("TRAVEL_VISIT_KEY", as_index=False).size().rename(columns={"size": "사진 수"})
    visit_summary = audited_merge(visit_summary, photo_visit, on="TRAVEL_VISIT_KEY", how="left", validate="one_to_one", name="방문지-사진 집계", audit=audit)
    for c in ["활동 수", "활동 소비", "사진 수"]:
        visit_summary[c] = visit_summary[c].fillna(0)

    # 여행 단위 이력을 각각 단독 집계한다. 이력 테이블끼리 직접 병합하지 않는다.
    visit_travel = visit_summary.groupby("TRAVEL_ID", as_index=False).agg(
        **{"방문지 수": ("TRAVEL_VISIT_KEY", "nunique"), "방문 체류시간(분)": ("체류시간(분)", "sum")}
    )
    move = pd.DataFrame({"TRAVEL_ID": s_col(src["이동 이력"], "travel_id"), "이동수단": s_col(src["이동 이력"], "move_type"),
                         "출발지": s_col(src["이동 이력"], "origin"), "도착지": s_col(src["이동 이력"], "destination")})
    move_travel = move.groupby("TRAVEL_ID", as_index=False).size().rename(columns={"size": "이동 수"})
    companion = pd.DataFrame({"TRAVEL_ID": s_col(src["동반자"], "travel_id")})
    companion_travel = companion.groupby("TRAVEL_ID", as_index=False).size().rename(columns={"size": "동반자 수"})
    photo_travel = p.groupby("TRAVEL_ID", as_index=False).size().rename(columns={"size": "사진 수"})
    activity_travel = activity_joined.groupby("TRAVEL_ID", as_index=False).agg(**{"활동 수": ("활동 수", "sum")})
    spend_travel = fact.pivot_table(index="TRAVEL_ID", columns="SPEND_CATEGORY", values="PAYMENT_AMT_WON", aggfunc="sum", fill_value=0).reset_index()
    spend_travel.columns.name = None
    for c in ["사전 소비", "활동 소비", "숙박 소비", "이동 소비"]:
        if c not in spend_travel: spend_travel[c] = 0.0
        spend_travel = spend_travel.rename(columns={c: c + "(원)"})

    t = pd.DataFrame({
        "TRAVEL_ID": s_col(travel, "travel_id"), "여행객 ID": s_col(travel, "traveller_id"),
        "여행 시작일": date_col(travel, "start_dt"), "여행 종료일": date_col(travel, "end_dt"),
        "여행 목적": s_col(travel, "purpose"),
    })
    # 여행 테이블은 여행ID가 유일해야 한다. 아니면 비정상 조인을 막는다.
    if t["TRAVEL_ID"].duplicated().any():
        raise ValueError("여행 테이블의 TRAVEL_ID가 중복되어 여행 단위 병합을 중단했습니다.")
    trv_id_col = find_col(traveller, "traveller_id")
    person = pd.DataFrame({"여행객 ID": s_col(traveller, "traveller_id"), "성별": s_col(traveller, "gender"),
                           "연령대": s_col(traveller, "age"), "소득": s_col(traveller, "income")})
    if person["여행객 ID"].duplicated().any() and trv_id_col:
        person = person.groupby("여행객 ID", as_index=False).agg({"성별":"first", "연령대":"first", "소득":"first"})
    if trv_id_col:
        t = audited_merge(t, person, on="여행객 ID", how="left", validate="many_to_one", name="여행-여행객", audit=audit)
    else:
        t[["성별", "연령대", "소득"]] = ""
    for piece, title in [(visit_travel,"여행-방문지 집계"), (activity_travel,"여행-활동 집계"), (move_travel,"여행-이동 집계"),
                         (companion_travel,"여행-동반자 집계"), (photo_travel,"여행-사진 집계"), (spend_travel,"여행-소비 집계")]:
        t = audited_merge(t, piece, on="TRAVEL_ID", how="left", validate="one_to_one", name=title, audit=audit)
    t["여행기간(일)"] = (t["여행 종료일"] - t["여행 시작일"]).dt.days + 1
    for col in ["방문지 수", "활동 수", "이동 수", "동반자 수", "사진 수", "방문 체류시간(분)", "사전 소비(원)", "활동 소비(원)", "숙박 소비(원)", "이동 소비(원)"]:
        if col not in t: t[col] = 0
        t[col] = t[col].fillna(0)
    spend_cols = ["사전 소비(원)", "활동 소비(원)", "숙박 소비(원)", "이동 소비(원)"]
    t["총지출(원)"] = t[spend_cols].sum(axis=1)
    t["일평균 지출(원)"] = t["총지출(원)"] / t["여행기간(일)"].replace(0, np.nan)

    # 품질 표: 파일/키/결측/음수/날짜 역전을 한 곳에 모은다.
    quality = []
    key_rules = {"여행객": [find_col(traveller,"traveller_id")], "여행": [find_col(travel,"travel_id")],
                 "방문지": [find_col(visit,"travel_id"),find_col(visit,"visit_id")],
                 "활동": [find_col(a_raw,"travel_id"),find_col(a_raw,"visit_id"),find_col(a_raw,"activity_type"),find_col(a_raw,"activity_seq")]}
    for label, df in src.items():
        amt = num_col(df, "amount")
        quality.append({"테이블": label, "행 수": len(df), "컬럼 수": len(df.columns),
                        "결측 셀 수": int((df == "").sum().sum()), "결측치 비율(%)": round(float((df == "").sum().sum() / max(df.size, 1) * 100), 2),
                        "후보 키 중복 행": key_count(df, [x for x in key_rules.get(label, []) if x]),
                        "음수 금액": int((amt < 0).sum()), "0원 결제": int((amt == 0).sum())})
    quality_df = pd.DataFrame(quality)
    anomalies = pd.DataFrame({"항목": ["날짜 역전", "이상 체류시간(음수 또는 7일 초과)"],
                              "건수": [int((t["여행기간(일)"] < 1).sum()), int(((visit_summary["체류시간(분)"] < 0) | (visit_summary["체류시간(분)"] > 10080)).sum())]})
    return {"fact_spend": fact, "travel_summary": t, "visit_summary": visit_summary, "move": move, "activity": activity_joined}, quality_df, audit, anomalies


def won(v: float | int) -> str:
    return f"₩{0 if pd.isna(v) else v:,.0f}"


def chart(fig, use_container_width: bool = True) -> None:
    fig.update_layout(margin=dict(l=10, r=10, t=50, b=10), font=dict(family="Malgun Gothic, Arial"), legend_title_text="")
    st.plotly_chart(fig, use_container_width=use_container_width)


def select_values(label: str, values: pd.Series) -> list[str]:
    choices = sorted([str(x) for x in values.dropna().unique() if str(x).strip()])
    return st.sidebar.multiselect(label, choices)


def apply_filters(data: dict[str, pd.DataFrame]) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    t, v, f = data["travel_summary"].copy(), data["visit_summary"].copy(), data["fact_spend"].copy()
    st.sidebar.header("공통 필터")
    dates = t["여행 시작일"].dropna()
    if not dates.empty:
        date_range = st.sidebar.date_input("여행 시작일 범위", value=(dates.min().date(), dates.max().date()), min_value=dates.min().date(), max_value=dates.max().date())
        if isinstance(date_range, tuple) and len(date_range) == 2:
            t = t[t["여행 시작일"].between(pd.Timestamp(date_range[0]), pd.Timestamp(date_range[1]))]
    for label, col in [("성별", "성별"), ("연령대", "연령대"), ("여행 목적", "여행 목적")]:
        selected = select_values(label, t[col])
        if selected: t = t[t[col].astype(str).isin(selected)]
    durations = st.sidebar.multiselect("여행기간", ["1일", "2일", "3일 이상"])
    if durations:
        d = t["여행기간(일)"]
        allowed = (d.eq(1) if "1일" in durations else False) | (d.eq(2) if "2일" in durations else False) | (d.ge(3) if "3일 이상" in durations else False)
        t = t[allowed]
    candidate_v = v[v["TRAVEL_ID"].isin(t["TRAVEL_ID"])]
    for label, col in [("시군구", "시군구"), ("방문지 유형", "방문지 유형")]:
        selected = select_values(label, candidate_v[col])
        if selected:
            ids = candidate_v.loc[candidate_v[col].astype(str).isin(selected), "TRAVEL_ID"].unique()
            t = t[t["TRAVEL_ID"].isin(ids)]
            candidate_v = candidate_v[candidate_v["TRAVEL_ID"].isin(ids)]
    cats = st.sidebar.multiselect("소비 유형", ["사전 소비", "활동 소비", "숙박 소비", "이동 소비"])
    f = f[f["TRAVEL_ID"].isin(t["TRAVEL_ID"])]
    if cats: f = f[f["SPEND_CATEGORY"].isin(cats)]
    # 소비 유형 필터도 여행별 평균 지출 등의 기준에 일관되게 반영한다.
    selected_spend = f.groupby("TRAVEL_ID")["PAYMENT_AMT_WON"].sum()
    t["총지출(원)"] = t["TRAVEL_ID"].map(selected_spend).fillna(0)
    t["일평균 지출(원)"] = t["총지출(원)"] / t["여행기간(일)"].replace(0, np.nan)
    return t, candidate_v, f


def overview(t: pd.DataFrame, f: pd.DataFrame) -> None:
    st.header("여행 개요")
    total_spend = f["PAYMENT_AMT_WON"].sum(min_count=1) if len(f) else 0
    c = st.columns(5)
    c[0].metric("여행 수", f"{t['TRAVEL_ID'].nunique():,}건")
    c[1].metric("여행객 수", f"{t['여행객 ID'].replace('', np.nan).nunique():,}명")
    c[2].metric("총지출", won(total_spend))
    c[3].metric("여행당 평균 지출", won(total_spend / max(t['TRAVEL_ID'].nunique(), 1)))
    c[4].metric("평균 여행기간", f"{t['여행기간(일)'].mean():.1f}일" if t['여행기간(일)'].notna().any() else "-" )
    if t.empty: st.info("선택한 조건에 해당하는 여행이 없습니다."); return
    monthly = t.assign(월=t["여행 시작일"].dt.to_period("M").astype(str)).groupby("월", as_index=False).agg(여행수=("TRAVEL_ID","nunique"), 총지출=("총지출(원)","sum"))
    col1, col2 = st.columns(2)
    with col1: chart(px.bar(monthly, x="월", y="여행수", title="월별 여행 수", labels={"월":"여행 시작 월", "여행수":"여행 수"}))
    with col2: chart(px.line(monthly, x="월", y="총지출", markers=True, title="월별 총지출 추이", labels={"월":"여행 시작 월", "총지출":"총지출(원)"}))
    purpose = t.groupby("여행 목적", as_index=False).agg(여행수=("TRAVEL_ID","nunique"), 평균지출=("총지출(원)","mean")).sort_values("여행수", ascending=False)
    col1, col2 = st.columns(2)
    with col1: chart(px.bar(purpose, x="여행 목적", y="여행수", title="여행 목적별 여행 수"))
    with col2: chart(px.bar(purpose, x="여행 목적", y="평균지출", title="여행 목적별 평균 지출", labels={"평균지출":"평균 지출(원)"}))
    dem = st.columns(3)
    for box, field, title in zip(dem, ["성별","연령대","소득"], ["성별 여행객 분포","연령대 여행객 분포","소득별 여행객 분포"]):
        with box: chart(px.bar(t.groupby(field,as_index=False)["여행객 ID"].nunique(), x=field, y="여행객 ID", title=title, labels={"여행객 ID":"여행객 수"}))


def spending(t: pd.DataFrame, f: pd.DataFrame) -> None:
    st.header("소비 분석")
    if f.empty: st.info("소비 데이터가 없습니다."); return
    by_cat = f.groupby("SPEND_CATEGORY", as_index=False)["PAYMENT_AMT_WON"].sum()
    col1,col2=st.columns(2)
    with col1: chart(px.pie(by_cat, names="SPEND_CATEGORY", values="PAYMENT_AMT_WON", title="소비 유형별 지출 비중", hole=.4, labels={"SPEND_CATEGORY":"소비 유형", "PAYMENT_AMT_WON":"지출액(원)"}))
    with col2: chart(px.box(t, y="총지출(원)", points="outliers", title="여행별 총지출 분포 및 이상치", labels={"총지출(원)":"총지출(원)"}))
    d = t.assign(여행기간구분=np.select([t["여행기간(일)"].eq(1),t["여행기간(일)"].eq(2)], ["1일","2일"], default="3일 이상"))
    a = d.groupby("여행기간구분",as_index=False)["총지출(원)"].mean()
    b = d.groupby("여행 목적",as_index=False)["총지출(원)"].mean()
    cc = d.groupby("동반자 수",as_index=False)["총지출(원)"].mean()
    col1,col2,col3=st.columns(3)
    with col1: chart(px.bar(a,x="여행기간구분",y="총지출(원)",title="여행기간별 평균 지출"))
    with col2: chart(px.bar(b,x="여행 목적",y="총지출(원)",title="여행 목적별 평균 지출"))
    with col3: chart(px.bar(cc,x="동반자 수",y="총지출(원)",title="동반자 수별 평균 지출"))
    pay=f.groupby("PAYMENT_MTHD_SE",as_index=False).agg(이용횟수=("PAYMENT_AMT_WON","size"),평균결제금액=("PAYMENT_AMT_WON","mean")).sort_values("이용횟수",ascending=False)
    col1,col2=st.columns(2)
    with col1: chart(px.bar(pay,x="PAYMENT_MTHD_SE",y="이용횟수",title="결제수단별 이용 횟수",labels={"PAYMENT_MTHD_SE":"결제수단"}))
    with col2: chart(px.bar(pay,x="PAYMENT_MTHD_SE",y="평균결제금액",title="결제수단별 평균 결제금액",labels={"PAYMENT_MTHD_SE":"결제수단","평균결제금액":"평균 결제금액(원)"}))
    st.subheader("소비처 상위 20개")
    top=f[f["STORE_NM"].ne("")].groupby("STORE_NM",as_index=False).agg(결제건수=("PAYMENT_AMT_WON","size"),총지출=("PAYMENT_AMT_WON","sum")).nlargest(20,"총지출")
    st.dataframe(top.style.format({"총지출": won}), use_container_width=True, hide_index=True)


def visits_routes(v: pd.DataFrame, f: pd.DataFrame, move: pd.DataFrame, ids: pd.Series) -> None:
    st.header("방문지·동선")
    if v.empty: st.info("방문지 데이터가 없습니다."); return
    vf=v.copy(); sf=f.groupby("TRAVEL_ID",as_index=False)["PAYMENT_AMT_WON"].sum()
    # 여행의 총소비는 방문지 개수로 나누지 않고, 시군구 소비는 방문지에 직접 귀속되는 소비만 사용한다.
    visit_ref = f["VISIT_AREA_ID"].fillna("").astype(str) if "VISIT_AREA_ID" in f else pd.Series("", index=f.index)
    vsp=f[visit_ref.ne("")].copy()
    vsp["TRAVEL_VISIT_KEY"]=vsp["TRAVEL_ID"].astype(str)+"|"+vsp["VISIT_AREA_ID"].astype(str)
    vs= vsp.groupby("TRAVEL_VISIT_KEY",as_index=False)["PAYMENT_AMT_WON"].sum()
    vf=audited_merge(vf,vs,on="TRAVEL_VISIT_KEY",how="left",validate="one_to_one",name="화면용 방문지-소비 집계",audit=[])
    vf["PAYMENT_AMT_WON"]=vf["PAYMENT_AMT_WON"].fillna(0)
    sgg=vf.groupby("시군구",as_index=False).agg(방문수=("TRAVEL_VISIT_KEY","size"),소비액=("PAYMENT_AMT_WON","sum"),평균체류시간=("체류시간(분)","mean"))
    col1,col2,col3=st.columns(3)
    with col1: chart(px.bar(sgg,x="시군구",y="방문수",title="시군구별 방문 수"))
    with col2: chart(px.bar(sgg,x="시군구",y="소비액",title="시군구별 소비액",labels={"소비액":"소비액(원)"}))
    with col3: chart(px.bar(sgg,x="시군구",y="평균체류시간",title="시군구별 평균 체류시간",labels={"평균체류시간":"평균 체류시간(분)"}))
    typ=vf.groupby("방문지 유형",as_index=False).agg(방문수=("TRAVEL_VISIT_KEY","size"),평균만족도=("만족도","mean"),활동수=("활동 수","sum"))
    col1,col2,col3=st.columns(3)
    with col1: chart(px.bar(typ,x="방문지 유형",y="방문수",title="방문지 유형별 방문 수"))
    with col2: chart(px.bar(typ,x="방문지 유형",y="평균만족도",title="방문지 유형별 만족도"))
    with col3: chart(px.bar(typ,x="방문지 유형",y="활동수",title="방문지 유형별 활동 수"))
    col1,col2=st.columns(2)
    with col1: chart(px.histogram(vf,x="방문 순서",title="방문 순서별 방문 수",labels={"방문 순서":"방문 순서","count":"방문 수"}))
    m=move[move["TRAVEL_ID"].isin(ids)]
    with col2: chart(px.bar(m.groupby("이동수단",as_index=False).size(),x="이동수단",y="size",title="이동수단별 이동 건수",labels={"size":"이동 건수"}))
    st.subheader("대표 출발지-도착지 조합")
    route=m[(m["출발지"]!="")&(m["도착지"]!="")].assign(경로=lambda x:x["출발지"]+" → "+x["도착지"]).groupby("경로",as_index=False).size().nlargest(20,"size").rename(columns={"size":"이동 건수"})
    st.dataframe(route, use_container_width=True, hide_index=True)


def experience(v: pd.DataFrame, data: dict[str,pd.DataFrame], ids: pd.Series) -> None:
    st.header("경험·만족")
    if v.empty: st.info("방문지 데이터가 없습니다."); return
    c=st.columns(3)
    c[0].metric("평균 만족도", f"{v['만족도'].mean():.2f}" if v['만족도'].notna().any() else "-")
    c[1].metric("평균 재방문 의향", f"{v['재방문 의향'].mean():.2f}" if v['재방문 의향'].notna().any() else "-")
    c[2].metric("평균 추천 의향", f"{v['추천 의향'].mean():.2f}" if v['추천 의향'].notna().any() else "-")
    typ=v.groupby("방문지 유형",as_index=False).agg(만족도=("만족도","mean"),재방문의향=("재방문 의향","mean"),추천의향=("추천 의향","mean"))
    long=typ.melt(id_vars="방문지 유형",var_name="지표",value_name="평균 점수")
    col1,col2=st.columns(2)
    with col1: chart(px.bar(long,x="방문지 유형",y="평균 점수",color="지표",barmode="group",title="방문지 유형별 만족·재방문·추천 의향"))
    with col2: chart(px.scatter(v,x="체류시간(분)",y="만족도",size="활동 수",color="방문지 유형",title="체류시간과 만족도",labels={"체류시간(분)":"체류시간(분)"}))
    a=data["activity"][data["activity"]["TRAVEL_ID"].isin(ids)].groupby("활동 유형",as_index=False).agg(활동수=("활동 수","sum"),활동소비=("활동 소비","sum"))
    with col1: chart(px.bar(a,x="활동 유형",y="활동수",title="활동 유형별 활동 수"))
    with col2: chart(px.bar(a,x="활동 유형",y="활동소비",title="활동 유형별 활동 소비",labels={"활동소비":"활동 소비(원)"}))
    chart(px.scatter(v,x="사진 수",y="체류시간(분)",size="만족도",color="방문지 유형",hover_name="방문지명",title="사진 수와 체류시간·만족도 관계"))


def quality_page(q: pd.DataFrame, audit: list[dict[str,Any]], anomalies: pd.DataFrame) -> None:
    st.header("데이터 품질")
    st.subheader("파일별 행 수·컬럼 수·결측 및 금액 이상")
    st.dataframe(q, use_container_width=True, hide_index=True)
    st.subheader("후보 키 중복 현황")
    st.dataframe(q[["테이블","후보 키 중복 행"]], use_container_width=True, hide_index=True)
    st.subheader("조인 성공/실패 현황")
    st.dataframe(pd.DataFrame(audit), use_container_width=True, hide_index=True)
    st.subheader("날짜·체류시간 이상")
    st.dataframe(anomalies, use_container_width=True, hide_index=True)


def main() -> None:
    st.title("🧭 2023년 수도권 여행로그 EDA 대시보드")
    st.caption("원본 CSV는 UTF-8-SIG·문자열 기준으로 읽으며, 소비 이력은 집계 후 결합해 중복 지출을 방지합니다.")
    found, missing = locate_files()
    if missing:
        st.error("필수 원본 CSV를 찾지 못했습니다. 원본을 수정하지 않고 현재 폴더(또는 하위 폴더)에 다음 파일을 배치한 뒤 새로고침하세요.")
        st.code("\n".join(missing), language=None)
        st.info("현재 앱은 원본 파일을 만들거나 변경하지 않습니다. CSV가 준비되면 자동으로 분석을 시작합니다.")
        return
    try:
        src = read_sources(tuple((label, str(source[0]), source[1] or "") for label, source in found.items() if source))
        data, quality, audit, anomalies = aggregate_data(src)
    except Exception as exc:
        st.error(f"데이터 적재 또는 안전 조인 중단: {exc}")
        return
    warning_count = int((quality["음수 금액"] + quality["후보 키 중복 행"]).sum() + anomalies["건수"].sum() + sum(x["참조키 미매칭"] for x in audit))
    if warning_count:
        st.warning(f"데이터 품질 경고 {warning_count:,}건이 있습니다. 자세한 내용은 ‘데이터 품질’ 탭에서 확인하세요.")
    # 원본과 분리된 산출물. 오류가 난 경우 이 지점에 도달하지 않는다.
    for name in ["fact_spend", "travel_summary", "visit_summary"]:
        data[name].to_csv(OUTPUT_DIR / f"{name}.csv", index=False, encoding="utf-8-sig")
    # 단일 품질 산출물에도 테이블 현황뿐 아니라 병합 검증과 이상치 결과를 함께 남긴다.
    quality_export = pd.concat([
        quality.assign(구분="테이블 현황"),
        pd.DataFrame(audit).assign(구분="병합 검증"),
        anomalies.assign(구분="이상치 점검"),
    ], ignore_index=True, sort=False)
    quality_export.to_csv(OUTPUT_DIR / "data_quality_summary.csv", index=False, encoding="utf-8-sig")
    t, v, f = apply_filters(data)
    pages = st.tabs(["여행 개요", "소비 분석", "방문지·동선", "경험·만족", "데이터 품질"])
    with pages[0]: overview(t, f)
    with pages[1]: spending(t, f)
    with pages[2]: visits_routes(v, f, data["move"], t["TRAVEL_ID"])
    with pages[3]: experience(v, data, t["TRAVEL_ID"])
    with pages[4]: quality_page(quality, audit, anomalies)


if __name__ == "__main__":
    main()
