# Appendix: The R Programming Language
# Source: Appendix R program.tex
# Extracted from the current textbook LaTeX source in original order.

# ------------------------------------------------------------------------------
# Chunk 001
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 算术与向量化运算
# ------------------------------------------------------------------------------

# Basic arithmetic
5 + 9
15 - 7
8 * 9
144 / 12

# Powers and roots
3^4
sqrt(81)

# Parentheses work as expected
(5 + 9) * 2

# ------------------------------------------------------------------------------
# Chunk 002
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 算术与向量化运算
# ------------------------------------------------------------------------------

# A numeric vector
x <- c(1, 2, 3, 4)

# Add 10 to every element
x + 10

# Multiply element-by-element
x * c(2, 2, 2, 2)

# Compare values (returns a logical vector)
x > 2

# ------------------------------------------------------------------------------
# Chunk 003
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 算术与向量化运算
# Paragraph: 循环补齐（谨慎使用）。
# ------------------------------------------------------------------------------

# Recycling: c(1, 2) is repeated to match length 6
1:6 + c(1, 2)

# If the longer length is not a multiple of the shorter one,
# R will warn you.
1:5 + c(1, 2)

# ------------------------------------------------------------------------------
# Chunk 004
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 检查对象：str()、class() 和 typeof()
# ------------------------------------------------------------------------------

# A single number in R is typically stored as a double (numeric)
str(2)
typeof(2)

# An integer uses the suffix L
str(2L)
typeof(2L)

# A character string
str("hello")
typeof("hello")

# ------------------------------------------------------------------------------
# Chunk 005
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 检查对象：str()、class() 和 typeof()
# ------------------------------------------------------------------------------

# A small data frame
df <- data.frame(
  id    = 1:3,
  group = c("A", "A", "B"),
  y     = c(1.2, 0.7, 2.4)
)

head(df)
summary(df)
str(df)

# ------------------------------------------------------------------------------
# Chunk 006
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 基本常数和特殊值
# Paragraph: 数学常数。
# ------------------------------------------------------------------------------

# pi is built in
pi

# e can be obtained as exp(1)
exp(1)

# Natural logarithm and exponential
log(10)
exp(2)

# ------------------------------------------------------------------------------
# Chunk 007
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 基本常数和特殊值
# Paragraph: 缺失值、无穷大和未定义结果。
# ------------------------------------------------------------------------------

# Missing data
NA

# Undefined operations
0/0        # NaN
1/0        # Inf
-1/0       # -Inf

# Check what is what
is.na(NA)
is.nan(0/0)
is.finite(1/0)

# ------------------------------------------------------------------------------
# Chunk 008
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本计算
# Subsubsection: 基本常数和特殊值
# Paragraph: 机器精度（可选但有用）。
# ------------------------------------------------------------------------------

# Smallest difference distinguishable from 1 (roughly)
.Machine$double.eps

# Approximate smallest/largest positive doubles
.Machine$double.xmin
.Machine$double.xmax

# ------------------------------------------------------------------------------
# Chunk 009
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: for 循环
# ------------------------------------------------------------------------------

# Looping over values
for (k in 1:5) {
  print(k)
}

# Looping over an arbitrary vector
cities <- c("Uppsala", "Stockholm", "Gothenburg")
for (c in cities) {
  print(c)
}

# ------------------------------------------------------------------------------
# Chunk 010
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: for 循环
# Paragraph: （安全地）遍历索引。
# ------------------------------------------------------------------------------

x <- c(10, 20, 30)

for (i in seq_along(x)) {
  print(x[i])
}

# ------------------------------------------------------------------------------
# Chunk 011
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: for 循环
# Paragraph: 预分配。
# ------------------------------------------------------------------------------

x <- 1:5

# Pre-allocate a numeric vector
y <- numeric(length(x))

for (i in seq_along(x)) {
  y[i] <- x[i]^2
}

y

# ------------------------------------------------------------------------------
# Chunk 012
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: while 循环
# ------------------------------------------------------------------------------

