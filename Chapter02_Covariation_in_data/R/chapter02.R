# Chapter 02: 数据中的共同变化
# Textbook data: 国家统计局 70 个大中城市商品住宅销售价格指数（2025）
#
# 教学对应关系：
#   教材变量 living_area -> 新建商品住宅同比价格指数
#   教材变量 price       -> 二手住宅同比价格指数
#
# 本脚本保留原章的计算顺序：散点图、协方差、Pearson 相关、Spearman 秩相关、
# 简单线性回归和 R^2。所有图表文字均使用中文。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
data_path <- file.path(repo_dir, "data", "processed", "nbs_70city_house_price_2025.csv")
fig_dir <- file.path(chapter_dir, "figures")
table_dir <- file.path(chapter_dir, "tables")
result_dir <- file.path(chapter_dir, "results")

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read.csv(data_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)

new_house <- raw[raw$market == "new_house",
                 c("city", "date", "year", "month", "mom_index", "yoy_index")]
second_hand <- raw[raw$market == "second_hand",
                   c("city", "date", "year", "month", "mom_index", "yoy_index")]

names(new_house)[names(new_house) == "mom_index"] <- "new_house_mom"
names(new_house)[names(new_house) == "yoy_index"] <- "new_house_yoy"
names(second_hand)[names(second_hand) == "mom_index"] <- "second_hand_mom"
names(second_hand)[names(second_hand) == "yoy_index"] <- "second_hand_yoy"

df <- merge(new_house, second_hand, by = c("city", "date", "year", "month"))
df <- df[order(df$date, df$city), ]
df <- df[complete.cases(df[, c("new_house_yoy", "second_hand_yoy")]), ]
row.names(df) <- NULL

