# Chapter 04: 关于总体相关的推断

本章使用 World Bank WDI 全球国家/地区年度数据。

## 本章数据设定

- 数据文件：`../data/processed/wdi_global_selected_indicators_wide.csv`
- 观测单位：国家或地区-年份
- 脚本自动选择完整观测数不少于 200 的最新年份
- 教材变量 `living_area` 对应为：`log(人均GDP，2015年不变美元)`
- 教材变量 `price` 对应为：预期寿命

## 本章保留的教材方法

- Pearson 相关系数
- Fisher Z 变换
- 相关系数的 95% 置信区间
- 相关为零的 t 检验与 p 值
- 相关与相依不等价的图形示例

## 运行方式

```bash
Rscript R/chapter04.R
python3 python/chapter04.py
```

## 输出文件

- `figures/`：WDI 散点图、相关置信区间图、相关与相依示例图，全部使用中文标签。
- `tables/`：WDI 样本预览表。
- `results/`：分析数据、Fisher Z 置信区间、t 检验结果和结果说明。
