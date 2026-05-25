"""Chapter 07: 非线性函数形式.

Textbook data: World Bank WDI global indicators + OWID global annual CO2.

教学对应关系：
    教材变量 wind_direction -> log(人均GDP，2015年不变美元)
    教材变量 pm25           -> 人均CO2排放（吨/人）
    教材变量 wind_cat       -> log(人均GDP)十分位分箱
    教材变量 land_wind      -> 高收入国家虚拟变量
    教材变量 strong_wind    -> 高贸易开放度虚拟变量
    教材变量 wind_speed     -> 贸易占GDP比重

This script mirrors the R workflow with bins, polynomial terms, log models,
dummy variables, interactions, and HC0 robust standard errors. It writes tables
and numerical results; the R script generates the chapter figures with Chinese
labels.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
WDI_PATH = REPO_DIR / "data" / "processed" / "wdi_global_selected_indicators_wide.csv"
OWID_PATH = REPO_DIR / "data" / "processed" / "owid_global_annual_co2.csv"
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


def t_pvalue(t_stat: float, df: int) -> float:
    if abs(float(t_stat)) > 12:
        return 0.0
    p = 2 * (1 - t_cdf(abs(float(t_stat)), df))
    return min(1.0, max(0.0, float(p)))


def t_ppf(prob: float, df: int) -> float:
    lo, hi = -20.0, 20.0
    for _ in range(80):
        mid = (lo + hi) / 2
        if t_cdf(mid, df) < prob:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


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


def coefficient_table(fit: dict[str, object], vcov_key: str, model_label: str) -> pd.DataFrame:
    beta = np.asarray(fit["beta"], dtype=float)
    se = np.sqrt(np.diag(fit[vcov_key]))
    df_resid = int(fit["df_resid"])
    tval = beta / se
    pval = np.array([t_pvalue(t, df_resid) for t in tval])
    crit = t_ppf(0.975, df_resid)
    return pd.DataFrame(
        {
            "模型": model_label,
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
    return np.column_stack([np.ones(len(df))] + [df[c].to_numpy(float) for c in cols])


wdi = pd.read_csv(WDI_PATH, encoding="utf-8-sig")
owid = pd.read_csv(OWID_PATH, encoding="utf-8-sig")
co2_col = [c for c in owid.columns if c.startswith("Annual")][0]

df_all = pd.merge(
    wdi,
    owid,
    left_on=["country_code", "year"],
    right_on=["Code", "Year"],
    how="inner",
)
df_all["annual_co2_emissions"] = df_all[co2_col]
df_all["co2_pc_tonnes"] = df_all["annual_co2_emissions"] / df_all["population"]
positive = (
    df_all["gdp_per_capita_constant_2015_usd"].gt(0)
    & df_all["population"].gt(0)
    & df_all["annual_co2_emissions"].gt(0)
    & df_all["co2_pc_tonnes"].gt(0)
)
df_all = df_all.loc[positive].copy()
df_all["log_gdp_pc"] = np.log(df_all["gdp_per_capita_constant_2015_usd"])
df_all["log_co2_pc"] = np.log(df_all["co2_pc_tonnes"])

needed = [
    "gdp_per_capita_constant_2015_usd",
    "population",
    "trade_pct_gdp",
    "annual_co2_emissions",
    "co2_pc_tonnes",
    "log_gdp_pc",
    "log_co2_pc",
]
usable = df_all.dropna(subset=needed).copy()

year_counts = usable.groupby("year")["country_code"].size()
analysis_year = int(year_counts[year_counts >= 150].index.max())
df = usable.loc[usable["year"].eq(analysis_year)].copy()
df = df.sort_values("country").reset_index(drop=True)

df["income_decile"] = pd.qcut(df["log_gdp_pc"], q=10, duplicates="drop")
df["income_group"] = pd.qcut(
    df["log_gdp_pc"],
    q=4,
    labels=["低收入组", "中低收入组", "中高收入组", "高收入组"],
    duplicates="drop",
)
df["high_income"] = (df["log_gdp_pc"] > df["log_gdp_pc"].median()).astype(int)
df["high_trade"] = (df["trade_pct_gdp"] > df["trade_pct_gdp"].median()).astype(int)

analysis_cols = [
    "country",
    "country_code",
    "year",
    "gdp_per_capita_constant_2015_usd",
    "log_gdp_pc",
    "trade_pct_gdp",
    "population",
    "co2_pc_tonnes",
    "log_co2_pc",
    "income_decile",
    "income_group",
    "high_income",
    "high_trade",
]
df[analysis_cols].to_csv(
    RESULT_DIR / "python_chapter07_wdi_owid_income_co2_analysis_data.csv",
    index=False,
)

# ------------------------------------------------------------------------------
# Box 01--05: 分箱均值
# ------------------------------------------------------------------------------

df_agg = (
    df.groupby("income_decile", observed=False)[["co2_pc_tonnes", "log_gdp_pc"]]
    .mean()
    .reset_index()
)
df_agg = df_agg.rename(
    columns={
        "income_decile": "收入分箱",
        "co2_pc_tonnes": "人均CO2均值",
        "log_gdp_pc": "log人均GDP均值",
    }
)
df_agg.to_csv(TABLE_DIR / "python_chapter07_income_decile_co2_means.csv", index=False)

# ------------------------------------------------------------------------------
# Box 06--13: 多项式函数形式
# ------------------------------------------------------------------------------

df["log_gdp2"] = df["log_gdp_pc"] ** 2
df["log_gdp3"] = df["log_gdp_pc"] ** 3
df["log_gdp4"] = df["log_gdp_pc"] ** 4

y = df["co2_pc_tonnes"].to_numpy(float)
poly_cols = ["log_gdp_pc", "log_gdp2", "log_gdp3", "log_gdp4"]
X_poly = design_matrix(df, poly_cols)
poly_fit = fit_ols(y, X_poly, ["截距", "log人均GDP", "log人均GDP二次项", "log人均GDP三次项", "log人均GDP四次项"])
poly_table = coefficient_table(poly_fit, "vcov_hc0", "四阶原始多项式")
poly_table.to_csv(TABLE_DIR / "python_chapter07_polynomial_hc0_table.csv", index=False)

X_quad = design_matrix(df, ["log_gdp_pc", "log_gdp2"])
quad_fit = fit_ols(y, X_quad, ["截距", "log人均GDP", "log人均GDP二次项"])
quad_points = df["log_gdp_pc"].quantile([0.25, 0.5, 0.75]).to_numpy(float)
quad_marginal = pd.DataFrame(
    {
        "位置": ["第25百分位", "中位数", "第75百分位"],
        "log人均GDP": quad_points,
        "边际效应": quad_fit["beta"][1] + 2 * quad_fit["beta"][2] * quad_points,
    }
)
quad_marginal.to_csv(
    TABLE_DIR / "python_chapter07_quadratic_marginal_effects.csv",
    index=False,
)

# ------------------------------------------------------------------------------
# 对数模型
# ------------------------------------------------------------------------------

X_log = design_matrix(df, ["log_gdp_pc"])
log_log_fit = fit_ols(df["log_co2_pc"].to_numpy(float), X_log, ["截距", "log人均GDP"])
lin_log_fit = fit_ols(y, X_log, ["截距", "log人均GDP"])
log_models = pd.concat(
    [
        coefficient_table(log_log_fit, "vcov_hc0", "log-log模型"),
        coefficient_table(lin_log_fit, "vcov_hc0", "lin-log模型"),
    ],
    ignore_index=True,
)
log_models.to_csv(TABLE_DIR / "python_chapter07_log_models_hc0_table.csv", index=False)

log_interpretation = pd.DataFrame(
    {
        "模型": ["log-log", "lin-log", "log-level"],
        "设定": ["log(Y) ~ log(X)", "Y ~ log(X)", "log(Y) ~ X"],
        "系数含义": [
            "X 增加1%，Y 平均约变化 beta%",
            "X 增加1%，Y 平均约变化 beta/100 个单位",
            "X 增加1个单位，Y 平均约变化 100*(exp(beta)-1)%",
        ],
        "本章读法": [
            f"收入弹性约 {float(log_log_fit['beta'][1]):.3f}",
            f"人均GDP增加1%，人均CO2约变化 {float(lin_log_fit['beta'][1]) / 100:.3f} 吨",
            "本章未作为主模型；常用于二元或比例型因变量的稳健性比较",
        ],
    }
)
log_interpretation.to_csv(
    TABLE_DIR / "python_chapter07_log_model_interpretation.csv",
    index=False,
)

# ------------------------------------------------------------------------------
# Box 14--15: 虚拟变量和交互项
# ------------------------------------------------------------------------------

df["high_income_high_trade"] = df["high_income"] * df["high_trade"]
df["high_income_trade"] = df["high_income"] * df["trade_pct_gdp"]

fit1 = fit_ols(y, design_matrix(df, ["high_income"]), ["截距", "高收入国家"])
fit2 = fit_ols(
    y,
    design_matrix(df, ["high_income", "high_trade", "high_income_high_trade"]),
    ["截距", "高收入国家", "高贸易开放度", "高收入×高贸易"],
)
fit3 = fit_ols(
    y,
    design_matrix(df, ["high_income", "trade_pct_gdp", "high_income_trade"]),
    ["截距", "高收入国家", "贸易占GDP比重", "高收入×贸易占GDP比重"],
)
interaction_models = pd.concat(
    [
        coefficient_table(fit1, "vcov_hc0", "模型1：高收入虚拟变量"),
        coefficient_table(fit2, "vcov_hc0", "模型2：两个虚拟变量交互"),
        coefficient_table(fit3, "vcov_hc0", "模型3：虚拟变量与连续变量交互"),
    ],
    ignore_index=True,
)
interaction_models.to_csv(
    TABLE_DIR / "python_chapter07_interaction_models_hc0_table.csv",
    index=False,
)

dummy_prediction = pd.DataFrame(
    {
        "high_income": [0, 1, 0, 1],
        "high_trade": [0, 0, 1, 1],
    }
)
dummy_prediction["high_income_high_trade"] = (
    dummy_prediction["high_income"] * dummy_prediction["high_trade"]
)
X_dummy_pred = design_matrix(
    dummy_prediction, ["high_income", "high_trade", "high_income_high_trade"]
)
dummy_prediction["收入组"] = np.where(dummy_prediction["high_income"].eq(1), "高收入", "非高收入")
dummy_prediction["贸易组"] = np.where(dummy_prediction["high_trade"].eq(1), "高贸易开放度", "低贸易开放度")
dummy_prediction["预测人均CO2"] = X_dummy_pred @ fit2["beta"]
dummy_prediction[["收入组", "贸易组", "预测人均CO2"]].to_csv(
    TABLE_DIR / "python_chapter07_dummy_interaction_predictions.csv",
    index=False,
)

trade_points = df["trade_pct_gdp"].quantile([0.25, 0.5, 0.75]).to_numpy(float)
trade_prediction = pd.concat(
    [
        pd.DataFrame(
            {
                "收入组": "非高收入",
                "贸易开放度": trade_points,
                "预测人均CO2": design_matrix(
                    pd.DataFrame(
                        {
                            "high_income": 0,
                            "trade_pct_gdp": trade_points,
                            "high_income_trade": 0,
                        }
                    ),
                    ["high_income", "trade_pct_gdp", "high_income_trade"],
                )
                @ fit3["beta"],
            }
        ),
        pd.DataFrame(
            {
                "收入组": "高收入",
                "贸易开放度": trade_points,
                "预测人均CO2": design_matrix(
                    pd.DataFrame(
                        {
                            "high_income": 1,
                            "trade_pct_gdp": trade_points,
                            "high_income_trade": trade_points,
                        }
                    ),
                    ["high_income", "trade_pct_gdp", "high_income_trade"],
                )
                @ fit3["beta"],
            }
        ),
    ],
    ignore_index=True,
)
trade_prediction.to_csv(
    TABLE_DIR / "python_chapter07_trade_interaction_predictions.csv",
    index=False,
)

group_means = (
    df.groupby("income_group", observed=False)["co2_pc_tonnes"]
    .mean()
    .reset_index()
    .rename(columns={"income_group": "收入组", "co2_pc_tonnes": "人均CO2均值"})
)
group_means.to_csv(TABLE_DIR / "python_chapter07_income_group_means.csv", index=False)

summary = pd.DataFrame(
    {
        "指标": [
            "分析年份",
            "样本量",
            "人均CO2均值",
            "人均CO2中位数",
            "log-log模型收入弹性",
            "四阶多项式R2",
            "交互模型R2",
        ],
        "数值": [
            analysis_year,
            len(df),
            df["co2_pc_tonnes"].mean(),
            df["co2_pc_tonnes"].median(),
            float(log_log_fit["beta"][1]),
            float(poly_fit["r2"]),
            float(fit3["r2"]),
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter07_summary.csv", index=False)

print("Chapter 07 finished.")
print(f"Analysis year: {analysis_year}")
print(f"Sample size: {len(df)}")
print(f"Log-log elasticity: {float(log_log_fit['beta'][1]):.4f}")
