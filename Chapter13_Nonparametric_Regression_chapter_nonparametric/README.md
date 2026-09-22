# 第11章：非参数回归

教材章号为11；代码目录保留历史编号 `Chapter13`，脚本及结果文件仍使用 `chapter13`，便于保持路径兼容。

## 数据与样本

WDI与OWID按经济体代码、年份合并；2024年收入、人口、排放完整且为正的189个经济体，各经济体等权。

数据文件：

- [`wdi_global_selected_indicators_wide.csv`](../data/processed/wdi_global_selected_indicators_wide.csv)
- [`owid_global_annual_co2.csv`](../data/processed/owid_global_annual_co2.csv)

`log_gdp_pc` 为2015年不变美元计人均GDP的自然对数；`co2_pc_tonnes` 为年度CO₂总量除以人口，单位吨/人。本章不要求贸易比率完整，故样本多于第7章157个经济体。

主脚本依次实现分箱、Nadaraya–Watson局部常数与局部线性拟合。NW留一交叉验证在0.18至1.10的25个带宽中选择0.64；局部线性在教学比较中沿用该带宽，并非另行选优。180个绘图点覆盖X的2%至98%分位区间；200次bootstrap用于演示给定带宽下的逐点波动。

正文GAM、核密度与独立局部回归代码框读取本章生成的分析CSV，先运行主脚本。R的mgcv与Python的pygam采用不同样条和REML/GCV平滑选择，EDF不必相同；bootstrap随机数生成器差异也会产生不同区间。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter13.R
python3 python/chapter13.py
```

主要核对文件：[`results/chapter13_nonparametric_analysis_data.csv`](results/chapter13_nonparametric_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
