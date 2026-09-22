# Python程序附录：本版离线练习入口。
# 请从“配套代码”根目录运行，按书中顺序执行。
# 安装命令、自备文件模板、交互帮助及联网API不在此离线脚本中。
# 不含审查辅助断言；代码内部用于教学的输入检查保留。

# 教材：Appendix Python.tex:321；代码块序号 21
# 基本算术运算
5 + 9
15 - 7
8 * 9
144 / 12

# 整数除法与余数
144 // 12
145 % 12

# 幂与开方
3**4
import math
math.sqrt(81)

# 括号按通常的运算优先级生效
(5 + 9) * 2

# 教材：Appendix Python.tex:353；代码块序号 22
import numpy as np

# 数值数组
x = np.array([1, 2, 3, 4])

# 每个元素都加 10
x + 10

# 逐元素相乘
x * np.array([2, 2, 2, 2])

# 比较数值（返回布尔数组）
x > 2

# 教材：Appendix Python.tex:377；代码块序号 23
import numpy as np

x = np.arange(1, 7)          # array([1, 2, 3, 4, 5, 6])

# 标量可以广播到每个元素
print(x + 1)
# 明确需要循环重复时，显式构造长度为 6 的数组
print(x + np.tile([1, 2], 3))
# 不兼容形状：捕获异常以便脚本继续运行
try:
    x + np.array([1, 2])
except ValueError as exc:
    print("形状不兼容：", exc)

# 教材：Appendix Python.tex:394；代码块序号 24
x.shape

# 教材：Appendix Python.tex:401；代码块序号 25
# 整数（int）
type(2)

# 浮点数（float）
type(2.0)

# 字符串
type("hello")

# 查看可用属性和方法（输出通常很长）
dir("hello")

# 查看函数和对象的内置帮助
help(len)

# 教材：Appendix Python.tex:419；代码块序号 26
import numpy as np
import pandas as pd

x = np.array([1, 2, 3, 4])
x.dtype
x.shape

df = pd.DataFrame({
  "id": [1, 2, 3],
  "group": ["A", "A", "B"],
  "y": [1.2, 0.7, 2.4]
})

df.head()
df.describe()
df.info()

# 教材：Appendix Python.tex:444；代码块序号 27
import math
import numpy as np

# 内置圆周率 pi
math.pi

# 内置自然常数 e
math.e

# 自然对数与指数函数
math.log(10)
math.exp(2)

# NumPy 版本（对数组逐元素运算）
np.log(np.array([1, 10, 100]))
np.exp(np.array([0, 1, 2]))

# 教材：Appendix Python.tex:471；代码块序号 28
import math
import numpy as np

# Python 中通用的“缺失”对象
None

# 未定义或缺失的数值
float("nan")     # NaN
float("inf")     # Inf
float("-inf")    # -Inf

# 浮点数中的未定义运算
try:
    0.0 / 0.0
except ZeroDivisionError as exc:
    print("纯 Python 的除零异常：", exc)
np.nan           # commonly used NaN in NumPy/pandas

# 检查各对象的类型与性质
math.isnan(float("nan"))
math.isfinite(float("inf"))

np.isnan(np.nan)
np.isfinite(np.array([1.0, np.nan, np.inf]))

# 教材：Appendix Python.tex:503；代码块序号 29
import sys
import numpy as np

# Python float 的浮点数信息（IEEE 754 双精度）
sys.float_info.epsilon
sys.float_info.min
sys.float_info.max

# NumPy float64 的信息（通常与 Python float 相同）
np.finfo(np.float64).eps
np.finfo(np.float64).tiny
np.finfo(np.float64).max

# 教材：Appendix Python.tex:547；代码块序号 30
# 遍历数值（range 生成 1、2、3、4、5）
for k in range(1, 6):
    print(k)

# 遍历任意列表
cities = ["Beijing", "Shanghai", "Guangzhou"]
for c in cities:
    print(c)

# 教材：Appendix Python.tex:561；代码块序号 31
x = [10, 20, 30]

for i, value in enumerate(x):
    print(i, value)

# 教材：Appendix Python.tex:571；代码块序号 32
names  = ["A", "B", "C"]
values = [1.2, 0.7, 2.4]

for n, v in zip(names, values):
    print(n, v)

# 教材：Appendix Python.tex:582；代码块序号 33
import numpy as np

x = np.arange(1, 6)              # array([1, 2, 3, 4, 5])
y = np.empty_like(x, dtype=float)

for i, xi in enumerate(x):
    y[i] = xi**2

