# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 如有需要，请在虚拟环境中安装：
# python -m pip install wbgapi pandas matplotlib

import wbgapi as wb
import pandas as pd
import matplotlib.pyplot as plt

# 搜索指标（交互式列表）
wb.series.info(q="gdp per capita")

# 下载所选国家 1990—2022 年人均 GDP（2015 年不变美元）
gdppc = wb.data.DataFrame(
    "NY.GDP.PCAP.KD",
    ["CHN", "GBR", "USA"],
    time=range(1990, 2023),
    index=["economy", "time"], columns="series", labels=False
).reset_index()

# 把“YR1990”等年份标签整理为 1990，并重命名数值列
gdppc["year"] = gdppc["time"].str.replace("YR", "", regex=False).astype(int)
gdppc = gdppc.rename(columns={"NY.GDP.PCAP.KD": "gdppc"})

# 绘制人均 GDP 的时间路径
plt.figure(figsize=(8, 4))
for name, g in gdppc.groupby("economy"):
    g = g.sort_values("year")
    plt.plot(g["year"], g["gdppc"], label=name)

plt.title("GDP per Capita (constant 2015 USD)")
plt.xlabel("Year")
plt.ylabel("GDP per capita")
plt.legend()
plt.tight_layout()
plt.show()
