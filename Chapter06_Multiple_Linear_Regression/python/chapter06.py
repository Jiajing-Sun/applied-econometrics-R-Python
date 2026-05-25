"""Chapter 06: 多元线性回归.

Textbook data: BEA state GDP/personal income + BLS state unemployment.

教学对应关系：
    教材变量 price          -> 人均个人收入（千美元）
    教材变量 living_area    -> 人均实际GDP（千美元，2017年不变价）
    教材变量 monthly_fee    -> 州年度平均失业率
    教材变量 new_production -> 是否人口大州
    教材变量 build_year     -> log(州人口)

This script implements multiple OLS, HC0 robust standard errors, nonzero t tests,
short-vs-long F tests, robust Wald tests, and confidence/prediction intervals
using only numpy/pandas plus the Python standard library.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
BEA_PATH = REPO_DIR / "data" / "processed" / "bea_us_state_gdp_income_panel_1997_2025.csv"
BLS_PATH = REPO_DIR / "data" / "processed" / "bls_state_unemployment_cpi_monthly_2015_2025.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def t_pdf(x: float, df: int) -> float:
    log_coef = (
        math.lgamma((df + 1) / 2)
        - 0.5 * math.log(df * math.pi)
        - math.lgamma(df / 2)
    )
    log_kernel = -((df + 1) / 2) * math.log1p((x * x) / df)
    return math.exp(log_coef + log_kernel)


def beta_pdf(x: float, a: float, b: float) -> float:
    if x <= 0 or x >= 1:
        return 0.0
    log_beta = math.lgamma(a) + math.lgamma(b) - math.lgamma(a + b)
    return math.exp((a - 1) * math.log(x) + (b - 1) * math.log1p(-x) - log_beta)


def simpson_integral(func, a: float, b: float, intervals: int = 6000) -> float:
    if b <= a:
        return 0.0
    if intervals % 2 == 1:
        intervals += 1
    h = (b - a) / intervals
    total = func(a) + func(b)
    for i in range(1, intervals):
        total += (4 if i % 2 else 2) * func(a + i * h)
    return total * h / 3


def t_cdf(x: float, df: int) -> float:
    if x == 0:
        return 0.5
    if x > 0:
        return 0.5 + simpson_integral(lambda z: t_pdf(z, df), 0, x)
    return 0.5 - simpson_integral(lambda z: t_pdf(z, df), 0, -x)


def t_ppf(prob: float, df: int) -> float:
    lo, hi = -20.0, 20.0
    for _ in range(80):
        mid = (lo + hi) / 2
        if t_cdf(mid, df) < prob:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def t_pvalue(t_stat: float, df: int) -> float:
    if abs(float(t_stat)) > 12:
        return 0.0
    p = 2 * (1 - t_cdf(abs(float(t_stat)), df))
    return min(1.0, max(0.0, float(p)))


def f_cdf(f_stat: float, df1: int, df2: int) -> float:
    if f_stat <= 0:
        return 0.0
    z = (df1 * f_stat) / (df1 * f_stat + df2)
    return simpson_integral(lambda u: beta_pdf(u, df1 / 2, df2 / 2), 0, z)


def f_pvalue(f_stat: float, df1: int, df2: int) -> float:
    p = 1 - f_cdf(float(f_stat), df1, df2)
    return min(1.0, max(0.0, float(p)))


def fit_ols(y: np.ndarray, X: np.ndarray, names: list[str]) -> dict[str, object]:
    n, p = X.shape
    xtx_inv = np.linalg.inv(X.T @ X)
    beta = xtx_inv @ X.T @ y
    fitted = X @ beta
    resid = y - fitted
    rss = float((resid**2).sum())
    tss = float(((y - y.mean()) ** 2).sum())
    df_resid = n - p
    sigma2 = rss / df_resid
    vcov = sigma2 * xtx_inv
    meat = X.T @ (X * (resid**2)[:, None])
    vcov_hc0 = xtx_inv @ meat @ xtx_inv
    return {
        "n": n,
        "p": p,
        "names": names,
        "beta": beta,
        "fitted": fitted,
        "resid": resid,
        "rss": rss,
        "tss": tss,
        "r2": 1 - rss / tss,
        "df_resid": df_resid,
        "vcov": vcov,
        "vcov_hc0": vcov_hc0,
    }


def coefficient_table(fit: dict[str, object], vcov_key: str, level: float = 0.95) -> pd.DataFrame:
    beta = fit["beta"]
    se = np.sqrt(np.diag(fit[vcov_key]))
    df_resid = int(fit["df_resid"])
    tval = beta / se
    pval = np.array([t_pvalue(t, df_resid) for t in tval])
    crit = t_ppf(1 - (1 - level) / 2, df_resid)
    return pd.DataFrame(
        {
            "项": fit["names"],
            "估计值": beta,
            "标准误": se,
            "t统计量": tval,
            "p值": pval,
            "CI下限": beta - crit * se,
            "CI上限": beta + crit * se,
        }
    )


def design_matrix(df: pd.DataFrame, cols: list[str]) -> np.ndarray:
    return np.column_stack([np.ones(len(df))] + [df[c].to_numpy() for c in cols])


def prediction_interval(fit: dict[str, object], x0: np.ndarray, level: float = 0.95) -> tuple[float, float, float, float, float]:
    beta = fit["beta"]
    yhat = float(x0 @ beta)
    xtx_inv = np.linalg.inv(fit["_X"].T @ fit["_X"])
    sigma2 = fit["rss"] / fit["df_resid"]
    var_mean = float(sigma2 * (x0 @ xtx_inv @ x0.T))
    crit = t_ppf(1 - (1 - level) / 2, int(fit["df_resid"]))
    ci_l = yhat - crit * math.sqrt(var_mean)
    ci_u = yhat + crit * math.sqrt(var_mean)
    pi_l = yhat - crit * math.sqrt(var_mean + sigma2)
    pi_u = yhat + crit * math.sqrt(var_mean + sigma2)
    return yhat, ci_l, ci_u, pi_l, pi_u


bea = pd.read_csv(BEA_PATH, encoding="utf-8-sig")
bea["state"] = bea["state"].str.replace(r"\s*\*$", "", regex=True).str.strip()
bea["state_fips"] = (pd.to_numeric(bea["geo_fips"]) // 1000).astype(int)
num_cols = [
    "real_gdp_millions_2017_usd",
    "current_gdp_millions_usd",
    "personal_income_millions_usd",
    "population",
    "per_capita_personal_income_usd",
]
bea_agg = (
    bea.groupby(["state_fips", "state", "year"], as_index=False)[num_cols]
    .first()
)

bls = pd.read_csv(BLS_PATH, encoding="utf-8-sig")
unemp = (
    bls.loc[bls["series_type"].eq("state_unemployment_rate")]
    .groupby(["state_fips", "year"], as_index=False)["value"]
    .mean()
    .rename(columns={"value": "unemployment_rate"})
)
unemp["state_fips"] = unemp["state_fips"].astype(int)

panel = pd.merge(bea_agg, unemp, on=["state_fips", "year"])
panel = panel.dropna().copy()
panel = panel.loc[
    panel["population"].gt(0) & panel["real_gdp_millions_2017_usd"].gt(0)
].copy()
analysis_year = int(panel["year"].max())
df = panel.loc[panel["year"].eq(analysis_year)].copy()
df["income_pc_thousand"] = df["per_capita_personal_income_usd"] / 1000
df["gdp_pc_thousand"] = df["real_gdp_millions_2017_usd"] * 1000 / df["population"]
df["log_population"] = np.log(df["population"])
df["large_state"] = (df["population"] > df["population"].median()).astype(int)
df = df.sort_values("state").reset_index(drop=True)
df = df[
    [
        "state",
        "state_fips",
        "year",
        "income_pc_thousand",
        "gdp_pc_thousand",
        "unemployment_rate",
        "large_state",
        "log_population",
        "population",
    ]
].copy()
df.to_csv(RESULT_DIR / "python_chapter06_bea_bls_state_analysis_data.csv", index=False)

y = df["income_pc_thousand"].to_numpy()

# ------------------------------------------------------------------------------
# Box 01--06: Python 中的多元回归
# ------------------------------------------------------------------------------

main_cols = ["gdp_pc_thousand", "unemployment_rate", "large_state"]
X_main = design_matrix(df, main_cols)
names_main = ["截距", "人均实际GDP", "失业率", "人口大州"]
ols_model = fit_ols(y, X_main, names_main)
ols_model["_X"] = X_main

rob_table = coefficient_table(ols_model, "vcov_hc0", level=0.95)
rob_table.to_csv(TABLE_DIR / "python_chapter06_mult_reg_hc0_table.csv", index=False)

b1 = float(rob_table.loc[rob_table["项"].eq("人均实际GDP"), "估计值"].iloc[0])
se1 = float(rob_table.loc[rob_table["项"].eq("人均实际GDP"), "标准误"].iloc[0])
t_stat = (b1 - 0.8) / se1
df_resid = int(ols_model["df_resid"])
p_value = t_pvalue(t_stat, df_resid)
pd.DataFrame(
    {
        "原假设": ["人均实际GDP系数 = 0.8"],
        "估计值": [b1],
        "HC0标准误": [se1],
        "t统计量": [t_stat],
        "p值": [p_value],
    }
).to_csv(RESULT_DIR / "python_chapter06_nonzero_slope_test.csv", index=False)

# ------------------------------------------------------------------------------
# Box 07--13: F 检验与稳健 F/Wald 检验
# ------------------------------------------------------------------------------

short_cols = ["gdp_pc_thousand", "unemployment_rate"]
long_cols = ["gdp_pc_thousand", "unemployment_rate", "large_state", "log_population"]
X_short = design_matrix(df, short_cols)
X_long = design_matrix(df, long_cols)
short_fit = fit_ols(y, X_short, ["截距", "人均实际GDP", "失业率"])
long_fit = fit_ols(y, X_long, ["截距", "人均实际GDP", "失业率", "人口大州", "log人口"])
long_fit["_X"] = X_long

n = int(long_fit["n"])
K = 4
G = 2
RSS_l = float(long_fit["rss"])
RSS_s = float(short_fit["rss"])
F_obs = ((RSS_s - RSS_l) / (K - G)) / (RSS_l / (n - (K + 1)))
p_f = f_pvalue(F_obs, K - G, n - (K + 1))

pd.DataFrame(
    {
        "检验": ["新增 large_state 和 log_population"],
        "RSS_短模型": [RSS_s],
        "RSS_长模型": [RSS_l],
        "分子自由度": [K - G],
        "分母自由度": [n - (K + 1)],
        "F统计量": [F_obs],
        "p值": [p_f],
    }
).to_csv(RESULT_DIR / "python_chapter06_f_test_short_long.csv", index=False)

Rmat = np.array([[0, 0, 0, 1, 0], [0, 0, 0, 0, 1]], dtype=float)
Rb = Rmat @ long_fit["beta"]
middle = Rmat @ long_fit["vcov_hc0"] @ Rmat.T
wald_chi2 = float(Rb.T @ np.linalg.inv(middle) @ Rb)
q = Rmat.shape[0]
F_rob = wald_chi2 / q
p_rob = f_pvalue(F_rob, q, int(long_fit["df_resid"]))

pd.DataFrame(
    {
        "检验": ["HC0稳健Wald检验：large_state = 0 且 log_population = 0"],
        "F统计量": [F_rob],
        "分子自由度": [q],
        "分母自由度": [int(long_fit["df_resid"])],
        "p值": [p_rob],
    }
).to_csv(RESULT_DIR / "python_chapter06_robust_wald_test.csv", index=False)

short_only = fit_ols(y, design_matrix(df, ["gdp_pc_thousand"]), ["截距", "人均实际GDP"])
pd.DataFrame(
    {
        "模型": [
            "短模型：收入~GDP",
            "中模型：收入~GDP+失业率+大州",
            "长模型：收入~GDP+失业率+大州+log人口",
        ],
        "GDP系数": [
            short_only["beta"][1],
            ols_model["beta"][1],
            long_fit["beta"][1],
        ],
        "R2": [short_only["r2"], ols_model["r2"], long_fit["r2"]],
    }
).to_csv(TABLE_DIR / "python_chapter06_short_long_model_comparison.csv", index=False)

aux_X = design_matrix(df, ["unemployment_rate", "large_state"])
aux_gdp = fit_ols(df["gdp_pc_thousand"].to_numpy(), aux_X, ["截距", "失业率", "人口大州"])
aux_income = fit_ols(y, aux_X, ["截距", "失业率", "人口大州"])
pd.DataFrame(
    {
        "state": df["state"],
        "gdp_residual": aux_gdp["resid"],
        "income_residual": aux_income["resid"],
    }
).to_csv(RESULT_DIR / "python_chapter06_fwl_residual_data.csv", index=False)

# ------------------------------------------------------------------------------
# Box 14--16: 条件期望的置信区间和预测区间
# ------------------------------------------------------------------------------

simple_fit = fit_ols(y, design_matrix(df, ["gdp_pc_thousand"]), ["截距", "人均实际GDP"])
simple_fit["_X"] = design_matrix(df, ["gdp_pc_thousand"])
x0_simple = np.array([1.0, 75.0])
yhat, ci_l, ci_u, pi_l, pi_u = prediction_interval(simple_fit, x0_simple, level=0.95)

x0_long = np.array([1.0, 75.0, 4.0, 1.0, math.log(5_000_000)])
yhat_l, ci_l_l, ci_u_l, pi_l_l, pi_u_l = prediction_interval(long_fit, x0_long, level=0.95)

prediction_table = pd.DataFrame(
    {
        "设定": [
            "简单模型：GDP=75千美元，条件期望CI",
            "简单模型：GDP=75千美元，单个州预测PI",
            "多元模型：GDP=75、失业率4%、大州、人口500万，条件期望CI",
            "多元模型：GDP=75、失业率4%、大州、人口500万，单个州预测PI",
        ],
        "拟合值": [yhat, yhat, yhat_l, yhat_l],
        "下限": [ci_l, pi_l, ci_l_l, pi_l_l],
        "上限": [ci_u, pi_u, ci_u_l, pi_u_l],
    }
)
prediction_table.to_csv(RESULT_DIR / "python_chapter06_prediction_intervals.csv", index=False)

result_lines = [
    "第 6 章：多元线性回归",
    "",
    "数据：BEA 美国州级 GDP/个人收入 + BLS 州级失业率。",
    f"分析年份：{analysis_year}；样本量：{len(df)}",
    "主模型：人均个人收入（千美元） ~ 人均实际GDP（千美元） + 失业率 + 是否人口大州。",
    f"HC0下人均实际GDP系数：{b1:.4f}，标准误：{se1:.4f}",
    f"检验 GDP 系数 = 0.8：t={t_stat:.4f}，p={p_value:.4f}",
    f"长短模型F检验：F={F_obs:.4f}，p={p_f:.4f}",
    f"HC0稳健Wald检验：F={F_rob:.4f}，p={p_rob:.4f}",
    f"简单模型在 GDP=75 千美元处的拟合值：{yhat:.4f}",
]
(RESULT_DIR / "python_chapter06_results_readme.txt").write_text(
    "\n".join(result_lines), encoding="utf-8"
)

print("\n".join(result_lines))
