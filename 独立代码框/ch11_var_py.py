# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
import numpy as np, pandas as pd
from statsmodels.tsa.vector_ar.var_model import VAR
macro = pd.read_csv("data/processed/wdi_china_macro_1960_2024.csv")
macro = macro[macro.year.between(1978,2024)].sort_values("year")
assert (np.diff(macro.year)==1).all()
assert macro[["gdp_constant_2015_usd","trade_pct_gdp"]].notna().all().all()
df = pd.DataFrame({"gdp":100*np.diff(np.log(macro.gdp_constant_2015_usd)),
    "trade_change":np.diff(macro.trade_pct_gdp)}, index=pd.PeriodIndex(macro.year.iloc[1:].astype(str), freq="Y"))

# 用 AIC 选择最优滞后阶数
model = VAR(df)
lag_results = model.select_order(maxlags=4)
print(lag_results.summary())
p_opt = 1 + int(np.argmin(lag_results.ics["aic"][1:5]))

# 估计 VAR(p_opt)
var_fit = model.fit(p_opt)
print(var_fit.summary())

# 在已选模型中检验，不能另固定为2阶
assert var_fit.is_stable()
print(var_fit.test_causality("gdp", ["trade_change"], kind="f"))

# 脉冲响应函数（Cholesky 正交化）
irf = var_fit.irf(10)
irf.plot(impulse="trade_change", response="gdp",
         orth=True, plot_params={"figsize":(8,4)})

# 预测误差方差分解
fevd = var_fit.fevd(10)
fevd.plot()