i <- 1
while (i <= 5) {
  print(i)
  i <- i + 1
}

# ------------------------------------------------------------------------------
# Chunk 013
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: while 循环
# ------------------------------------------------------------------------------

# Example: stop after at most 100 iterations
iter <- 0
value <- 1

while (value < 1000 && iter < 100) {
  value <- value * 1.2
  iter  <- iter + 1
}

c(iter = iter, value = value)

# ------------------------------------------------------------------------------
# Chunk 014
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: repeat 循环
# ------------------------------------------------------------------------------

i <- 0
repeat {
  i <- i + 1
  print(i)

  if (i >= 5) {
    break
  }
}

# ------------------------------------------------------------------------------
# Chunk 015
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: 显式循环的替代方法
# Paragraph: 向量化。
# ------------------------------------------------------------------------------

x <- 1:10

# Vectorized: squares every element at once
x^2

# Vectorized: sum of squares
sum(x^2)

# ------------------------------------------------------------------------------
# Chunk 016
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: 显式循环的替代方法
# Paragraph: apply 函数族。
# ------------------------------------------------------------------------------

# lapply returns a list
lapply(1:5, function(a) a + 1)

# sapply tries to simplify to a vector
sapply(1:5, function(a) a + 1)

# ------------------------------------------------------------------------------
# Chunk 017
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的循环与迭代
# Subsubsection: 显式循环的替代方法
# Paragraph: 一个现代说明（可选）。
# ------------------------------------------------------------------------------

# Anonymous function (compact syntax)
sapply(1:5, \(a) a + 1)

# ------------------------------------------------------------------------------
# Chunk 018
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的函数
# Subsubsection: 定义和调用函数
# ------------------------------------------------------------------------------

add_numbers <- function(a, b) {
  a + b
}

add_numbers(5, 3)

# ------------------------------------------------------------------------------
# Chunk 019
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的函数
# Subsubsection: 定义和调用函数
# Paragraph: 默认值和命名参数。
# ------------------------------------------------------------------------------

power <- function(x, p = 2) {
  x^p
}

power(3)          # uses p = 2
power(3, p = 4)   # explicit
power(x = 3, p = 4)

# ------------------------------------------------------------------------------
# Chunk 020
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的函数
# Subsubsection: 定义和调用函数
# Paragraph: 一个小型数值例子：近似 $e$。
# ------------------------------------------------------------------------------

# (1) Compound-interest limit: (1 + 1/n)^n
approx_e_limit <- function(n = 1000) {
  (1 + 1/n)^n
}

# (2) Series expansion with a loop: sum_{k=0}^n 1/k!
approx_e_series_loop <- function(n = 10) {
  out <- 0
  for (k in 0:n) {
    out <- out + 1 / factorial(k)
  }
  out
}

# (3) Series expansion, vectorized
approx_e_series_vec <- function(n = 10) {
  sum(1 / factorial(0:n))
}

approx_e_limit(10)
approx_e_series_loop(10)
approx_e_series_vec(10)
exp(1)  # reference value

# ------------------------------------------------------------------------------
# Chunk 021
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 向量（原子向量）
# ------------------------------------------------------------------------------

x_num <- c(1, 3, 5, 7, 9)
x_chr <- c("Emma", "Liam", "Noah")
x_log <- c(TRUE, FALSE, TRUE)

length(x_num)
x_num[1]      # first element
x_num[2:4]    # a slice

# ------------------------------------------------------------------------------
# Chunk 022
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 向量（原子向量）
# Paragraph: 强制转换。
# ------------------------------------------------------------------------------

c(1, "two", 3)    # coerces to character

# ------------------------------------------------------------------------------
# Chunk 023
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 列表
# ------------------------------------------------------------------------------

emp_ids   <- c(201, 202, 203)
emp_names <- c("Emma", "Liam", "Noah")

employee_list <- list(
  ids   = emp_ids,
  names = emp_names,
  n     = length(emp_ids)
)