y

# 教材：Appendix Python.tex:599；代码块序号 34
i = 1
while i <= 5:
    print(i)
    i = i + 1

# 教材：Appendix Python.tex:611；代码块序号 35
# 示例：最多迭代 100 次后停止
iter_ = 0
value = 1.0

while value < 1000 and iter_ < 100:
    value = value * 1.2
    iter_ = iter_ + 1

{"iter": iter_, "value": value}

# 教材：Appendix Python.tex:628；代码块序号 36
for k in range(1, 11):
    if k % 2 == 0:
        continue      # skip even numbers
    if k > 7:
        break         # stop the loop
    print(k)

# 教材：Appendix Python.tex:639；代码块序号 37
for k in range(2, 10):
    if 10 % k == 0:
        print("10 is divisible by", k)
        break
else:
    print("no divisor found")

# 教材：Appendix Python.tex:660；代码块序号 38
import numpy as np

x = np.arange(1, 11)

# 向量化：一次计算所有元素的平方
x**2

# 向量化：计算平方和
np.sum(x**2)

# 教材：Appendix Python.tex:675；代码块序号 39
# 每个数值加 1（生成列表）
[a + 1 for a in range(1, 6)]

# 加入条件（只保留大于 2 的数值）
[a for a in range(1, 6) if a > 2]

# 教材：Appendix Python.tex:686；代码块序号 40
list(map(lambda a: a + 1, range(1, 6)))
list(filter(lambda a: a > 2, range(1, 6)))

# 教材：Appendix Python.tex:693；代码块序号 41
sum(a*a for a in range(1, 11))   # sum of squares without building a list

# 教材：Appendix Python.tex:711；代码块序号 42
def add_numbers(a, b):
    return a + b

add_numbers(5, 3)

# 教材：Appendix Python.tex:721；代码块序号 43
def power(x, p=2):
    return x**p

power(3)            # uses p = 2
power(3, p=4)       # explicit
power(x=3, p=4)

# 教材：Appendix Python.tex:733；代码块序号 44
import math
import numpy as np

# （1）复利极限：(1 + 1/n)^n
def approx_e_limit(n=1000):
    return (1 + 1/n)**n

# （2）用循环计算级数展开：sum_{k=0}^n 1/k!
def approx_e_series_loop(n=10):
    out = 0.0
    for k in range(0, n + 1):
        out = out + 1 / math.factorial(k)
    return out

# （3）用 NumPy 向量化计算级数展开
def approx_e_series_vec(n=10):
    ks = np.arange(0, n + 1)
    return np.sum(1 / np.vectorize(math.factorial)(ks))

approx_e_limit(10)
approx_e_series_loop(10)
approx_e_series_vec(10)
math.exp(1)   # reference value

# 教材：Appendix Python.tex:783；代码块序号 45
x_num = [1, 3, 5, 7, 9]
x_chr = ["Emma", "Liam", "Noah"]
x_log = [True, False, True]

len(x_num)
x_num[0]       # first element (Python uses 0-based indexing)
x_num[1:4]     # a slice (elements 2 to 4)

# 教材：Appendix Python.tex:799；代码块序号 46
[1, "two", 3]     # allowed: heterogeneous list

# 教材：Appendix Python.tex:808；代码块序号 47
t = (201, "Emma", 32)
t
t[1]          # second element

# 教材：Appendix Python.tex:819；代码块序号 48
emp = {
    "ids":   [201, 202, 203],
    "names": ["Emma", "Liam", "Noah"],
    "n":     3
}

emp
emp["names"]     # access by key

# 教材：Appendix Python.tex:835；代码块序号 49
import numpy as np

x = np.array([1, 3, 5, 7, 9])
x
x.shape
x[0]          # first element
x[1:4]        # slice

# 矩阵
M = np.array([[10, 20, 30],
              [40, 50, 60],
              [70, 80, 90]])

M
M.shape
M[0, 1]       # row 1, column 2 (0-based)
M[:, 0]       # first column

# 教材：Appendix Python.tex:860；代码块序号 50
import pandas as pd

df = pd.DataFrame({
    "name": ["Emma", "Liam", "Noah", "Olivia"],
    "age":  [32, 17, 45, 27],
    "is_adult": [True, False, True, True]
})

df
df.shape          # (rows, columns)
df["age"]         # a column (Series)
df.loc[0:1, :]    # first two rows (label-based)
df.loc[:, ["name", "age"]]

# 教材：Appendix Python.tex:886；代码块序号 51
import numpy as np

