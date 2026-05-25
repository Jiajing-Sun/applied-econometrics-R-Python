# Chapter 10: 预测

本章已从公寓价格相关数据使用国家统计局 70 个大中城市商品住宅销售价格指数。

## 数据说明

- 相关数据：`apartment_price_data.csv`
- 本章数据：`../data/processed/nbs_70city_house_price_2025.csv`

## 教学对应

- `price` -> 二手住宅同比价格指数。
- `living_area` -> 新建商品住宅同比价格指数。
- `monthly_fee` -> 二手住宅环比价格指数。
- `city_area` -> 新建住宅环比价格指数。
- `number_of_rooms/build_year` 等类别特征 -> 月份和城市虚拟变量。

## 保留的方法

- 训练/测试集划分。
- 多项式复杂度与过拟合比较。
- 5 折交叉验证。
- 岭回归。
- lasso。
- 回归树。
- 多模型训练误差和测试误差比较。

## 运行

```bash
Rscript R/chapter10.R
/Users/sunjiajing/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 python/chapter10.py
```

## 输出

- 图：`figures/`
- 表：`tables/`
- 结果：`results/`

所有 R 图形的坐标轴、标题和图例均已中文化。Python 版本生成对应的数据表和数值结果；图形由 R 版本生成。
