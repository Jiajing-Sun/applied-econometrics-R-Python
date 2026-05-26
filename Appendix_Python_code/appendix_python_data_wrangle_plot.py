# ============================================================
# 附录 B：Python 编程语言
# 脚本: appendix_python_data_wrangle_plot.py
# 内容: 数据整理（WDI中国数据）、matplotlib 可视化（70城房价）
# 数据: data/processed/wdi_china_macro_1960_2024.csv
#       data/processed/nbs_70city_house_price_2025.csv
# 输出: Appendix_Python_code/figures/china_gdp_timeseries_py.png
#       Appendix_Python_code/figures/housing70_*.png
# ============================================================

import numpy as np
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
from matplotlib import font_manager
from pathlib import Path

# 设置字体，避免中文乱码。不同 macOS / Windows / Linux 环境中的中文字体名称
# 不完全一致，因此先从本机可用字体中选择第一个匹配项。
available_fonts = {f.name for f in font_manager.fontManager.ttflist}
preferred_fonts = [
    "PingFang SC", "PingFang HK", "Songti SC", "Heiti TC", "Hiragino Sans GB",
    "Arial Unicode MS", "SimHei", "SimSong", "Microsoft YaHei", "Noto Sans CJK SC",
]
for font_name in preferred_fonts:
    if font_name in available_fonts:
        matplotlib.rcParams["font.family"] = font_name
        break
else:
    matplotlib.rcParams["font.family"] = "DejaVu Sans"
matplotlib.rcParams["axes.unicode_minus"] = False

# 图表输出目录（相对于本代码仓库根目录）
FIG_DIR = Path("Appendix_Python_code") / "figures"
FIG_DIR.mkdir(parents=True, exist_ok=True)


# =====================================================================
# 第一部分：基础数据集操作——WDI 中国宏观数据
# 演示: read_csv、列选取、行筛选、新建变量、groupby 聚合、describe
# =====================================================================

wdi = pd.read_csv(
    "data/processed/wdi_china_macro_1960_2024.csv",
    encoding="utf-8-sig"
)

# 快速检查
wdi.head()
wdi.info()

# 选取若干分析列
wdi_sub = wdi[["year", "gdp_growth_pct", "gdp_per_capita_constant_2015_usd",
               "life_expectancy", "population"]]

# 筛选：1980年以后且增长率不缺失
wdi_1980 = wdi_sub[
    (wdi_sub["year"] >= 1980) & wdi_sub["gdp_growth_pct"].notna()
].copy()

