"""Chapter 13: 非参数回归方法.

Textbook data: WDI global indicators + OWID global annual CO2.

This script implements Nadaraya-Watson kernel regression, local linear
regression, bandwidth comparison, leave-one-out cross-validation, and bootstrap
pointwise confidence bands with numpy/pandas only.
"""

from __future__ import annotations

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


def gaussian_kernel(u: np.ndarray) -> np.ndarray:
    return np.exp(-0.5 * u * u) / np.sqrt(2 * np.pi)


def nw_predict(x: np.ndarray, y: np.ndarray, grid: np.ndarray, h: float) -> np.ndarray:
    out = []
    for x0 in grid:
        w = gaussian_kernel((x - x0) / h)
        out.append(float((w * y).sum() / w.sum()))
    return np.asarray(out)


def local_linear_predict(x: np.ndarray, y: np.ndarray, grid: np.ndarray, h: float) -> np.ndarray:
    out = []
    for x0 in grid:
        z = x - x0
        w = gaussian_kernel(z / h)
        X = np.column_stack([np.ones(len(x)), z])
        xtwx = X.T @ (X * w[:, None])
        xtwy = X.T @ (w * y)
        beta = np.linalg.pinv(xtwx) @ xtwy
        out.append(float(beta[0]))
    return np.asarray(out)


def loocv_nw(x: np.ndarray, y: np.ndarray, h: float) -> float:
    pred = np.empty(len(y))
    for i in range(len(y)):
        mask = np.ones(len(y), dtype=bool)
        mask[i] = False
        pred[i] = nw_predict(x[mask], y[mask], np.array([x[i]]), h)[0]
    return float(np.mean((y - pred) ** 2))


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
df_all = df_all.loc[
    df_all["gdp_per_capita_constant_2015_usd"].gt(0)
    & df_all["population"].gt(0)
    & df_all["annual_co2_emissions"].gt(0)
    & df_all["co2_pc_tonnes"].gt(0)
].copy()
df_all["log_gdp_pc"] = np.log(df_all["gdp_per_capita_constant_2015_usd"])
usable = df_all.dropna(
    subset=["gdp_per_capita_constant_2015_usd", "population", "annual_co2_emissions", "co2_pc_tonnes", "log_gdp_pc"]
).copy()
year_counts = usable.groupby("year")["country_code"].size()
analysis_year = int(year_counts[year_counts >= 150].index.max())
df = usable.loc[usable["year"].eq(analysis_year)].sort_values("log_gdp_pc").reset_index(drop=True)

x = df["log_gdp_pc"].to_numpy(float)
y = df["co2_pc_tonnes"].to_numpy(float)
grid = np.linspace(np.quantile(x, 0.02), np.quantile(x, 0.98), 180)
h_values = {"小带宽": 0.25, "中带宽": 0.45, "大带宽": 0.75}

df[
    ["country", "country_code", "year", "gdp_per_capita_constant_2015_usd", "log_gdp_pc", "population", "co2_pc_tonnes"]
].to_csv(RESULT_DIR / "python_chapter13_nonparametric_analysis_data.csv", index=False)

bin_breaks = np.linspace(x.min(), x.max(), 9)
bin_id = np.digitize(x, bin_breaks[1:-1], right=False) + 1
hist_rows = []
for group in sorted(np.unique(bin_id)):
    mask = bin_id == group
    hist_rows.append(
        {
            "组": int(group),
            "log_gdp_pc": float(x[mask].mean()),
            "co2_pc_tonnes": float(y[mask].mean()),
            "样本量": int(mask.sum()),
            "左端点": float(bin_breaks[group - 1]),
            "右端点": float(bin_breaks[group]),
        }
    )
pd.DataFrame(hist_rows).to_csv(TABLE_DIR / "python_chapter13_regression_histogram_bins.csv", index=False)

nw_curves = pd.DataFrame({"log_gdp_pc": grid})
for name, h in h_values.items():
    nw_curves[name] = nw_predict(x, y, grid, h)
nw_curves.to_csv(RESULT_DIR / "python_chapter13_nw_bandwidth_curves.csv", index=False)

h_grid = np.linspace(0.18, 1.1, 25)
cv_mse = np.array([loocv_nw(x, y, h) for h in h_grid])
cv_table = pd.DataFrame({"带宽": h_grid, "LOOCV_MSE": cv_mse})
cv_table.to_csv(TABLE_DIR / "python_chapter13_bandwidth_loocv.csv", index=False)
best_h = float(h_grid[np.argmin(cv_mse)])

nw_best = nw_predict(x, y, grid, best_h)
ll_best = local_linear_predict(x, y, grid, best_h)
X_poly = np.column_stack([np.ones(len(x)), x, x**2, x**3])
beta_poly = np.linalg.pinv(X_poly) @ y
poly_pred = np.column_stack([np.ones(len(grid)), grid, grid**2, grid**3]) @ beta_poly
smooth_table = pd.DataFrame(
    {"log_gdp_pc": grid, "NW最优带宽": nw_best, "局部线性": ll_best, "三阶多项式": poly_pred}
)
smooth_table.to_csv(RESULT_DIR / "python_chapter13_smooth_curves.csv", index=False)

boundary_rng = np.random.default_rng(20260525)
x_sim = np.sort(boundary_rng.uniform(size=180))
y_sim = 1 + 2 * x_sim + boundary_rng.normal(scale=0.25, size=len(x_sim))
grid_sim = np.linspace(0.0, 1.0, 160)
h_boundary = 0.14
boundary_table = pd.DataFrame(
    {
        "x": grid_sim,
        "真实条件均值": 1 + 2 * grid_sim,
        "NW核回归": nw_predict(x_sim, y_sim, grid_sim, h_boundary),
        "局部线性": local_linear_predict(x_sim, y_sim, grid_sim, h_boundary),
    }
)
boundary_table.to_csv(TABLE_DIR / "python_chapter13_boundary_bias_demo.csv", index=False)

rng = np.random.default_rng(20260524)
B = 200
boot = np.empty((len(grid), B))
for b in range(B):
    idx = rng.integers(0, len(y), size=len(y))
    boot[:, b] = local_linear_predict(x[idx], y[idx], grid, best_h)
ci_low = np.quantile(boot, 0.025, axis=1)
ci_high = np.quantile(boot, 0.975, axis=1)
ci_table = pd.DataFrame({"log_gdp_pc": grid, "局部线性": ll_best, "CI下限": ci_low, "CI上限": ci_high})
ci_table.to_csv(RESULT_DIR / "python_chapter13_local_linear_bootstrap_ci.csv", index=False)

summary = pd.DataFrame(
    {
        "指标": ["分析年份", "样本量", "最优带宽", "最小LOOCV_MSE", "bootstrap次数", "局部线性曲线均值"],
        "数值": [analysis_year, len(y), best_h, float(cv_mse.min()), B, float(ll_best.mean())],
    }
)
summary.to_csv(RESULT_DIR / "python_chapter13_summary.csv", index=False)

print("Chapter 13 finished.")
print(f"Analysis year: {analysis_year}")
print(f"Sample size: {len(y)}")
print(f"Best bandwidth: {best_h:.4f}")
