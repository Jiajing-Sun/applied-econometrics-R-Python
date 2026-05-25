# Chapter 12: 因果分析

本章使用 NHTSA FARS 21 岁法定饮酒年龄 RD 教学示例。

## 数据说明

- 本章数据：`../data/processed/nhtsa_fars_rd_age18_24_2018_2023.csv`

## 教学对应

- `rv` -> 年龄减 21。
- `Z` -> 年龄是否达到 21 岁。
- `change_tax_rate` -> 事故中是否报告酒精涉及。
- `left_coalition_last_term` -> sharp RD 中的阈值处理状态。

## 保留的方法

- 构造运行变量。
- 构造阈值处理指示变量。
- 局部线性 RD。
- 阈值两侧斜率不同的交互项。
- HC0 稳健标准误。
- 带协变量和年份控制的稳健性版本。

## 运行

```bash
Rscript R/chapter12.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter12.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
