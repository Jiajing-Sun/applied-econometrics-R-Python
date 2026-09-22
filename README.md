# 《应用计量经济学：基于 R 与 Python 的回归分析与因果推断》配套代码

本配套材料包含章节主程序、正文示例、数据和结果文件。R 与 Python 可分别完成各自的运行流程。

## 运行方法

1. 下载并解压完整材料，保留目录结构，将工作目录设为配套代码根目录。
2. 选择 R 或 Python，安装对应依赖。
3. 运行所学章节的本语言主脚本，生成分析 CSV 和结果表；R 主脚本同时生成教材图形。
4. 按书中顺序运行正文代码框，也可运行“补充示例/正文”或“独立代码框”中的提取脚本。

Python 学生示例读取带 `python_` 前缀的输出。正文后续代码框会复用本章前面建立的对象；在普通脚本中，使用 `print()` 显示希望查看的结果。

## 安装依赖

Python：
```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

Windows 的命令提示符中使用 `.venv\Scripts\activate` 激活环境。

R：
```bash
Rscript install_required_R_packages.R
```

软件包版本和历史运行环境见 `requirements-20260922.txt`、`R-package-versions.csv` 及 `docs/validation_20260922`。在线 API、自备文件格式和交互式工具按附录说明准备。

## 运行示例

以下命令在配套代码根目录中执行，选择一种语言即可：
```bash
Rscript Chapter05_The_simple_linear_regression_model/R/chapter05.R
Rscript 补充示例/正文/ch05_正文代码框.R

python Chapter05_The_simple_linear_regression_model/python/chapter05.py
python 补充示例/正文/ch05_正文代码框.py
```

## 文件位置

- `补充示例/正文/`：第 2—10 章正文提取脚本、编程附录离线入口及注明模拟性质的数据。
- `独立代码框/`：非参数、时间序列、因果与数学补充的独立示例；非参数示例先运行同语言章节主程序。
- `补充示例/`：事件研究、合成控制和 ARMA 搜索的完整程序。
- `data/processed/`：随书数据；观测单位、时期和筛选方式见数据字典。

| 教材章号 | 配套目录 |
|---|---|
| 第 2—10 章 | Chapter02—Chapter10 |
| 第 11 章 非参数回归 | Chapter13_Nonparametric_Regression_chapter_nonparametric |
| 第 12 章 时间序列 | Chapter11_Time_series_analysis |
| 第 13 章 因果分析 | Chapter12_Causal_analyses_ch_causality |

重复运行会更新相应图表和 CSV。不同语言的随机数流和部分估计方法有所不同，具体结果按教材中的模型与计算方法解释。
