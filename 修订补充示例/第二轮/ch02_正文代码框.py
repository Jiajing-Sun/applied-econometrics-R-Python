# 第 2 章 Python：按章顺序提取教材正文代码框。
# 从“配套代码”根目录运行；data/processed 为冻结数据目录。
# 此文件不含审查断言；保留教材显示用的表达式。


# 教材：ch02_covariation.tex:113；box:pkorr
import pandas as pd
import numpy as np

df = pd.read_csv("data/processed/nbs_70city_house_price_2025.csv")
new_house = df.loc[df["market"].eq("new_house")]
second_hand = df.loc[df["market"].eq("second_hand")]

wide = new_house.merge(
    second_hand, on=["city", "date", "year", "month"],
    suffixes=("_new", "_second")
)
wide = wide.sort_values(["date", "city"]).reset_index(drop=True)
x = wide["yoy_index_new"]
y = wide["yoy_index_second"]

s_xy = ((x - x.mean()) * (y - y.mean())).sum() / (len(wide) - 1)
r_xy = s_xy / (x.std(ddof=1) * y.std(ddof=1))
r_xy


# 教材：ch02_covariation.tex:228；box:pspearman
wide["rank_new"] = wide["yoy_index_new"].rank(method="average")
wide["rank_second"] = wide["yoy_index_second"].rank(method="average")

wide["rank_new"].corr(wide["rank_second"])
wide["yoy_index_new"].corr(wide["yoy_index_second"], method="spearman")


# 教材：ch02_covariation.tex:322；ch02_kendall_py
from scipy.stats import kendalltau, spearmanr
from itertools import combinations

x = wide["yoy_index_new"].to_numpy()
y = wide["yoy_index_second"].to_numpy()
tau_b = kendalltau(x, y).statistic
rho_s = spearmanr(x, y).statistic
print(f"Kendall tau_b = {tau_b:.4f}; Spearman = {rho_s:.4f}")

signs = [np.sign((x[i]-x[j])*(y[i]-y[j]))
         for i, j in combinations(range(20), 2)]
C = sum(s > 0 for s in signs)
D = sum(s < 0 for s in signs)
T = sum(s == 0 for s in signs)
print("C, D, 并列对 =", C, D, T)
print("tau_a =", (C-D)/len(signs))


# 教材：ch02_covariation.tex:395；box:pols
import statsmodels.api as sm

X = sm.add_constant(wide["yoy_index_new"])
ols_model = sm.OLS(wide["yoy_index_second"], X).fit()
ols_model.params
ols_model.rsquared


# 教材：ch02_covariation.tex:546；ch02_binned_py
import numpy as np, pandas as pd, statsmodels.formula.api as smf
import matplotlib.pyplot as plt

# 按五分位切分
wide["x_bin"] = pd.qcut(wide["yoy_index_new"], q=5,
                         labels=["Q1","Q2","Q3","Q4","Q5"])
bin_means = wide.groupby("x_bin", observed=True).agg(
    x_mid=("yoy_index_new", "mean"),
    y_mean=("yoy_index_second", "mean"),
    n=("yoy_index_second", "count")
).reset_index()
print(bin_means)

# 画图：散点 + OLS 线 + 分箱均值
mod = smf.ols("yoy_index_second ~ yoy_index_new", data=wide).fit()
x_grid = np.linspace(wide.yoy_index_new.min(), wide.yoy_index_new.max(), 100)
y_hat  = mod.params["Intercept"] + mod.params["yoy_index_new"] * x_grid

fig, ax = plt.subplots()
ax.scatter(wide.yoy_index_new, wide.yoy_index_second, alpha=0.3, s=10)
ax.plot(x_grid, y_hat, color="blue", label="OLS 拟合线")
ax.scatter(bin_means.x_mid, bin_means.y_mean, color="red",
           zorder=5, s=60, marker="D", label="分箱条件均值")
ax.legend(); ax.set_xlabel("新房同比指数"); ax.set_ylabel("二手房同比指数")
plt.tight_layout()

