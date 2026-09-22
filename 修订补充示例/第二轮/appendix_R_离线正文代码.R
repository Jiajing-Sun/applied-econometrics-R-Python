# R程序附录：本版离线练习入口。
# 请从“配套代码”根目录运行，按书中顺序执行。
# 安装命令、自备文件模板、交互帮助及联网API不在此离线脚本中。
# 不含审查辅助断言；代码内部用于教学的输入检查保留。

# 教材：Appendix R program.tex:129；代码块序号 0
# 基本算术运算
5 + 9
15 - 7
8 * 9
144 / 12

# 幂与开方
3^4
sqrt(81)

# 括号按通常的运算优先级生效
(5 + 9) * 2

# 教材：Appendix R program.tex:152；代码块序号 1
# 数值向量
x <- c(1, 2, 3, 4)

# 每个元素都加 10
x + 10

# 逐元素相乘
x * c(2, 2, 2, 2)

# 比较数值（返回逻辑向量）
x > 2

# 教材：Appendix R program.tex:169；代码块序号 2
# 循环补齐：重复 c(1, 2) 以匹配长度 6
1:6 + c(1, 2)

# 若较长向量的长度不是较短向量长度的整数倍，
# R 会给出警告。
1:5 + c(1, 2)

# 教材：Appendix R program.tex:182；代码块序号 3
# R 中的单个数通常以双精度浮点数（numeric）存储
str(2)
typeof(2)

# 整数使用后缀 L
str(2L)
typeof(2L)

# 字符串
str("hello")
typeof("hello")

# 教材：Appendix R program.tex:198；代码块序号 4
# 一个小型数据框
df <- data.frame(
  id    = 1:3,
  group = c("A", "A", "B"),
  y     = c(1.2, 0.7, 2.4)
)

head(df)
summary(df)
str(df)

# 教材：Appendix R program.tex:217；代码块序号 5
# 内置圆周率 pi
pi

# 可用 exp(1) 得到自然常数 e
exp(1)

# 自然对数与指数函数
log(10)
exp(2)

# 教材：Appendix R program.tex:237；代码块序号 6
# 缺失值
NA

# 未定义运算
0/0        # NaN
1/0        # Inf
-1/0       # -Inf

# 检查各对象的类型与性质
is.na(NA)
is.nan(0/0)
is.finite(1/0)

# 教材：Appendix R program.tex:255；代码块序号 7
# 与 1 可分辨的最小差值（近似）
.Machine$double.eps

# 最小正正规数与最大有限正双精度数
.Machine$double.xmin
.Machine$double.xmax

# 教材：Appendix R program.tex:288；代码块序号 8
# 遍历数值
for (k in 1:5) {
  print(k)
}

# 遍历任意向量
cities <- c("Beijing", "Shanghai", "Guangzhou")
for (c in cities) {
  print(c)
}

# 教材：Appendix R program.tex:304；代码块序号 9
x <- c(10, 20, 30)

for (i in seq_along(x)) {
  print(x[i])
}

# 教材：Appendix R program.tex:315；代码块序号 10
x <- 1:5

# 预先分配数值向量
y <- numeric(length(x))

for (i in seq_along(x)) {
  y[i] <- x[i]^2
}

y

# 教材：Appendix R program.tex:333；代码块序号 11
i <- 1
while (i <= 5) {
  print(i)
  i <- i + 1
}

# 教材：Appendix R program.tex:346；代码块序号 12
# 示例：最多迭代 100 次后停止
iter <- 0
value <- 1

while (value < 1000 && iter < 100) {
  value <- value * 1.2
  iter  <- iter + 1
}

c(iter = iter, value = value)

# 教材：Appendix R program.tex:364；代码块序号 13
i <- 0
repeat {
  i <- i + 1
  print(i)

  if (i >= 5) {
    break
  }
}

# 教材：Appendix R program.tex:388；代码块序号 14
x <- 1:10

# 向量化：一次计算所有元素的平方
x^2

# 向量化：计算平方和
sum(x^2)

