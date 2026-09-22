# R 程序附录：最新版入口

## 离线运行

`appendix_R_program_all.R` 是兼容包装器，会根据脚本自身位置找到配套代码根目录，再执行 `补充示例/正文/appendix_R_离线正文代码.R`。它不再包含旧版合集内容；旧分题文件已移除。

从任何工作目录都可使用该包装器的完整路径：

```sh
Rscript "/实际仓库路径/Appendix_R_program_R_code/appendix_R_program_all.R"
```

只核对目录与目标文件、不执行附录：

```sh
Rscript "/实际仓库路径/Appendix_R_program_R_code/appendix_R_program_all.R" --check-paths
```

离线正文共 69 个代码框，按教材顺序运行；依赖 readr、dplyr、ggplot2、writexl、httr2、jsonlite。读取根目录 `data/processed` 下的冻结数据，输出位于根目录 `output`。安装步骤、自备文件格式模板和联网请求不在此离线入口内。运行前按仓库根目录说明安装相应依赖。

## 在线API示例

`examples/` 提供与2026-09-22二轮审阅正文一致的 8 个API代码框。这些文件已逐个通过语法核查（R `parse()` / Python `compile()`），**本轮没有联网执行**，也没有验证密钥、服务配额或实时返回数据。

文件编号按原书代码框顺序排列。部分框复用同小节前一个框创建的对象，例如下载结果后的缓存/绘图；请按教材对应小节阅读和执行，不能假定每个文件都能在空会话独立运行。需要API专用包时，按文件中的安装注释安装。不要把在线返回值自动覆盖教材冻结CSV。

| 文件 | 审阅源码代码框起始行 | 语法检查 | 联网执行 |
|---|---:|---|---|
| `appendix_R_block_080.R` | 1894 | 通过 | 未执行 |
| `appendix_R_block_081.R` | 1926 | 通过 | 未执行 |
| `appendix_R_block_082.R` | 1937 | 通过 | 未执行 |
| `appendix_R_block_083.R` | 1967 | 通过 | 未执行 |
| `appendix_R_block_084.R` | 1990 | 通过 | 未执行 |
| `appendix_R_block_085.R` | 2014 | 通过 | 未执行 |
| `appendix_R_block_086.R` | 2034 | 通过 | 未执行 |
| `appendix_R_block_087.R` | 2054 | 通过 | 未执行 |