write.csv(df,
          file.path(result_dir, "chapter02_70city_wide_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 01: R 中相关的计算
# ------------------------------------------------------------------------------

x <- df$new_house_yoy
y <- df$second_hand_yoy

# ------------------------------------------------------------------------------
# Box 02: R 中相关的计算
# ------------------------------------------------------------------------------

xbar <- mean(x)
ybar <- mean(y)

# ------------------------------------------------------------------------------
# Box 03--05: 缺失值检查与完整样本
# ------------------------------------------------------------------------------

missing_check <- data.frame(
  variable = c("new_house_yoy", "second_hand_yoy"),
  missing_count = c(sum(is.na(df$new_house_yoy)), sum(is.na(df$second_hand_yoy)))
)
write.csv(missing_check,
          file.path(result_dir, "chapter02_missing_value_check.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

complete_mask <- !is.na(df$new_house_yoy) & !is.na(df$second_hand_yoy)
df <- df[complete_mask, ]
x <- df$new_house_yoy
y <- df$second_hand_yoy

# ------------------------------------------------------------------------------
# Box 06: 样本均值和样本量
# ------------------------------------------------------------------------------

xbar <- mean(x)
ybar <- mean(y)
n <- nrow(df)

# ------------------------------------------------------------------------------
# Box 07: 样本协方差
# ------------------------------------------------------------------------------

s_xy <- 1 / (n - 1) * sum((x - xbar) * (y - ybar))

# ------------------------------------------------------------------------------
# Box 08: 两个变量的样本方差
# ------------------------------------------------------------------------------

s_x2 <- 1 / (n - 1) * sum((x - xbar)^2)
s_y2 <- 1 / (n - 1) * sum((y - ybar)^2)

# ------------------------------------------------------------------------------
# Box 09--11: Pearson 相关系数
# ------------------------------------------------------------------------------

corr_xy_manual <- s_xy / (sqrt(s_x2) * sqrt(s_y2))
corr_xy_cov <- cov(x, y) / (sd(x) * sd(y))
corr_xy <- cor(x, y)

covariance_table <- df[1:10, c("city", "date", "new_house_yoy", "second_hand_yoy")]
covariance_table$x_minus_xbar <- covariance_table$new_house_yoy - xbar
covariance_table$y_minus_ybar <- covariance_table$second_hand_yoy - ybar
covariance_table$product_xy <- covariance_table$x_minus_xbar * covariance_table$y_minus_ybar

names(covariance_table) <- c("城市", "月份", "新房同比指数", "二手房同比指数",
                             "新房偏离均值", "二手房偏离均值", "偏离乘积")
write.csv(covariance_table,
          file.path(table_dir, "chapter02_covariance_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 12--16: Spearman 秩相关系数
# ------------------------------------------------------------------------------

df$Rx <- rank(df$new_house_yoy, ties.method = "average")
df$Ry <- rank(df$second_hand_yoy, ties.method = "average")

mean_Rx <- (n + 1) / 2
mean_Ry <- (n + 1) / 2

covRxRy <- sum((df$Rx - mean_Rx) * (df$Ry - mean_Ry)) / (n - 1)
sRx <- sqrt(sum((df$Rx - mean_Rx)^2) / (n - 1))
sRy <- sqrt(sum((df$Ry - mean_Ry)^2) / (n - 1))

rS <- covRxRy / (sRx * sRy)
rS_alt <- cor(df$new_house_yoy, df$second_hand_yoy, method = "spearman")

rank_table <- df[1:10, c("city", "date", "new_house_yoy", "second_hand_yoy", "Rx", "Ry")]
names(rank_table) <- c("城市", "月份", "新房同比指数", "二手房同比指数",
                       "新房秩", "二手房秩")
write.csv(rank_table,
          file.path(table_dir, "chapter02_rank_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 17--22: 简单线性回归与判定系数
# ------------------------------------------------------------------------------

beta_1_hat <- s_xy / s_x2
beta_0_hat <- ybar - xbar * beta_1_hat

y_hat <- beta_0_hat + beta_1_hat * x
u_hat <- y - y_hat

RSS <- sum(u_hat^2)
TSS <- sum((y - ybar)^2)
R2 <- 1 - RSS / TSS

ols_model <- lm(second_hand_yoy ~ new_house_yoy, data = df)

summary_table <- data.frame(
  指标 = c("样本量", "新房同比指数均值", "二手房同比指数均值",
           "样本协方差", "新房同比指数方差", "二手房同比指数方差",
           "Pearson相关系数_手算", "Pearson相关系数_cor",
           "Spearman秩相关系数_手算", "Spearman秩相关系数_cor",
           "OLS截距", "OLS斜率", "RSS", "TSS", "R2"),
  数值 = c(n, xbar, ybar, s_xy, s_x2, s_y2,
           corr_xy_manual, corr_xy, rS, rS_alt,
           beta_0_hat, beta_1_hat, RSS, TSS, R2)
)
write.csv(summary_table,
          file.path(result_dir, "chapter02_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

capture.output(summary(ols_model),
               file = file.path(result_dir, "chapter02_lm_summary.txt"))

writeLines(c(
  "第 2 章：数据中的共同变化",
  "",
  "数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025 年月度）。",
  "X：新建商品住宅同比价格指数；Y：二手住宅同比价格指数。",
  "",
  sprintf("完整样本量：%d", n),
  sprintf("Pearson 相关系数：%.4f", corr_xy),
  sprintf("Spearman 秩相关系数：%.4f", rS_alt),
  sprintf("OLS：二手房同比指数 = %.4f + %.4f * 新房同比指数", beta_0_hat, beta_1_hat),
  sprintf("R^2：%.4f", R2)
), con = file.path(result_dir, "chapter02_results_readme.txt"))

write_tex_table <- function(tab, path, caption, label) {
  lines <- c(
    "\\begin{table}[htbp]",
    "\\centering",
    paste0("\\caption{", caption, "}"),
    paste0("\\label{", label, "}"),
    paste0("\\begin{tabular}{", paste(rep("l", ncol(tab)), collapse = ""), "}"),
    "\\hline",
    paste(names(tab), collapse = " & "), "\\\\",
    "\\hline"
  )
  for (i in seq_len(nrow(tab))) {
    row <- vapply(tab[i, ], function(z) {
      if (is.numeric(z)) sprintf("%.3f", z) else as.character(z)
    }, character(1))
    lines <- c(lines, paste(row, collapse = " & "), "\\\\")
  }
  lines <- c(lines, "\\hline", "\\end{tabular}", "\\end{table}")
  writeLines(lines, con = path)
}

write_tex_table(covariance_table,
                file.path(table_dir, "chapter02_covariance_table.tex"),
                "70城新房与二手房同比价格指数的协方差计算示例",
                "tab:ch2-70city-covariance")
write_tex_table(rank_table,
                file.path(table_dir, "chapter02_rank_table.tex"),
                "70城新房与二手房同比价格指数的秩相关计算示例",
                "tab:ch2-70city-rank")

# ------------------------------------------------------------------------------
# Figures with Chinese labels
# ------------------------------------------------------------------------------

use_quartz <- isTRUE(capabilities("aqua"))
if (use_quartz) {
  try(quartzFonts(PingFang = quartzFont(rep("PingFangSC-Regular", 4))), silent = TRUE)
}
png_type <- if (use_quartz) "quartz" else "cairo"
cn_family <- if (use_quartz) "PingFang" else ""

open_png <- function(filename, width = 1800, height = 1300, res = 220) {
  grDevices::png(filename = file.path(fig_dir, filename),
                 width = width, height = height, res = res, type = png_type)
  par(family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
}

month_cols <- grDevices::hcl.colors(12, "Dark 3")
point_cols <- adjustcolor(month_cols[df$month], alpha.f = 0.65)

open_png("chapter02_scatter_new_vs_second_hand_yoy.png")
plot(x, y, pch = 16, col = point_cols,
     xlab = "新建商品住宅同比价格指数",
     ylab = "二手住宅同比价格指数",
     main = "70城新房与二手房价格同比指数")
grid(col = "gray85")
legend("topleft", legend = paste0(1:12, "月"), col = month_cols, pch = 16,
       title = "月份", ncol = 3, cex = 0.72, bty = "n")
dev.off()

open_png("chapter02_scatter_with_regression_line.png")
plot(x, y, pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "新建商品住宅同比价格指数",
     ylab = "二手住宅同比价格指数",
     main = "70城价格指数散点图与OLS拟合线")
grid(col = "gray85")
abline(ols_model, col = "#D95F0E", lwd = 2)
legend("topleft", legend = c("城市-月份观测", "OLS拟合线"),
       col = c("#2C7FB8", "#D95F0E"), pch = c(16, NA), lty = c(NA, 1),
       lwd = c(NA, 2), bty = "n")
dev.off()

set.seed(20260524)
x_demo <- seq(0, 10, length.out = 120)
y_monotone <- 2 + log1p(x_demo) + rnorm(length(x_demo), sd = 0.08)
y_ushape <- 0.15 * (x_demo - 5)^2 + rnorm(length(x_demo), sd = 0.12)

open_png("chapter02_nonlinear_examples.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
plot(x_demo, y_monotone, pch = 16, col = adjustcolor("#1B9E77", alpha.f = 0.7),
     xlab = "变量X", ylab = "变量Y", main = "单调但非线性的共同变化")
lines(lowess(x_demo, y_monotone), col = "#D95F02", lwd = 2)
grid(col = "gray85")
plot(x_demo, y_ushape, pch = 16, col = adjustcolor("#7570B3", alpha.f = 0.7),
     xlab = "变量X", ylab = "变量Y", main = "U形共同变化")
lines(lowess(x_demo, y_ushape), col = "#D95F02", lwd = 2)
grid(col = "gray85")
dev.off()

x_rank <- 1:15
y_rank <- sqrt(x_rank) + c(-0.10, 0.05, 0.02, -0.03, 0.06, -0.04, 0.03, 0.02,
                           -0.05, 0.04, -0.02, 0.06, -0.03, 0.02, 0.00)
x_outlier <- c(x_rank, 18)
y_outlier <- c(y_rank, -0.6)

open_png("chapter02_pearson_spearman_examples.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
plot(x_rank, y_rank, pch = 16, col = "#1B9E77",
     xlab = "变量X", ylab = "变量Y", main = "Spearman关注秩次")
legend("bottomright",
       legend = c(sprintf("Pearson = %.2f", cor(x_rank, y_rank)),
                  sprintf("Spearman = %.2f", cor(x_rank, y_rank, method = "spearman"))),
       bty = "n")
grid(col = "gray85")
plot(x_outlier, y_outlier, pch = 16, col = "#7570B3",
     xlab = "变量X", ylab = "变量Y", main = "Pearson更容易受极端值影响")
points(18, -0.6, pch = 17, col = "#D95F02", cex = 1.4)
legend("bottomleft",
       legend = c(sprintf("Pearson = %.2f", cor(x_outlier, y_outlier)),
                  sprintf("Spearman = %.2f", cor(x_outlier, y_outlier, method = "spearman")),
                  "极端值"),
       pch = c(NA, NA, 17), col = c("black", "black", "#D95F02"), bty = "n")
grid(col = "gray85")
dev.off()

open_png("chapter02_r2_examples.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
x_r2 <- seq(0, 10, length.out = 80)
y_low <- 2 + 0.5 * x_r2 + rnorm(80, sd = 2.0)
y_high <- 2 + 0.5 * x_r2 + rnorm(80, sd = 0.35)
fit_low <- lm(y_low ~ x_r2)
fit_high <- lm(y_high ~ x_r2)
plot(x_r2, y_low, pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "解释变量X", ylab = "被解释变量Y",
     main = sprintf("解释度较低：R² = %.2f", summary(fit_low)$r.squared))
abline(fit_low, col = "#D95F0E", lwd = 2)
grid(col = "gray85")
plot(x_r2, y_high, pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "解释变量X", ylab = "被解释变量Y",
     main = sprintf("解释度较高：R² = %.2f", summary(fit_high)$r.squared))
abline(fit_high, col = "#D95F0E", lwd = 2)
grid(col = "gray85")
dev.off()

message("Chapter 02 complete. Outputs written to: ", chapter_dir)