# 教材：Appendix R program.tex:407；代码块序号 15
# lapply 返回列表
lapply(1:5, function(a) a + 1)

# sapply 会尝试简化为向量
sapply(1:5, function(a) a + 1)

# 教材：Appendix R program.tex:419；代码块序号 16
# 匿名函数（紧凑写法）
sapply(1:5, \(a) a + 1)

# 教材：Appendix R program.tex:438；代码块序号 17
add_numbers <- function(a, b) {
  a + b
}

add_numbers(5, 3)

# 教材：Appendix R program.tex:449；代码块序号 18
power <- function(x, p = 2) {
  x^p
}

power(3)          # uses p = 2
power(3, p = 4)   # explicit
power(x = 3, p = 4)

# 教材：Appendix R program.tex:462；代码块序号 19
# （1）复利极限：(1 + 1/n)^n
approx_e_limit <- function(n = 1000) {
  (1 + 1/n)^n
}

# （2）用循环计算级数展开：sum_{k=0}^n 1/k!
approx_e_series_loop <- function(n = 10) {
  out <- 0
  for (k in 0:n) {
    out <- out + 1 / factorial(k)
  }
  out
}

# （3）向量化计算级数展开
approx_e_series_vec <- function(n = 10) {
  sum(1 / factorial(0:n))
}

approx_e_limit(10)
approx_e_series_loop(10)
approx_e_series_vec(10)
exp(1)  # reference value

# 教材：Appendix R program.tex:505；代码块序号 20
x_num <- c(1, 3, 5, 7, 9)
x_chr <- c("Emma", "Liam", "Noah")
x_log <- c(TRUE, FALSE, TRUE)

length(x_num)
x_num[1]      # first element
x_num[2:4]    # a slice

# 教材：Appendix R program.tex:518；代码块序号 21
c(1, "two", 3)    # coerces to character

# 教材：Appendix R program.tex:527；代码块序号 22
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

# 教材：Appendix R program.tex:547；代码块序号 23
df <- data.frame(
  name    = c("Emma", "Liam", "Noah", "Olivia"),
  age     = c(32, 17, 45, 27),
  is_adult = c(TRUE, FALSE, TRUE, TRUE)
)

df
nrow(df)
ncol(df)

df$age
df[1:2, ]        # first two rows
df[, c("name", "age")]

# 教材：Appendix R program.tex:573；代码块序号 24
M <- matrix(
  c(10, 20, 30,
    40, 50, 60,
    70, 80, 90),
  nrow = 3, byrow = TRUE
)

M
M[1, 2]      # row 1, column 2
M[, 1]       # first column

# 教材：Appendix R program.tex:591；代码块序号 25
A <- array(1:12, dim = c(2, 3, 2))
A
dim(A)
A[1, , 1]    # first row, all columns, first "slice"

# 教材：Appendix R program.tex:603；代码块序号 26
f <- factor(c("Low", "Medium", "High", "Low", "High"))
f
levels(f)
table(f)

# 教材：Appendix R program.tex:637；代码块序号 27
# 查看当前工作目录
getwd()

# 若必须更改工作目录，请在脚本开头统一设置：
# setwd("/path/to/your/project")

# 常用替代方案是用 {here} 包构造项目相对路径：
# install.packages("here")
# library(here)
# here("data", "my_file.csv")

# 教材：Appendix R program.tex:655；代码块序号 28
# 用 base R 导入
df_base <- read.csv("data/processed/nbs_70city_house_price_2025.csv", fileEncoding = "UTF-8-BOM")

# 快速检查
head(df_base)
str(df_base)

# 教材：Appendix R program.tex:664；代码块序号 29
# 快速易用的导入方式（tidyverse 风格）
# install.packages("readr")
library(readr)

# 返回 tibble（现代数据框）
df <- read_csv("data/processed/nbs_70city_house_price_2025.csv")  
# 用 dplyr 查看紧凑概览
str(df)

