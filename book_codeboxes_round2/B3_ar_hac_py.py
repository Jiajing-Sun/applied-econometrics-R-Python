# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
import numpy as np, pandas as pd
import statsmodels.api as sm
dft = pd.read_csv("data/processed/wdi_china_macro_1960_2024.csv")
dft = dft[dft.year.between(1978,2024)].sort_values("year").copy()
assert (np.diff(dft.year)==1).all() and (dft.gdp_constant_2015_usd>0).all()
dft["dloggdp"] = 100*np.log(dft.gdp_constant_2015_usd).diff()
dft["dloggdpL1"] = dft.dloggdp.shift(1)
reg = dft.dropna(subset=["dloggdp", "dloggdpL1"])
y = reg["dloggdp"].to_numpy()
X = sm.add_constant(reg["dloggdpL1"].to_numpy())

# OLS 系数与常规标准误
ols_res  = sm.OLS(y, X).fit()
print(ols_res.params)                              # \hat\alpha, \hat\phi
print(ols_res.bse)                                 # 普通 OLS 标准误

# Newey--West HAC 标准误（与 R 端 NeweyWest(lag=5) 一致）
hac_res  = ols_res.get_robustcov_results(cov_type="HAC",
                                         maxlags=5, use_correction=False)
print(hac_res.bse)                                 # HAC 标准误
