# Chapter 05: 一元线性回归模型
#
# 本章数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025）。
# 教学对应关系：
#   教材变量 price       -> 二手住宅同比价格指数
#   教材变量 living_area -> 新建商品住宅同比价格指数
#   教材变量 new_production -> 是否一线城市（北京、上海、广州、深圳）
#
# 本脚本保留原章方法：简单 OLS、球形误差标准误、t 检验、置信区间、
# 二元自变量回归、Eicker-Huber-White/HC0 稳健标准误，以及 DGP Monte Carlo。

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
df <- df[complete.cases(df[, c("new_house_yoy", "second_hand_yoy")]), ]
df$first_tier_city <- as.integer(df$city %in% c("北京", "上海", "广州", "深圳"))
df <- df[order(df$date, df$city), ]
row.names(df) <- NULL

write.csv(df,
          file.path(result_dir, "chapter05_70city_regression_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

x <- df$new_house_yoy
y <- df$second_hand_yoy
n <- nrow(df)
xbar <- mean(x)
ybar <- mean(y)
SXX <- sum((x - xbar)^2)
SXY <- sum((x - xbar) * (y - ybar))
beta_1_hat <- SXY / SXX
beta_0_hat <- ybar - beta_1_hat * xbar
y_hat <- beta_0_hat + beta_1_hat * x
u_hat <- y - y_hat
RSS <- sum(u_hat^2)
TSS <- sum((y - ybar)^2)
R2 <- 1 - RSS / TSS
ols_model <- lm(second_hand_yoy ~ new_house_yoy, data = df)

# ------------------------------------------------------------------------------
# Box 01: R 中的回归推断
# ------------------------------------------------------------------------------

s2_epsilon <- RSS / (n - 2)
SSX <- sum((df$new_house_yoy - mean(df$new_house_yoy))^2)
var_hat_beta_1_hat <- s2_epsilon / SSX

# ------------------------------------------------------------------------------
# Box 02: R 中的回归推断
# ------------------------------------------------------------------------------

beta_1_H0 <- 0
se_beta_1_hat <- sqrt(var_hat_beta_1_hat)
t_stat <- (beta_1_hat - beta_1_H0) / se_beta_1_hat
p_val <- 2 * (1 - pt(abs(t_stat), df = n - 2))

# ------------------------------------------------------------------------------
# Box 03: R 中的回归推断
# ------------------------------------------------------------------------------

alpha <- 0.1
t_crit <- qt(1 - alpha / 2, df = n - 2)
lb <- beta_1_hat - t_crit * se_beta_1_hat
ub <- beta_1_hat + t_crit * se_beta_1_hat

# ------------------------------------------------------------------------------
# Box 04--07: lm() 输出、系数表和置信区间
# ------------------------------------------------------------------------------

sum_ols_model <- summary(ols_model)
reg_table <- sum_ols_model$coefficients
t_from_lm <- reg_table[2, 3]
ci_lm_90 <- confint(ols_model, level = 0.9)

standard_table <- data.frame(
  项 = c("截距", "新房同比指数"),
  估计值 = coef(ols_model),
  标准误 = reg_table[, 2],
  t统计量 = reg_table[, 3],
  p值 = reg_table[, 4],
  CI90下限 = ci_lm_90[, 1],
  CI90上限 = ci_lm_90[, 2]
)
write.csv(standard_table,
          file.path(table_dir, "chapter05_ols_standard_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 08--09: 二元自变量回归
# ------------------------------------------------------------------------------

ols_model2 <- lm(second_hand_yoy ~ first_tier_city, data = df)
ci_model2_90 <- confint(ols_model2, level = 0.9)
model2_summary <- summary(ols_model2)$coefficients
binary_table <- data.frame(
  项 = c("截距", "一线城市"),
  估计值 = coef(ols_model2),
  标准误 = model2_summary[, 2],
  t统计量 = model2_summary[, 3],
  p值 = model2_summary[, 4],
  CI90下限 = ci_model2_90[, 1],
  CI90上限 = ci_model2_90[, 2]
)
write.csv(binary_table,
          file.path(table_dir, "chapter05_binary_city_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 10--14: R 中的稳健推断
# ------------------------------------------------------------------------------

dx2 <- (df$new_house_yoy - mean(df$new_house_yoy))^2
var_beta_1_var_r <- sum(dx2 * u_hat^2) / (sum(dx2))^2
se_beta_1_hat_r <- sqrt(var_beta_1_var_r)

Xmat <- cbind("(Intercept)" = 1, "new_house_yoy" = x)
bread <- solve(t(Xmat) %*% Xmat)
meat <- t(Xmat) %*% (Xmat * as.numeric(u_hat^2))
vcov_hc0 <- bread %*% meat %*% bread
se_hc0 <- sqrt(diag(vcov_hc0))
t_hc0 <- coef(ols_model) / se_hc0
p_hc0 <- 2 * (1 - pt(abs(t_hc0), df = n - 2))
ci_hc0 <- cbind(coef(ols_model) - t_crit * se_hc0,
                coef(ols_model) + t_crit * se_hc0)

robust_table <- data.frame(
  项 = c("截距", "新房同比指数"),
  估计值 = coef(ols_model),
  HC0稳健标准误 = se_hc0,
  t统计量 = t_hc0,
  p值 = p_hc0,
  CI90下限 = ci_hc0[, 1],
  CI90上限 = ci_hc0[, 2]
)
write.csv(robust_table,
          file.path(table_dir, "chapter05_ols_hc0_robust_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

model_summary <- data.frame(
  指标 = c("样本量", "OLS截距", "OLS斜率", "RSS", "TSS", "R2",
           "普通斜率标准误", "普通斜率t统计量", "普通斜率p值",
           "普通斜率90%CI下限", "普通斜率90%CI上限",
           "HC0斜率标准误", "HC0斜率t统计量", "HC0斜率p值",
           "HC0斜率90%CI下限", "HC0斜率90%CI上限",
           "一线城市斜率", "一线城市斜率p值"),
  数值 = c(n, beta_0_hat, beta_1_hat, RSS, TSS, R2,
           se_beta_1_hat, t_stat, p_val, lb, ub,
           se_hc0[2], t_hc0[2], p_hc0[2], ci_hc0[2, 1], ci_hc0[2, 2],
           coef(ols_model2)[2], model2_summary[2, 4])
)
write.csv(model_summary,
          file.path(result_dir, "chapter05_regression_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
capture.output(summary(ols_model),
               file = file.path(result_dir, "chapter05_lm_summary.txt"))
capture.output(summary(ols_model2),
               file = file.path(result_dir, "chapter05_binary_lm_summary.txt"))

# ------------------------------------------------------------------------------
# DGP Monte Carlo: standard vs robust t statistics
# ------------------------------------------------------------------------------

set.seed(20260524)
nr_samples <- 10000
n_mc <- 30
tstat_standard <- rep(NA_real_, nr_samples)
tstat_robust <- rep(NA_real_, nr_samples)

for (i in 1:nr_samples) {
  X <- runif(n_mc, min = 0, max = 1)
  E <- rchisq(n_mc, df = 1)
  Y <- 0.3 + 0.2 * X * E

  xbar_mc <- mean(X)
  ybar_mc <- mean(Y)
  SXX_mc <- sum((X - xbar_mc)^2)
  SXY_mc <- sum((X - xbar_mc) * (Y - ybar_mc))
  beta1_mc <- SXY_mc / SXX_mc
  beta0_mc <- ybar_mc - beta1_mc * xbar_mc
  u_mc <- Y - (beta0_mc + beta1_mc * X)
  RSS_mc <- sum(u_mc^2)

  s2_mc <- RSS_mc / (n_mc - 2)
  se_standard_mc <- sqrt(s2_mc / SXX_mc)
  var_robust_mc <- sum(((X - xbar_mc)^2) * u_mc^2) / (SXX_mc^2)
  se_robust_mc <- sqrt(var_robust_mc)

  tstat_standard[i] <- (beta1_mc - 0.2) / se_standard_mc
  tstat_robust[i] <- (beta1_mc - 0.2) / se_robust_mc
}

dgp_summary <- data.frame(
  统计量 = c("普通标准误t统计量均值", "普通标准误t统计量方差",
           "稳健标准误t统计量均值", "稳健标准误t统计量方差",
           "t分布理论方差_df28"),
  数值 = c(mean(tstat_standard), var(tstat_standard),
           mean(tstat_robust), var(tstat_robust),
           (n_mc - 2) / (n_mc - 4))
)
write.csv(dgp_summary,
          file.path(result_dir, "chapter05_dgp_monte_carlo_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(data.frame(模拟编号 = seq_len(nr_samples),
                     普通标准误t统计量 = tstat_standard,
                     稳健标准误t统计量 = tstat_robust),
          file.path(result_dir, "chapter05_dgp_tstat_distribution.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Figures
# ------------------------------------------------------------------------------

open_png("chapter05_70city_simple_regression.png")
plot(x, y, pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "新建商品住宅同比价格指数",
     ylab = "二手住宅同比价格指数",
     main = "一元线性回归：二手房指数对新房指数")
grid(col = "gray85")
abline(ols_model, col = "#D95F0E", lwd = 2)
legend("topleft", legend = c("城市-月份观测", "OLS拟合线"),
       pch = c(16, NA), lty = c(NA, 1), lwd = c(NA, 2),
       col = c("#2C7FB8", "#D95F0E"), bty = "n")
dev.off()

open_png("chapter05_residuals_vs_fitted.png")
plot(y_hat, u_hat, pch = 16, col = adjustcolor("#7570B3", alpha.f = 0.65),
     xlab = "拟合值",
     ylab = "残差",
     main = "残差与拟合值")
grid(col = "gray85")
abline(h = 0, col = "#D95F0E", lwd = 2, lty = 2)
dev.off()

open_png("chapter05_first_tier_city_boxplot.png", width = 1600, height = 1000)
boxplot(second_hand_yoy ~ first_tier_city, data = df,
        names = c("其他城市", "一线城市"),
        col = c("#A6CEE3", "#FDBF6F"), border = "gray40",
        xlab = "城市类型", ylab = "二手住宅同比价格指数",
        main = "二元自变量示例：一线城市与其他城市")
stripchart(second_hand_yoy ~ first_tier_city, data = df,
           vertical = TRUE, method = "jitter", pch = 16,
           col = adjustcolor("#1F78B4", alpha.f = 0.45), add = TRUE)
dev.off()

open_png("chapter05_dgp_tstat_histograms.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
hist(tstat_standard, breaks = 80, probability = TRUE,
     col = "#A6CEE3", border = "white",
     xlab = "t统计量", ylab = "密度",
     main = "DGP模拟：普通标准误")
curve(dt(x, df = n_mc - 2), add = TRUE, col = "#D95F0E", lwd = 2)
grid(col = "gray85")
hist(tstat_robust, breaks = 80, probability = TRUE,
     col = "#B2DF8A", border = "white",
     xlab = "t统计量", ylab = "密度",
     main = "DGP模拟：HC0稳健标准误")
curve(dt(x, df = n_mc - 2), add = TRUE, col = "#D95F0E", lwd = 2)
grid(col = "gray85")
dev.off()

writeLines(c(
  "第 5 章：一元线性回归模型",
  "",
  "数据：国家统计局 70 个大中城市商品住宅销售价格指数（2025 年月度）。",
  "连续自变量回归：二手住宅同比价格指数 ~ 新建商品住宅同比价格指数。",
  "二元自变量回归：二手住宅同比价格指数 ~ 是否一线城市。",
  sprintf("样本量：%d", n),
  sprintf("OLS斜率：%.4f；普通标准误：%.4f；90%%CI：[%.4f, %.4f]",
          beta_1_hat, se_beta_1_hat, lb, ub),
  sprintf("HC0稳健标准误：%.4f；90%%稳健CI：[%.4f, %.4f]",
          se_hc0[2], ci_hc0[2, 1], ci_hc0[2, 2]),
  sprintf("R2：%.4f", R2),
  sprintf("一线城市斜率：%.4f", coef(ols_model2)[2])
), con = file.path(result_dir, "chapter05_results_readme.txt"))

message("Chapter 05 complete. Outputs written to: ", chapter_dir)
