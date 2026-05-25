# Chapter 03: 基本概率论与统计推断
#
# 本章原本不依赖外部数据，而是使用掷骰子和 Monte Carlo 模拟说明
# 估计量、抽样分布、中心极限定理、假设检验和置信区间。
# 这里保留原章方法，并把图、表、结果正式保存到本章文件夹。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
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
      if (is.numeric(z)) sprintf("%.4f", z) else as.character(z)
    }, character(1))
    lines <- c(lines, paste(row, collapse = " & "), "\\\\")
  }
  lines <- c(lines, "\\hline", "\\end{tabular}", "\\end{table}")
  writeLines(lines, con = path)
}

set.seed(20260524)

# ------------------------------------------------------------------------------
# Box 01: R 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

n <- 50
dice_throws <- sample(1:6, n, replace = TRUE)
ybar <- mean(dice_throws)

# ------------------------------------------------------------------------------
# Box 02: R 中的 Monte Carlo 模拟
# ------------------------------------------------------------------------------

nr_samples <- 10000
n <- 50
ybar_dist <- rep(NA_real_, nr_samples)
for (i in 1:nr_samples) {
  dice_throws_i <- sample(1:6, n, replace = TRUE)
  ybar_dist[i] <- mean(dice_throws_i)
}

sim_summary <- data.frame(
  指标 = c("模拟次数", "每次样本量", "样本均值的模拟均值",
           "样本均值的模拟方差", "理论均值", "理论方差"),
  数值 = c(nr_samples, n, mean(ybar_dist), var(ybar_dist), 3.5, (35 / 12) / n)
)
write.csv(sim_summary,
          file.path(result_dir, "chapter03_monte_carlo_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(data.frame(模拟编号 = seq_along(ybar_dist), 样本均值 = ybar_dist),
          file.path(result_dir, "chapter03_dice_sample_mean_distribution.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 03: 直方图
# ------------------------------------------------------------------------------

open_png("chapter03_dice_sample_mean_histogram.png")
hist(ybar_dist, breaks = 50, probability = TRUE,
     col = "#A6CEE3", border = "white",
     xlab = "50次掷骰的样本均值",
     ylab = "密度",
     main = "样本均值的模拟抽样分布")
curve(dnorm(x, mean = 3.5, sd = sqrt((35 / 12) / n)),
      add = TRUE, col = "#D95F0E", lwd = 2)
legend("topright", legend = c("Monte Carlo直方图", "理论正态近似"),
       fill = c("#A6CEE3", NA), border = c("white", NA),
       lty = c(NA, 1), lwd = c(NA, 2), col = c(NA, "#D95F0E"), bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# 中心极限定理图：均匀分布与卡方分布
# ------------------------------------------------------------------------------

sample_sizes <- c(1, 2, 5, 10, 30, 100)
nr_clt <- 50000

plot_clt_grid <- function(dist_name, generator, mu, sigma2, filename, main_prefix, fill_col) {
  open_png(filename, width = 2200, height = 1500)
  par(mfrow = c(2, 3), family = cn_family, mar = c(4, 4, 3, 1) + 0.1)
  for (nn in sample_sizes) {
    vals <- replicate(nr_clt, mean(generator(nn)))
    hist_obj <- hist(vals, breaks = 60, plot = FALSE)
    curve_x <- seq(min(hist_obj$breaks), max(hist_obj$breaks), length.out = 300)
    curve_y <- dnorm(curve_x, mean = mu, sd = sqrt(sigma2 / nn))
    ymax <- max(hist_obj$density, curve_y) * 1.08
    plot(hist_obj, freq = FALSE, col = fill_col, border = "white", ylim = c(0, ymax),
         xlab = "样本均值", ylab = "密度",
         main = paste0(main_prefix, "，n=", nn))
    lines(curve_x, curve_y, col = "#D95F0E", lwd = 2)
    grid(col = "gray88")
  }
  dev.off()
}

plot_clt_grid(
  dist_name = "uniform",
  generator = function(nn) runif(nn, min = 0, max = 2),
  mu = 1,
  sigma2 = 1 / 3,
  filename = "chapter03_clt_uniform_distribution.png",
  main_prefix = "均匀分布样本均值",
  fill_col = "#B2DF8A"
)

plot_clt_grid(
  dist_name = "chi-square",
  generator = function(nn) rchisq(nn, df = 1),
  mu = 1,
  sigma2 = 2,
  filename = "chapter03_clt_chi_square_distribution.png",
  main_prefix = "卡方分布样本均值",
  fill_col = "#CAB2D6"
)

# ------------------------------------------------------------------------------
# Box 04--09: 使用 R 进行假设检验和构造置信区间
# ------------------------------------------------------------------------------

dice_throws <- c(rep(1, 13), rep(2, 7), rep(3, 8),
                 rep(4, 9), rep(5, 9), rep(6, 4))

n <- length(dice_throws)
mean_dice_throws <- mean(dice_throws)
var_dice_throws <- sum((dice_throws - mean_dice_throws)^2) / (n - 1)

se_dice_throws <- sqrt(var_dice_throws / n)
t_stat <- (mean_dice_throws - 3.5) / se_dice_throws

p_value <- 2 * (1 - pt(abs(t_stat), df = n - 1))

alpha <- 0.05
t_crit <- qt(1 - alpha / 2, n - 1)
ci_lower <- mean_dice_throws - t_crit * se_dice_throws
ci_upper <- mean_dice_throws + t_crit * se_dice_throws

t_test_result <- t.test(dice_throws, mu = 3.5)

dice_count_table <- data.frame(
  点数 = 1:6,
  出现次数 = as.integer(table(factor(dice_throws, levels = 1:6))),
  理论概率 = rep(1 / 6, 6)
)
write.csv(dice_count_table,
          file.path(table_dir, "chapter03_dice_count_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write_tex_table(dice_count_table,
                file.path(table_dir, "chapter03_dice_count_table.tex"),
                "50次掷骰结果的频数表",
                "tab:ch3-dice-count")

test_summary <- data.frame(
  指标 = c("样本量", "样本均值", "样本方差", "标准误", "t统计量",
           "p值", "95%置信区间下限", "95%置信区间上限"),
  数值 = c(n, mean_dice_throws, var_dice_throws, se_dice_throws, t_stat,
           p_value, ci_lower, ci_upper)
)
write.csv(test_summary,
          file.path(result_dir, "chapter03_t_test_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
capture.output(t_test_result,
               file = file.path(result_dir, "chapter03_t_test_R_output.txt"))

open_png("chapter03_dice_counts_and_confidence_interval.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
barplot(dice_count_table$出现次数, names.arg = dice_count_table$点数,
        col = "#A6CEE3", border = "white",
        xlab = "骰子点数", ylab = "出现次数",
        main = "50次掷骰的观测频数")
abline(h = n / 6, col = "#D95F0E", lwd = 2, lty = 2)
legend("topright", legend = "均衡骰子的期望频数", lwd = 2, lty = 2,
       col = "#D95F0E", bty = "n")
plot(1, mean_dice_throws, xlim = c(0.5, 1.5), ylim = c(2.5, 4.0),
     pch = 16, cex = 1.2, xaxt = "n",
     xlab = "", ylab = "均值", main = "样本均值的95%置信区间")
axis(1, at = 1, labels = "50次掷骰")
arrows(1, ci_lower, 1, ci_upper, angle = 90, code = 3, length = 0.08, lwd = 2)
abline(h = 3.5, col = "#D95F0E", lwd = 2, lty = 2)
legend("bottomright", legend = c("样本均值", "原假设均值3.5"),
       pch = c(16, NA), lty = c(NA, 2), lwd = c(NA, 2),
       col = c("black", "#D95F0E"), bty = "n")
grid(col = "gray88")
dev.off()

# ------------------------------------------------------------------------------
# 置信区间覆盖率模拟
# ------------------------------------------------------------------------------

coverage_B <- 5000
coverage_n <- 30
coverage_results <- replicate(coverage_B, {
  yy <- sample(1:6, coverage_n, replace = TRUE)
  yy_mean <- mean(yy)
  yy_se <- sd(yy) / sqrt(coverage_n)
  yy_tcrit <- qt(0.975, df = coverage_n - 1)
  lower <- yy_mean - yy_tcrit * yy_se
  upper <- yy_mean + yy_tcrit * yy_se
  c(lower = lower, upper = upper, cover = lower <= 3.5 && upper >= 3.5)
})
coverage_results <- as.data.frame(t(coverage_results))
coverage_results$simulation <- seq_len(nrow(coverage_results))
coverage_results$cover <- as.logical(coverage_results$cover)
coverage_rate <- mean(coverage_results$cover)

coverage_summary <- data.frame(
  指标 = c("重复抽样次数", "每次样本量", "名义覆盖率", "模拟覆盖率"),
  数值 = c(coverage_B, coverage_n, 0.95, coverage_rate)
)
write.csv(coverage_summary,
          file.path(result_dir, "chapter03_ci_coverage_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(coverage_results,
          file.path(result_dir, "chapter03_ci_coverage_intervals.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

plot_intervals <- coverage_results[1:80, ]
open_png("chapter03_ci_coverage_simulation.png", width = 2100, height = 1300)
plot(NA, xlim = c(2.2, 4.8), ylim = c(1, nrow(plot_intervals)),
     xlab = "置信区间端点", ylab = "模拟编号",
     main = "重复抽样中95%置信区间的覆盖情况")
for (i in seq_len(nrow(plot_intervals))) {
  col_i <- if (plot_intervals$cover[i]) "#2B8CBE" else "#D95F0E"
  segments(plot_intervals$lower[i], i, plot_intervals$upper[i], i,
           col = col_i, lwd = 2)
  points((plot_intervals$lower[i] + plot_intervals$upper[i]) / 2, i,
         pch = 16, cex = 0.5, col = col_i)
}
abline(v = 3.5, col = "black", lwd = 2, lty = 2)
legend("topright", legend = c("覆盖真实均值", "未覆盖真实均值", "真实均值3.5"),
       col = c("#2B8CBE", "#D95F0E", "black"), lwd = c(2, 2, 2),
       lty = c(1, 1, 2), bty = "n")
grid(col = "gray90")
dev.off()

writeLines(c(
  "第 3 章：基本概率论与统计推断",
  "",
  "本章使用模拟数据，不依赖外部数据源。",
  sprintf("Monte Carlo模拟次数：%d；每次样本量：%d", nr_samples, 50),
  sprintf("样本均值抽样分布的模拟均值：%.4f", sim_summary$数值[3]),
  sprintf("样本均值抽样分布的模拟方差：%.5f", sim_summary$数值[4]),
  sprintf("理论均值：%.4f；理论方差：%.5f", 3.5, (35 / 12) / 50),
  "",
  sprintf("50次掷骰样本均值：%.4f", mean_dice_throws),
  sprintf("t统计量：%.4f；p值：%.4f", t_stat, p_value),
  sprintf("95%%置信区间：[%.4f, %.4f]", ci_lower, ci_upper),
  "",
  sprintf("置信区间覆盖率模拟次数：%d；每次样本量：%d", coverage_B, coverage_n),
  sprintf("95%%置信区间的模拟覆盖率：%.4f", coverage_rate)
), con = file.path(result_dir, "chapter03_results_readme.txt"))

message("Chapter 03 complete. Outputs written to: ", chapter_dir)
