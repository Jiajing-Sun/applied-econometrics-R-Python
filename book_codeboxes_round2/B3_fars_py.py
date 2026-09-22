# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
import numpy as np, pandas as pd
import statsmodels.api as sm
df = pd.read_csv("data/processed/nhtsa_fars_rd_age18_24_2018_2023.csv")
df = df[df.age.between(18,24)].copy()
df["outcome_observed"] = df["drinking"].isin([0, 1])
(~df["outcome_observed"]).mean()  # 结果变量缺失比例
df_h = df.loc[df["outcome_observed"] &
              ((df["age"] - 21).abs() <= 3)].copy()
df_h["alcohol_involved"] = (df_h["drinking"] == 1).astype(int)
df_h["rv"] = df_h["age"] - 21
df_h["Z"] = (df_h["rv"] >= 0).astype(int)
df_h["Zrv"] = df_h["Z"] * df_h["rv"]
X = sm.add_constant(df_h[["Z","rv","Zrv"]])
fit = sm.OLS(df_h.alcohol_involved, X).fit()
print(fit.params, fit.get_robustcov_results(cov_type="HC0").bse)
accident = df_h.year.astype(str)+"_"+df_h.st_case.astype(str)
cluster = fit.get_robustcov_results(cov_type="cluster", groups=accident,
                                   use_correction=True, use_t=True)
print(cluster.bse)
