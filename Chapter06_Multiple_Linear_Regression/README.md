# Chapter 06: 多元线性回归

本章使用 BEA 美国州级 GDP/个人收入数据与 BLS 州级失业率数据。

## 本章数据设定

- 数据文件：
  - `../data/processed/bea_us_state_gdp_income_panel_1997_2025.csv`
  - `../data/processed/bls_state_unemployment_cpi_monthly_2015_2025.csv`
- 观测单位：美国州-年份；本章使用最新共同年份 2024 年的州截面
- 教材变量 `price` 对应为：人均个人收入（千美元）
- 教材变量 `living_area` 对应为：人均实际 GDP（千美元，2017 年不变价）
- 教材变量 `monthly_fee` 对应为：州年度平均失业率
- 教材变量 `new_production` 对应为：是否人口大州
- 教材变量 `build_year` 对应为：`log(州人口)`

## 本章保留的教材方法

- 多元 OLS
- HC0 稳健标准误与稳健置信区间
- 非零系数假设的 t 检验
- 长短模型 F 检验
- HC0 稳健 Wald/F 检验
- 条件期望置信区间与单个观测预测区间

## 运行方式

```bash
Rscript R/chapter06.R
python3 python/chapter06.py
```

## 输出文件

- `figures/`：双变量关系图、条件预测线、置信区间/预测区间图，全部使用中文标签。
- `tables/`：多元回归 HC0 表、短/中/长模型比较表。
- `results/`：整理后的分析数据、t 检验、F 检验、稳健 Wald 检验、预测区间和结果说明。
