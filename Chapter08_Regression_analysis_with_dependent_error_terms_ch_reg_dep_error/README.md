# Chapter 08: 带有相关误差项的回归分析

本章使用可公开再分发的 ACS PUMS 个人样本以及 BEA/BLS 州级面板数据。

## 数据说明

- 聚类/多层模型本章数据：`../data/processed/acs_pums_california_persons_2023_selected.csv`
- 面板固定效应本章数据：
  - `../data/processed/bea_us_state_gdp_income_panel_1997_2025.csv`
  - `../data/processed/bls_state_unemployment_cpi_monthly_2015_2025.csv`

## 教学对应

- `read_score` -> `log(个人收入+1)`。
- `small_class` -> 是否本科及以上学历。
- `birth_month` -> 年龄。
- `class_id` -> 家庭编号 `serialno`。
- `tax_rate` -> 人均个人收入（千美元）。
- `left_coalition_last_term` -> 州失业率。
- `municip_name/year` -> `state/year`。

## 保留的方法

- 普通 OLS。
- HC0 稳健标准误。
- 按家庭或州聚类的稳健标准误。
- 随机截距/多层结构。
- 州固定效应。
- 州与年份双向固定效应。

## 运行

```bash
Rscript R/chapter08.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter08.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
