"""Chapter 03: 基本概率论与统计推断.

The chapter uses simulation rather than an external dataset. This script follows
the textbook's original Monte Carlo, sampling distribution, t-test, and confidence
interval examples, while saving reproducible tables/results to the chapter folder.

It uses only the Python standard library plus numpy/pandas. The companion R script
generates the Chinese-labelled figures.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import pandas as pd


SCRIPT_DIR = Path(__file__).resolve().parent
CHAPTER_DIR = SCRIPT_DIR.parent
TABLE_DIR = CHAPTER_DIR / "tables"
RESULT_DIR = CHAPTER_DIR / "results"

TABLE_DIR.mkdir(parents=True, exist_ok=True)
RESULT_DIR.mkdir(parents=True, exist_ok=True)

rng = np.random.default_rng(20260524)


def t_pdf(x: float, df: int) -> float:
    """Student t density using the standard-library gamma function."""

    num = math.gamma((df + 1) / 2)
    den = math.sqrt(df * math.pi) * math.gamma(df / 2)
    return num / den * (1 + x * x / df) ** (-(df + 1) / 2)


def simpson_integral(func, a: float, b: float, intervals: int = 8000) -> float:
    """Numerically integrate func from a to b with Simpson's rule."""

    if intervals % 2 == 1:
        intervals += 1
    h = (b - a) / intervals
    total = func(a) + func(b)
    for i in range(1, intervals):
        total += (4 if i % 2 else 2) * func(a + i * h)
    return total * h / 3


def t_cdf(x: float, df: int) -> float:
    """Student t CDF by numerical integration."""

    if x == 0:
        return 0.5
    if x > 0:
        return 0.5 + simpson_integral(lambda z: t_pdf(z, df), 0, x)
    return 0.5 - simpson_integral(lambda z: t_pdf(z, df), 0, -x)


def t_ppf(prob: float, df: int) -> float:
    """Student t quantile by bisection."""

    lo, hi = -20.0, 20.0
    for _ in range(80):
        mid = (lo + hi) / 2
        if t_cdf(mid, df) < prob:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


# ------------------------------------------------------------------------------
# Box 01: Python 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

dice_throw = rng.integers(1, 7)

# ------------------------------------------------------------------------------
# Box 02: Python 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

n = 50
dice_throws = rng.integers(1, 7, size=n)
ybar = dice_throws.mean()

# ------------------------------------------------------------------------------
# Box 03: Python 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

nr_samples = 10000
n = 50
ybar_dist = np.empty(nr_samples)

for i in range(nr_samples):
    dice_throws_i = rng.integers(1, 7, size=n)
    ybar_dist[i] = dice_throws_i.mean()

# ------------------------------------------------------------------------------
# Box 04: Python 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

mean_ybar = ybar_dist.mean()
var_ybar = ybar_dist.var(ddof=1)

# ------------------------------------------------------------------------------
# Box 05: Python 中的 Monte Carlo 模拟：向量化写法
# ------------------------------------------------------------------------------

ybar_dist_vectorized = rng.integers(1, 7, size=(nr_samples, n)).mean(axis=1)

mc_summary = pd.DataFrame(
    {
        "指标": [
            "模拟次数",
            "每次样本量",
            "一次模拟样本均值",
            "样本均值的模拟均值_循环",
            "样本均值的模拟方差_循环",
            "样本均值的模拟均值_向量化",
            "样本均值的模拟方差_向量化",
            "理论均值",
            "理论方差",
        ],
        "数值": [
            nr_samples,
            n,
            ybar,
            mean_ybar,
            var_ybar,
            ybar_dist_vectorized.mean(),
            ybar_dist_vectorized.var(ddof=1),
            3.5,
            (35 / 12) / n,
        ],
    }
)
mc_summary.to_csv(RESULT_DIR / "python_chapter03_monte_carlo_summary.csv", index=False)
pd.DataFrame(
    {"模拟编号": np.arange(1, nr_samples + 1), "样本均值": ybar_dist}
).to_csv(RESULT_DIR / "python_chapter03_dice_sample_mean_distribution.csv", index=False)

# ------------------------------------------------------------------------------
# Box 07--13: 使用 Python 进行假设检验和构造置信区间
# ------------------------------------------------------------------------------