# 教材：Appendix R program.tex:681；代码块序号 30
# 示例：指定 R 应将哪些字符串视为缺失值
df2 <- read.csv("data/processed/nbs_70city_house_price_2025.csv", na.strings = c("", "NA", ".",
        "-999"))

# 教材：Appendix R program.tex:746；代码块序号 34
# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)

# 示例模板（网址仅作说明；不同 API 的格式不同）
get_api_json <- function(api_endpoint, query = list()) {
  req <- request(api_endpoint)
  req <- do.call(req_url_query, c(list(req), query))
  resp <- req |> req_timeout(30) |> req_perform()
  fromJSON(resp_body_string(resp))
}
# 定义函数不会联网。先从数据提供方文档取得真实端点和参数，
# 再调用 get_api_json(端点字符串, 参数列表)。
# 后文给出世界银行的具体例子。

# 教材：Appendix R program.tex:777；代码块序号 35
library(readr)

housing <- read_csv(
  "data/processed/nbs_70city_house_price_2025.csv",
  locale = locale(encoding = "UTF-8")
)
head(housing)
str(housing)

# 教材：Appendix R program.tex:793；代码块序号 36
# 按列名选取若干列
housing_small <- housing[, c("year", "month", "city", "market",
                              "mom_index", "yoy_index")]

# 取前10行
housing_first10 <- housing[1:10, ]

# 取单列（返回向量）
mom <- housing$mom_index

# 教材：Appendix R program.tex:811；代码块序号 37
# 只保留新建住宅
new_house <- housing[housing$market == "new_house", ]

# 只保留环比指数和同比指数均不缺失的行
housing_clean <- housing[housing$market == "new_house" &
                          !is.na(housing$mom_index) &
                          !is.na(housing$yoy_index), ]

nrow(housing_clean)

# 教材：Appendix R program.tex:827；代码块序号 38
# 环比偏离（距基准 100 的偏差）
housing_clean$mom_deviation <- housing_clean$mom_index - 100

# 同比偏离
housing_clean$yoy_deviation <- housing_clean$yoy_index - 100

# 价格是否上涨（环比 > 100）的逻辑变量
housing_clean$price_up <- housing_clean$mom_index > 100

head(housing_clean)

# 教材：Appendix R program.tex:845；代码块序号 39
# 按年份计算平均环比指数（base R）
avg_mom_by_year <- aggregate(mom_index ~ year, data = housing_clean,
                   FUN = mean, na.rm = TRUE)
avg_mom_by_year

# 按年份计算平均同比指数
avg_yoy_by_year <- aggregate(yoy_index ~ year, data = housing_clean,
                   FUN = mean, na.rm = TRUE)
avg_yoy_by_year

# 教材：Appendix R program.tex:865；代码块序号 40
avg_by_year <- aggregate(cbind(mom_index, yoy_index) ~ year,
                         data = housing_clean, FUN = mean,
                         na.rm = TRUE)
avg_by_year

# 教材：Appendix R program.tex:877；代码块序号 41
# 整体摘要
summary(housing_clean[, c("mom_index", "yoy_index")])

# 环比指数的均值和方差
mean(housing_clean$mom_index)
var(housing_clean$mom_index)

# 分位数
quantile(housing_clean$mom_index, probs = c(0.1, 0.5, 0.9), na.rm = TRUE)

# 各年份观测数
table(housing_clean$year)

# 教材：Appendix R program.tex:902；代码块序号 42
dir.create("output", showWarnings = FALSE)
saveRDS(housing_clean, file = "output/housing_new_clean.rds")
housing_loaded <- readRDS("output/housing_new_clean.rds")

# 教材：Appendix R program.tex:908；代码块序号 43
avg_mom <- aggregate(mom_index ~ year, data = housing_clean, FUN = mean)
avg_yoy <- aggregate(yoy_index ~ year, data = housing_clean, FUN = mean)

save(housing_clean, avg_mom, avg_yoy, file = "output/housing_objects.RData")

