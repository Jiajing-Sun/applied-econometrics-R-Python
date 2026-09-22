# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 如有需要：
# python -m pip install fredapi pandas matplotlib

import os
from fredapi import Fred
import matplotlib.pyplot as plt

api_key = os.getenv("FRED_API_KEY")
if not api_key:
    raise ValueError("请先设置环境变量 FRED_API_KEY")
fred = Fred(api_key=api_key)

# 美国城市消费者 CPI（月度）
cpi = fred.get_series("CPIAUCSL", observation_start="2000-01-01")
print(cpi.tail())

cpi.plot(figsize=(8, 4), title="CPI (CPIAUCSL), FRED")
plt.xlabel("Date")
plt.ylabel("Index")
plt.tight_layout()
plt.show()
