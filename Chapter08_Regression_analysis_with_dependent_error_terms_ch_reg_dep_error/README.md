# 第8章：误差相关：聚类与面板

## 数据与样本

ACS加州2023年原表392318人；按年龄25–64岁、收入非负及所需字段完整筛选后203337人、113780个serialno编号组。另有51个州级单位×2015–2024年，共510个州—年观测。

数据文件：

- [`acs_pums_california_persons_2023_selected.csv`](../data/processed/acs_pums_california_persons_2023_selected.csv)
- [`bea_us_state_gdp_income_panel_1997_2025.csv`](../data/processed/bea_us_state_gdp_income_panel_1997_2025.csv)
- [`bls_state_unemployment_cpi_monthly_2015_2025.csv`](../data/processed/bls_state_unemployment_cpi_monthly_2015_2025.csv)

| 变量 | 定义和单位 |
|---|---|
| `household_id` | 脚本中对ACS的 `serialno` 的命名；SERIALNO标识住房单元或集体住所中的个人记录，按该值划分编号组 |
| `personal_income`, `log_income` | 文件中的个人年收入（美元）；`log1p(personal_income)` 即 ln(1+收入) |
| `bachelor`, `female`, `employed` | 选列文件提供的本科及以上、女性、就业0/1编码 |
| `age_centered` | 年龄减本章样本平均年龄，单位年 |
| `income_pc_thousand`, `gdp_pc_thousand` | 州人均个人收入（现价千美元）和人均GDP（2017年不变价千美元） |
| `unemployment_rate` | 州月失业率的年度算术平均，百分比 |

住房单元中属于同一记录的成员共享SERIALNO；集体住所（GQ）中每名被抽中的个人各有独立SERIALNO。因此，按SERIALNO形成的编号组可以识别同一住房单元的记录，不能恢复同一集体住所中不同个人的组内依赖。“家庭聚类”如作为教学简称，专指这里的编号分组方式，不表示所有编号组都是亲属家庭，也不表示已按集体住所共同聚类。

ACS估计不使用 `person_weight`，用于比较OLS、异方差稳健和按编号组聚类的推断，不宣称为完整复杂抽样设计下的加州总体估计。

州面板按州/年份对齐并保留共同完整样本，演示个体固定效应、双向固定效应及按州聚类。ACS人员样本与州面板是两个不同数据层级，不能混用主键或样本量。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter08.R
python3 python/chapter08.py
```

主要核对文件：[`results/chapter08_acs_cluster_analysis_data.csv`](results/chapter08_acs_cluster_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
