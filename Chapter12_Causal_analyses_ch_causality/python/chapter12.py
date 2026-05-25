"""Chapter 12: 因果分析.

Textbook data: NHTSA FARS 2018--2023, persons aged 18--24.

教学对应关系：
    Swedish municipal election RD -> age-21 legal drinking threshold RD example
    running variable rv           -> age - 21
    treatment Z                   -> age >= 21
    outcome                       -> alcohol involved in crash

This script implements local linear RD and HC0 robust standard errors without
statsmodels/linearmodels/rdrobust.
"""

from __future__ import annotations

import math
from itertools import combinations
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
FARS_PATH = REPO_DIR / "data" / "processed" / "nhtsa_fars_rd_age18_24_2018_2023.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def normal_cdf(z: np.ndarray) -> np.ndarray:
    return 0.5 * (1 + np.vectorize(math.erf)(z / math.sqrt(2)))


def fit_ols(y: np.ndarray, X: np.ndarray, names: list[str]) -> dict[str, object]:
    xtx_inv = np.linalg.pinv(X.T @ X)
    beta = xtx_inv @ X.T @ y
    fitted = X @ beta
    resid = y - fitted
    n, p = X.shape
    sigma2 = float((resid @ resid) / (n - p))
    vcov = sigma2 * xtx_inv
    meat = X.T @ (X * (resid**2)[:, None])
    vcov_hc0 = xtx_inv @ meat @ xtx_inv
    return {
        "names": names,
        "beta": beta,
        "fitted": fitted,
        "resid": resid,
        "vcov": vcov,
        "vcov_hc0": vcov_hc0,
        "df_resid": n - p,
    }


def coefficient_table(fit: dict[str, object], vcov_key: str, model_label: str) -> pd.DataFrame:
    beta = np.asarray(fit["beta"], dtype=float)
    se = np.sqrt(np.diag(fit[vcov_key]))
    stat = beta / se
    p = np.maximum(0.0, 2 * (1 - normal_cdf(np.abs(stat))))
    return pd.DataFrame(
        {"模型": model_label, "项": fit["names"], "估计值": beta, "标准误": se, "t统计量": stat, "p值": p}
    )


def design(df: pd.DataFrame, cols: list[str], intercept: bool = True) -> np.ndarray:
    blocks = [df[c].to_numpy(float) for c in cols]
    if intercept:
        blocks = [np.ones(len(df))] + blocks
    return np.column_stack(blocks)


potential = pd.DataFrame(
    {
        "个体": np.arange(1, 9),
        "未处理潜在结果": [4, 5, 5, 6, 7, 7, 8, 9],
        "处理潜在结果": [5, 7, 5, 8, 8, 10, 9, 11],
        "处理指示": [1, 0, 1, 0, 1, 0, 0, 1],
    }
)
potential["个体处理效应"] = potential["处理潜在结果"] - potential["未处理潜在结果"]
potential["观测结果"] = np.where(
    potential["处理指示"].eq(1), potential["处理潜在结果"], potential["未处理潜在结果"]
)
potential.to_csv(TABLE_DIR / "python_chapter12_potential_outcomes_demo.csv", index=False)

sharp_outcomes = potential["观测结果"].to_numpy(float)
n_treated = int(potential["处理指示"].sum())
stats = []
for assign_id, treated_idx in enumerate(combinations(range(len(potential)), n_treated), start=1):
    z = np.zeros(len(potential), dtype=int)
    z[list(treated_idx)] = 1
    stat = float(sharp_outcomes[z == 1].mean() - sharp_outcomes[z == 0].mean())
    stats.append({"分配编号": assign_id, "均值差": stat})
rand_table = pd.DataFrame(stats)
obs_stat = float(
    potential.loc[potential["处理指示"].eq(1), "观测结果"].mean()
    - potential.loc[potential["处理指示"].eq(0), "观测结果"].mean()
)
rand_table["是否至少同样极端"] = (rand_table["均值差"].abs() >= abs(obs_stat)).astype(int)
rand_table.to_csv(TABLE_DIR / "python_chapter12_randomization_distribution.csv", index=False)
randomization_summary = pd.DataFrame(
    {
        "指标": ["个体数", "处理组人数", "观测均值差", "Fisher精确p值", "真实样本ATE"],
        "数值": [
            len(potential),
            n_treated,
            obs_stat,
            float(rand_table["是否至少同样极端"].mean()),
            float(potential["个体处理效应"].mean()),
        ],
    }
)
randomization_summary.to_csv(TABLE_DIR / "python_chapter12_randomization_summary.csv", index=False)

