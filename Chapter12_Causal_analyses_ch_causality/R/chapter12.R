# Chapter 12: 因果分析
#
# 本章数据：NHTSA FARS 2018--2023 年 18--24 岁事故人员样本。
# 教学对应关系：
#   RD 教学例子        -> 21 岁法定饮酒年龄阈值
#   running variable rv  -> 年龄 - 21
#   treatment Z          -> 年龄是否达到 21 岁
#   outcome              -> 事故中是否报告酒精涉及
#
# 本脚本保留原章 RD 方法：构造运行变量、阈值指示变量、局部线性 RD、
# 阈值两侧斜率不同的交互项、HC0 稳健标准误，并给出带控制变量的稳健性版本。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
fars_path <- file.path(repo_dir, "data", "processed", "nhtsa_fars_rd_age18_24_2018_2023.csv")
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

set.seed(20260412)

potential <- data.frame(
  个体 = 1:8,
  未处理潜在结果 = c(4, 5, 5, 6, 7, 7, 8, 9),
  处理潜在结果 = c(5, 7, 5, 8, 8, 10, 9, 11),
  处理指示 = c(1, 0, 1, 0, 1, 0, 0, 1)
)
potential$个体处理效应 <- potential$处理潜在结果 - potential$未处理潜在结果
potential$观测结果 <- ifelse(potential$处理指示 == 1,
                         potential$处理潜在结果,
                         potential$未处理潜在结果)
