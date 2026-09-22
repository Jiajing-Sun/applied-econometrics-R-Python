# 第 3 章 Python：按章顺序提取教材正文代码框。
# 从“配套代码”根目录运行；data/processed 为冻结数据目录。
# 此文件不含审查断言；保留教材显示用的表达式。


# 教材：ch03_probability.tex:345；
import numpy as np

rng = np.random.default_rng(2026)
B = 10000
n = 50
draws = rng.integers(1, 7, size=(B, n))
sample_means = draws.mean(axis=1)
sample_means.mean(), sample_means.std(ddof=1)


# 教材：ch03_probability.tex:537；
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

