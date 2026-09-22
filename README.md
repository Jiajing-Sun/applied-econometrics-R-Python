# 中文教材配套代码｜2026-09-22 针对性终审版

本仓库对应《应用计量经济学：基于R与Python的回归分析与因果推断》针对性终审书稿。修订书稿以深红色累计标示此前审阅与本轮新增、改写的内容。本次直接更新当前代码、数据说明和输出文件。

## 学生下载后的运行顺序

1. 下载并解压整个仓库，保留目录结构，把工作目录设为仓库根目录。
2. 选择R或Python，先按下节安装该语言依赖。
3. 运行所学章节的本语言主脚本，生成分析CSV、数值表；R主脚本还生成教材图形。
4. 再按书中顺序运行本语言正文代码框，或运行已提取的按章脚本。

Python学生代码读取python_前缀输出，无须先运行R。代码框可能沿用同节前面定义的对象。普通.py中末尾表达式不会像notebook自动显示，需用print查看。

## 安装

本轮实测为macOS 26.5.2（arm64）、Python 3.14.6、R 4.5.1。新建Python虚拟环境并关闭pip下载缓存；R使用新第三方包目录，仅保留R发行版的base/recommended包。此结果不代表已在Windows或Linux实测。Python锁定包版本见requirements-20260922.txt；R实测版本见R-package-versions.csv。

Python：
~~~bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --no-cache-dir -r requirements.txt
~~~

Windows中激活命令改为`.venv/Scripts/activate`，其他环境差异需按本机情况处理。

R：
~~~bash
Rscript install_required_R_packages.R
~~~

安装程序会检查每个直接依赖是否可载入；本次补齐httr2、jsonlite、writexl。在线API、自备文件格式或交互式工具按附录另行准备。

## 运行示例

以下命令从仓库根目录执行，选择其中一种语言即可：
~~~bash
Rscript Chapter05_The_simple_linear_regression_model/R/chapter05.R
Rscript 修订补充示例/第二轮/ch05_正文代码框.R

python Chapter05_The_simple_linear_regression_model/python/chapter05.py
python 修订补充示例/第二轮/ch05_正文代码框.py
~~~

- `修订补充示例/第二轮/`：第2—10章按章脚本、两个编程附录离线入口、两份注明模拟性质的数据。
- `book_codeboxes_round2/`：非参数、时间序列、因果与数学补充的独立代码框；非参数需先运行同语言主脚本。
- `修订补充示例/`：事件研究、合成控制、ARMA搜索共6个完整补充程序。
- `data/processed/`：冻结观测数据和明确标记的模拟数据。实际单位、时期、筛选见数据字典。
- 两个离线编程附录入口为`修订补充示例/第二轮/appendix_R_离线正文代码.R`和`修订补充示例/第二轮/appendix_Python_离线正文代码.py`。

## 本轮真实验证结果

测试从GitHub重新clone开始，删除两套运行目录内全部预生成results/tables/figures，分别只运行R或Python，再执行学生代码。

| 验证对象 | 结果 |
|---|---|
| 章节主脚本 | R 12/12、Python 12/12 |
| 学生脚本入口 | R 27/27、Python 27/27 |
| 正文及技术/数学补充代码框 | 93框，46个脚本，包含在上述学生入口内 |
| 两个编程附录离线框 | R69、Python65，共134框，包含在上述学生入口内 |
| 其余补充程序 | 6个，包含在上述学生入口内 |
| 数值核对 | 17组跨语言/独立实现，另20项回归专项、18组进阶专项及新增OLS算例通过 |

49个安装命令、自备文件模板、交互帮助或在线API框不计入离线运行通过数。未在本轮重新执行外部API。完整运行SHA、代码框来源及核对证据在`docs/validation_20260922`。脚本成功不构成因果识别成立的证明。

## 本轮修正要点

1. 8个Python学生入口改为读取Python输出，消除隐含的R先运行依赖。
2. R安装清单补齐附录依赖；图形保存使用独立对象p_saved，避免Quartz字体进入默认PDF设备而报错。
3. 第8章统一HC0乘G/(G−1)与t(G−1)的聚类口径，同步区间、表格、p值。
4. AR(1)至AR(5)在相同41年样本比较含方差参数的高斯AIC；PACF统一Yule–Walker。
5. FARS性别8/9不再视为女性。无控制样本39935；控制样本39905，按35693起事故聚类。
6. 对数模型区分条件几何均值与算术均值；多项logit两语言明确以公交为基准。
7. 图文解释补齐模型特征差异、预测评估边界、固定截距似然切片、非参数图窗截断等信息。

## 教材章号与目录

| 中文教材章号 | 配套目录 |
|---|---|
| 第2—10章 | Chapter02—Chapter10 |
| 第11章 非参数回归 | Chapter13_Nonparametric_Regression_chapter_nonparametric |
| 第12章 时间序列 | Chapter11_Time_series_analysis |
| 第13章 因果分析 | Chapter12_Causal_analyses_ch_causality |

目录名中的round2或第二轮保留作稳定入口，不表示本轮交付旧代码。再次运行会更新图表和CSV。R/Python不同随机数流、不同树算法、mgcv与pyGAM及多层模型不同估计方法的例子，书中已说明差异，不要求逐位一致。

## 数据背景

详见`data/metadata/数据字典与样本规则_20260922.md`。本轮未把真实观测刷新到2026年。文件名年份不等于覆盖末年；中国教材保留数据的真实来源，不把国外观测冒充中国数据，也不把模拟结果解释成实际政策效果。FARS缺少人员编号，不能仅因选列相同就删除记录。