employee_list
employee_list$names   # access by name
employee_list[[1]]    # access by position

# ------------------------------------------------------------------------------
# Chunk 024
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 数据框
# ------------------------------------------------------------------------------

df <- data.frame(
  name    = c("Emma", "Liam", "Noah", "Olivia"),
  age     = c(32, 19, 45, 27),
  is_adult = c(TRUE, FALSE, TRUE, TRUE)
)

df
nrow(df)
ncol(df)

df$age
df[1:2, ]        # first two rows
df[, c("name", "age")]

# ------------------------------------------------------------------------------
# Chunk 025
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 矩阵
# ------------------------------------------------------------------------------

M <- matrix(
  c(10, 20, 30,
    40, 50, 60,
    70, 80, 90),
  nrow = 3, byrow = TRUE
)

M
M[1, 2]      # row 1, column 2
M[, 1]       # first column

# ------------------------------------------------------------------------------
# Chunk 026
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 数组
# ------------------------------------------------------------------------------

A <- array(1:12, dim = c(2, 3, 2))
A
dim(A)
A[1, , 1]    # first row, all columns, first "slice"

# ------------------------------------------------------------------------------
# Chunk 027
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的核心数据结构
# Subsubsection: 因子
# ------------------------------------------------------------------------------

f <- factor(c("Low", "Medium", "High", "Low", "High"))
f
levels(f)
table(f)

# ------------------------------------------------------------------------------
# Chunk 028
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: 文件路径与可复现性
# ------------------------------------------------------------------------------

# Where am I?
getwd()

# If you must change working directory, do it once at the top of the script:
# setwd("/path/to/your/project")

# A common alternative is the {here} package for project-relative paths:
# install.packages("here")
# library(here)
# here("data", "my_file.csv")

# ------------------------------------------------------------------------------
# Chunk 029
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: 分隔文本文件：CSV 及相关格式
# ------------------------------------------------------------------------------

# Base R import
df_base <- read.csv("data/macro_panel.csv")

# Quick checks
head(df_base)
str(df_base)

# ------------------------------------------------------------------------------
# Chunk 030
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: 分隔文本文件：CSV 及相关格式
# ------------------------------------------------------------------------------

# Fast and friendly import (tidyverse style)
# install.packages("readr")
library(readr)

# returns a tibble (a modern data frame)
df <- read_csv("data/macro_panel.csv")  
# compact overview (from dplyr)
glimpse(df)

# ------------------------------------------------------------------------------
# Chunk 031
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: 分隔文本文件：CSV 及相关格式
# ------------------------------------------------------------------------------

# Example: tell R which strings should be treated as missing
df2 <- read.csv("data/macro_panel.csv", na.strings = c("", "NA", ".",
        "-999"))

# ------------------------------------------------------------------------------
# Chunk 032
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: Excel 工作簿（.xls 和 .xlsx）
# ------------------------------------------------------------------------------

# install.packages("readxl")
library(readxl)

survey <- read_excel("data/household_survey.xlsx")
survey_wave1 <- read_excel("data/household_survey.xlsx", 
                sheet = "Wave1")

head(survey_wave1)

# ------------------------------------------------------------------------------
# Chunk 033
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: Stata、SPSS 和 SAS 文件
# ------------------------------------------------------------------------------

# install.packages("haven")
library(haven)

firm_panel <- read_dta("data/firm_panel.dta")
experiment <- read_sav("data/experiment_data.sav")

str(firm_panel)

# ------------------------------------------------------------------------------
# Chunk 034
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: 现代列式格式：Parquet/Arrow
# ------------------------------------------------------------------------------

# install.packages("arrow")
library(arrow)

df_parquet <- read_parquet("data/large_panel.parquet")

# Select a subset of columns (helps when files are big)
df_small <- read_parquet("data/large_panel.parquet",
                         col_select = c("id", "year", "outcome"))