write.csv(potential,
          file.path(table_dir, "chapter12_potential_outcomes_demo.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

all_assign <- combn(nrow(potential), sum(potential$处理指示))
sharp_outcomes <- potential$观测结果
rand_stats <- apply(all_assign, 2, function(idx) {
  z <- rep(0, nrow(potential))
  z[idx] <- 1
  mean(sharp_outcomes[z == 1]) - mean(sharp_outcomes[z == 0])
})
obs_stat <- mean(potential$观测结果[potential$处理指示 == 1]) -
  mean(potential$观测结果[potential$处理指示 == 0])
rand_table <- data.frame(
  分配编号 = seq_along(rand_stats),
  均值差 = rand_stats,
  是否至少同样极端 = as.integer(abs(rand_stats) >= abs(obs_stat))
)
write.csv(rand_table,
          file.path(table_dir, "chapter12_randomization_distribution.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

randomization_summary <- data.frame(
  指标 = c("个体数", "处理组人数", "观测均值差", "Fisher精确p值", "真实样本ATE"),
  数值 = c(nrow(potential), sum(potential$处理指示), obs_stat,
         mean(abs(rand_stats) >= abs(obs_stat)),
         mean(potential$个体处理效应))
)
write.csv(randomization_summary,
          file.path(table_dir, "chapter12_randomization_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter12_dag_confounding.png", width = 1500, height = 1000)
plot(0, 0, type = "n", axes = FALSE, xlab = "", ylab = "",
     xlim = c(0, 1), ylim = c(0, 1),
     main = "遗漏变量偏误的DAG")
points(c(0.18, 0.50, 0.82), c(0.72, 0.35, 0.72), pch = 21,
       bg = c("#FEE08B", "#ABD9E9", "#FDAE61"), cex = 9)
text(0.18, 0.72, "X\n混杂因素", cex = 1.15)
text(0.50, 0.35, "D\n处理", cex = 1.15)
text(0.82, 0.72, "Y\n结果", cex = 1.15)
arrows(0.25, 0.67, 0.43, 0.42, length = 0.12, lwd = 2, col = "#4D4D4D")
arrows(0.27, 0.74, 0.72, 0.74, length = 0.12, lwd = 2, col = "#4D4D4D")
arrows(0.57, 0.42, 0.75, 0.67, length = 0.12, lwd = 2, col = "#4D4D4D")
text(0.34, 0.50, "选择进入处理", cex = 0.95)
text(0.50, 0.80, "同时影响结果", cex = 0.95)
text(0.70, 0.50, "目标因果路径", cex = 0.95)
dev.off()

open_png("chapter12_randomization_distribution.png", width = 1500, height = 1100)
hist(rand_stats, breaks = seq(min(rand_stats) - 0.25, max(rand_stats) + 0.25, by = 0.5),
     col = "#BFD3E6", border = "white",
     xlab = "处理组与对照组均值差",
     main = "尖锐原假设下的随机化分布")
abline(v = obs_stat, col = "#D73027", lwd = 2.5)
abline(v = -obs_stat, col = "#D73027", lwd = 2.5, lty = 2)
legend("topright",
       legend = c(sprintf("观测均值差 = %.2f", obs_stat), "同样极端的反方向"),
       col = c("#D73027", "#D73027"), lwd = 2.5, lty = c(1, 2), bty = "n")
dev.off()

did_units <- 40
did_times <- -3:3
did_df <- expand.grid(unit = 1:did_units, period = did_times)
did_df$treated <- as.integer(did_df$unit > did_units / 2)
unit_fe <- rnorm(did_units, sd = 0.7)
did_df$unit_fe <- unit_fe[did_df$unit]
did_df$post <- as.integer(did_df$period >= 0)
did_df$common_trend <- 0.35 * did_df$period
did_df$tau <- 1.8 * did_df$treated * did_df$post
did_df$y <- 5 + did_df$unit_fe + did_df$common_trend + did_df$tau +
  rnorm(nrow(did_df), sd = 0.5)
did_cells <- aggregate(y ~ treated + period, data = did_df, FUN = mean)
write.csv(did_cells,
          file.path(table_dir, "chapter12_did_simulated_cell_means.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
did_model <- lm(y ~ treated + post + treated:post, data = did_df)
write.csv(coef_table(did_model, vcovHC(did_model, type = "HC0"), "模拟DID"),
          file.path(table_dir, "chapter12_did_simulated_regression.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter12_did_parallel_trends.png", width = 1600, height = 1100)
plot(did_cells$period[did_cells$treated == 0],
     did_cells$y[did_cells$treated == 0],
     type = "b", pch = 19, col = "#2166AC", lwd = 2.4,
     xlab = "相对政策期",
     ylab = "组均值",
     main = "DID的平行趋势与处理后差异",
     ylim = range(did_cells$y))
lines(did_cells$period[did_cells$treated == 1],
      did_cells$y[did_cells$treated == 1],
      type = "b", pch = 17, col = "#D73027", lwd = 2.4)
abline(v = -0.5, lty = 2, col = "gray40")
legend("topleft", legend = c("对照组", "处理组", "政策开始"),
       col = c("#2166AC", "#D73027", "gray40"),
       pch = c(19, 17, NA), lty = c(1, 1, 2), lwd = 2.4, bty = "n")
dev.off()

iv_n <- 800
z <- rbinom(iv_n, 1, 0.5)
u <- rnorm(iv_n)
d <- 0.7 * z + 0.9 * u + rnorm(iv_n)
y_iv <- 1 + 2.0 * d + u + rnorm(iv_n)
iv_df <- data.frame(y = y_iv, d = d, z = z, u = u)
iv_ols <- lm(y ~ d, data = iv_df)
iv_fs <- lm(d ~ z, data = iv_df)
iv_rf <- lm(y ~ z, data = iv_df)
iv_df$dhat <- fitted(iv_fs)
iv_2sls <- lm(y ~ dhat, data = iv_df)
fs_f <- summary(iv_fs)$fstatistic
iv_table <- rbind(
  data.frame(方程 = "OLS结构式", 关键变量 = "D", 估计值 = coef(iv_ols)["d"],
             标准误 = sqrt(diag(vcovHC(iv_ols, type = "HC0")))["d"]),
  data.frame(方程 = "第一阶段", 关键变量 = "Z", 估计值 = coef(iv_fs)["z"],
             标准误 = sqrt(diag(vcovHC(iv_fs, type = "HC0")))["z"]),
  data.frame(方程 = "简约式", 关键变量 = "Z", 估计值 = coef(iv_rf)["z"],
             标准误 = sqrt(diag(vcovHC(iv_rf, type = "HC0")))["z"]),
  data.frame(方程 = "2SLS第二阶段", 关键变量 = "Dhat", 估计值 = coef(iv_2sls)["dhat"],
             标准误 = sqrt(diag(vcovHC(iv_2sls, type = "HC0")))["dhat"])
)
write.csv(iv_table,
          file.path(table_dir, "chapter12_iv_simulated_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(data.frame(指标 = c("第一阶段F统计量", "真实处理效应"),
                     数值 = c(unname(fs_f["value"]), 2.0)),
          file.path(table_dir, "chapter12_iv_simulated_diagnostics.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

df <- read.csv(fars_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(df) <- gsub("^\ufeff", "", names(df))
df <- df[df$age >= 18 & df$age <= 24, ]
df <- df[df$drinking %in% c(0, 1), ]
df$alcohol_involved <- ifelse(df$drinking == 1, 1, 0)
df$rv <- df$age - 21
df$Z <- ifelse(df$rv >= 0, 1, 0)
df$Zrv <- df$Z * df$rv
df$male <- ifelse(df$sex == 1, 1, 0)
df$fatal_injury <- ifelse(df$inj_sev == 4, 1, 0)

h <- 3
df_h <- df[abs(df$rv) <= h, ]
write.csv(df_h[, c("year", "state", "statename", "age", "rv", "Z",
                   "alcohol_involved", "male", "fatal_injury")],
          file.path(result_dir, "chapter12_fars_rd_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

rd_rf <- lm(alcohol_involved ~ Z + rv + Zrv, data = df_h)
df_h$Dhat <- df_h$Z
rd_2sls_naive <- lm(alcohol_involved ~ Dhat + rv + Zrv, data = df_h)
rd_controls <- lm(alcohol_involved ~ Z + rv + Zrv + male + fatal_injury +
                    factor(year), data = df_h)

rd_bw_rows <- data.frame()
for (bw in c(2, 3, 4)) {
  df_bw <- df[abs(df$rv) <= bw, ]
  mod_bw <- lm(alcohol_involved ~ Z + rv + Zrv, data = df_bw)
  se_bw <- sqrt(diag(vcovHC(mod_bw, type = "HC0")))["Z"]
  rd_bw_rows <- rbind(
    rd_bw_rows,
    data.frame(带宽 = bw, 样本量 = nrow(df_bw),
               左侧样本量 = sum(df_bw$rv < 0), 右侧样本量 = sum(df_bw$rv >= 0),
               跳跃估计 = coef(mod_bw)["Z"], HC0标准误 = se_bw)
  )
}
write.csv(rd_bw_rows,
          file.path(table_dir, "chapter12_fars_rd_bandwidth_sensitivity.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

rd_tables <- rbind(
  coef_table(rd_rf, vcovHC(rd_rf, type = "HC0"), "局部线性RD"),
  coef_table(rd_2sls_naive, vcovHC(rd_2sls_naive, type = "HC0"),
             "sharp RD的2SLS等价写法"),
  coef_table(rd_controls, vcovHC(rd_controls, type = "HC0"),
             "加入性别、伤害严重程度和年份控制")
)
write.csv(rd_tables,
          file.path(table_dir, "chapter12_fars_rd_hc0_tables.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

age_bins <- aggregate(alcohol_involved ~ age, data = df_h, FUN = mean)
names(age_bins) <- c("年龄", "酒精涉及比例")
write.csv(age_bins,
          file.path(table_dir, "chapter12_fars_rd_age_bins.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

grid_left <- data.frame(rv = seq(min(df_h$rv), -0.001, length.out = 100))
grid_left$Z <- 0
grid_left$Zrv <- 0
grid_left$pred <- predict(rd_rf, newdata = grid_left)
grid_right <- data.frame(rv = seq(0, max(df_h$rv), length.out = 100))
grid_right$Z <- 1
grid_right$Zrv <- grid_right$rv
grid_right$pred <- predict(rd_rf, newdata = grid_right)

open_png("chapter12_fars_rd_age21.png")
plot(age_bins$年龄, age_bins$酒精涉及比例,
     pch = 19, col = "#C0392B",
     xlab = "年龄",
     ylab = "酒精涉及比例",
     main = "21岁法定饮酒年龄附近的断点回归示例",
     ylim = range(c(age_bins$酒精涉及比例, grid_left$pred, grid_right$pred)))
lines(grid_left$rv + 21, grid_left$pred, col = "#2166AC", lwd = 2.5)
lines(grid_right$rv + 21, grid_right$pred, col = "#2166AC", lwd = 2.5)
abline(v = 21, lty = 2, col = "gray40")
legend("topleft", legend = c("年龄均值", "局部线性拟合", "21岁阈值"),
       pch = c(19, NA, NA), lty = c(NA, 1, 2),
       col = c("#C0392B", "#2166AC", "gray40"), bty = "n")
dev.off()

open_png("chapter12_fars_rd_balance.png")
balance <- aggregate(cbind(male, fatal_injury) ~ age, data = df_h, FUN = mean)
plot(balance$age, balance$male, type = "b", pch = 19,
     col = "#2166AC", lwd = 2,
     ylim = range(balance[, c("male", "fatal_injury")]),
     xlab = "年龄",
     ylab = "比例",
     main = "阈值附近协变量均衡性示意")
lines(balance$age, balance$fatal_injury, type = "b", pch = 17,
      col = "#D73027", lwd = 2)
abline(v = 21, lty = 2, col = "gray40")
legend("topright", legend = c("男性比例", "致命伤比例"),
       col = c("#2166AC", "#D73027"), pch = c(19, 17), lwd = 2, bty = "n")
dev.off()

open_png("chapter12_fars_rd_density.png", width = 1500, height = 1100)
age_counts <- as.data.frame(table(df_h$age))
names(age_counts) <- c("age", "count")
age_counts$age <- as.numeric(as.character(age_counts$age))
barplot(age_counts$count, names.arg = age_counts$age,
        col = "#BFD3E6", border = "white",
        xlab = "年龄", ylab = "样本人数",
        main = "21岁阈值附近的样本分布")
abline(v = which(age_counts$age == 21) - 0.5, col = "#D73027", lwd = 2, lty = 2)
dev.off()

summary_table <- data.frame(
  指标 = c("样本量", "带宽h", "阈值左侧样本量", "阈值右侧样本量",
         "21岁RD跳跃估计", "HC0标准误", "加入控制后的跳跃估计"),
  数值 = c(nrow(df_h), h, sum(df_h$rv < 0), sum(df_h$rv >= 0),
         coef(rd_rf)["Z"], sqrt(diag(vcovHC(rd_rf, type = "HC0")))["Z"],
         coef(rd_controls)["Z"])
)
write.csv(summary_table,
          file.path(result_dir, "chapter12_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 12 finished.\n")
cat("Sample size:", nrow(df_h), "\n")
cat("RD jump:", round(coef(rd_rf)["Z"], 4), "\n")
