# Chapter 13: 非参数回归方法

本章使用 WDI/OWID 开放数据构造非参数回归示例。

## 数据

- `../data/processed/wdi_global_selected_indicators_wide.csv`
- `../data/processed/owid_global_annual_co2.csv`

## 教学主题

- `Y`：人均 CO2 排放（吨/人）。
- `X`：`log(人均GDP，2015年不变美元)`。

## 方法

- Nadaraya-Watson 核回归。
- 局部线性回归。
- 带宽比较。
- 留一交叉验证选择带宽。
- bootstrap 点态置信带。
- 与三阶多项式拟合对比。

## 运行

```bash
Rscript R/chapter13.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter13.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
