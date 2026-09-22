# 第13章：因果分析

教材章号为13；代码目录保留历史编号 `Chapter12`，脚本及结果文件仍使用 `chapter12`，便于保持路径兼容。

## 数据与样本

真实数据为美国FARS2018–2023年18–24岁记录82615行；只保留drinking=0或1后39935行、35715起事故。其余DiD、IV、事件研究、合成控制、连续RD和中介例子均明确模拟。

数据文件：

- [`nhtsa_fars_rd_age18_24_2018_2023.csv`](../data/processed/nhtsa_fars_rd_age18_24_2018_2023.csv)
- [`chapter13_did_simulated.csv`](../data/processed/chapter13_did_simulated.csv)
- [`chapter13_iv_simulated.csv`](../data/processed/chapter13_iv_simulated.csv)
- [`chapter13_event_common_timing_simulated.csv`](../data/processed/chapter13_event_common_timing_simulated.csv)
- [`chapter13_scm_cities_simulated.csv`](../data/processed/chapter13_scm_cities_simulated.csv)
- [`chapter13_rd_continuous_simulated.csv`](../data/processed/chapter13_rd_continuous_simulated.csv)
- [`chapter13_mediation_simulated.csv`](../data/processed/chapter13_mediation_simulated.csv)

| 变量 | 定义 |
|---|---|
| `year`, `st_case` | 两列共同标识事故，是聚类键，不能标识每一个人 |
| `age`, `rv` | 年龄（整岁）、`age-21`；仅7个离散年龄值 |
| `Z` | `age>=21`取1，阈值侧指示变量 |
| `alcohol_involved` | `drinking`为1取1、0取0；原码8/9表示未报告/未知，排除 |
| `male` | 脚本按原性别编码生成的指示变量 |
| `fatal_injury` | 保留作数据追踪，不进入因果控制项 |

结果是入选FARS且饮酒状态已知记录中的酒精涉及概率差异；不是一般驾驶人口的事故风险。未报告/未知42680行，占原筛选年龄样本约51.66%。主脚本报告按事故聚类的标准误；离散年龄和选择样本限制因果解释。

模拟数据规则、真实参数与生成器详见共享数据目录说明。DiD使用单位和时期固定效应、按40个单位聚类；IV的稳健协方差使用结构残差 `y-Xβ`，不可使用拟合处理变量回归的第二阶段残差。连续RD模拟专门配合 `rdrobust/rddensity`；不要把其连续运行变量假设套到FARS整岁年龄上。中介使用连续M，R/Python读取同一CSV，再各自行bootstrap。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter12.R
python3 python/chapter12.py
```

主要核对文件：[`results/chapter12_fars_rd_analysis_data.csv`](results/chapter12_fars_rd_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
