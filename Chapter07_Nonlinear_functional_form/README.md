# 第7章：非线性函数形式

## 数据与样本

WDI与OWID按经济体代码、年份合并；2024年收入、人口、排放和贸易比率共同可用，最终157个经济体。

数据文件：

- [`wdi_global_selected_indicators_wide.csv`](../data/processed/wdi_global_selected_indicators_wide.csv)
- [`owid_global_annual_co2.csv`](../data/processed/owid_global_annual_co2.csv)

| 变量 | 定义和单位 |
|---|---|
| `log_gdp_pc` | 2015年不变价美元计人均GDP的自然对数 |
| `co2_pc_tonnes` | OWID年度CO₂排放量/人口，吨/人 |
| `log_co2_pc` | 人均CO₂排放的自然对数 |
| `trade_pct_gdp` | 进出口合计占GDP比重，百分比；不是贸易量增速 |
| `high_income`, `high_trade` | 分别严格超过本章收入对数、贸易比重样本中位数取1 |
| `income_group`, `income_decile` | 按本章收入分布生成的四分位组、十分位组 |

完整样本还要求收入、人口和排放为正，以便取对数。这里的 `high_income` 和 `income_group` 是脚本自定义分组，不是世界银行官方收入等级。各经济体等权。脚本比较多项式、对数变换、分组虚拟变量与交互项；这是跨经济体的描述性关系。第11章非参数回归不要求贸易比率完整，因此使用189个经济体。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter07.R
python3 python/chapter07.py
```

主要核对文件：[`results/chapter07_wdi_owid_income_co2_analysis_data.csv`](results/chapter07_wdi_owid_income_co2_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
