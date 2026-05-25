"""Chapter 05: 一元线性回归模型.

Textbook data: 国家统计局 70 个大中城市商品住宅销售价格指数（2025）。

教学对应关系：
    教材变量 price          -> 二手住宅同比价格指数
    教材变量 living_area    -> 新建商品住宅同比价格指数
    教材变量 new_production -> 是否一线城市（北京、上海、广州、深圳）

The script keeps the original chapter workflow: standard OLS inference, a binary
regressor example, HC0 robust standard errors, and a DGP Monte Carlo exercise.
It uses only numpy/pandas plus the Python standard library.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
DATA_PATH = REPO_DIR / "data" / "processed" / "nbs_70city_house_price_2025.csv"
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


def two_sided_t_pvalue(t_stat: float, df: int) -> float:
    if abs(float(t_stat)) > 12:
        return 0.0
    p = 2 * (1 - t_cdf(abs(float(t_stat)), df=df))
    return min(1.0, max(0.0, float(p)))


def fit_simple_ols(x: np.ndarray, y: np.ndarray) -> dict[str, np.ndarray | float]:
    n = len(y)
    xbar = x.mean()
    ybar = y.mean()
    sxx = ((x - xbar) ** 2).sum()
    sxy = ((x - xbar) * (y - ybar)).sum()
    beta1 = sxy / sxx
    beta0 = ybar - beta1 * xbar
    y_hat = beta0 + beta1 * x
    u_hat = y - y_hat
    rss = float((u_hat**2).sum())
    tss = float(((y - ybar) ** 2).sum())
    r2 = 1 - rss / tss
    s2 = rss / (n - 2)
    se1 = math.sqrt(s2 / sxx)
    se0 = math.sqrt(s2 * (1 / n + xbar**2 / sxx))
    xmat = np.column_stack([np.ones(n), x])
    bread = np.linalg.inv(xmat.T @ xmat)
    meat = xmat.T @ (xmat * (u_hat**2)[:, None])
    vcov_hc0 = bread @ meat @ bread
    se_hc0 = np.sqrt(np.diag(vcov_hc0))
    return {
        "n": n,
        "beta": np.array([beta0, beta1]),
        "y_hat": y_hat,
        "u_hat": u_hat,
        "rss": rss,
        "tss": tss,
        "r2": r2,
        "se_standard": np.array([se0, se1]),
        "se_hc0": se_hc0,
        "vcov_hc0": vcov_hc0,
    }


raw = pd.read_csv(DATA_PATH, encoding="utf-8-sig")

new_house = raw.loc[
    raw["market"].eq("new_house"),
    ["city", "date", "year", "month", "mom_index", "yoy_index"],
].rename(columns={"mom_index": "new_house_mom", "yoy_index": "new_house_yoy"})

second_hand = raw.loc[
    raw["market"].eq("second_hand"),
    ["city", "date", "year", "month", "mom_index", "yoy_index"],
].rename(columns={"mom_index": "second_hand_mom", "yoy_index": "second_hand_yoy"})

df = pd.merge(new_house, second_hand, on=["city", "date", "year", "month"])
df = df.dropna(subset=["new_house_yoy", "second_hand_yoy"]).copy()
df["first_tier_city"] = df["city"].isin(["北京", "上海", "广州", "深圳"]).astype(int)
df = df.sort_values(["date", "city"]).reset_index(drop=True)

df.to_csv(RESULT_DIR / "python_chapter05_70city_regression_data.csv", index=False)

x = df["new_house_yoy"].to_numpy()
y = df["second_hand_yoy"].to_numpy()
fit = fit_simple_ols(x, y)
n = int(fit["n"])
beta_0_hat, beta_1_hat = fit["beta"]
y_hat = fit["y_hat"]
u_hat = fit["u_hat"]
RSS = float(fit["rss"])
TSS = float(fit["tss"])
R2 = float(fit["r2"])

# ------------------------------------------------------------------------------
# Box 01: Python 中的回归推断
# ------------------------------------------------------------------------------

s2_epsilon = RSS / (n - 2)
SSX = ((df["new_house_yoy"] - df["new_house_yoy"].mean()) ** 2).sum()

var_hat_beta_1_hat = s2_epsilon / SSX
se_beta_1_hat = np.sqrt(var_hat_beta_1_hat)

# ------------------------------------------------------------------------------
# Box 02: Python 中的回归推断
# ------------------------------------------------------------------------------

beta_1_H0 = 0
t_stat = (beta_1_hat - beta_1_H0) / se_beta_1_hat
p_val = two_sided_t_pvalue(t_stat, df=n - 2)

# ------------------------------------------------------------------------------
# Box 03: Python 中的回归推断
# ------------------------------------------------------------------------------

alpha = 0.10
t_crit = t_ppf(1 - alpha / 2, df=n - 2)

lb = beta_1_hat - t_crit * se_beta_1_hat
ub = beta_1_hat + t_crit * se_beta_1_hat

standard_se = fit["se_standard"]
t_standard = fit["beta"] / standard_se
p_standard = np.array([two_sided_t_pvalue(t, n - 2) for t in t_standard])
standard_ci = np.column_stack(
    [fit["beta"] - t_crit * standard_se, fit["beta"] + t_crit * standard_se]
)
standard_table = pd.DataFrame(
    {
        "项": ["截距", "新房同比指数"],
        "估计值": fit["beta"],
        "标准误": standard_se,
        "t统计量": t_standard,
        "p值": p_standard,
        "CI90下限": standard_ci[:, 0],
        "CI90上限": standard_ci[:, 1],
    }
)
standard_table.to_csv(TABLE_DIR / "python_chapter05_ols_standard_table.csv", index=False)

# ------------------------------------------------------------------------------
# Box 06: 二元自变量回归
# ------------------------------------------------------------------------------

x_binary = df["first_tier_city"].to_numpy()
fit_binary = fit_simple_ols(x_binary, y)
binary_se = fit_binary["se_standard"]
t_binary = fit_binary["beta"] / binary_se
p_binary = np.array([two_sided_t_pvalue(t, n - 2) for t in t_binary])
binary_ci = np.column_stack(
    [fit_binary["beta"] - t_crit * binary_se, fit_binary["beta"] + t_crit * binary_se]
)
binary_table = pd.DataFrame(
    {
        "项": ["截距", "一线城市"],
        "估计值": fit_binary["beta"],
        "标准误": binary_se,
        "t统计量": t_binary,
        "p值": p_binary,
        "CI90下限": binary_ci[:, 0],
        "CI90上限": binary_ci[:, 1],
    }
)
binary_table.to_csv(TABLE_DIR / "python_chapter05_binary_city_table.csv", index=False)

# ------------------------------------------------------------------------------
# Box 07--10: 稳健推断
# ------------------------------------------------------------------------------

dx2 = (df["new_house_yoy"] - df["new_house_yoy"].mean()) ** 2
var_beta_1_hat_r = (dx2 * (u_hat**2)).sum() / (dx2.sum() ** 2)
se_beta_1_hat_r = np.sqrt(var_beta_1_hat_r)

lb_r = beta_1_hat - t_crit * se_beta_1_hat_r
ub_r = beta_1_hat + t_crit * se_beta_1_hat_r

se_hc0 = fit["se_hc0"]
t_hc0 = fit["beta"] / se_hc0
p_hc0 = np.array([two_sided_t_pvalue(t, n - 2) for t in t_hc0])
ci_hc0 = np.column_stack([fit["beta"] - t_crit * se_hc0, fit["beta"] + t_crit * se_hc0])
robust_table = pd.DataFrame(
    {
        "项": ["截距", "新房同比指数"],
        "估计值": fit["beta"],
        "HC0稳健标准误": se_hc0,
        "t统计量": t_hc0,
        "p值": p_hc0,
        "CI90下限": ci_hc0[:, 0],
        "CI90上限": ci_hc0[:, 1],
    }
)
robust_table.to_csv(TABLE_DIR / "python_chapter05_ols_hc0_robust_table.csv", index=False)

model_summary = pd.DataFrame(
    {
        "指标": [
            "样本量",
            "OLS截距",
            "OLS斜率",
            "RSS",
            "TSS",
            "R2",
            "普通斜率标准误",
            "普通斜率t统计量",
            "普通斜率p值",
            "普通斜率90%CI下限",
            "普通斜率90%CI上限",
            "HC0斜率标准误",
            "HC0斜率t统计量",
            "HC0斜率p值",
            "HC0斜率90%CI下限",
            "HC0斜率90%CI上限",
            "一线城市斜率",
            "一线城市斜率p值",
        ],
        "数值": [
            n,
            beta_0_hat,
            beta_1_hat,
            RSS,
            TSS,
            R2,
            se_beta_1_hat,
            t_stat,
            p_val,
            lb,
            ub,
            se_hc0[1],
            t_hc0[1],
            p_hc0[1],
            ci_hc0[1, 0],
            ci_hc0[1, 1],
            fit_binary["beta"][1],
            p_binary[1],
        ],
    }
)
model_summary.to_csv(RESULT_DIR / "python_chapter05_regression_summary.csv", index=False)

# ------------------------------------------------------------------------------
# Box 11--12: 数据生成过程与 Monte Carlo 模拟
# ------------------------------------------------------------------------------

rng = np.random.default_rng(20260524)
nr_samples = 10000
n_mc = 30

tstat_standard = np.empty(nr_samples)
tstat_robust = np.empty(nr_samples)

for i in range(nr_samples):
    X = rng.uniform(0, 1, size=n_mc)
    E = rng.chisquare(df=1, size=n_mc)
    Y = 0.3 + 0.2 * X * E

    fit_mc = fit_simple_ols(X, Y)
    beta1_hat_mc = fit_mc["beta"][1]
    se_standard_mc = fit_mc["se_standard"][1]
    se_robust_mc = fit_mc["se_hc0"][1]

    tstat_standard[i] = (beta1_hat_mc - 0.2) / se_standard_mc
    tstat_robust[i] = (beta1_hat_mc - 0.2) / se_robust_mc

dgp_summary = pd.DataFrame(
    {
        "统计量": [
            "普通标准误t统计量均值",
            "普通标准误t统计量方差",
            "稳健标准误t统计量均值",
            "稳健标准误t统计量方差",
            "t分布理论方差_df28",
        ],
        "数值": [
            tstat_standard.mean(),
            tstat_standard.var(ddof=1),
            tstat_robust.mean(),
            tstat_robust.var(ddof=1),
            (n_mc - 2) / (n_mc - 4),
        ],
    }
)
dgp_summary.to_csv(RESULT_DIR / "python_chapter05_dgp_monte_carlo_summary.csv", index=False)
pd.DataFrame(
    {
        "模拟编号": np.arange(1, nr_samples + 1),
        "普通标准误t统计量": tstat_standard,
        "稳健标准误t统计量": tstat_robust,
    }
).to_csv(RESULT_DIR / "python_chapter05_dgp_tstat_distribution.csv", index=False)

result_lines = [
    "第 5 章：一元线性回归模型",
    "",
    "数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025 年月度）。",
    "连续自变量回归：二手住宅同比价格指数 ~ 新建商品住宅同比价格指数。",
    "二元自变量回归：二手住宅同比价格指数 ~ 是否一线城市。",
    f"样本量：{n}",
    f"OLS斜率：{beta_1_hat:.4f}；普通标准误：{se_beta_1_hat:.4f}；90%CI：[{lb:.4f}, {ub:.4f}]",
    f"HC0稳健标准误：{se_hc0[1]:.4f}；90%稳健CI：[{ci_hc0[1, 0]:.4f}, {ci_hc0[1, 1]:.4f}]",
    f"R2：{R2:.4f}",
    f"一线城市斜率：{fit_binary['beta'][1]:.4f}",
]
(RESULT_DIR / "python_chapter05_results_readme.txt").write_text(
    "\n".join(result_lines), encoding="utf-8"
)

print("\n".join(result_lines))
