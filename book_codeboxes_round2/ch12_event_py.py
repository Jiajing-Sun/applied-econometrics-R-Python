# Extracted verbatim from book_chapters/ch12_causal.tex; run from companion-code root.
import numpy as np, pandas as pd
import statsmodels.formula.api as smf
import matplotlib.pyplot as plt
df = pd.read_csv("data/processed/chapter13_event_common_timing_simulated.csv")
lags = [-4,-3,-2,0,1,2,3]
cols = [f"D_n{-l}" if l<0 else f"D_{l}" for l in lags]
for l, col in zip(lags,cols):
    df[col] = ((df.treated==1) & (df.rel_time==l)).astype(int)
fit_es = smf.ols("Y ~ "+" + ".join(cols)+" + C(id)+C(year)",df).fit(
    cov_type="cluster",cov_kwds={"groups":df.id},use_t=True)
ci = fit_es.conf_int().loc[cols]
plt.errorbar(lags,fit_es.params[cols],
    yerr=[fit_es.params[cols]-ci[0],ci[1]-fit_es.params[cols]],fmt="o")
plt.axhline(0,color="gray"); plt.xlabel("相对处理时间")
print(fit_es.wald_test("D_n4=0,D_n3=0,D_n2=0",scalar=True))
