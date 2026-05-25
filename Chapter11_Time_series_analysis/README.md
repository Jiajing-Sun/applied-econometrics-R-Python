# Chapter 11: 时间序列分析

本章使用 WDI 中国实际 GDP 年度序列。

## 数据说明

- 相关数据：`time_series_sweden.csv`
- 本章数据：`../data/processed/wdi_china_macro_1960_2024.csv`
- 当前分析区间：1978--2024 年。

## 教学对应

- `gdp` -> 中国实际 GDP（2015 年不变美元）。
- 季度频率 -> 年度频率。

## 保留的方法

- 时间序列图。
- 中心移动平均。
- 自相关函数 ACF。
- 对数增长率。
- AR(1) 回归。
- Newey-West/HAC 标准误。
- AR 阶数选择。

## 运行

```bash
Rscript R/chapter11.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter11.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
