from statsmodels.tsa.arima.model import ARIMA
from statsmodels.stats.diagnostic import acorr_ljungbox
import pandas as pd, numpy as np

# 在配套代码根目录运行；对数差分，不乘100
macro = pd.read_csv("data/processed/wdi_china_macro_1960_2024.csv")
macro = macro[(macro.year>=1978) & (macro.gdp_constant_2015_usd>0)]
macro = macro.sort_values("year")
gdp_growth = np.diff(np.log(macro.gdp_constant_2015_usd.to_numpy()))
# 比较三个规格的 AIC
results = {}
for p, q in [(1,0),(1,1),(2,1)]:
    res = ARIMA(gdp_growth, order=(p,0,q)).fit(
        method_kwargs={"maxiter":1000})
    assert res.mle_retvals["converged"]
    results[(p,q)] = res.aic
print(pd.Series(results, name="AIC"))

# 固定 d=0，在相同候选范围内按 AICc 选择
fits = {}
for p in range(3):
    for q in range(3):
        m = ARIMA(gdp_growth, order=(p,0,q), trend="c").fit(
            method_kwargs={"maxiter":1000})
        if not m.mle_retvals["converged"]:
            raise RuntimeError(f"ARMA({p},{q}) 未收敛，需检查优化")
        fits[(p,q)] = m
order = min(fits, key=lambda k: fits[k].aicc)
m_auto = fits[order]
print(order, m_auto.summary())

# 柳恩--博克斯（Ljung-Box）残差检验
lb = acorr_ljungbox(m_auto.resid, lags=[10],
                   model_df=sum(order), return_df=True)
print(lb)
pd.DataFrame([{"order":f"{p} {q}","AICc":m.aicc} for (p,q),m in fits.items()]).to_csv("补充示例/arma_Python.csv",index=False)
