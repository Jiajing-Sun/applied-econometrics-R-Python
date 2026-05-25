"""Chapter 11: 时间序列分析.

Textbook data: World Bank WDI annual China macro data.

教学对应关系：
    Sweden quarterly GDP -> 中国实际 GDP 年度序列（2015年不变美元）

This script implements moving averages, autocorrelation, log growth, AR(1),
Newey-West/HAC standard errors, and AR order selection without statsmodels.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
WDI_PATH = REPO_DIR / "data" / "processed" / "wdi_china_macro_1960_2024.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def fit_ols(y: np.ndarray, X: np.ndarray) -> dict[str, np.ndarray | float | int]:
    xtx_inv = np.linalg.inv(X.T @ X)
    beta = xtx_inv @ X.T @ y
    fitted = X @ beta
    resid = y - fitted
    n, p = X.shape
    sigma2 = float((resid @ resid) / (n - p))
    vcov = sigma2 * xtx_inv
    return {"beta": beta, "fitted": fitted, "resid": resid, "vcov": vcov, "n": n, "p": p}


def newey_west_vcov(X: np.ndarray, resid: np.ndarray, max_lag: int) -> np.ndarray:
    n, _ = X.shape
    xtx_inv = np.linalg.inv(X.T @ X)
    scores = X * resid[:, None]
    S = scores.T @ scores
    for lag in range(1, max_lag + 1):
        weight = 1 - lag / (max_lag + 1)
        Gamma = scores[lag:].T @ scores[:-lag]
        S += weight * (Gamma + Gamma.T)
    return xtx_inv @ S @ xtx_inv


def normal_cdf(z: np.ndarray) -> np.ndarray:
    import math

    return 0.5 * (1 + np.vectorize(math.erf)(z / np.sqrt(2)))


def coefficient_table(beta: np.ndarray, vcov: np.ndarray, names: list[str], model: str) -> pd.DataFrame:
    se = np.sqrt(np.diag(vcov))
    stat = beta / se
    p = np.maximum(0.0, 2 * (1 - normal_cdf(np.abs(stat))))
    return pd.DataFrame(
        {"模型": model, "项": names, "估计值": beta, "标准误": se, "t统计量": stat, "p值": p}
    )


def acf_values(x: np.ndarray, max_lag: int) -> pd.DataFrame:
    x = x - x.mean()
    denom = float((x * x).sum())
    rows = []
    for lag in range(max_lag + 1):
        num = float((x[lag:] * x[: len(x) - lag]).sum())
        rows.append({"滞后阶数": lag, "自相关": num / denom})
    return pd.DataFrame(rows)


def pacf_values(y: np.ndarray, max_lag: int) -> pd.DataFrame:
    rows = [{"滞后阶数": 0, "偏自相关": 1.0}]
    for p in range(1, max_lag + 1):
        y_ar, X_ar = embed_lags(y, p)
        fit_p = fit_ols(y_ar, X_ar)
        rows.append({"滞后阶数": p, "偏自相关": float(fit_p["beta"][-1])})
    return pd.DataFrame(rows)


def embed_lags(y: np.ndarray, p: int) -> tuple[np.ndarray, np.ndarray]:
    rows_y, rows_x = [], []
    for t in range(p, len(y)):
        rows_y.append(y[t])
        rows_x.append([1.0] + [y[t - j] for j in range(1, p + 1)])
    return np.asarray(rows_y), np.asarray(rows_x)


df = pd.read_csv(WDI_PATH, encoding="utf-8-sig")
df = df.dropna(subset=["year", "gdp_constant_2015_usd"]).copy()
df = df.loc[df["year"].ge(1978) & df["gdp_constant_2015_usd"].gt(0)].copy()
df = df.sort_values("year").reset_index(drop=True)

years = df["year"].to_numpy(int)
gdp = df["gdp_constant_2015_usd"].to_numpy(float)
gdpL1 = np.r_[np.nan, gdp[:-1]]
gdpL2 = np.r_[np.nan, np.nan, gdp[:-2]]
gdpF1 = np.r_[gdp[1:], np.nan]
gdpF2 = np.r_[gdp[2:], np.nan, np.nan]
ma = (gdpL2 / 2 + gdpL1 + gdp + gdpF1 + gdpF2 / 2) / 4

mean_gdp = gdp.mean()
r_1 = float(((gdp[1:] - mean_gdp) * (gdpL1[1:] - mean_gdp)).sum() / ((gdp - mean_gdp) ** 2).sum())

dloggdp = np.r_[np.nan, np.diff(np.log(gdp)) * 100]
dlogma = np.r_[np.nan, np.diff(np.log(ma)) * 100]
dloggdpL1 = np.r_[np.nan, dloggdp[:-1]]
dlogmaL1 = np.r_[np.nan, dlogma[:-1]]
loggdp = np.log(gdp)

dft = pd.DataFrame(
    {
        "year": years,
        "gdp": gdp,
        "gdp_trillion": gdp / 1e12,
        "ma": ma / 1e12,
        "dloggdp": dloggdp,
        "dlogma": dlogma,
        "dloggdpL1": dloggdpL1,
        "dlogmaL1": dlogmaL1,
    }
)
dft.to_csv(RESULT_DIR / "python_chapter11_china_gdp_time_series_data.csv", index=False)

acf_level_table = acf_values(gdp, 15)
acf_level_table.to_csv(TABLE_DIR / "python_chapter11_china_gdp_level_acf.csv", index=False)
growth = dloggdp[~np.isnan(dloggdp)]
acf_table = acf_values(growth, 15)
acf_table.to_csv(TABLE_DIR / "python_chapter11_china_gdp_acf.csv", index=False)
pacf_table = pacf_values(growth, 15)
pacf_table.to_csv(TABLE_DIR / "python_chapter11_china_gdp_pacf.csv", index=False)

reg = dft.dropna(subset=["dloggdp", "dloggdpL1"]).copy()
y = reg["dloggdp"].to_numpy(float)
X = np.column_stack([np.ones(len(reg)), reg["dloggdpL1"].to_numpy(float)])
fit = fit_ols(y, X)
nw_vcov = newey_west_vcov(X, fit["resid"], max_lag=5)
ar1_tables = pd.concat(
    [
        coefficient_table(fit["beta"], fit["vcov"], ["截距", "GDP增长率滞后一期"], "普通OLS"),
        coefficient_table(fit["beta"], nw_vcov, ["截距", "GDP增长率滞后一期"], "Newey-West HAC"),
    ],
    ignore_index=True,
)
ar1_tables.to_csv(TABLE_DIR / "python_chapter11_ar1_hac_table.csv", index=False)

y_growth = dloggdp[~np.isnan(dloggdp)]
ar_rows = []
for p in range(1, 6):
    y_ar, X_ar = embed_lags(y_growth, p)
    fit_p = fit_ols(y_ar, X_ar)
    rss = float(fit_p["resid"] @ fit_p["resid"])
    sigma2 = rss / len(y_ar)
    aic = len(y_ar) * np.log(sigma2) + 2 * (p + 1)
    ar_rows.append({"阶数": p, "AIC": aic, "RSS": rss})
ar_aic = pd.DataFrame(ar_rows)
ar_aic.to_csv(TABLE_DIR / "python_chapter11_ar_order_aic.csv", index=False)

se_compare = pd.DataFrame(
    {
        "标准误类型": ["普通OLS", "Newey-West HAC"],
        "滞后项标准误": [float(np.sqrt(np.diag(fit["vcov"]))[1]), float(np.sqrt(np.diag(nw_vcov))[1])],
    }
)
se_compare.to_csv(TABLE_DIR / "python_chapter11_se_comparison.csv", index=False)

last_year = int(reg["year"].max())
last_gdp = float(df.loc[df["year"].eq(last_year), "gdp_constant_2015_usd"].iloc[0])
last_growth = float(reg.loc[reg["year"].eq(last_year), "dloggdp"].iloc[0])
forecast_growth = float(fit["beta"][0] + fit["beta"][1] * last_growth)
resid_sd_pct = float(np.sqrt(np.mean(fit["resid"] ** 2)))
forecast_log_naive = np.log(last_gdp) + forecast_growth / 100
forecast_log_corrected = forecast_log_naive + 0.5 * (resid_sd_pct / 100) ** 2
forecast_level_naive = float(np.exp(forecast_log_naive))
forecast_level_corrected = float(np.exp(forecast_log_corrected))
forecast_lower = float(np.exp(forecast_log_naive - 1.96 * resid_sd_pct / 100))
forecast_upper = float(np.exp(forecast_log_naive + 1.96 * resid_sd_pct / 100))
forecast_table = pd.DataFrame(
    {
        "项": [
            "最后观测年份",
            "最后观测GDP（万亿美元）",
            "最后观测增长率（%）",
            "预测年份",
            "预测增长率（%）",
            "朴素水平预测（万亿美元）",
            "Jensen修正水平预测（万亿美元）",
            "95%预测区间下限（万亿美元）",
            "95%预测区间上限（万亿美元）",
        ],
        "数值": [
            last_year,
            last_gdp / 1e12,
            last_growth,
            last_year + 1,
            forecast_growth,
            forecast_level_naive / 1e12,
            forecast_level_corrected / 1e12,
            forecast_lower / 1e12,
            forecast_upper / 1e12,
        ],
    }
)
forecast_table.to_csv(TABLE_DIR / "python_chapter11_forecast_backtransform.csv", index=False)

dlog_level = np.diff(loggdp)
lag_log_level = loggdp[:-1]
lag_dlog_level = np.r_[np.nan, dlog_level[:-1]]
trend = np.arange(1, len(loggdp))
unit_df = pd.DataFrame(
    {
        "dlog_level": dlog_level,
        "lag_log_level": lag_log_level,
        "lag_dlog_level": lag_dlog_level,
        "trend": trend,
    }
).dropna()
y_df = unit_df["dlog_level"].to_numpy(float)
X_df = np.column_stack(
    [
        np.ones(len(unit_df)),
        unit_df["lag_log_level"].to_numpy(float),
        unit_df["lag_dlog_level"].to_numpy(float),
        unit_df["trend"].to_numpy(float),
    ]
)
df_fit = fit_ols(y_df, X_df)
unit_root_table = coefficient_table(
    df_fit["beta"],
    df_fit["vcov"],
    ["截距", "滞后log水平", "滞后对数差分", "趋势"],
    "ADF式辅助回归",
)
unit_root_table.to_csv(TABLE_DIR / "python_chapter11_unit_root_illustration.csv", index=False)

summary = pd.DataFrame(
    {
        "指标": [
            "起始年份",
            "结束年份",
            "样本量",
            "GDP水平一阶自相关",
            "GDP增长率一阶自相关",
            "AR1滞后项系数",
            "AR1滞后项HAC标准误",
            "AIC选择阶数",
            "一步预测增长率",
            "一步预测GDP万亿美元",
        ],
        "数值": [
            int(years.min()),
            int(years.max()),
            len(years),
            r_1,
            float(acf_table.loc[acf_table["滞后阶数"].eq(1), "自相关"].iloc[0]),
            float(fit["beta"][1]),
            float(np.sqrt(np.diag(nw_vcov))[1]),
            int(ar_aic.loc[ar_aic["AIC"].idxmin(), "阶数"]),
            forecast_growth,
            forecast_level_naive / 1e12,
        ],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter11_summary.csv", index=False)

print("Chapter 11 finished.")
print(f"Years: {years.min()} - {years.max()}")
print(f"Lag-1 autocorrelation: {r_1:.4f}")
print(f"AR(1) coefficient: {float(fit['beta'][1]):.4f}")