A = np.arange(1, 13).reshape((2, 3, 2))
A
A.shape
A[0, :, 0]    # first "row block", all columns, first slice

# 教材：Appendix Python.tex:900；代码块序号 52
import pandas as pd

f = pd.Categorical(["Low", "Medium", "High", "Low", "High"])
f
f.categories
pd.Series(f).value_counts(sort=False)

# 教材：Appendix Python.tex:937；代码块序号 53
from pathlib import Path

# 项目根目录（按实际项目位置调整）
project = Path(".")   # current directory

# 数据文件的相对路径
csv_path = project / "data" / "processed" / "wdi_china_macro_1960_2024.csv"
csv_path

# 教材：Appendix Python.tex:949；代码块序号 54
csv_path.resolve()

# 教材：Appendix Python.tex:960；代码块序号 55
import pandas as pd
from pathlib import Path

csv_path = Path("data") / "processed" / "wdi_china_macro_1960_2024.csv"

# 基本导入
df = pd.read_csv(csv_path)

# 快速检查
df.head()
df.info()
df.describe()

# 教材：Appendix Python.tex:981；代码块序号 56
# 示例：指定 pandas 应将哪些字符串视为缺失值
df2 = pd.read_csv(csv_path, na_values=["", "NA", ".", "-999"])

# 示例：以分号分隔的文件
# 若另有分号分隔文件，再把下面路径替换成真实文件：
# df3 = pd.read_csv("实际的分号分隔文件.csv", sep=";")

# 教材：Appendix Python.tex:1058；代码块序号 60
import requests

# 示例模板（用实际网址替换 API_ENDPOINT；不同 API 的格式不同）
def get_api_json(api_endpoint, params=None):
    resp = requests.get(api_endpoint, params=params, timeout=30)
    resp.raise_for_status()
    return resp.json()

# 定义函数不会联网；取得提供方文档中的端点与参数后再调用。
# 用一个明确标为模拟的响应练习解析：
obj = [{"country": "CHN", "year": 2024, "value": 1.0}]
print(type(obj))

# 教材：Appendix Python.tex:1075；代码块序号 61
import pandas as pd

df_api = pd.json_normalize(obj)
df_api.head()

# 教材：Appendix Python.tex:1096；代码块序号 62
import numpy as np
import pandas as pd
from pathlib import Path

# 读取 世界银行中国宏观数据
wdi = pd.read_csv(
    Path("data") / "processed" / "wdi_china_macro_1960_2024.csv",
    encoding="utf-8-sig"
)

wdi.head()
wdi.info()

# 教材：Appendix Python.tex:1116；代码块序号 63
# 选取主要分析列
wdi_sub = wdi[["year", "gdp_growth_pct",
               "gdp_per_capita_constant_2015_usd",
               "life_expectancy", "population"]]

# 选取前 10 行（基于位置）
wdi_first10 = wdi_sub.iloc[:10, :]

# 选取单列（返回 Series）
gdp_growth = wdi["gdp_growth_pct"]

# 教材：Appendix Python.tex:1134；代码块序号 64
# 筛选 1980 年以后且 GDP 增长率不缺失的行
wdi_1980 = wdi_sub[
    (wdi_sub["year"] >= 1980) & wdi_sub["gdp_growth_pct"].notna()
].copy()

len(wdi_1980)

# 教材：Appendix Python.tex:1153；代码块序号 65
# 统计各列缺失值数量
wdi_sub.isna().sum()

# 筛选时排除缺失值
wdi_noNA = wdi_sub[wdi_sub["gdp_growth_pct"].notna() &
                   wdi_sub["life_expectancy"].notna()]
wdi_noNA[["year", "gdp_growth_pct", "life_expectancy"]].head()

# 教材：Appendix Python.tex:1168；代码块序号 66
wdi_1980 = wdi_1980.copy()

# 对数人均 GDP
positive_gdp = wdi_1980["gdp_per_capita_constant_2015_usd"] > 0
wdi_1980["log_gdppc"] = np.log(
    wdi_1980["gdp_per_capita_constant_2015_usd"].where(positive_gdp))

# 高速增长年份指示变量
wdi_1980["high_growth"] = wdi_1980["gdp_growth_pct"] >= 8

wdi_1980[["year", "gdp_growth_pct", "log_gdppc", "high_growth"]].head()