# 教材：Appendix R program.tex:918；代码块序号 44
avg_by_year <- aggregate(cbind(mom_index, yoy_index) ~ year,
                         data = housing_clean, FUN = mean, na.rm = TRUE)

write.csv(avg_by_year, file = "output/housing_avg_by_year.csv", row.names = FALSE)

# 教材：Appendix R program.tex:925；代码块序号 45
# install.packages("writexl")
library(writexl)
write_xlsx(avg_by_year, path = "output/housing_avg_by_year.xlsx")

# 教材：Appendix R program.tex:934；代码块序号 46
market_type <- "new_house"
end_year    <- max(housing_clean$year)

fname <- paste0("output/housing_", market_type, "_to_", end_year, ".rds")
saveRDS(housing_clean, file = fname)

# 教材：Appendix R program.tex:964；代码块序号 47
# 散点图：环比指数与同比指数
plot(housing_clean$mom_index, housing_clean$yoy_index,
     xlab = "环比指数（上月=100）",
     ylab = "同比指数（上年同月=100）",
     main = "70城新建住宅价格指数：环比与同比")

# 环比指数直方图
hist(housing_clean$mom_index,
     xlab = "月度环比指数",
     main = "70城新建住宅环比指数直方图")

# 按月份绘制环比指数箱线图
boxplot(mom_index ~ factor(month), data = housing_clean,
        xlab = "2025年月次", ylab = "环比指数",
        main = "2025年各月环比指数分布",
        las = 2, cex.axis = 0.7)

# 教材：Appendix R program.tex:987；代码块序号 48
dir.create("output/figures/R", recursive = TRUE, showWarnings = FALSE)

png("output/figures/R/housing_mom_vs_yoy.png", width = 900, height = 650,
     res = 120)
plot(housing_clean$mom_index, housing_clean$yoy_index,
     xlab = "环比指数（上月=100）", ylab = "同比指数（上年同月=100）",
     main = "70城新建住宅价格指数：环比与同比")
dev.off()

# 教材：Appendix R program.tex:1002；代码块序号 49
# install.packages("ggplot2")
library(ggplot2)

p <- ggplot(housing_clean, aes(x = mom_index, y = yoy_index)) +
  geom_point(alpha = 0.3, na.rm = TRUE) +
  labs(x = "环比指数（上月=100）", y = "同比指数（上年同月=100）",
       title = "70城新建住宅价格指数：环比与同比")

p

# 教材：Appendix R program.tex:1016；代码块序号 50
# 保存设备与图形对象都显式指定中文字体。
cn_font <- "Noto Sans CJK SC"  # 其他系统先安装或替换为已有中文字体
png_type <- "cairo"
if (capabilities("aqua")) {
  quartzFonts(PingFang = quartzFont(rep("PingFangSC-Regular", 4)))
  cn_font <- "PingFang"
  png_type <- "quartz"
}
p <- p + theme(text = element_text(family = cn_font))
ggsave("output/figures/R/housing_mom_yoy_ggplot.png", plot = p,
       width = 7.5, height = 5.5, dpi = 150,
       device = grDevices::png, type = png_type)

# 教材：Appendix R program.tex:1068；代码块序号 53
example(runif)

# 教材：Appendix R program.tex:1078；代码块序号 54
args(runif)
formals(runif)

# 教材：Appendix R program.tex:1085；代码块序号 55
stats::runif(5)

# 教材：Appendix R program.tex:1105；代码块序号 57
apropos("unif")

# 教材：Appendix R program.tex:1337；代码块序号 63
set.seed(1234)
rnorm(5)

set.seed(1234)
rnorm(5)   # identical output

# 教材：Appendix R program.tex:1376；代码块序号 64
set.seed(1)

n <- 10000
rate <- 2

u <- runif(n)
x_icdf <- -log(u) / rate         # inverse cdf method
x_rexp <- rexp(n, rate = rate)   # built-in generator

c(mean_icdf = mean(x_icdf), mean_rexp = mean(x_rexp))
c(var_icdf  = var(x_icdf),  var_rexp  = var(x_rexp))

