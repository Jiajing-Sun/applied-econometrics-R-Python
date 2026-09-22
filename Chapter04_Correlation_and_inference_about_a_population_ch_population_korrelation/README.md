# 第4章：总体相关与推断

## 数据与样本

世界银行WDI本地历史快照：2024年192个经济体，各经济体等权。

数据文件：

- [`chapter04_wdi_life_gdp_2024_economies.csv`](../data/processed/chapter04_wdi_life_gdp_2024_economies.csv)

| 变量 | 含义和单位 |
|---|---|
| `country_code`, `year` | 经济体代码与年份 |
| `gdp_per_capita_constant_2015_usd` | 人均GDP，2015年不变价美元/人 |
| `life_expectancy` | 预期寿命，年 |
| `log_gdp_per_capita`, `log_gdp_pc` | 同一个人均GDP变量的自然对数；保留两名以兼容代码框 |
| `region`, `income_group` | 2026-09-22保存的经济体元数据分类，不是2024年历史分类 |

源快照2024年收入与寿命完整的236行中剔除44个地区、世界、收入组等汇总行，得到192行。名单见数据元信息中的 `chapter04_excluded_aggregates.csv`；生成器 `prepare_chapter04.py` 默认只核验，`--write` 才重建。教材演示相关系数及推断；本例是经济体横截面，不是随机抽取的世界居民样本。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter04.R
python3 python/chapter04.py
```

主要核对文件：[`results/chapter04_wdi_life_gdp_analysis_data.csv`](results/chapter04_wdi_life_gdp_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