rng = np.random.default_rng(20260412)
did_units = 40
did_times = np.arange(-3, 4)
rows = []
unit_fe = rng.normal(0, 0.7, did_units)
for unit in range(1, did_units + 1):
    treated = int(unit > did_units / 2)
    for period in did_times:
        post = int(period >= 0)
        y_sim = 5 + unit_fe[unit - 1] + 0.35 * period + 1.8 * treated * post + rng.normal(0, 0.5)
        rows.append({"unit": unit, "period": period, "treated": treated, "post": post, "y": y_sim})
did_df = pd.DataFrame(rows)
did_cells = did_df.groupby(["treated", "period"], as_index=False)["y"].mean()
did_cells.to_csv(TABLE_DIR / "python_chapter12_did_simulated_cell_means.csv", index=False)
X_did = np.column_stack(
    [
        np.ones(len(did_df)),
        did_df["treated"].to_numpy(float),
        did_df["post"].to_numpy(float),
        (did_df["treated"] * did_df["post"]).to_numpy(float),
    ]
)
did_fit = fit_ols(did_df["y"].to_numpy(float), X_did, ["截距", "处理组", "政策后", "处理组×政策后"])
coefficient_table(did_fit, "vcov_hc0", "模拟DID").to_csv(
    TABLE_DIR / "python_chapter12_did_simulated_regression.csv", index=False
)

iv_n = 800
z = rng.binomial(1, 0.5, iv_n)
u = rng.normal(size=iv_n)
d = 0.7 * z + 0.9 * u + rng.normal(size=iv_n)
y_iv = 1 + 2.0 * d + u + rng.normal(size=iv_n)
iv_df = pd.DataFrame({"y": y_iv, "d": d, "z": z, "u": u})
ols_fit = fit_ols(iv_df["y"].to_numpy(float), design(iv_df, ["d"]), ["截距", "D"])
fs_fit = fit_ols(iv_df["d"].to_numpy(float), design(iv_df, ["z"]), ["截距", "Z"])
rf_fit = fit_ols(iv_df["y"].to_numpy(float), design(iv_df, ["z"]), ["截距", "Z"])
iv_df["dhat"] = np.asarray(fs_fit["fitted"], dtype=float)
tsls_fit = fit_ols(iv_df["y"].to_numpy(float), design(iv_df, ["dhat"]), ["截距", "Dhat"])
iv_rows = []
for equation, variable, fit_obj in [
    ("OLS结构式", "D", ols_fit),
    ("第一阶段", "Z", fs_fit),
    ("简约式", "Z", rf_fit),
    ("2SLS第二阶段", "Dhat", tsls_fit),
]:
    beta = np.asarray(fit_obj["beta"], dtype=float)[1]
    se = float(np.sqrt(np.diag(fit_obj["vcov_hc0"]))[1])
    iv_rows.append({"方程": equation, "关键变量": variable, "估计值": beta, "标准误": se})
pd.DataFrame(iv_rows).to_csv(TABLE_DIR / "python_chapter12_iv_simulated_table.csv", index=False)
fs_beta = np.asarray(fs_fit["beta"], dtype=float)[1]
fs_se = float(np.sqrt(np.diag(fs_fit["vcov_hc0"]))[1])
pd.DataFrame(
    {"指标": ["第一阶段F统计量", "真实处理效应"], "数值": [(fs_beta / fs_se) ** 2, 2.0]}
).to_csv(TABLE_DIR / "python_chapter12_iv_simulated_diagnostics.csv", index=False)


df = pd.read_csv(FARS_PATH, encoding="utf-8-sig")
df = df.loc[df["age"].between(18, 24)].copy()
df = df.loc[df["drinking"].isin([0, 1])].copy()
df["alcohol_involved"] = (df["drinking"] == 1).astype(int)
df["rv"] = df["age"] - 21
df["Z"] = (df["rv"] >= 0).astype(int)
df["Zrv"] = df["Z"] * df["rv"]
df["male"] = (df["sex"] == 1).astype(int)
df["fatal_injury"] = (df["inj_sev"] == 4).astype(int)

