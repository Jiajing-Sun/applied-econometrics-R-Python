# 第5章Python：从教材按顺序提取；从仓库根目录运行。

# 代码框 1: book_chapters/ch05_simple_regression.tex:213 / ch05_simple_regression_1
import pandas as pd
import statsmodels.api as sm
raw = pd.read_csv("data/processed/nbs_70city_house_price_2025.csv")
key = ["city", "date", "year", "month"]
a = raw.loc[raw.market.eq("new_house"), key+["yoy_index"]].rename(
    columns={"yoy_index": "new_house_yoy"})
b = raw.loc[raw.market.eq("second_hand"), key+["yoy_index"]].rename(
    columns={"yoy_index": "second_hand_yoy"})
df = a.merge(b, on=key, validate="one_to_one")
assert len(df) == 840
assert df[["new_house_yoy", "second_hand_yoy"]].notna().all().all()
X = sm.add_constant(df["new_house_yoy"])
mod = sm.OLS(df["second_hand_yoy"], X).fit()
mod.summary()
mod.conf_int()


# 代码框 2: book_chapters/ch05_simple_regression.tex:376 / ch05_simple_regression_3
robust_mod = mod.get_robustcov_results(cov_type="HC0")
print(robust_mod.summary())
city_mod = mod.get_robustcov_results(
    cov_type="cluster", groups=df["city"], use_correction=True,
    df_correction=True, use_t=True)
print(city_mod.summary())


# 代码框 3: book_chapters/ch05_simple_regression.tex:521 / ch05_mc_py
import numpy as np
import statsmodels.api as sm
import matplotlib.pyplot as plt

rng = np.random.default_rng(42)
n, beta0, beta1, sigma = 50, 2.0, 0.5, 1.0
x = rng.normal(5, 2, n)
SSX = np.sum((x - x.mean())**2)

# 重复 2000 次抽样
b1_hat = np.array([
    sm.OLS(beta0 + beta1*x + rng.normal(0, sigma, n),
           sm.add_constant(x)).fit().params[1]
    for _ in range(2000)
])

print(f"理论均值: {beta1}  模拟均值: {b1_hat.mean():.4f}")
print(f"理论 SE:  {sigma/np.sqrt(SSX):.4f}  模拟 SD: {b1_hat.std():.4f}")

# 置信区间与预测区间
y = beta0 + beta1*x + rng.normal(0, sigma, n)
m = sm.OLS(y, sm.add_constant(x)).fit()
x_new = sm.add_constant(np.linspace(1, 9, 50))
# 置信区间（均值）
pred_ci = m.get_prediction(x_new).summary_frame(alpha=0.05)
print(pred_ci[["mean","mean_ci_lower","mean_ci_upper",
               "obs_ci_lower","obs_ci_upper"]].head())