# 教材：Appendix R program.tex:1407；代码块序号 65
set.seed(2)

vals  <- c(0, 1, 2, 5)
probs <- c(0.10, 0.30, 0.50, 0.10)
cdf   <- cumsum(probs)

n <- 20
u <- runif(n)

# 通过广义逆把 u 映射到 vals
stopifnot(length(vals) == length(probs), all(diff(vals) > 0),
          all(probs >= 0), abs(sum(probs) - 1) < 1e-12)
cdf[length(cdf)] <- 1
idx <- vapply(u, function(ui) which(cdf >= ui)[1], integer(1))
x_icdf_discrete <- vals[idx]

x_icdf_discrete

# 与 R 内置的离散分布抽样函数比较
x_sample <- sample(vals, size = n, replace = TRUE, prob = probs)
x_sample

# 教材：Appendix R program.tex:1443；代码块序号 66
qnorm_uniroot <- function(u, lower = -10, upper = 10) {
  stopifnot(u > 0, u < 1)
  f <- function(x) pnorm(x) - u
  uniroot(f, interval = c(lower, upper))$root
}

set.seed(3)
u <- runif(5)
sapply(u, qnorm_uniroot)

# 教材：Appendix R program.tex:1509；代码块序号 67
# 如有需要：
# install.packages(c("dplyr", "readr"))
library(dplyr)
library(readr)

wdi <- read_csv(
  "data/processed/wdi_global_selected_indicators_wide.csv",
  locale = locale(encoding = "UTF-8")
)

# 检查结构
wdi |>
  select(country, country_code, year,
         gdp_per_capita_constant_2015_usd, life_expectancy) |>
  head()

# 教材：Appendix R program.tex:1530；代码块序号 68
asia <- wdi |>
  filter(country_code %in% c("CHN", "JPN", "KOR", "IND", "IDN"),
         !is.na(gdp_per_capita_constant_2015_usd),
         !is.na(life_expectancy)) |>
  select(country, year, gdp_per_capita_constant_2015_usd,
         life_expectancy, gdp_growth_pct) |>
  arrange(country, year)

head(asia, 10)

# 教材：Appendix R program.tex:1545；代码块序号 69
asia <- asia |>
  mutate(
    log_gdppc = log(gdp_per_capita_constant_2015_usd),
    decade    = (year %/% 10) * 10
  )

# 教材：Appendix R program.tex:1556；代码块序号 70
asia |>
  filter(!is.na(gdp_growth_pct)) |>
  group_by(country, decade) |>
  summarise(
    avg_growth  = mean(gdp_growth_pct, na.rm = TRUE),
    avg_lifeexp = mean(life_expectancy),
    n           = n(),
    .groups     = "drop"
  ) |>
  filter(n >= 5) |>
  arrange(country, decade)

# 教材：Appendix R program.tex:1589；代码块序号 71
# 如有需要：
# install.packages(c("ggplot2", "readr", "dplyr"))
library(ggplot2)
library(readr)
library(dplyr)

housing <- read_csv(
  "data/processed/nbs_70city_house_price_2025.csv",
  locale = locale(encoding = "UTF-8")
)
housing_new <- housing |>
  filter(market == "new_house", !is.na(mom_index), !is.na(yoy_index)) |>
  mutate(date = as.Date(paste0(date, "-01"), format = "%Y-%m-%d"))
housing_all <- housing |>
  filter(market %in% c("new_house", "second_hand"),
         !is.na(mom_index), !is.na(yoy_index)) |>
  mutate(market_cn = ifelse(market == "new_house", "新建住宅", "二手住宅"),
         date      = as.Date(paste0(date, "-01"), format = "%Y-%m-%d"))
cities5  <- c("北京", "上海", "广州", "成都", "西安")
housing5 <- housing_new |> filter(city %in% cities5)

# 教材：Appendix R program.tex:1616；代码块序号 72
ggplot(housing_new, aes(x = mom_index, y = yoy_index)) +
  labs(title = "70城新建商品住宅价格指数（仅数据层）")

