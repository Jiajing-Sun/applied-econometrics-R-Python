# 第4章Python：从教材按顺序提取；从仓库根目录运行。

# 代码框 1: book_chapters/ch04_correlation_inference.tex:118 / ch4_corr_py
import pandas as pd, numpy as np
from scipy import stats

df = pd.read_csv("data/processed/chapter04_wdi_life_gdp_2024_economies.csv")
assert len(df) == 192 and df["country_code"].is_unique

# Pearson 相关检验
r, pval = stats.pearsonr(df["log_gdp_pc"], df["life_expectancy"])
print(f"r = {r:.4f}, p = {pval:.2e}")

# 手工 Fisher 变换置信区间
n = len(df)
z  = np.arctanh(r)            # = 0.5 * log((1+r)/(1-r))
se = 1 / np.sqrt(n - 3)
ci_z = z + np.array([-1, 1]) * stats.norm.ppf(0.975) * se
ci_r = np.tanh(ci_z)          # 反变换回相关系数尺度
print(f"95% CI: [{ci_r[0]:.3f}, {ci_r[1]:.3f}]")

# 按地区分组
def corr_row(g):
    r2 = g["log_gdp_pc"].corr(g["life_expectancy"])
    return pd.Series({"r": r2, "n": len(g)})

df.groupby("region").apply(corr_row)


# 代码框 2: book_chapters/ch04_correlation_inference.tex:253 / ch4_boot_py
rng = np.random.default_rng(42)
r_boot = np.array([
    np.corrcoef(
        *df[["log_gdp_pc","life_expectancy"]]
          .sample(n=len(df), replace=True, random_state=rng).values.T
    )[0,1]
    for _ in range(9999)
])
np.percentile(r_boot, [2.5, 97.5])   # 百分位 Bootstrap CI


# 代码框 3: book_chapters/ch04_correlation_inference.tex:418 / ch04_correlation_inference_5
x = df["log_gdp_pc"].to_numpy()
y = df["life_expectancy"].to_numpy()
Z = np.column_stack([np.ones(len(df)), np.log(df["population"])])
ex = x - Z @ np.linalg.lstsq(Z, x, rcond=None)[0]
ey = y - Z @ np.linalg.lstsq(Z, y, rcond=None)[0]
partial = np.corrcoef(ex, ey)[0, 1]
semipartial = np.corrcoef(y, ex)[0, 1]
ZX = np.column_stack([Z, x])
e_full = y - ZX @ np.linalg.lstsq(ZX, y, rcond=None)[0]
delta_r2 = (ey @ ey - e_full @ e_full) / np.sum((y - y.mean())**2)
assert np.isclose(semipartial**2, delta_r2)
print(partial, semipartial)


# 代码框 4: book_chapters/ch04_correlation_inference.tex:495 / ch04_correlation_inference_7
import numpy as np
rng = np.random.default_rng(42)
x = df["log_gdp_pc"].to_numpy()
y = df["life_expectancy"].to_numpy()
B = 9999
t_obs = np.corrcoef(x, y)[0, 1]
t_perm = np.array([np.corrcoef(x, rng.permutation(y))[0, 1]
                   for _ in range(B)])
p_perm = (1 + np.sum(np.abs(t_perm) >= abs(t_obs))) / (B + 1)
print(p_perm)

