# Extracted verbatim from book_chapters/ch11_timeseries.tex; run from companion-code root.
import numpy as np, pandas as pd
from statsmodels.tsa.seasonal import STL
from statsmodels.tsa.holtwinters import ExponentialSmoothing

# 合成月度季节序列
np.random.seed(123)
t = np.arange(1,121)
y = 100 + 0.5*t + 5*np.sin(2*np.pi*t/12) + np.random.normal(0,2,120)
idx = pd.date_range("2000-01", periods=120, freq="MS")
cpi_ts = pd.Series(y, index=idx)

# STL 分解
stl = STL(cpi_ts, seasonal=13, robust=True)
stl_res = stl.fit()
stl_res.plot()   # 趋势、季节、残差图

# Holt-Winters 加法模型
hw = ExponentialSmoothing(cpi_ts, seasonal_periods=12,
                          trend="add", seasonal="add",
                          initialization_method="estimated")
hw_fit = hw.fit()
fc = hw_fit.forecast(12)
print(fc)

# 预测区间（基于模拟）
sim = hw_fit.simulate(nsimulations=12, repetitions=1000,
                      error="add", rng=np.random.default_rng(20260922))
lower = sim.quantile(0.025, axis=1)
upper = sim.quantile(0.975, axis=1)