# ------------------------------------------------------------------------------
# Chunk 035
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 导入数据和访问外部来源
# Subsubsection: API 和网络数据（初步了解）
# ------------------------------------------------------------------------------

# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)

# Example pattern (URL is just an illustration; APIs differ)
req <- request("https://api.example.com/data") |>
  req_url_query(country = "SE", year = 2020)

resp <- req_perform(req)

# Parse JSON into an R object (often a list/data frame)
content_txt <- resp_body_string(resp)
obj <- fromJSON(content_txt)

str(obj)

# ------------------------------------------------------------------------------
# Chunk 036
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# ------------------------------------------------------------------------------

data(airquality)
head(airquality)
str(airquality)

# ------------------------------------------------------------------------------
# Chunk 037
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 选取行和列的子集
# ------------------------------------------------------------------------------

# Select columns by name
aq_small <- airquality[, c("Ozone", "Solar.R", "Wind", "Temp")]

# Select the first 10 rows
aq_first10 <- airquality[1:10, ]

# Select one column (returns a vector)
temp <- airquality$Temp

# ------------------------------------------------------------------------------
# Chunk 038
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 筛选观测
# ------------------------------------------------------------------------------

# Hot days (Temp >= 90)
hot_days <- airquality[airquality$Temp >= 90, ]

# Days with high ozone (and not missing)
high_ozone <- airquality[!is.na(airquality$Ozone) 
              & airquality$Ozone > 80, ]

nrow(high_ozone)

# ------------------------------------------------------------------------------
# Chunk 039
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 创建新变量
# ------------------------------------------------------------------------------

aq <- airquality

# A simple transformation (Celsius)
aq$TempC <- (aq$Temp - 32) * 5/9

# A logical indicator (very windy day)
aq$HighWind <- aq$Wind > 15

head(aq)

# ------------------------------------------------------------------------------
# Chunk 040
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 聚合与分组
# ------------------------------------------------------------------------------

# Average temperature by month (base R)
avg_temp_by_month <- aggregate(Temp ~ Month, data = airquality, 
                    FUN = mean)
avg_temp_by_month

# Average ozone by month (remove missing values)
avg_ozone_by_month <- aggregate(Ozone ~ Month, data = airquality,
                               FUN = function(x) 
                               mean(x, na.rm = TRUE))
avg_ozone_by_month

# ------------------------------------------------------------------------------
# Chunk 041
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 聚合与分组
# ------------------------------------------------------------------------------

avg_by_month <- aggregate(cbind(Temp, Wind) ~ Month,
                          data = airquality, FUN = mean, 
                          na.rm = TRUE)
avg_by_month

# ------------------------------------------------------------------------------
# Chunk 042
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 初步分析：快速摘要
# ------------------------------------------------------------------------------

# Summary of the whole dataset
summary(airquality)

# Mean and variance of temperature
mean(airquality$Temp)
var(airquality$Temp)

# Quantiles
quantile(airquality$Temp, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)

# Frequency table for Month
table(airquality$Month)

# ------------------------------------------------------------------------------
# Chunk 043
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 保存结果和输出
# Paragraph: R 原生格式。
# ------------------------------------------------------------------------------

fit <- lm(Ozone ~ Temp + Wind, data = airquality)

saveRDS(fit, file = "output/fit_ozone_model.rds")
fit_loaded <- readRDS("output/fit_ozone_model.rds")

# ------------------------------------------------------------------------------
# Chunk 044
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 保存结果和输出
# Paragraph: R 原生格式。
# ------------------------------------------------------------------------------

dir.create("output", showWarnings = FALSE)

coef_fit <- coef(fit)
res_fit  <- resid(fit)

save(fit, coef_fit, res_fit, file = "output/model_objects.RData")

# ------------------------------------------------------------------------------
# Chunk 045
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 保存结果和输出
# Paragraph: 表格格式。
# ------------------------------------------------------------------------------

summary_df <- data.frame(
  term = names(coef_fit),
  estimate = as.numeric(coef_fit)
)

