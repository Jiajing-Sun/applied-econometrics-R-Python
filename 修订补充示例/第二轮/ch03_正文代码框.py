# 第3章Python：从教材按顺序提取；从仓库根目录运行。

# 代码框 1: book_chapters/ch03_probability.tex:358 / ch03_probability_2
import numpy as np

rng = np.random.default_rng(2026)
B = 10000
n = 50
draws = rng.integers(1, 7, size=(B, n))
sample_means = draws.mean(axis=1)
sample_means.mean(), sample_means.std(ddof=1)


# 代码框 2: book_chapters/ch03_probability.tex:551 / ch03_probability_4
from scipy.stats import t
rng = np.random.default_rng(2026)
coverage_B = 5000
coverage_n = 30
tcrit = t.ppf(0.975, df=coverage_n - 1)
cover = []
for _ in range(coverage_B):
    yy = rng.integers(1, 7, size=coverage_n)
    se = yy.std(ddof=1) / np.sqrt(coverage_n)
    ci = yy.mean() + np.array([-1, 1]) * tcrit * se
    cover.append(ci[0] <= 3.5 <= ci[1])
np.mean(cover)