# 新建变量：对数人均 GDP、十年组
wdi_1980["log_gdppc"] = np.log(wdi_1980["gdp_per_capita_constant_2015_usd"])
wdi_1980["decade"]    = (wdi_1980["year"] // 10) * 10

wdi_1980[["year", "gdp_growth_pct", "log_gdppc", "decade"]].head()

# 按十年聚合
avg_by_decade = (
    wdi_1980
    .groupby("decade", as_index=False)
    .agg(
        avg_growth  = ("gdp_growth_pct", "mean"),
        avg_lifeexp = ("life_expectancy", "mean"),
        n           = ("year", "count")
    )
)
print(avg_by_decade)

# 汇总统计
wdi_1980.describe()
wdi_1980["gdp_growth_pct"].mean()
wdi_1980["gdp_growth_pct"].var()
wdi_1980["gdp_growth_pct"].quantile([0.1, 0.5, 0.9])

# 保存整理后的数据
Path("output").mkdir(exist_ok=True)
wdi_1980.to_pickle("output/wdi_china_1980_clean.pkl")
avg_by_decade.to_csv("output/wdi_china_avg_by_decade.csv", index=False)


# =====================================================================
# 第二部分：时序可视化——中国 GDP 增长率折线图
# 替换原 Mauna Loa CO2 时序示例
# =====================================================================

wdi_plot = wdi[wdi["year"] >= 1980].dropna(subset=["gdp_growth_pct"])

plt.figure(figsize=(9, 4))
plt.plot(wdi_plot["year"], wdi_plot["gdp_growth_pct"], linewidth=2, color="#2166ac")
plt.axhline(0, color="gray", linewidth=0.8, linestyle="--")
plt.fill_between(
    wdi_plot["year"], wdi_plot["gdp_growth_pct"], 0,
    where=wdi_plot["gdp_growth_pct"] >= 0, alpha=0.15, color="#2166ac"
)
plt.xlabel("年份")
plt.ylabel("GDP 增长率（%）")
plt.title("中国 GDP 年增长率（1980—2024）\n数据来源：World Bank WDI")
plt.grid(axis="y", linewidth=0.5, alpha=0.5)
plt.tight_layout()

plt.savefig(FIG_DIR / "china_gdp_timeseries_py.png", dpi=120)
plt.close()
print("china_gdp_timeseries_py.png 已保存")


# =====================================================================
# 第三部分：多类型图表——70城新建住宅价格指数
# 替换原 iris 数据集六幅图
# =====================================================================

housing = pd.read_csv(
    "data/processed/nbs_70city_house_price_2025.csv",
    encoding="utf-8-sig"
)
df70 = housing[
    (housing["market"] == "new_house") &
    housing["mom_index"].notna() &
    housing["yoy_index"].notna()
].copy()
df70["date"] = pd.to_datetime(df70["date"])

# 城市等级分组
tier1 = ["北京", "上海", "广州", "深圳"]
tier2 = ["南京", "成都", "武汉", "杭州", "西安", "重庆"]

def get_tier(city):
    if city in tier1:
        return "一线"
    elif city in tier2:
        return "新一线"
    return "其他"

df70["tier"] = df70["city"].apply(get_tier)
cities5 = ["北京", "上海", "广州", "成都", "西安"]

# ── 直方图 ────────────────────────────────────────────────────────
plt.figure(figsize=(6.5, 4.8))
plt.hist(df70["mom_index"], bins=25, edgecolor="black", color="#4393c3", alpha=0.8)
plt.axvline(100, color="firebrick", linewidth=1.5, linestyle="--")
plt.xlabel("月度环比指数（新建住宅）")
plt.ylabel("频次")
plt.title("70城新建住宅价格环比指数直方图")
plt.tight_layout()
plt.savefig(FIG_DIR / "housing70_hist_py.png", dpi=120)
plt.close()
print("housing70_hist_py.png 已保存")

# ── 散点图（环比 vs 同比）─────────────────────────────────────────
plt.figure(figsize=(6.5, 4.8))
plt.scatter(df70["mom_index"], df70["yoy_index"], s=12, alpha=0.35, color="#4393c3")
plt.axvline(100, color="gray", linewidth=0.8, linestyle="--")
plt.axhline(100, color="gray", linewidth=0.8, linestyle="--")
plt.xlabel("环比指数（上月=100）")
plt.ylabel("同比指数（上年同月=100）")
plt.title("环比价格指数与同比价格指数散点图\n（70城新建住宅）")
plt.tight_layout()
plt.savefig(FIG_DIR / "housing70_scatter_py.png", dpi=120)
plt.close()
print("housing70_scatter_py.png 已保存")

# ── 箱线图（按城市等级）──────────────────────────────────────────
tier_order = ["一线", "新一线", "其他"]
data_by_tier = [
    df70[df70["tier"] == t]["mom_index"].dropna().values
    for t in tier_order
]
fig, ax = plt.subplots(figsize=(6.5, 4.8))
bp = ax.boxplot(data_by_tier, tick_labels=tier_order, patch_artist=True,
                medianprops=dict(color="firebrick", linewidth=2))
colors_box = ["#2166ac", "#4393c3", "#92c5de"]
for patch, c in zip(bp["boxes"], colors_box):
    patch.set_facecolor(c)
    patch.set_alpha(0.6)
ax.axhline(100, color="gray", linewidth=0.8, linestyle="--")
ax.set_xlabel("城市等级")
ax.set_ylabel("月度环比指数（新建住宅）")
ax.set_title("不同等级城市新建住宅环比价格分布")
plt.tight_layout()
plt.savefig(FIG_DIR / "housing70_boxplot_py.png", dpi=120)
plt.close()
print("housing70_boxplot_py.png 已保存")

# ── 散点矩阵（5城市）────────────────────────────────────────────
pivot = (
    df70[df70["city"].isin(cities5)]
    .pivot_table(index="date", columns="city", values="mom_index")
    .dropna()
)
from pandas.plotting import scatter_matrix
axes_arr = scatter_matrix(pivot, figsize=(8, 8), diagonal="hist",
                          alpha=0.3, s=6)
plt.suptitle("五城市新建住宅环比价格指数散点矩阵", y=1.01, fontsize=11)
plt.tight_layout()
plt.savefig(FIG_DIR / "housing70_scatter_matrix_py.png", dpi=120)
plt.close()
print("housing70_scatter_matrix_py.png 已保存")

# ── 相关热图 ─────────────────────────────────────────────────────
corr = pivot.corr()
cols = list(corr.columns)
fig, ax = plt.subplots(figsize=(6.5, 5))
im = ax.imshow(corr.values, vmin=-1, vmax=1, cmap="RdBu_r")
ax.set_xticks(range(len(cols)))
ax.set_yticks(range(len(cols)))
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
print("housing70_corr_heatmap_py.png 已保存")

# ── 3D 散点图 ────────────────────────────────────────────────────
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401
df_3d = df70[df70["city"].isin(cities5)].copy()
tier_map = {"北京": 1, "上海": 1, "广州": 2, "成都": 3, "西安": 3}
df_3d["tier_num"] = df_3d["city"].map(tier_map)
df_3d["year_num"] = df_3d["date"].dt.year + df_3d["date"].dt.month / 12

fig = plt.figure(figsize=(7, 5))
ax = fig.add_subplot(111, projection="3d")
sc = ax.scatter(df_3d["year_num"], df_3d["tier_num"], df_3d["mom_index"],
                s=12, alpha=0.5, c=df_3d["yoy_index"],
                cmap="coolwarm", vmin=88, vmax=112)
ax.set_xlabel("年份")
ax.set_ylabel("城市层级")
ax.set_zlabel("环比指数")
ax.set_title("年份、城市层级与环比价格指数（三维散点）")
fig.colorbar(sc, ax=ax, shrink=0.5, pad=0.1, label="同比指数")
plt.tight_layout()
plt.savefig(FIG_DIR / "housing70_3d_scatter_py.png", dpi=120)
plt.close()
print("housing70_3d_scatter_py.png 已保存")

print("\n全部 Python 附录图表脚本运行完毕")