write.csv(summary_df, file = "output/coef_table.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# Chunk 046
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 保存结果和输出
# Paragraph: 表格格式。
# ------------------------------------------------------------------------------

# install.packages("writexl")
library(writexl)
write_xlsx(summary_df, path = "output/coef_table.xlsx")

# ------------------------------------------------------------------------------
# Chunk 047
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的基本数据集处理
# Subsubsection: 保存结果和输出
# Paragraph: 系统化文件名。
# ------------------------------------------------------------------------------

spec <- "baseline"
year <- 1973

fname <- paste0("output/ozone_model_", spec, "_year_", year, ".rds")
saveRDS(fit, file = fname)

# ------------------------------------------------------------------------------
# Chunk 048
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的数据可视化
# Subsubsection: Base graphics：常见图形类型
# ------------------------------------------------------------------------------

# Scatter plot: Ozone vs Temperature
plot(airquality$Temp, airquality$Ozone,
     xlab = "Temperature (F)",
     ylab = "Ozone",
     main = "Ozone and temperature (airquality)")

# Histogram of Wind
hist(airquality$Wind,
     xlab = "Wind",
     main = "Histogram of wind speed")

# Boxplot of temperature by month
boxplot(Temp ~ factor(Month), data = airquality,
        xlab = "Month", ylab = "Temperature (F)",
        main = "Temperature by month")

# ------------------------------------------------------------------------------
# Chunk 049
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的数据可视化
# Subsubsection: 不嵌入图形而保存图形
# ------------------------------------------------------------------------------

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

png("output/figures/R/ozone_vs_temp.png", width = 900, height = 650, 
     res = 120)
plot(airquality$Temp, airquality$Ozone,
     xlab = "Temperature (F)", ylab = "Ozone",
     main = "Ozone vs Temperature")
dev.off()

# ------------------------------------------------------------------------------
# Chunk 050
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的数据可视化
# Subsubsection: ggplot2：一个快速示例
# ------------------------------------------------------------------------------

# install.packages("ggplot2")
library(ggplot2)

p <- ggplot(airquality, aes(x = Temp, y = Ozone)) +
  geom_point(na.rm = TRUE) +
  labs(x = "Temperature (F)", y = "Ozone",
       title = "Ozone vs Temperature (airquality)")

p

# ------------------------------------------------------------------------------
# Chunk 051
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: R 中的数据可视化
# Subsubsection: ggplot2：一个快速示例
# ------------------------------------------------------------------------------

ggsave("output/figures/R/ozone_vs_temp_ggplot.png", plot = p,
       width = 7.5, height = 5.5, dpi = 150)

# ------------------------------------------------------------------------------
# Chunk 052
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 帮助页面：你的第一站
# ------------------------------------------------------------------------------

?runif

# ------------------------------------------------------------------------------
# Chunk 053
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 帮助页面：你的第一站
# ------------------------------------------------------------------------------

help(runif)

# ------------------------------------------------------------------------------
# Chunk 054
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 直接运行示例
# ------------------------------------------------------------------------------

example(runif)

# ------------------------------------------------------------------------------
# Chunk 055
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 快速检查：args()、formals() 和命名空间
# ------------------------------------------------------------------------------

args(runif)
formals(runif)

# ------------------------------------------------------------------------------
# Chunk 056
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 快速检查：args()、formals() 和命名空间
# ------------------------------------------------------------------------------

stats::runif(5)

# ------------------------------------------------------------------------------
# Chunk 057
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 不知道函数名时搜索帮助
# Paragraph: 在已安装文档中按关键词搜索。
# ------------------------------------------------------------------------------

??uniform
help.search("uniform")

# ------------------------------------------------------------------------------
# Chunk 058
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 不知道函数名时搜索帮助
# Paragraph: 按部分名称搜索。
# ------------------------------------------------------------------------------

apropos("unif")

# ------------------------------------------------------------------------------
# Chunk 059
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 不知道函数名时搜索帮助
# Paragraph: 在在线文档中搜索。
# ------------------------------------------------------------------------------

RSiteSearch("uniform distribution")
RSiteSearch("random effects")

# ------------------------------------------------------------------------------
# Chunk 060
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: Vignette：更长的教程式文档
# ------------------------------------------------------------------------------

browseVignettes()

# ------------------------------------------------------------------------------
# Chunk 061
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: Vignette：更长的教程式文档
# ------------------------------------------------------------------------------

browseVignettes(package = "ggplot2")

# ------------------------------------------------------------------------------
# Chunk 062
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: Vignette：更长的教程式文档
# ------------------------------------------------------------------------------

vignette(package = "survival")

# ------------------------------------------------------------------------------
# Chunk 063
# Chapter: R 编程语言
# Section: R 编程基础
# Subsection: 在 R（以及 RStudio）中获取帮助
# Subsubsection: 在线帮助页面以及 HTML 与文本帮助
# ------------------------------------------------------------------------------

# Open HTML help (if available)
help(runif, help_type = "html")

# Check how help is currently configured
getOption("help_type")

# ------------------------------------------------------------------------------
# Chunk 064
# Chapter: R 编程语言
# Section: 概率分布
# Subsection: 可复现性：设置种子
# ------------------------------------------------------------------------------

set.seed(1234)
rnorm(5)

set.seed(1234)
rnorm(5)   # identical output

# ------------------------------------------------------------------------------
# Chunk 065
# Chapter: R 编程语言
# Section: 概率分布
# Subsection: 逆 c.d.f. （分位数）方法
# Subsubsection: 例 1：指数分布的逆 c.d.f.
# ------------------------------------------------------------------------------

set.seed(1)

n <- 10000
rate <- 2

u <- runif(n)
x_icdf <- -log(u) / rate         # inverse cdf method
x_rexp <- rexp(n, rate = rate)   # built-in generator

c(mean_icdf = mean(x_icdf), mean_rexp = mean(x_rexp))
c(var_icdf  = var(x_icdf),  var_rexp  = var(x_rexp))

# ------------------------------------------------------------------------------
# Chunk 066
# Chapter: R 编程语言
# Section: 概率分布
# Subsection: 逆 c.d.f. （分位数）方法
# Subsubsection: 广义逆（离散情形）
# ------------------------------------------------------------------------------

set.seed(2)

vals  <- c(0, 1, 2, 5)
probs <- c(0.10, 0.30, 0.50, 0.10)
cdf   <- cumsum(probs)

n <- 20
u <- runif(n)

# Map u to vals via the generalized inverse
idx <- findInterval(u, vec = c(0, cdf), rightmost.closed = TRUE)
x_icdf_discrete <- vals[idx]

x_icdf_discrete

# Compare with R's built-in sampler for discrete distributions
x_sample <- sample(vals, size = n, replace = TRUE, prob = probs)
x_sample

# ------------------------------------------------------------------------------
# Chunk 067
# Chapter: R 编程语言
# Section: 概率分布
# Subsection: 逆 c.d.f. （分位数）方法
# Subsubsection: 例 2：不存在闭式分位数时的数值求逆
# ------------------------------------------------------------------------------

qnorm_uniroot <- function(u, lower = -10, upper = 10) {
  stopifnot(u > 0, u < 1)
  f <- function(x) pnorm(x) - u
  uniroot(f, interval = c(lower, upper))$root
}

set.seed(3)
u <- runif(5)
sapply(u, qnorm_uniroot)

# ------------------------------------------------------------------------------
# Chunk 068
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 dplyr 进行数据处理
# ------------------------------------------------------------------------------

# If needed:
# install.packages(c("dplyr", "tibble"))
library(dplyr)

# Inspect the data
starwars %>% 
  select(name, species, homeworld, height, mass) %>%
  head()

# ------------------------------------------------------------------------------
# Chunk 069
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 dplyr 进行数据处理
# Paragraph: 筛选和选择。
# ------------------------------------------------------------------------------

starwars %>%
  filter(species == "Human", !is.na(height)) %>%
  select(name, sex, homeworld, height, mass) %>%
  arrange(desc(height)) %>%
  head(10)

# ------------------------------------------------------------------------------
# Chunk 070
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 dplyr 进行数据处理
# Paragraph: 用 mutate() 创建新变量。
# ------------------------------------------------------------------------------

starwars %>%
  filter(!is.na(height), !is.na(mass)) %>%
  mutate(height_m = height / 100,
         bmi      = mass / (height_m^2)) %>%
  select(name, species, height, mass, bmi) %>%
  arrange(desc(bmi)) %>%
  head(10)

# ------------------------------------------------------------------------------
# Chunk 071
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 dplyr 进行数据处理
# Paragraph: 分组摘要。
# ------------------------------------------------------------------------------

starwars %>%
  filter(!is.na(height), !is.na(mass), !is.na(species)) %>%
  group_by(species) %>%
  summarise(
    avg_height = mean(height),
    avg_mass   = mean(mass),
    n          = n(),
    .groups    = "drop"
  ) %>%
  filter(n >= 5) %>%
  arrange(desc(avg_height))

# ------------------------------------------------------------------------------
# Chunk 072
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# ------------------------------------------------------------------------------

# If needed:
# install.packages("ggplot2")
library(ggplot2)

# ------------------------------------------------------------------------------
# Chunk 073
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 从数据开始
# ------------------------------------------------------------------------------

ggplot(data = diamonds) +
  labs(title = "The diamonds dataset (ggplot2)")

# ------------------------------------------------------------------------------
# Chunk 074
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 添加美学映射和几何图层
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = carat, y = price, colour = cut)) +
  geom_point(alpha = 0.4) +
  labs(title = "Diamond Price and Carat (coloured by cut)",
       x = "Carat", y = "Price (USD)")

