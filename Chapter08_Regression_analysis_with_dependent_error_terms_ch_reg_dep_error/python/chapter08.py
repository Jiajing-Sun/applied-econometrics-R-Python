"""Chapter 08: 带有相关误差项的回归分析.

Textbook data:
    1. ACS PUMS 2023 California person-level sample for clustered inference.
    2. BEA state income/GDP + BLS state unemployment for fixed effects.

教学对应关系：
    outcome_income           -> log(个人收入+1)
    bachelor_or_above        -> 是否本科及以上学历
    age                      -> 年龄
    household_id             -> 家庭编号 serialno
    municipal tax_rate        -> 人均个人收入（千美元）
    left_coalition_last_term  -> 州失业率

This script uses only numpy/pandas plus the standard library. It implements OLS,
HC0 and cluster-robust standard errors, an ANOVA-style random-intercept variance
decomposition, and one-way/two-way fixed effects via within transformations.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
ACS_PATH = REPO_DIR / "data" / "processed" / "acs_pums_california_persons_2023_selected.csv"
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
        "r2": 1 - rss / tss if tss > 0 else np.nan,
        "df_resid": df_resid,
        "vcov": vcov,
        "vcov_hc0": vcov_hc0,
        "X": X,
    }


def design_matrix(df: pd.DataFrame, cols: list[str], intercept: bool = True) -> np.ndarray:
    blocks = [df[c].to_numpy(float) for c in cols]
    if intercept:
        blocks = [np.ones(len(df))] + blocks
    return np.column_stack(blocks)


def cluster_vcov(fit: dict[str, object], clusters: pd.Series | np.ndarray) -> np.ndarray:
    X = np.asarray(fit["X"], dtype=float)
    u = np.asarray(fit["resid"], dtype=float)
    n, p = X.shape
    xtx_inv = np.linalg.inv(X.T @ X)
    score_df = pd.DataFrame(X * u[:, None])
    score_df["_cluster"] = np.asarray(clusters)
    grouped_scores = score_df.groupby("_cluster", sort=False).sum().drop(columns=[], errors="ignore")
    S = grouped_scores.to_numpy(float)
    meat = S.T @ S
    g = S.shape[0]
    correction = (g / (g - 1)) * ((n - 1) / (n - p)) if g > 1 else 1.0
    return correction * xtx_inv @ meat @ xtx_inv


def coefficient_table(
    fit: dict[str, object],
    vcov: np.ndarray,
    model_label: str,
    df_for_p: int | None = None,
) -> pd.DataFrame:
    beta = np.asarray(fit["beta"], dtype=float)
    se = np.sqrt(np.diag(vcov))
    df_resid = int(fit["df_resid"] if df_for_p is None else df_for_p)
    tval = beta / se
    pval = np.array([t_pvalue(t, df_resid) for t in tval])
    return pd.DataFrame(
        {
            "模型": model_label,
            "项": fit["names"],
            "估计值": beta,
            "标准误": se,
            "t统计量": tval,
            "p值": pval,
            "自由度": df_resid,
        }
    )


def demean_oneway(values: pd.Series, group: pd.Series) -> pd.Series:
    return values - values.groupby(group).transform("mean")


def demean_twoway(values: pd.Series, entity: pd.Series, time: pd.Series) -> pd.Series:
    return (
        values
        - values.groupby(entity).transform("mean")
        - values.groupby(time).transform("mean")
        + values.mean()
    )


def random_intercept_anova(df: pd.DataFrame, y_col: str, group_col: str) -> pd.DataFrame:
    grouped = df.groupby(group_col)[y_col]
    n_g = grouped.size()
    mean_g = grouped.mean()
    overall = df[y_col].mean()
    ss_between = float((n_g * (mean_g - overall) ** 2).sum())
    ss_within = float(grouped.apply(lambda s: ((s - s.mean()) ** 2).sum()).sum())
    g = len(n_g)
    n = len(df)
    ms_between = ss_between / (g - 1)
    ms_within = ss_within / (n - g)
    n_bar = (n - (n_g.pow(2).sum() / n)) / (g - 1)
    sigma_household = max((ms_between - ms_within) / n_bar, 0.0)
    sigma_resid = ms_within
    total = sigma_household + sigma_resid
    return pd.DataFrame(
        {
            "层级": ["家庭随机截距", "个体残差"],
            "方差": [sigma_household, sigma_resid],
            "占比": [sigma_household / total, sigma_resid / total],
        }
    )


# ------------------------------------------------------------------------------
# Box 01: 聚类数据下的 OLS
# ------------------------------------------------------------------------------

acs = pd.read_csv(ACS_PATH, encoding="utf-8-sig")
acs = acs.dropna(
    subset=[
        "serialno",
        "age",
        "personal_income",
        "female",
        "employed",
        "has_bachelor_or_higher",
    ]
).copy()
acs = acs.loc[
    acs["age"].between(25, 64) & acs["personal_income"].ge(0)
].copy()
acs["household_id"] = acs["serialno"]
acs["log_income"] = np.log1p(acs["personal_income"])
acs["income_thousand"] = acs["personal_income"] / 1000
acs["bachelor"] = acs["has_bachelor_or_higher"]
acs["age_centered"] = acs["age"] - acs["age"].mean()
acs = acs.sort_values(["household_id", "person_order"]).reset_index(drop=True)
acs[
    [
        "household_id",
        "person_order",
        "age",
        "female",
        "employed",
        "bachelor",
        "personal_income",
        "log_income",
    ]
].to_csv(RESULT_DIR / "python_chapter08_acs_cluster_analysis_data.csv", index=False)

y_acs = acs["log_income"].to_numpy(float)
X_bach = design_matrix(acs, ["bachelor"], intercept=True)
fit_bach = fit_ols(y_acs, X_bach, ["截距", "本科及以上"])
cluster_df = acs["household_id"].nunique() - 1
bach_tables = pd.concat(
    [
        coefficient_table(fit_bach, fit_bach["vcov"], "普通OLS"),
        coefficient_table(fit_bach, fit_bach["vcov_hc0"], "HC0稳健"),
        coefficient_table(
            fit_bach,
            cluster_vcov(fit_bach, acs["household_id"]),
            "按家庭聚类",
            cluster_df,
        ),
    ],
    ignore_index=True,
)

fit_age = fit_ols(y_acs, design_matrix(acs, ["age_centered"]), ["截距", "年龄"])
age_tables = pd.concat(
    [
        coefficient_table(fit_age, fit_age["vcov"], "年龄：普通OLS"),
        coefficient_table(fit_age, fit_age["vcov_hc0"], "年龄：HC0稳健"),
        coefficient_table(
            fit_age,
            cluster_vcov(fit_age, acs["household_id"]),
            "年龄：按家庭聚类",
            cluster_df,
        ),
    ],
    ignore_index=True,
)

fit_full = fit_ols(
    y_acs,
    design_matrix(acs, ["bachelor", "age_centered", "female", "employed"]),
    ["截距", "本科及以上", "年龄", "女性", "就业"],
)
full_table = coefficient_table(
    fit_full,
    cluster_vcov(fit_full, acs["household_id"]),
    "本科+年龄+性别+就业：按家庭聚类",
    cluster_df,
)
cluster_tables = pd.concat([bach_tables, age_tables, full_table], ignore_index=True)
cluster_tables.to_csv(TABLE_DIR / "python_chapter08_acs_cluster_robust_tables.csv", index=False)

se_compare = cluster_tables.loc[
    cluster_tables["项"].eq("本科及以上")
    & cluster_tables["模型"].isin(["普通OLS", "HC0稳健", "按家庭聚类"]),
    ["模型", "标准误"],
].copy()
hc0_se = float(se_compare.loc[se_compare["模型"].eq("HC0稳健"), "标准误"].iloc[0])
se_compare["相对HC0"] = se_compare["标准误"] / hc0_se
se_compare.to_csv(TABLE_DIR / "python_chapter08_bachelor_se_comparison.csv", index=False)

household_size = acs.groupby("household_id").size()
household_size_summary = pd.DataFrame(
    {
        "指标": ["家庭数", "平均家庭样本人数", "中位数家庭样本人数", "最大家庭样本人数", "单人家庭占比"],
        "数值": [
            household_size.size,
            household_size.mean(),
            household_size.median(),
            household_size.max(),
            household_size.eq(1).mean(),
        ],
    }
)
household_size_summary.to_csv(
    RESULT_DIR / "python_chapter08_household_size_summary.csv",
    index=False,
)

# ------------------------------------------------------------------------------
# Box 02--03: 随机截距方差分解
# ------------------------------------------------------------------------------

rng = np.random.default_rng(20260524)
lme_sample_size = min(12000, len(acs))
lme_idx = rng.choice(len(acs), size=lme_sample_size, replace=False)
lme_df = acs.iloc[lme_idx].copy()
variance_components = random_intercept_anova(lme_df, "log_income", "household_id")
variance_components.to_csv(
    RESULT_DIR / "python_chapter08_multilevel_variance_components.csv",
    index=False,
)

# ------------------------------------------------------------------------------
# Box 04: 面板数据与固定效应
# ------------------------------------------------------------------------------

bea = pd.read_csv(BEA_PATH, encoding="utf-8-sig")
bea["state"] = bea["state"].str.replace(r"\s*\*$", "", regex=True).str.strip()
bea["state_fips"] = (pd.to_numeric(bea["geo_fips"]) // 1000).astype(int)
bea_cols = [
    "real_gdp_millions_2017_usd",
    "personal_income_millions_usd",
    "population",
    "per_capita_personal_income_usd",
]
bea_agg = (
    bea.groupby(["state_fips", "state", "year"], as_index=False)[bea_cols]
    .first()
)

bls = pd.read_csv(BLS_PATH, encoding="utf-8-sig")
unemp = (
    bls.loc[bls["series_type"].eq("state_unemployment_rate")]
    .dropna(subset=["state_fips"])
    .copy()
)
unemp["state_fips"] = unemp["state_fips"].astype(int)
unemp = (
    unemp.groupby(["state_fips", "year"], as_index=False)["value"]
    .mean()
    .rename(columns={"value": "unemployment_rate"})
)

panel = pd.merge(bea_agg, unemp, on=["state_fips", "year"])
panel = panel.dropna().copy()
panel = panel.loc[
    panel["population"].gt(0) & panel["real_gdp_millions_2017_usd"].gt(0)
].copy()
panel["income_pc_thousand"] = panel["per_capita_personal_income_usd"] / 1000
panel["gdp_pc_thousand"] = panel["real_gdp_millions_2017_usd"] * 1000 / panel["population"]
panel = panel.loc[panel["year"].between(2015, 2024)].copy()
panel = panel.sort_values(["state", "year"]).reset_index(drop=True)
panel[
    [
        "state",
        "state_fips",
        "year",
        "income_pc_thousand",
        "gdp_pc_thousand",
        "unemployment_rate",
        "population",
    ]
].to_csv(RESULT_DIR / "python_chapter08_bea_bls_state_panel_analysis_data.csv", index=False)

y_panel = panel["income_pc_thousand"].to_numpy(float)
X_pool = design_matrix(panel, ["unemployment_rate"], intercept=True)
fit_pool = fit_ols(y_panel, X_pool, ["截距", "失业率"])
pool_table = coefficient_table(
    fit_pool,
    cluster_vcov(fit_pool, panel["state"]),
    "合并OLS（按州聚类）",
    panel["state"].nunique() - 1,
)

panel["income_state_dm"] = demean_oneway(panel["income_pc_thousand"], panel["state"])
panel["unemp_state_dm"] = demean_oneway(panel["unemployment_rate"], panel["state"])
X_state_fe = panel[["unemp_state_dm"]].to_numpy(float)
fit_state_fe = fit_ols(
    panel["income_state_dm"].to_numpy(float),
    X_state_fe,
    ["失业率"],
)
state_fe_table = coefficient_table(
    fit_state_fe,
    cluster_vcov(fit_state_fe, panel["state"]),
    "州固定效应",
    panel["state"].nunique() - 1,
)

panel["income_tw_dm"] = demean_twoway(panel["income_pc_thousand"], panel["state"], panel["year"])
panel["unemp_tw_dm"] = demean_twoway(panel["unemployment_rate"], panel["state"], panel["year"])
X_tw_fe = panel[["unemp_tw_dm"]].to_numpy(float)
fit_tw_fe = fit_ols(panel["income_tw_dm"].to_numpy(float), X_tw_fe, ["失业率"])
tw_fe_table = coefficient_table(
    fit_tw_fe,
    cluster_vcov(fit_tw_fe, panel["state"]),
    "州与年份双向固定效应",
    panel["state"].nunique() - 1,
)

panel_tables = pd.concat([pool_table, state_fe_table, tw_fe_table], ignore_index=True)
panel_tables.to_csv(TABLE_DIR / "python_chapter08_state_panel_fe_tables.csv", index=False)

panel_model_summary = panel_tables.loc[
    panel_tables["项"].eq("失业率"),
    ["模型", "估计值", "标准误", "t统计量", "p值"],
].copy()
panel_model_summary.to_csv(
    TABLE_DIR / "python_chapter08_panel_model_comparison.csv",
    index=False,
)

within_demo = panel.loc[panel["state"].eq("California")].copy()
within_demo["income_dm"] = within_demo["income_pc_thousand"] - within_demo["income_pc_thousand"].mean()
within_demo["unemp_dm"] = within_demo["unemployment_rate"] - within_demo["unemployment_rate"].mean()
within_demo[
    ["state", "year", "income_pc_thousand", "unemployment_rate", "income_dm", "unemp_dm"]
].to_csv(RESULT_DIR / "python_chapter08_within_transformation_demo.csv", index=False)

bachelor_coef = float(fit_bach["beta"][1])
sd_y = float(acs["log_income"].std(ddof=1))
summary = pd.DataFrame(
    {
        "指标": [
            "ACS样本量",
            "ACS家庭数",
            "本科及以上普通OLS系数",
            "本科及以上标准化系数",
            "方差分解样本量",
            "面板州数",
            "面板年份起点",
            "面板年份终点",
            "双向FE失业率系数",
        ],
        "数值": [
            len(acs),
            acs["household_id"].nunique(),
            bachelor_coef,
            bachelor_coef / sd_y,
            lme_sample_size,
            panel["state"].nunique(),
            panel["year"].min(),
            panel["year"].max(),
            float(fit_tw_fe["beta"][0]),
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter08_summary.csv", index=False)

print("Chapter 08 finished.")
print(f"ACS sample size: {len(acs)}")
print(f"ACS households: {acs['household_id'].nunique()}")
print(f"Panel observations: {len(panel)}")
print(f"Two-way FE unemployment coefficient: {float(fit_tw_fe['beta'][0]):.4f}")