# 教材：Appendix Python.tex:1187；代码块序号 67
# 新建十年组变量
wdi_1980["decade"] = (wdi_1980["year"] // 10) * 10

# 按十年计算平均增长率
avg_by_decade = wdi_1980.groupby("decade", as_index=False)["gdp_growth_pct"].mean()
print(avg_by_decade)

# 教材：Appendix Python.tex:1198；代码块序号 68
summary_by_decade = wdi_1980.groupby("decade").agg(
    avg_growth  = ("gdp_growth_pct", "mean"),
    sd_growth   = ("gdp_growth_pct", "std"),
    avg_lifeexp = ("life_expectancy", "mean")
).reset_index()

print(summary_by_decade)

# 教材：Appendix Python.tex:1219；代码块序号 69
# 所有数值列的摘要
wdi_1980.describe()

# 均值与方差
wdi_1980["gdp_growth_pct"].mean()
wdi_1980["gdp_growth_pct"].var()

# 分位数
wdi_1980["gdp_growth_pct"].quantile([0.1, 0.5, 0.9])

# 按十年计数
wdi_1980["decade"].value_counts().sort_index()

# 教材：Appendix Python.tex:1242；代码块序号 70
from pathlib import Path

Path("output").mkdir(exist_ok=True)

wdi_1980.to_pickle("output/wdi_china_1980_clean.pkl")
wdi_loaded = pd.read_pickle("output/wdi_china_1980_clean.pkl")

# 教材：Appendix Python.tex:1254；代码块序号 71
import statsmodels.api as sm

model_data = wdi_1980[["gdp_growth_pct", "log_gdppc"]].replace(
    [np.inf, -np.inf], np.nan).dropna()
y = model_data["gdp_growth_pct"]
X = model_data[["log_gdppc"]]
X = sm.add_constant(X)

fit = sm.OLS(y, X).fit()
print(fit.summary())

fit.save("output/fit_growth_gdppc.pickle")

# 教材：Appendix Python.tex:1272；代码块序号 72
coef_table = pd.DataFrame({
    "term":     fit.params.index,
    "estimate": fit.params.values
})

coef_table.to_csv("output/coef_table.csv", index=False)
# 可选：先在项目环境安装 openpyxl，再取消下一行注释。
# coef_table.to_excel("output/coef_table.xlsx", index=False)

# 教材：Appendix Python.tex:1285；代码块序号 73
spec       = "baseline"
start_year = int(wdi_1980["year"].min())
end_year   = int(wdi_1980["year"].max())

fname = Path("output") / f"growth_model_{spec}_{start_year}_{end_year}.pickle"
fit.save(fname)

# 教材：Appendix Python.tex:1309；代码块序号 74
from pathlib import Path

FIG_DIR = Path("output") / "figures" / "python"
FIG_DIR.mkdir(parents=True, exist_ok=True)

# 为中文图形选择本机已有字体；未找到时需先安装支持中文的字体。
import matplotlib as mpl
from matplotlib import font_manager
available_fonts = {f.name for f in font_manager.fontManager.ttflist}
for font in ["Noto Sans CJK SC", "Microsoft YaHei", "PingFang SC",
             "Arial Unicode MS", "SimHei"]:
    if font in available_fonts:
        mpl.rcParams["font.family"] = font
        break
mpl.rcParams["axes.unicode_minus"] = False

# 教材：Appendix Python.tex:1329；代码块序号 75
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

wdi = pd.read_csv(
    Path("data") / "processed" / "wdi_china_macro_1960_2024.csv",
    encoding="utf-8-sig"
)
wdi_plot = wdi[wdi["year"] >= 1980].dropna(subset=["gdp_growth_pct"])

# 教材：Appendix Python.tex:1342；代码块序号 76
plt.figure(figsize=(9, 4))
plt.plot(wdi_plot["year"], wdi_plot["gdp_growth_pct"], linewidth=2, color="#2166ac")
plt.axhline(0, color="gray", linewidth=0.8, linestyle="--")
plt.fill_between(wdi_plot["year"], wdi_plot["gdp_growth_pct"], 0,
                 where=wdi_plot["gdp_growth_pct"] >= 0,
                 alpha=0.15, color="#2166ac")
plt.xlabel("年份")
plt.ylabel("GDP 增长率（%）")
plt.title("中国 GDP 年增长率（1980—2024）\n数据来源：世界银行世界发展指标")
plt.grid(axis="y", linewidth=0.5, alpha=0.5)
plt.tight_layout()

plt.savefig(FIG_DIR / "china_gdp_timeseries_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1374；代码块序号 77
import pandas as pd
from pathlib import Path

housing = pd.read_csv(
    Path("data") / "processed" / "nbs_70city_house_price_2025.csv",
    encoding="utf-8-sig"
)
df = housing[
    (housing["market"] == "new_house") &
    housing["mom_index"].notna() &
    housing["yoy_index"].notna()
].copy()
df["date"] = pd.to_datetime(df["date"])

# 教学分组：四个一线城市与其他城市，不另造“新一线”名单
tier1 = ["北京", "上海", "广州", "深圳"]
df["tier"] = np.where(df["city"].isin(tier1), "一线", "其他")

df.head()
df.describe()

# 教材：Appendix Python.tex:1401；代码块序号 78
import matplotlib.pyplot as plt

plt.figure(figsize=(6.5, 4.8))
plt.hist(df["mom_index"], bins=25, edgecolor="black", color="#4393c3", alpha=0.8)
plt.axvline(100, color="firebrick", linewidth=1.5, linestyle="--")
plt.title("70城新建住宅价格环比指数直方图")
plt.xlabel("月度环比指数（新建住宅）")
plt.ylabel("频次")
plt.tight_layout()

plt.savefig(FIG_DIR / "housing70_hist_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1418；代码块序号 79
plt.figure(figsize=(6.5, 4.8))
plt.scatter(df["mom_index"], df["yoy_index"], s=12, alpha=0.35, color="#4393c3")
plt.axvline(100, color="gray", linewidth=0.8, linestyle="--")
plt.axhline(100, color="gray", linewidth=0.8, linestyle="--")
plt.xlabel("环比指数（上月=100）")
plt.ylabel("同比指数（上年同月=100）")
plt.title("环比与同比房价指数散点图\n（70城新建住宅）")
plt.tight_layout()

plt.savefig(FIG_DIR / "housing70_scatter_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1434；代码块序号 80
tier_order = ["一线", "其他"]
data_by_tier = [
    df[df["tier"] == t]["mom_index"].dropna().values
    for t in tier_order
]

fig, ax = plt.subplots(figsize=(6.5, 4.8))
bp = ax.boxplot(data_by_tier, tick_labels=tier_order, patch_artist=True,
                medianprops=dict(color="firebrick", linewidth=2))
for patch, c in zip(bp["boxes"], ["#2166ac", "#92c5de"]):
    patch.set_facecolor(c); patch.set_alpha(0.6)
ax.axhline(100, color="gray", linewidth=0.8, linestyle="--")
ax.set_xlabel("城市分组")
ax.set_ylabel("月度环比指数（新建住宅）")
ax.set_title("一线与其他城市的新建住宅环比价格分布")
plt.tight_layout()

plt.savefig(FIG_DIR / "housing70_boxplot_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1458；代码块序号 81
from pandas.plotting import scatter_matrix

cities5 = ["北京", "上海", "广州", "成都", "西安"]
pivot = (
    df[df["city"].isin(cities5)]
    .pivot_table(index="date", columns="city", values="mom_index")
    .dropna()
)

axes_arr = scatter_matrix(pivot, figsize=(8, 8), diagonal="hist",
                          alpha=0.3, s=6)
fig = axes_arr[0, 0].figure
fig.suptitle("五城市新建住宅环比价格指数散点矩阵", y=0.98, fontsize=11)
# 为总标题预留顶部空间，并将所有文字纳入保存边界。
fig.tight_layout(rect=(0, 0, 1, 0.95))
fig.savefig(FIG_DIR / "housing70_scatter_matrix_py.png", dpi=120,
            bbox_inches="tight", pad_inches=0.12)
plt.close(fig)

# 教材：Appendix Python.tex:1479；代码块序号 82
corr = pivot.corr()
cols = list(corr.columns)

fig, ax = plt.subplots(figsize=(6.5, 5))
im = ax.imshow(corr.values, vmin=-1, vmax=1, cmap="RdBu_r")
ax.set_xticks(range(len(cols))); ax.set_yticks(range(len(cols)))
ax.set_xticklabels(cols, rotation=30, ha="right")
ax.set_yticklabels(cols)
plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
for i in range(len(cols)):
    for j in range(len(cols)):
        ax.text(j, i, f"{corr.values[i, j]:.2f}",
                ha="center", va="center", fontsize=8,
                color="white" if abs(corr.values[i, j]) > 0.6 else "black")
ax.set_title("五城市新建住宅环比价格指数相关矩阵")
plt.tight_layout()

plt.savefig(FIG_DIR / "housing70_corr_heatmap_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1503；代码块序号 83
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401

df_3d = df[df["city"].isin(cities5)].copy()
city_positions = {city: i for i, city in enumerate(cities5)}
df_3d["city_num"] = df_3d["city"].map(city_positions)
df_3d["month_num"] = df_3d["date"].dt.month

fig = plt.figure(figsize=(8.5, 6))
ax = fig.add_subplot(111, projection="3d")
sc = ax.scatter(df_3d["month_num"], df_3d["city_num"], df_3d["mom_index"],
                s=12, alpha=0.5, c=df_3d["yoy_index"],
                cmap="coolwarm", vmin=88, vmax=112)
ax.set_xlabel("2025年月次")
ax.set_ylabel("城市", labelpad=12)
ax.set_zlabel("环比指数", labelpad=14)
ax.set_yticks(range(len(cities5)), labels=cities5)
ax.set_title("月份、城市与环比价格指数（三维散点）")
fig.colorbar(sc, ax=ax, shrink=0.5, pad=0.2, label="同比指数")
plt.tight_layout()

plt.savefig(FIG_DIR / "housing70_3d_scatter_py.png", dpi=120)
plt.close()

# 教材：Appendix Python.tex:1585；代码块序号 84
import numpy as np

help(np.random.Generator.uniform)

# 教材：Appendix Python.tex:1593；代码块序号 85
import inspect
import textwrap
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

FIG_DIR = Path("output") / "figures" / "python"
FIG_DIR.mkdir(parents=True, exist_ok=True)

doc = inspect.getdoc(np.random.Generator.uniform)
doc_lines = doc.splitlines()
excerpt = "\n".join(doc_lines[:40])   # keep it short for a figure

# 为便于阅读而折行
excerpt = "\n".join(textwrap.fill(line, width=95) for line in excerpt.splitlines())

fig = plt.figure(figsize=(10, 6))
fig.text(0.01, 0.99, excerpt, va="top", ha="left", family="monospace", fontsize=8)
plt.axis("off")

plt.savefig(FIG_DIR / "help-uniform-python.png", dpi=150, bbox_inches="tight")
plt.close()

# 教材：Appendix Python.tex:1648；代码块序号 86
import numpy as np
import scipy.stats as st

rng = np.random.default_rng(123456789) # reproducible random numbers

# 教材：Appendix Python.tex:1911；代码块序号 87
import numpy as np
import scipy.stats as st
from scipy.integrate import quad
from scipy.optimize import brentq
from scipy.stats import gaussian_kde
import matplotlib.pyplot as plt

# 设置随机种子以保证可复现
rng = np.random.default_rng(123456789)

# 用数值积分计算标准正态分布函数
def compute_phi(z):
    integrand = lambda t: (1.0 / np.sqrt(2.0 * np.pi)) * np.exp(-t**2 / 2.0)
    val, _ = quad(integrand, -np.inf, z)
    return val

# 测试函数，并与 SciPy 内置分布函数比较
z_val = 1.96
print(compute_phi(z_val))
print(st.norm.cdf(z_val))

# 用求根算法数值反演 Phi
def inverse_phi(u):
    if not 0 < u < 1:
        raise ValueError("u 必须严格位于0和1之间")
    f = lambda z: compute_phi(z) - u
    return brentq(f, -10.0, 10.0)

# 第 1 步：从 U(0,1) 抽样（避开端点以保持数值稳定）
eps = 1e-12
u = rng.uniform(eps, 1.0 - eps, size=1000)

# 第 2 步：应用逆分布函数
sample_norm = np.array([inverse_phi(ui) for ui in u])

# 绘制直方图和经验核密度曲线
plt.figure(figsize=(7, 5))
plt.hist(sample_norm, bins=30, density=True, edgecolor="black", alpha=0.6)

kde = gaussian_kde(sample_norm)
grid = np.linspace(sample_norm.min(), sample_norm.max(), 200)
plt.plot(grid, kde(grid), linewidth=2)

plt.title("标准正态分布的逆CDF模拟")
plt.xlabel("取值")
plt.ylabel("密度")
plt.tight_layout()

# 保存图形（按需要调整路径）
FIG_DIR.mkdir(parents=True, exist_ok=True)
plt.savefig(FIG_DIR / "inverse-cdf-python.png", dpi=150)
plt.close()

# 教材：Appendix Python.tex:1967；代码块序号 88
# 若已有分位数函数（ppf），可采用以下简便方法：
sample_norm_fast = st.norm.ppf(u)
