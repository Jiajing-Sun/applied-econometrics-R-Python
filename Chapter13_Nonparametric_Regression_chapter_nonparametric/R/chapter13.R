# Chapter 13: 非参数回归方法
#
# 本章数据：World Bank WDI 全球宏观指标 + Our World in Data 全球年度 CO2。
# 教学主题：不预设线性或二次函数，使用核回归和局部线性回归刻画
# log(人均GDP) 与人均CO2排放之间的平滑关系。
#
# 本脚本实现 Nadaraya-Watson 核回归、局部线性回归、带宽比较、
# 留一交叉验证选择带宽和 bootstrap 点态置信带。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
wdi_path <- file.path(repo_dir, "data", "processed", "wdi_global_selected_indicators_wide.csv")
owid_path <- file.path(repo_dir, "data", "processed", "owid_global_annual_co2.csv")
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

gaussian_kernel <- function(u) exp(-0.5 * u^2) / sqrt(2 * pi)

nw_predict <- function(x, y, grid, h) {
  sapply(grid, function(x0) {
    w <- gaussian_kernel((x - x0) / h)
    sum(w * y) / sum(w)
  })
}

local_linear_predict <- function(x, y, grid, h) {
  sapply(grid, function(x0) {
    z <- x - x0
    w <- gaussian_kernel(z / h)
    X <- cbind(1, z)
    beta <- solve(t(X) %*% (X * w), t(X) %*% (w * y))
    beta[1]
  })
}

loocv_nw <- function(x, y, h) {
  pred <- rep(NA_real_, length(y))
  for (i in seq_along(y)) {
    pred[i] <- nw_predict(x[-i], y[-i], x[i], h)
  }
  mean((y - pred)^2)
}

