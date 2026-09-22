# 第6章：多元线性回归

## 数据与样本

美国BEA州GDP与收入、BLS州失业率合并；最新完整共同年份为2024年，51个州级单位（50州及哥伦比亚特区）。

数据文件：

- [`bea_us_state_gdp_income_panel_1997_2025.csv`](../data/processed/bea_us_state_gdp_income_panel_1997_2025.csv)
- [`bls_state_unemployment_cpi_monthly_2015_2025.csv`](../data/processed/bls_state_unemployment_cpi_monthly_2015_2025.csv)

| 变量 | 定义和单位 |
|---|---|
| `income_pc_thousand` | 人均个人收入/1000，现价千美元/人 |
| `gdp_pc_thousand` | 实际GDP（百万2017年美元）×1000/人口，2017年不变价千美元/人 |
| `unemployment_rate` | 州月失业率的年度算术平均，百分比 |
| `large_state` | 人口严格超过该年51单位样本中位数取1 |
| `log_population` | 人口的自然对数 |

BEA先清理州名称末尾的星号，再按州与年份对互补记录取每列第一个非缺失值；BLS只使用 `state_unemployment_rate`。合并后仅保留所需指标完整、人口与实际GDP为正的观测。脚本演示多元OLS、HC0、FWL残差回归及模型比较。收入与GDP采用不同价格口径，不把二者的系数称为同价收入份额。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter06.R
python3 python/chapter06.py
```

主要核对文件：[`results/chapter06_bea_bls_state_analysis_data.csv`](results/chapter06_bea_bls_state_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
