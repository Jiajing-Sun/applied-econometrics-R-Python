# 第2章：数据中的共同变动

## 数据与样本

国家统计局2025年70城住宅销售价格指数；原表1680行＝70城×12月×两类住宅，合并后840个城市—月份观测。

数据文件：

- [`nbs_70city_house_price_2025.csv`](../data/processed/nbs_70city_house_price_2025.csv)

| 变量 | 含义和单位 |
|---|---|
| `city`, `date` | 城市、月份；二者共同标识一条分析记录 |
| `new_house_yoy`, `second_hand_yoy` | 新建商品住宅、二手住宅同比指数，上年同月＝100 |
| `new_house_mom`, `second_hand_mom` | 两类住宅环比指数，上月＝100 |

同比指数95表示相对上年同月下降5%，不是每平方米95元。脚本计算均值、标准差、协方差、Pearson和Spearman相关；秩相关对并列值使用平均秩。城市—月份观测等权，相关性描述共同变动。

## 运行与输出

先按配套代码根目录说明准备R/Python依赖，再在本章目录执行：

```bash
Rscript R/chapter02.R
python3 python/chapter02.py
```

主要核对文件：[`results/chapter02_70city_wide_analysis_data.csv`](results/chapter02_70city_wide_analysis_data.csv)；其余数值在 `results/`、表格在 `tables/`，主脚本绘图在 `figures/`。Python结果通常以 `python_` 开头。

本说明核对日期：2026-09-22。数据来源、完整文件清单、缺失值和主键核验见 [共享数据说明](../data/README.md)。运行成功说明程序能够执行；经济识别条件和数据代表性仍按正文解释。