dice_throws = np.concatenate(
    [
        np.repeat(1, 13),
        np.repeat(2, 7),
        np.repeat(3, 8),
        np.repeat(4, 9),
        np.repeat(5, 9),
        np.repeat(6, 4),
    ]
)

n = dice_throws.size
mean_dice_throws = dice_throws.mean()
var_dice_throws = dice_throws.var(ddof=1)

se_dice_throws = np.sqrt(var_dice_throws / n)
t_stat = (mean_dice_throws - 3.5) / se_dice_throws

p_value = 2 * (1 - t_cdf(abs(float(t_stat)), df=n - 1))

alpha = 0.05
t_crit = t_ppf(1 - alpha / 2, df=n - 1)

ci_lower = mean_dice_throws - t_crit * se_dice_throws
ci_upper = mean_dice_throws + t_crit * se_dice_throws

dice_count_table = pd.DataFrame(
    {
        "点数": np.arange(1, 7),
        "出现次数": [(dice_throws == k).sum() for k in range(1, 7)],
        "理论概率": np.repeat(1 / 6, 6),
    }
)
dice_count_table.to_csv(TABLE_DIR / "python_chapter03_dice_count_table.csv", index=False)

test_summary = pd.DataFrame(
    {
        "指标": [
            "样本量",
            "样本均值",
            "样本方差",
            "标准误",
            "t统计量",
            "p值",
            "95%置信区间下限",
            "95%置信区间上限",
        ],
        "数值": [
            n,
            mean_dice_throws,
            var_dice_throws,
            se_dice_throws,
            t_stat,
            p_value,
            ci_lower,
            ci_upper,
        ],
    }
)
test_summary.to_csv(RESULT_DIR / "python_chapter03_t_test_summary.csv", index=False)

# ------------------------------------------------------------------------------
# Python 中的置信区间覆盖率模拟
# ------------------------------------------------------------------------------

coverage_B = 5000
coverage_n = 30
coverage_rows = []
tcrit_coverage = t_ppf(0.975, df=coverage_n - 1)
for sim in range(1, coverage_B + 1):
    yy = rng.integers(1, 7, size=coverage_n)
    yy_mean = yy.mean()
    yy_se = yy.std(ddof=1) / math.sqrt(coverage_n)
    lower = yy_mean - tcrit_coverage * yy_se
    upper = yy_mean + tcrit_coverage * yy_se
    coverage_rows.append(
        {
            "simulation": sim,
            "lower": lower,
            "upper": upper,
            "cover": lower <= 3.5 <= upper,
        }
    )
coverage_df = pd.DataFrame(coverage_rows)
coverage_rate = coverage_df["cover"].mean()
coverage_df.to_csv(RESULT_DIR / "python_chapter03_ci_coverage_intervals.csv", index=False)
pd.DataFrame(
    {
        "指标": ["重复抽样次数", "每次样本量", "名义覆盖率", "模拟覆盖率"],
        "数值": [coverage_B, coverage_n, 0.95, coverage_rate],
    }
).to_csv(RESULT_DIR / "python_chapter03_ci_coverage_summary.csv", index=False)

result_lines = [
    "第 3 章：基本概率论与统计推断",
    "",
    "本章使用模拟数据，不依赖外部数据源。",
    f"Monte Carlo模拟次数：{nr_samples}；每次样本量：50",
    f"循环写法下样本均值抽样分布的模拟均值：{mean_ybar:.4f}",
    f"循环写法下样本均值抽样分布的模拟方差：{var_ybar:.5f}",
    f"理论均值：{3.5:.4f}；理论方差：{((35 / 12) / 50):.5f}",
    "",
    f"50次掷骰样本均值：{mean_dice_throws:.4f}",
    f"t统计量：{t_stat:.4f}；p值：{p_value:.4f}",
    f"95%置信区间：[{ci_lower:.4f}, {ci_upper:.4f}]",
    "",
    f"置信区间覆盖率模拟次数：{coverage_B}；每次样本量：{coverage_n}",
    f"95%置信区间的模拟覆盖率：{coverage_rate:.4f}",
]
(RESULT_DIR / "python_chapter03_results_readme.txt").write_text(
    "\n".join(result_lines), encoding="utf-8"
)

print("\n".join(result_lines))