wdi <- read.csv(wdi_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
owid <- read.csv(owid_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(wdi) <- gsub("^\ufeff", "", names(wdi))
names(owid) <- gsub("^\ufeff", "", names(owid))

df_all <- merge(wdi, owid,
                by.x = c("country_code", "year"),
                by.y = c("Code", "Year"))
co2_col <- grep("^Annual", names(df_all), value = TRUE)[1]
df_all$annual_co2_emissions <- df_all[[co2_col]]
df_all$co2_pc_tonnes <- df_all$annual_co2_emissions / df_all$population
df_all$log_gdp_pc <- log(df_all$gdp_per_capita_constant_2015_usd)

usable <- df_all[
  complete.cases(df_all[, c("gdp_per_capita_constant_2015_usd", "population",
                            "annual_co2_emissions", "co2_pc_tonnes",
                            "log_gdp_pc")]) &
    df_all$gdp_per_capita_constant_2015_usd > 0 &
    df_all$population > 0 &
    df_all$annual_co2_emissions > 0 &
    df_all$co2_pc_tonnes > 0,
]
year_counts <- aggregate(country_code ~ year, data = usable, FUN = length)
analysis_year <- max(year_counts$year[year_counts$country_code >= 150])
df <- usable[usable$year == analysis_year, ]
df <- df[order(df$log_gdp_pc), ]
row.names(df) <- NULL

x <- df$log_gdp_pc
y <- df$co2_pc_tonnes
grid <- seq(quantile(x, 0.02), quantile(x, 0.98), length.out = 180)
h_values <- c(0.25, 0.45, 0.75)
names(h_values) <- c("小带宽", "中带宽", "大带宽")
co2_ylim <- c(0, 20)

write.csv(df[, c("country", "country_code", "year",
                 "gdp_per_capita_constant_2015_usd", "log_gdp_pc",
                 "population", "co2_pc_tonnes")],
          file.path(result_dir, "chapter13_nonparametric_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# 回归直方图：把局部平均作为非参数回归的入口
# ------------------------------------------------------------------------------

bin_breaks <- seq(min(x), max(x), length.out = 9)
bin_id <- cut(x, breaks = bin_breaks, include.lowest = TRUE, labels = FALSE)
hist_table <- aggregate(cbind(log_gdp_pc = x, co2_pc_tonnes = y),
                        by = list(组 = bin_id), FUN = mean)
hist_table$样本量 <- as.integer(table(bin_id)[as.character(hist_table$组)])
hist_table$左端点 <- bin_breaks[hist_table$组]
hist_table$右端点 <- bin_breaks[hist_table$组 + 1]
write.csv(hist_table,
          file.path(table_dir, "chapter13_regression_histogram_bins.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter13_regression_histogram.png")
plot(x, y, pch = 16, col = rgb(0.35, 0.35, 0.35, 0.25),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     ylim = co2_ylim,
     main = "回归直方图：分箱局部平均")
for (i in seq_len(nrow(hist_table))) {
  segments(hist_table$左端点[i], hist_table$co2_pc_tonnes[i],
           hist_table$右端点[i], hist_table$co2_pc_tonnes[i],
           col = "#D73027", lwd = 4)
  points(hist_table$log_gdp_pc[i], hist_table$co2_pc_tonnes[i],
         pch = 19, col = "#2166AC")
}
legend("topleft", legend = c("国家观测", "分箱均值"),
       col = c(rgb(0.35, 0.35, 0.35, 0.6), "#D73027"),
       pch = c(16, NA), lty = c(NA, 1), lwd = c(NA, 4), bty = "n")
dev.off()

nw_curves <- data.frame(log_gdp_pc = grid)
for (nm in names(h_values)) {
  nw_curves[[nm]] <- nw_predict(x, y, grid, h_values[[nm]])
}
write.csv(nw_curves,
          file.path(result_dir, "chapter13_nw_bandwidth_curves.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter13_nw_bandwidth_comparison.png")
plot(x, y, pch = 16, col = rgb(0.35, 0.35, 0.35, 0.3),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     ylim = co2_ylim,
     main = "Nadaraya-Watson 核回归：带宽比较")
cols <- c("#2166AC", "#D73027", "#1B7837")
for (i in seq_along(h_values)) {
  lines(grid, nw_curves[[i + 1]], col = cols[i], lwd = 2.5)
}
legend("topleft", legend = paste0(names(h_values), " h=", h_values),
       col = cols, lwd = 2.5, bty = "n")
dev.off()

h_grid <- seq(0.18, 1.1, length.out = 25)
cv_mse <- sapply(h_grid, function(h) loocv_nw(x, y, h))
cv_table <- data.frame(带宽 = h_grid, LOOCV_MSE = cv_mse)
write.csv(cv_table,
          file.path(table_dir, "chapter13_bandwidth_loocv.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
best_h <- h_grid[which.min(cv_mse)]

open_png("chapter13_bandwidth_cv_curve.png")
cv_y <- range(cv_mse, finite = TRUE)
cv_y_pad <- diff(cv_y) * 0.18
plot(h_grid, cv_mse, type = "b", pch = 19, col = "#2166AC", lwd = 2,
     xlab = "带宽 h",
     ylab = "留一交叉验证 MSE",
     main = "带宽选择：留一交叉验证",
     ylim = c(cv_y[1] - cv_y_pad * 0.15, cv_y[2] + cv_y_pad))
abline(v = best_h, col = "#D73027", lty = 2, lwd = 2)
legend("topright", legend = paste0("最优带宽 h=", round(best_h, 3)),
       col = "#D73027", lty = 2, lwd = 2, bty = "n")
dev.off()

nw_best <- nw_predict(x, y, grid, best_h)
ll_best <- local_linear_predict(x, y, grid, best_h)
poly_model <- lm(y ~ x + I(x^2) + I(x^3))
poly_pred <- predict(poly_model, newdata = data.frame(x = grid))
smooth_table <- data.frame(
  log_gdp_pc = grid,
  NW最优带宽 = nw_best,
  局部线性 = ll_best,
  三阶多项式 = poly_pred
)
write.csv(smooth_table,
          file.path(result_dir, "chapter13_smooth_curves.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter13_local_linear_vs_polynomial.png")
plot(x, y, pch = 16, col = rgb(0.35, 0.35, 0.35, 0.3),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     ylim = co2_ylim,
     main = "局部线性平滑与三阶多项式比较")
lines(grid, ll_best, col = "#2166AC", lwd = 2.5)
lines(grid, poly_pred, col = "#D73027", lwd = 2.5, lty = 2)
legend("topleft", legend = c("局部线性", "三阶多项式"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, lty = c(1, 2), bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# 边界偏误模拟：NW 与局部线性在边界处的差异
# ------------------------------------------------------------------------------

set.seed(20260525)
x_sim <- sort(runif(180))
y_true <- 1 + 2 * x_sim
y_sim <- y_true + rnorm(length(x_sim), sd = 0.25)
grid_sim <- seq(0, 1, length.out = 160)
h_boundary <- 0.14
nw_boundary <- nw_predict(x_sim, y_sim, grid_sim, h_boundary)
ll_boundary <- local_linear_predict(x_sim, y_sim, grid_sim, h_boundary)
boundary_table <- data.frame(
  x = grid_sim,
  真实条件均值 = 1 + 2 * grid_sim,
  NW核回归 = nw_boundary,
  局部线性 = ll_boundary
)
write.csv(boundary_table,
          file.path(table_dir, "chapter13_boundary_bias_demo.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter13_boundary_bias_demo.png")
plot(x_sim, y_sim, pch = 16, col = rgb(0.35, 0.35, 0.35, 0.3),
     xlab = "X",
     ylab = "Y",
     main = "边界偏误：核平均与局部线性")
lines(grid_sim, 1 + 2 * grid_sim, col = "black", lwd = 2)
lines(grid_sim, nw_boundary, col = "#D73027", lwd = 2.5, lty = 2)
lines(grid_sim, ll_boundary, col = "#2166AC", lwd = 2.5)
legend("topleft", legend = c("真实条件均值", "NW核回归", "局部线性"),
       col = c("black", "#D73027", "#2166AC"), lwd = 2.5,
       lty = c(1, 2, 1), bty = "n")
dev.off()

set.seed(20260524)
B <- 200
boot_mat <- matrix(NA_real_, nrow = length(grid), ncol = B)
for (b in 1:B) {
  idx <- sample(seq_along(y), replace = TRUE)
  boot_mat[, b] <- local_linear_predict(x[idx], y[idx], grid, best_h)
}
ci_low <- apply(boot_mat, 1, quantile, probs = 0.025, na.rm = TRUE)
ci_high <- apply(boot_mat, 1, quantile, probs = 0.975, na.rm = TRUE)
ci_table <- data.frame(log_gdp_pc = grid, 局部线性 = ll_best,
                       CI下限 = ci_low, CI上限 = ci_high)
write.csv(ci_table,
          file.path(result_dir, "chapter13_local_linear_bootstrap_ci.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter13_local_linear_bootstrap_ci.png")
plot(x, y, pch = 16, col = rgb(0.35, 0.35, 0.35, 0.25),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     ylim = co2_ylim,
     main = "局部线性平滑与 bootstrap 点态置信带")
polygon(c(grid, rev(grid)), c(ci_low, rev(ci_high)),
        col = rgb(0.13, 0.40, 0.67, 0.18), border = NA)
lines(grid, ll_best, col = "#2166AC", lwd = 2.5)
dev.off()

summary_table <- data.frame(
  指标 = c("分析年份", "样本量", "最优带宽", "最小LOOCV_MSE",
         "bootstrap次数", "局部线性曲线均值"),
  数值 = c(analysis_year, length(y), best_h, min(cv_mse), B, mean(ll_best))
)
write.csv(summary_table,
          file.path(result_dir, "chapter13_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 13 finished.\n")
cat("Analysis year:", analysis_year, "\n")
cat("Sample size:", length(y), "\n")
cat("Best bandwidth:", round(best_h, 4), "\n")
