# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 如有需要：
# python -m pip install yfinance pandas matplotlib

import yfinance as yf
import matplotlib.pyplot as plt

# 下载苹果公司的日度价格
aapl = yf.download("AAPL", start="2020-01-01", end="2021-01-01",
                   auto_adjust=False, multi_level_index=False, timeout=30)
assert not aapl.empty and "Adj Close" in aapl.columns
print(aapl.head())

# 绘制复权收盘价
plt.figure(figsize=(8, 4))
aapl["Adj Close"].plot()
plt.title("AAPL adjusted close price")
plt.xlabel("Date")
plt.ylabel("Price (USD)")
plt.tight_layout()
plt.show()
