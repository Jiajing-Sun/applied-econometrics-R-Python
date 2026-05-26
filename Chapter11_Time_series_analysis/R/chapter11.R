# Chapter 11: 时间序列分析
#
# 本章数据：World Bank WDI 中国年度宏观数据。
# 教学对应关系：
#   教材变量 Sweden quarterly GDP -> 中国实际 GDP 年度序列（2015年不变美元）
#
# 本脚本保留原章方法：时间序列图、中心移动平均、自相关函数、
# 对数增长率、AR(1)、Newey-West/HAC 标准误和 AR 阶数选择。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
wdi_path <- file.path(repo_dir, "data", "processed", "wdi_china_macro_1960_2024.csv")
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

coef_table <- function(model, vcov_mat, label) {
  est <- coef(model)
  se <- sqrt(diag(vcov_mat))
  tval <- est / se
  pval <- 2 * (1 - pt(abs(tval), df = df.residual(model)))
  data.frame(
    模型 = label,
    项 = names(est),
    估计值 = as.numeric(est),
    标准误 = as.numeric(se),
    t统计量 = as.numeric(tval),
    p值 = as.numeric(pval),
    row.names = NULL
  )
}

library(sandwich)

df <- read.csv(wdi_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(df) <- gsub("^\ufeff", "", names(df))
df <- df[complete.cases(df[, c("year", "gdp_constant_2015_usd")]), ]
df <- df[df$year >= 1978 & df$gdp_constant_2015_usd > 0, ]
df <- df[order(df$year), ]
row.names(df) <- NULL

gdp_ts <- ts(df$gdp_constant_2015_usd / 1e12,
             frequency = 1, start = min(df$year))
years <- df$year

gdpL1 <- c(NA, head(df$gdp_constant_2015_usd, -1))
gdpL2 <- c(NA, NA, head(df$gdp_constant_2015_usd, -2))
gdpF1 <- c(tail(df$gdp_constant_2015_usd, -1), NA)
gdpF2 <- c(tail(df$gdp_constant_2015_usd, -2), NA, NA)
ma <- (gdpL2 / 2 + gdpL1 + df$gdp_constant_2015_usd + gdpF1 + gdpF2 / 2) / 4

mean_gdp <- mean(df$gdp_constant_2015_usd)
r_1 <- sum((df$gdp_constant_2015_usd[-1] - mean_gdp) *
             (gdpL1[-1] - mean_gdp)) /
  sum((df$gdp_constant_2015_usd - mean_gdp)^2)

dloggdp <- c(NA, diff(log(df$gdp_constant_2015_usd)) * 100)
dlogma <- c(NA, diff(log(ma)) * 100)
dloggdpL1 <- c(NA, head(dloggdp, -1))
dlogmaL1 <- c(NA, head(dlogma, -1))
loggdp <- log(df$gdp_constant_2015_usd)

dft <- data.frame(
  year = years,
  gdp = df$gdp_constant_2015_usd,
  gdp_trillion = df$gdp_constant_2015_usd / 1e12,
  ma = ma / 1e12,
  dloggdp = dloggdp,
  dlogma = dlogma,
  dloggdpL1 = dloggdpL1,
  dlogmaL1 = dlogmaL1
)
write.csv(dft,
          file.path(result_dir, "chapter11_china_gdp_time_series_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_china_gdp_level.png")
plot(years, df$gdp_constant_2015_usd / 1e12, type = "l",
     col = "#2166AC", lwd = 2.5,
     xlab = "年份",
     ylab = "实际GDP（万亿美元，2015年不变价）",
     main = "中国实际GDP年度序列")
dev.off()

open_png("chapter11_china_gdp_moving_average.png")
plot(years, df$gdp_constant_2015_usd / 1e12, type = "l",
     col = rgb(0.4, 0.4, 0.4, 0.5), lwd = 2,
     xlab = "年份",
     ylab = "实际GDP（万亿美元，2015年不变价）",
     main = "中心移动平均")
lines(years, ma / 1e12, col = "#D73027", lwd = 2.5)
legend("topleft", legend = c("原始序列", "中心移动平均"),
       col = c("gray50", "#D73027"), lwd = 2.5, bty = "n")
dev.off()

open_png("chapter11_china_gdp_growth.png")
plot(years, dloggdp, type = "l", col = "#2166AC", lwd = 2.5,
     xlab = "年份",
     ylab = "对数增长率（%）",
     main = "中国实际GDP对数增长率")
lines(years, dlogma, col = "#D73027", lwd = 2)
legend("topright", legend = c("GDP增长率", "移动平均增长率"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, bty = "n")
dev.off()

open_png("chapter11_level_growth_logdiff_panel.png", width = 1800, height = 1500)
par(mfrow = c(2, 1), family = cn_family, mar = c(4.2, 5, 2.5, 1) + 0.1)
plot(years, loggdp, type = "l", col = "#2166AC", lwd = 2.4,
     xlab = "年份", ylab = "log(GDP)",
     main = "水平取对数后仍有明显趋势")
plot(years, dloggdp, type = "l", col = "#D73027", lwd = 2.4,
     xlab = "年份", ylab = "对数差分（%）",
     main = "对数差分后更接近平稳增长率")
abline(h = mean(dloggdp, na.rm = TRUE), lty = 2, col = "gray35")
dev.off()

acf_level_vals <- acf(df$gdp_constant_2015_usd, plot = FALSE, lag.max = 15)
acf_level_table <- data.frame(
  滞后阶数 = as.integer(acf_level_vals$lag),
  自相关 = as.numeric(acf_level_vals$acf)
)
write.csv(acf_level_table,
          file.path(table_dir, "chapter11_china_gdp_level_acf.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

growth <- na.omit(dloggdp)
acf_growth_vals <- acf(growth, plot = FALSE, lag.max = 15)
acf_growth_table <- data.frame(
  滞后阶数 = as.integer(acf_growth_vals$lag),
  自相关 = as.numeric(acf_growth_vals$acf)
)
write.csv(acf_growth_table,
          file.path(table_dir, "chapter11_china_gdp_acf.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_china_gdp_acf.png")
acf(growth, lag.max = 15,
    main = "中国实际GDP增长率的自相关函数",
    xlab = "滞后阶数",
    ylab = "自相关")
dev.off()

pacf_growth_vals <- pacf(growth, plot = FALSE, lag.max = 15)
pacf_growth_table <- data.frame(
  滞后阶数 = as.integer(pacf_growth_vals$lag),
  偏自相关 = as.numeric(pacf_growth_vals$acf)
)
write.csv(pacf_growth_table,
          file.path(table_dir, "chapter11_china_gdp_pacf.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_china_gdp_pacf.png")
pacf(growth, lag.max = 15,
     main = "中国实际GDP增长率的偏自相关函数",
     xlab = "滞后阶数",
     ylab = "偏自相关")
dev.off()

reg_df <- dft[complete.cases(dft[, c("dloggdp", "dloggdpL1")]), ]
ar1_model <- lm(dloggdp ~ dloggdpL1, data = reg_df)
nw_vcov <- NeweyWest(ar1_model, lag = 5, prewhite = FALSE)
ar1_table <- coef_table(ar1_model, vcov(ar1_model), "普通OLS")
ar1_nw_table <- coef_table(ar1_model, nw_vcov, "Newey-West HAC")
write.csv(rbind(ar1_table, ar1_nw_table),
          file.path(table_dir, "chapter11_ar1_hac_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

ar1_model_alt <- ar.ols(na.omit(dloggdp), order.max = 1,
                        aic = FALSE, demean = FALSE, intercept = TRUE)
ar5_model <- ar.ols(na.omit(dloggdp), order.max = 5,
                    aic = TRUE, demean = FALSE, intercept = TRUE)

ar_aic_rows <- data.frame()
y <- as.numeric(na.omit(dloggdp))
for (p in 1:5) {
  lagged <- embed(y, p + 1)
  y_ar <- lagged[, 1]
  X_ar <- lagged[, -1, drop = FALSE]
  model_p <- lm(y_ar ~ X_ar)
  n_p <- length(y_ar)
  sigma2 <- mean(residuals(model_p)^2)
  aic <- n_p * log(sigma2) + 2 * (p + 1)
  ar_aic_rows <- rbind(ar_aic_rows,
                       data.frame(阶数 = p, AIC = aic,
                                  RSS = sum(residuals(model_p)^2)))
}
write.csv(ar_aic_rows,
          file.path(table_dir, "chapter11_ar_order_aic.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_ar_order_aic_curve.png")
plot(ar_aic_rows$阶数, ar_aic_rows$AIC, type = "b", pch = 19,
     col = "#2166AC", lwd = 2.5,
     xlab = "AR阶数",
     ylab = "AIC",
     main = "AR阶数选择：AIC越小越好")
abline(v = ar_aic_rows$阶数[which.min(ar_aic_rows$AIC)],
       col = "#D73027", lty = 2, lwd = 2)
dev.off()

reg_df$fitted_ar1 <- fitted(ar1_model)
open_png("chapter11_ar1_actual_fitted.png")
plot(reg_df$year, reg_df$dloggdp, type = "l",
     col = "#2166AC", lwd = 2.5,
     xlab = "年份",
     ylab = "GDP对数增长率（%）",
     main = "AR(1)模型：实际值与拟合值")
lines(reg_df$year, reg_df$fitted_ar1, col = "#D73027", lwd = 2)
legend("topright", legend = c("实际增长率", "AR(1)拟合值"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, bty = "n")
dev.off()

se_compare <- data.frame(
  标准误类型 = c("普通OLS", "Newey-West HAC"),
  滞后项标准误 = c(
    sqrt(diag(vcov(ar1_model)))["dloggdpL1"],
    sqrt(diag(nw_vcov))["dloggdpL1"]
  )
)
write.csv(se_compare,
          file.path(table_dir, "chapter11_se_comparison.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_se_comparison.png", width = 1500, height = 1100)
bp <- barplot(se_compare$滞后项标准误,
              names.arg = se_compare$标准误类型,
              col = c("#9ECAE1", "#FCAE91"),
              ylab = "AR(1)滞后项标准误",
              main = "普通标准误与HAC标准误的比较")
text(x = bp, y = se_compare$滞后项标准误,
     labels = sprintf("%.3f", se_compare$滞后项标准误),
     pos = 3)
dev.off()

last_year <- max(reg_df$year)
last_gdp <- df$gdp_constant_2015_usd[df$year == last_year]
last_growth <- reg_df$dloggdp[reg_df$year == last_year]
forecast_growth <- as.numeric(coef(ar1_model)[1] + coef(ar1_model)[2] * last_growth)
resid_sd_pct <- sqrt(mean(residuals(ar1_model)^2))
forecast_log_naive <- log(last_gdp) + forecast_growth / 100
forecast_log_corrected <- forecast_log_naive + 0.5 * (resid_sd_pct / 100)^2
forecast_level_naive <- exp(forecast_log_naive)
forecast_level_corrected <- exp(forecast_log_corrected)
forecast_lower <- exp(forecast_log_naive - 1.96 * resid_sd_pct / 100)
forecast_upper <- exp(forecast_log_naive + 1.96 * resid_sd_pct / 100)
forecast_table <- data.frame(
  项 = c("最后观测年份", "最后观测GDP（万亿美元）", "最后观测增长率（%）",
       "预测年份", "预测增长率（%）", "朴素水平预测（万亿美元）",
       "Jensen修正水平预测（万亿美元）", "95%预测区间下限（万亿美元）",
       "95%预测区间上限（万亿美元）"),
  数值 = c(last_year, last_gdp / 1e12, last_growth,
         last_year + 1, forecast_growth, forecast_level_naive / 1e12,
         forecast_level_corrected / 1e12, forecast_lower / 1e12,
         forecast_upper / 1e12)
)
write.csv(forecast_table,
          file.path(table_dir, "chapter11_forecast_backtransform.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter11_forecast_backtransform.png")
hist_gdp_trillion <- df$gdp_constant_2015_usd / 1e12
forecast_y_trillion <- c(forecast_lower, forecast_level_naive, forecast_upper) / 1e12
y_lim <- range(c(hist_gdp_trillion, forecast_y_trillion), finite = TRUE)
y_pad <- diff(y_lim) * 0.08
x_lim <- range(c(years, last_year + 1), finite = TRUE)
x_pad <- max(1, diff(x_lim) * 0.04)
plot(years, hist_gdp_trillion, type = "l",
     col = "#2166AC", lwd = 2.5,
     xlim = c(x_lim[1], x_lim[2] + x_pad),
     ylim = c(max(0, y_lim[1] - y_pad), y_lim[2] + y_pad),
     xlab = "年份",
     ylab = "实际GDP（万亿美元，2015年不变价）",
     main = "从增长率预测回到GDP水平")
points(last_year + 1, forecast_level_naive / 1e12, pch = 19,
       col = "#D73027", cex = 1.4)
arrows(last_year + 1, forecast_lower / 1e12,
       last_year + 1, forecast_upper / 1e12,
       angle = 90, code = 3, length = 0.08, col = "#D73027", lwd = 2)
legend("topleft", legend = c("历史GDP", "一步预测与区间"),
       col = c("#2166AC", "#D73027"), lwd = 2.5,
       pch = c(NA, 19), bty = "n")
dev.off()

df_unit <- data.frame(
  dlog_level = diff(loggdp),
  lag_log_level = head(loggdp, -1),
  trend = seq_len(length(loggdp) - 1)
)
df_unit$lag_dlog_level <- c(NA, head(df_unit$dlog_level, -1))
df_unit <- df_unit[complete.cases(df_unit), ]
df_test <- lm(dlog_level ~ lag_log_level + lag_dlog_level + trend, data = df_unit)
unit_root_table <- data.frame(
  项 = names(coef(df_test)),
  估计值 = as.numeric(coef(df_test)),
  标准误 = sqrt(diag(vcov(df_test))),
  t统计量 = as.numeric(coef(df_test) / sqrt(diag(vcov(df_test))))
)
write.csv(unit_root_table,
          file.path(table_dir, "chapter11_unit_root_illustration.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

summary_table <- data.frame(
  指标 = c("起始年份", "结束年份", "样本量", "GDP水平一阶自相关",
         "GDP增长率一阶自相关", "AR1滞后项系数", "AR1滞后项HAC标准误",
         "AIC选择阶数", "一步预测增长率", "一步预测GDP万亿美元"),
  数值 = c(min(years), max(years), length(years), r_1,
         acf_growth_table$自相关[acf_growth_table$滞后阶数 == 1],
         coef(ar1_model)["dloggdpL1"],
         sqrt(diag(nw_vcov))["dloggdpL1"],
         ar_aic_rows$阶数[which.min(ar_aic_rows$AIC)],
         forecast_growth,
         forecast_level_naive / 1e12)
)
write.csv(summary_table,
          file.path(result_dir, "chapter11_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 11 finished.\n")
cat("Years:", min(years), "-", max(years), "\n")
cat("Lag-1 autocorrelation:", round(r_1, 4), "\n")
cat("AR(1) coefficient:", round(coef(ar1_model)[2], 4), "\n")
