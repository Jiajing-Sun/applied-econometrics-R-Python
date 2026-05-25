# Chapter 02: 数据中的共同变化

本章使用国家统计局 70 个大中城市商品住宅销售价格指数（2025 年月度）。

## 本章数据设定

- 数据文件：`../data/processed/nbs_70city_house_price_2025.csv`
- 观测单位：城市-月份
- 教材变量 `living_area` 对应为：新建商品住宅同比价格指数
- 教材变量 `price` 对应为：二手住宅同比价格指数

## 本章保留的教材方法

- 散点图与共同变化的直观观察
- 样本协方差的手工计算
- Pearson 相关系数的手工计算与内置函数计算
- Spearman 秩相关系数的手工计算与秩变量计算
- 简单线性回归、拟合值、残差、RSS、TSS 与 `R^2`

## 运行方式

```bash
Rscript R/chapter02.R
python3 python/chapter02.py
```

## 输出文件

- `figures/`：本章图形，坐标轴、标题、图例均为中文。
- `tables/`：协方差计算表、秩相关计算表，包含 CSV 与可粘回 LaTeX 的 `.tex` 表。
- `results/`：整理后的宽表数据、缺失值检查、关键统计量、OLS 摘要。