# ------------------------------------------------------------------------------
# Chunk 075
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 直方图和密度
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = price)) +
  geom_histogram(binwidth = 500, fill = "skyblue", color = "black") +
  labs(title = "Distribution of Diamond Prices",
       x = "Price (USD)", y = "Count")

# ------------------------------------------------------------------------------
# Chunk 076
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 分面（小多图）
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = carat, y = price)) +
  geom_point(alpha = 0.3) +
  facet_wrap(~ cut) +
  labs(title = "Price vs Carat by Cut",
       x = "Carat", y = "Price (USD)")

# ------------------------------------------------------------------------------
# Chunk 077
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 统计变换（平滑）
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = carat, y = price)) +
  geom_point(alpha = 0.15) +
  geom_smooth(method = "lm", se = FALSE, color = "firebrick") +
  labs(title = "Linear Trend: Price vs Carat",
       x = "Carat", y = "Price (USD)")

# ------------------------------------------------------------------------------
# Chunk 078
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 坐标和缩放
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = carat, y = price, colour = cut)) +
  geom_point(alpha = 0.3) +
  coord_cartesian(xlim = c(0, 2), ylim = c(0, 15000)) +
  labs(title = "Zoomed View: Price vs Carat",
       x = "Carat", y = "Price (USD)")