h = 3
df_h = df.loc[df["rv"].abs() <= h].copy()
df_h[
    ["year", "state", "statename", "age", "rv", "Z", "alcohol_involved", "male", "fatal_injury"]
].to_csv(RESULT_DIR / "python_chapter12_fars_rd_analysis_data.csv", index=False)

y = df_h["alcohol_involved"].to_numpy(float)
X_rd = design(df_h, ["Z", "rv", "Zrv"])
rd_rf = fit_ols(y, X_rd, ["截距", "21岁及以上", "年龄差", "21岁及以上×年龄差"])

df_h["Dhat"] = df_h["Z"]
X_2sls = design(df_h, ["Dhat", "rv", "Zrv"])
rd_2sls = fit_ols(y, X_2sls, ["截距", "Dhat", "年龄差", "21岁及以上×年龄差"])

year_dummies = pd.get_dummies(df_h["year"].astype(int), prefix="year", drop_first=True, dtype=float)
control_df = pd.concat([df_h[["Z", "rv", "Zrv", "male", "fatal_injury"]], year_dummies], axis=1)
X_controls = np.column_stack([np.ones(len(control_df)), control_df.to_numpy(float)])
names_controls = ["截距", "21岁及以上", "年龄差", "21岁及以上×年龄差", "男性", "致命伤"] + list(year_dummies.columns)
rd_controls = fit_ols(y, X_controls, names_controls)

rd_bw_rows = []
for bw in [2, 3, 4]:
    df_bw = df.loc[df["rv"].abs() <= bw].copy()
    y_bw = df_bw["alcohol_involved"].to_numpy(float)
    X_bw = design(df_bw, ["Z", "rv", "Zrv"])
    fit_bw = fit_ols(y_bw, X_bw, ["截距", "21岁及以上", "年龄差", "21岁及以上×年龄差"])
    rd_bw_rows.append(
        {
            "带宽": bw,
            "样本量": len(df_bw),
            "左侧样本量": int((df_bw["rv"] < 0).sum()),
            "右侧样本量": int((df_bw["rv"] >= 0).sum()),
            "跳跃估计": float(fit_bw["beta"][1]),
            "HC0标准误": float(np.sqrt(np.diag(fit_bw["vcov_hc0"]))[1]),
        }
    )
pd.DataFrame(rd_bw_rows).to_csv(
    TABLE_DIR / "python_chapter12_fars_rd_bandwidth_sensitivity.csv", index=False
)

rd_tables = pd.concat(
    [
        coefficient_table(rd_rf, "vcov_hc0", "局部线性RD"),
        coefficient_table(rd_2sls, "vcov_hc0", "sharp RD的2SLS等价写法"),
        coefficient_table(rd_controls, "vcov_hc0", "加入性别、伤害严重程度和年份控制"),
    ],
    ignore_index=True,
)
rd_tables.to_csv(TABLE_DIR / "python_chapter12_fars_rd_hc0_tables.csv", index=False)

age_bins = (
    df_h.groupby("age", as_index=False)["alcohol_involved"]
    .mean()
    .rename(columns={"age": "年龄", "alcohol_involved": "酒精涉及比例"})
)
age_bins.to_csv(TABLE_DIR / "python_chapter12_fars_rd_age_bins.csv", index=False)

summary = pd.DataFrame(
    {
        "指标": ["样本量", "带宽h", "阈值左侧样本量", "阈值右侧样本量", "21岁RD跳跃估计", "HC0标准误", "加入控制后的跳跃估计"],
        "数值": [
            len(df_h),
            h,
            int((df_h["rv"] < 0).sum()),
            int((df_h["rv"] >= 0).sum()),
            float(rd_rf["beta"][1]),
            float(np.sqrt(np.diag(rd_rf["vcov_hc0"]))[1]),
            float(rd_controls["beta"][1]),
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter12_summary.csv", index=False)

print("Chapter 12 finished.")
print(f"Sample size: {len(df_h)}")
print(f"RD jump: {float(rd_rf['beta'][1]):.4f}")
