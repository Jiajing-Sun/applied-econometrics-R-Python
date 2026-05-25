# Chapter 07: 非线性函数形式

本章使用可公开再分发的 WDI/OWID 数据案例。

## 数据说明

- 相关数据：`pollution_sf.csv`，变量包括 `pm25`、`wind_direction`、`wind_speed`。
- 本章数据：
  - `../data/processed/wdi_global_selected_indicators_wide.csv`
  - `../data/processed/owid_global_annual_co2.csv`
- 教学对应：
  - `pm25` -> 人均 CO2 排放（吨/人）。
  - `wind_direction` -> `log(人均GDP，2015年不变美元)`。
  - `wind_cat` -> `log(人均GDP)` 十分位分箱。
  - `land_wind` -> 高收入国家虚拟变量。
  - `strong_wind` -> 高贸易开放度虚拟变量。
  - `wind_speed` -> 贸易占 GDP 比重。

## 保留的方法

- 分箱均值图。
- 虚拟变量与分类变量。
- 原始四阶多项式与 `poly()` 正交多项式。
- log-log 与 lin-log 对数模型。
- 虚拟变量交互、虚拟变量与连续变量交互。
- HC0 稳健标准误。

## 运行

```bash
Rscript R/chapter07.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter07.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有图的坐标轴、标题和图例均已中文化。Python 版本生成同一分析的数据表和结果文件；图形由 R 版本生成。