# ------------------------------------------------------------------------------
# Chunk 079
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 主题
# ------------------------------------------------------------------------------

ggplot(diamonds, aes(x = carat, y = price)) +
  geom_point(alpha = 0.25) +
  facet_wrap(~ cut) +
  theme_minimal() +
  labs(title = "Price vs Carat by Cut (minimal theme)",
       x = "Carat", y = "Price (USD)")

# ------------------------------------------------------------------------------
# Chunk 080
# Chapter: R 编程语言
# Section: Tidyverse 包
# Subsection: 用 ggplot2 进行数据可视化
# Subsubsection: 保存和复用图形
# ------------------------------------------------------------------------------

p <- ggplot(diamonds, aes(x = carat, y = price, colour = cut)) +
  geom_point(alpha = 0.3) +
  labs(title = "Diamond Price vs Carat",
       x = "Carat", y = "Price (USD)")

# Save as a PNG file in the working directory
ggsave("diamond_price_vs_carat.png", p, width = 7, height = 5, dpi = 300)

# Keep the plot object for later modification
p

# ------------------------------------------------------------------------------
# Chunk 081
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 WDI 获取 World Bank 指标
# ------------------------------------------------------------------------------

# install.packages("WDI")
library(WDI)

# Search indicator names (returns a data frame of matches)
head(WDIsearch("life expectancy"))