# 教材：Appendix R program.tex:1625；代码块序号 73
ggplot(housing_all,
       aes(x = mom_index, y = yoy_index, colour = market_cn)) +
  geom_point(alpha = 0.35, size = 0.9) +
  geom_vline(xintercept = 100, linetype = "dashed", colour = "grey60") +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  scale_colour_manual(values = c("新建住宅" = "#2166ac",
                                  "二手住宅" = "#d6604d")) +
  labs(title = "环比与同比房价指数（按市场类型区分）",
       x = "环比指数（上月=100）",
       y = "同比指数（上年同月=100）",
       colour = "市场类型")

# 教材：Appendix R program.tex:1643；代码块序号 74
ggplot(housing_new, aes(x = mom_index)) +
  geom_histogram(bins = 30, fill = "#4393c3", colour = "white",
                 linewidth = 0.3) +
  geom_vline(xintercept = 100, linetype = "dashed", colour = "firebrick",
             linewidth = 1.2) +
  labs(title = "70城新建住宅环比价格指数分布",
       x = "月度环比指数（新建住宅）", y = "频次")

# 教材：Appendix R program.tex:1657；代码块序号 75
ggplot(housing5, aes(x = date, y = mom_index)) +
  geom_point(size = 0.8, alpha = 0.6, colour = "#2166ac") +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  facet_wrap(~ city, nrow = 1) +
  labs(title = "五城市新建住宅月度环比价格指数",
       x = "", y = "环比指数") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

# 教材：Appendix R program.tex:1671；代码块序号 76
bj <- housing5 |> filter(city == "北京") |> arrange(date)

ggplot(bj, aes(x = date, y = mom_index)) +
  geom_point(size = 1.2, alpha = 0.7, colour = "#4393c3") +
  geom_smooth(method = "lm", se = FALSE, colour = "firebrick",
              linewidth = 1.5) +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  labs(title = "北京新建住宅环比价格指数与线性趋势",
       x = "日期", y = "环比指数（新建住宅）")

# 教材：Appendix R program.tex:1687；代码块序号 77
ggplot(
  housing_all,
  aes(x = mom_index, y = yoy_index, colour = market_cn)
) +
  geom_point(alpha = 0.35, size = 0.9) +
  coord_cartesian(xlim = c(96, 104), ylim = c(85, 115)) +
  scale_colour_manual(values = c("新建住宅" = "#2166ac",
                                  "二手住宅" = "#d6604d")) +
  labs(title = "2025年房价指数缩放视图",
       x = "环比指数", y = "同比指数", colour = "市场类型")

# 教材：Appendix R program.tex:1704；代码块序号 78
ggplot(housing5, aes(x = date, y = mom_index)) +
  geom_point(size = 0.8, alpha = 0.55, colour = "#636363") +
  geom_hline(yintercept = 100, colour = "#cccccc") +
  facet_wrap(~ city, nrow = 1) +
  theme_minimal() +
  labs(title = "五城市新建住宅价格（极简主题）",
       x = "", y = "环比指数") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

# 教材：Appendix R program.tex:1719；代码块序号 79
p <- ggplot(housing_all,
            aes(x = mom_index, y = yoy_index, colour = market_cn)) +
  geom_point(alpha = 0.3, size = 0.9) +
  scale_colour_manual(values = c("新建住宅" = "#2166ac",
                                  "二手住宅" = "#d6604d")) +
  labs(title = "新旧住宅环比与同比价格指数",
       x = "环比指数（上月=100）",
       y = "同比指数（上年同月=100）",
       colour = "市场类型")

fig_dir <- file.path("output", "figures", "R")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# 沿用前面保存示例定义的 cn_font 和 png_type。
p <- p + theme(text = element_text(family = cn_font))
ggsave(file.path(fig_dir, "housing70_saved_plot.png"),
       p, width = 6.5, height = 4.5, dpi = 150,
       device = grDevices::png, type = png_type)

# 保留图形对象以备后续修改
p
