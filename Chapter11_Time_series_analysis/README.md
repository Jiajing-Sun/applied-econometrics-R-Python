# 第12章：时间序列

教材章号为12；代码目录保留历史编号 `Chapter11`，脚本及结果文件仍使用 `chapter11`，便于保持路径兼容。

## 数据与样本

中国年度GDP本地历史快照：原表1960–2024年65行；主案例1978–2024年47个水平值，46个对数增长率，AR(1)有效样本45个。

数据文件：

- [`wdi_china_macro_1960_2024.csv`](../data/processed/wdi_china_macro_1960_2024.csv)

| 变量 | 定义和单位 |
|---|---|
| `gdp`, `gdp_trillion` | `gdp_constant_2015_usd`；另除以10¹²，2015年不变价万亿美元 |
| `dloggdp` | `100*diff(log(gdp))`，百分数尺度的对数增长率 |
| `dloggdpL1` | 前一期对数增长率；滞后构造使首行缺失 |
| `ma`, `dlogma` | 脚本构造的平滑序列及其对数变化，须按脚本定义解释 |

AR(1)至AR(5)模型比较使用共同有效区间；HAC采用Bartlett权重、最大滞后5。正文ARMA代码使用未乘100的对数差分，与 `dloggdp` 相差100倍。正文VAR用GDP对数增长率和 `trade_pct_gdp` 的年度百分点变化，按共同年份对齐；此文件没有中国CPI字段。季节分解代码为独立模拟月度例子。

预测示例使用当前冻结的历史快照做回溯练习，没有构造各历史时点实际可得的数据版本。中心移动平均会使用未来观测，不能当作当时已知的预测变量。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter11.R
python3 python/chapter11.py
```

主要核对文件：[`results/chapter11_china_gdp_time_series_data.csv`](results/chapter11_china_gdp_time_series_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
