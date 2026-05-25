"""Chapter 04: 关于总体相关的推断.

Textbook data: World Bank WDI global country-year data.

教学对应关系：
    教材变量 living_area -> log(人均GDP，2015年不变美元)
    教材变量 price       -> 预期寿命

The script keeps the chapter's original Fisher z confidence interval and
correlation t-test workflow. It avoids scipy so it runs in the current minimal
Python environment.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
REPO_DIR = CHAPTER_DIR.parent
DATA_PATH = REPO_DIR / "data" / "processed" / "wdi_global_selected_indicators_wide.csv"
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


def t_pdf(x: float, df: int) -> float:
    num = math.gamma((df + 1) / 2)
    den = math.sqrt(df * math.pi) * math.gamma(df / 2)
    return num / den * (1 + x * x / df) ** (-(df + 1) / 2)


def simpson_integral(func, a: float, b: float, intervals: int = 8000) -> float:
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


wdi = pd.read_csv(DATA_PATH, encoding="utf-8-sig")
complete_counts = (
    wdi.assign(
        complete_cases=lambda d: (
            d["gdp_per_capita_constant_2015_usd"].notna()
            & d["life_expectancy"].notna()
            & d["gdp_per_capita_constant_2015_usd"].gt(0)
        )
    )
    .groupby("year", as_index=False)["complete_cases"]
    .sum()
)
analysis_year = int(complete_counts.loc[complete_counts["complete_cases"].ge(200), "year"].max())

df = wdi.loc[
    wdi["year"].eq(analysis_year),
    ["country", "country_code", "year", "gdp_per_capita_constant_2015_usd", "life_expectancy"],
].dropna()
df = df.loc[df["gdp_per_capita_constant_2015_usd"].gt(0)].copy()
df["log_gdp_per_capita"] = np.log(df["gdp_per_capita_constant_2015_usd"])
df = df.sort_values("country").reset_index(drop=True)

df.to_csv(RESULT_DIR / "python_chapter04_wdi_life_gdp_analysis_data.csv", index=False)

# ------------------------------------------------------------------------------
# Box 01: 在 Python 中计算相关的置信区间
# ------------------------------------------------------------------------------

x = df["log_gdp_per_capita"].to_numpy()
y = df["life_expectancy"].to_numpy()
n = len(df)

corrXY = np.corrcoef(x, y)[0, 1]
Z = 0.5 * np.log((1 + corrXY) / (1 - corrXY))

alpha = 0.05
z_alpha_2 = 1.959963984540054

Z_L = Z - z_alpha_2 * np.sqrt(1 / (n - 3))
Z_U = Z + z_alpha_2 * np.sqrt(1 / (n - 3))

CI_L = (np.exp(2 * Z_L) - 1) / (np.exp(2 * Z_L) + 1)
CI_U = (np.exp(2 * Z_U) - 1) / (np.exp(2 * Z_U) + 1)

# ------------------------------------------------------------------------------
# Box 02: 相关为零的 t 检验
# ------------------------------------------------------------------------------

corrXY2 = corrXY
t_stat = corrXY2 * np.sqrt((n - 2) / (1 - corrXY2**2))
p_value = 2 * (1 - t_cdf(abs(float(t_stat)), df=n - 2))
p_value = min(1.0, max(0.0, float(p_value)))
p_value_text = "< 1e-15" if p_value == 0 else f"{p_value:.4g}"

summary_table = pd.DataFrame(
    {
        "指标": [
            "分析年份",
            "完整样本量",
            "Pearson相关系数",
            "Fisher_Z",
            "95%置信区间下限_手算",
            "95%置信区间上限_手算",
            "t统计量",
            "p值",
        ],
        "数值": [
            analysis_year,
            n,
            corrXY,
            Z,
            CI_L,
            CI_U,
            t_stat,
            p_value,
        ],
    }
)
summary_table.to_csv(RESULT_DIR / "python_chapter04_correlation_inference_summary.csv", index=False)

preview_table = (
    df.sort_values("gdp_per_capita_constant_2015_usd", ascending=False)
    .loc[
        :,
        [
            "country",
            "country_code",
            "gdp_per_capita_constant_2015_usd",
            "log_gdp_per_capita",
            "life_expectancy",
        ],
    ]
    .head(12)
    .rename(
        columns={
            "country": "国家或地区",
            "country_code": "代码",
            "gdp_per_capita_constant_2015_usd": "人均GDP_2015不变美元",
            "log_gdp_per_capita": "log人均GDP",
            "life_expectancy": "预期寿命",
        }
    )
)
preview_table.to_csv(TABLE_DIR / "python_chapter04_wdi_preview_table.csv", index=False)

result_lines = [
    "第 4 章：关于总体相关的推断",
    "",
    "数据：World Bank WDI 全球国家/地区年度数据。",
    "X：log(人均GDP，2015年不变美元)；Y：预期寿命。",
    f"分析年份：{analysis_year}；完整样本量：{n}",
    f"Pearson相关系数：{corrXY:.4f}",
    f"95% Fisher Z置信区间：[{CI_L:.4f}, {CI_U:.4f}]",
    f"相关为零的t统计量：{t_stat:.4f}；p值：{p_value_text}",
]
(RESULT_DIR / "python_chapter04_results_readme.txt").write_text(
    "\n".join(result_lines), encoding="utf-8"
)

print("\n".join(result_lines))