# Download life expectancy and GDP per capita (constant prices)
wb <- WDI(
  country   = c("SWE", "DEU", "USA"),
  indicator = c(le = "SP.DYN.LE00.IN", gdppc = "NY.GDP.PCAP.KD"),
  start     = 1995,
  end       = 2022
)

# Basic checks
head(wb)
str(wb)

# Simple base-R ordering and a quick plot for one country
wb <- wb[order(wb$country, wb$year), ]
sweden <- wb[wb$country == "SWE", ]

plot(sweden$year, sweden$gdppc, type = "l",
     xlab = "Year", ylab = "GDP per capita (constant prices)",
     main = "Sweden: GDP per capita over time")

# ------------------------------------------------------------------------------
# Chunk 082
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 WDI 获取 World Bank 指标
# ------------------------------------------------------------------------------

dir.create("data_cache", showWarnings = FALSE)
saveRDS(wb, file = "data_cache/wb_le_gdppc.rds")

# Later:
# wb <- readRDS("data_cache/wb_le_gdppc.rds")

# ------------------------------------------------------------------------------
# Chunk 083
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 fredr 获取 FRED 数据（需要 API 密钥）
# ------------------------------------------------------------------------------

# install.packages("fredr")
library(fredr)

fredr_set_key(Sys.getenv("FRED_API_KEY"))

# Example series: U.S. unemployment rate (UNRATE)
unrate <- fredr(
  series_id = "UNRATE",
  observation_start = as.Date("2000-01-01")
)

head(unrate)

# ------------------------------------------------------------------------------
# Chunk 084
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 eurostat 获取 Eurostat 数据
# ------------------------------------------------------------------------------

# install.packages("eurostat")
library(eurostat)

# Monthly unemployment rate dataset (example)
une <- get_eurostat("une_rt_m", time_format = "date")

# Keep a small slice: total, all ages, Sweden
une_se <- une[une$geo == "SE" & une$sex == "T" & une$age == "TOTAL", ]

head(une_se)

# ------------------------------------------------------------------------------
# Chunk 085
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 OECD 获取 OECD 数据
# ------------------------------------------------------------------------------

# install.packages("OECD")
library(OECD)

# Example: download a dataset (start_time restricts the time range)
cli <- get_dataset("MEI_CLI", start_time = 2018)

head(cli)

# ------------------------------------------------------------------------------
# Chunk 086
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 通过 quantmod 获取市场数据（Yahoo Finance 接口）
# ------------------------------------------------------------------------------

# install.packages("quantmod")
library(quantmod)

# Example: daily prices for Microsoft from Yahoo Finance
getSymbols("MSFT", src = "yahoo")

# Inspect the first rows
head(MSFT)

# Plot adjusted close
plot(Ad(MSFT), main = "MSFT adjusted close", ylab = "Price")

# ------------------------------------------------------------------------------
# Chunk 087
# Chapter: R 编程语言
# Section: 通过 API 访问数据
# Subsection: 示例
# Subsubsection: 直接调用 API（进阶但有用）
# ------------------------------------------------------------------------------

# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)

# Example: World Bank API endpoint (returns JSON)
url <- "https://api.worldbank.org/v2/country/SWE/indicator/NY.GDP.PCAP.KD?format=json&per_page=20000"

resp <- request(url) |> req_perform()
txt  <- resp_body_string(resp)

obj <- fromJSON(txt)

# The data are typically in the second element
head(obj[[2]])
