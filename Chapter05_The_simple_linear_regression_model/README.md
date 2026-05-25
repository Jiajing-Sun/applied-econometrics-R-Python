# Chapter 05: 一元线性回归模型

本章使用国家统计局 70 个大中城市商品住宅销售价格指数（2025 年月度）。

## 本章数据设定

- 数据文件：`../data/processed/nbs_70city_house_price_2025.csv`
- 观测单位：城市-月份
- 教材变量 `price` 对应为：二手住宅同比价格指数
- 教材变量 `living_area` 对应为：新建商品住宅同比价格指数
- 教材变量 `new_production` 对应为：是否一线城市（北京、上海、广州、深圳）

## 本章保留的教材方法

- 简单 OLS 闭式计算
- 球形误差项下的标准误、t 检验和 90% 置信区间
- `lm()`/回归表形式的结果整理
- 二元自变量回归
- HC0/Eicker-Huber-White 稳健标准误
- 小样本 DGP Monte Carlo 模拟

## 运行方式

```bash
Rscript R/chapter05.R
python3 python/chapter05.py
```

## 输出文件

- `figures/`：回归散点图、残差图、二元自变量箱线图、DGP 模拟直方图，全部使用中文标签。
- `tables/`：普通 OLS 表、HC0 稳健 OLS 表、二元自变量回归表。
- `results/`：整理后的回归数据、回归摘要、DGP 模拟分布和结果说明。
