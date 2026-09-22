# Extracted verbatim from technical_supplements/tech_ols_design_ch12.tex; run from companion-code root.
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
df = pd.DataFrame({"y":[5,5,5,6,8,7,8,11],
    "d":[1,0,1,0,1,0,0,1],"x":[50,55,58,60,65,66,70,75]})
# 基础均值差（HC2 稳健标准误）
m0 = smf.ols("y ~ d", data=df).fit(
         cov_type="HC2")
print(m0.params["d"],m0.bse["d"])
v_neyman = sum(df.loc[df.d==g,"y"].var(ddof=1)/4 for g in [0,1])
assert abs(m0.cov_params().loc["d","d"]-v_neyman)<1e-12

# Lin (2013) 规范：加入交互项
df["x_c"] = df["x"] - df["x"].mean()
m1 = smf.ols("y ~ d + x_c + d:x_c", data=df).fit(
         cov_type="HC2")
print(m1.params["d"], m1.bse["d"])
