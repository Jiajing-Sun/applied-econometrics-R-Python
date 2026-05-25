# Chapter 04: 关于总体相关的推断
#
# 本章数据：World Bank WDI 全球国家/地区年度数据。
# 教学对应关系：
#   教材变量 living_area -> log(人均GDP，2015年不变美元)
#   教材变量 price       -> 预期寿命
#
# 本脚本保留原章方法：Pearson 相关、Fisher Z 变换、相关的置信区间、
# 以及相关为零的 t 检验。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
data_path <- file.path(repo_dir, "data", "processed", "wdi_global_selected_indicators_wide.csv")
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

wdi <- read.csv(data_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)

complete_counts <- aggregate(
  complete_cases ~ year,
  data = transform(
    wdi,
    complete_cases = !is.na(gdp_per_capita_constant_2015_usd) &
      !is.na(life_expectancy) &
      gdp_per_capita_constant_2015_usd > 0
  ),
  FUN = sum
)
analysis_year <- max(complete_counts$year[complete_counts$complete_cases >= 200])

df <- wdi[wdi$year == analysis_year,
          c("country", "country_code", "year",
            "gdp_per_capita_constant_2015_usd", "life_expectancy")]
df <- df[complete.cases(df) & df$gdp_per_capita_constant_2015_usd > 0, ]
df$log_gdp_per_capita <- log(df$gdp_per_capita_constant_2015_usd)
df <- df[order(df$country), ]
row.names(df) <- NULL

write.csv(df,
          file.path(result_dir, "chapter04_wdi_life_gdp_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 01: 在 R 中计算相关的置信区间
# ------------------------------------------------------------------------------

corrXY <- cor(df$log_gdp_per_capita, df$life_expectancy)
Z <- 1 / 2 * log((1 + corrXY) / (1 - corrXY))
alpha <- 0.05
z_alpha_2 <- qnorm(1 - alpha / 2)
n <- nrow(df)
Z_L <- Z - z_alpha_2 * sqrt(1 / (n - 3))
Z_U <- Z + z_alpha_2 * sqrt(1 / (n - 3))
CI_L <- (exp(2 * Z_L) - 1) / (exp(2 * Z_L) + 1)
CI_U <- (exp(2 * Z_U) - 1) / (exp(2 * Z_U) + 1)

T_obs <- corrXY * sqrt(n - 2) / sqrt(1 - corrXY^2)
p_value <- 2 * (1 - pt(abs(T_obs), df = n - 2))
p_value_text <- if (p_value == 0) "< 1e-15" else sprintf("%.4g", p_value)

# ------------------------------------------------------------------------------
# Box 02: 在 R 中计算相关的置信区间
# ------------------------------------------------------------------------------

cor_test <- cor.test(df$log_gdp_per_capita, df$life_expectancy, conf.level = 0.95)

summary_table <- data.frame(
  指标 = c("分析年份", "完整样本量", "Pearson相关系数", "Fisher_Z",
           "95%置信区间下限_手算", "95%置信区间上限_手算",
           "t统计量", "p值", "cor.test置信区间下限", "cor.test置信区间上限"),
  数值 = c(analysis_year, n, corrXY, Z, CI_L, CI_U,
           T_obs, p_value, cor_test$conf.int[1], cor_test$conf.int[2])
)
write.csv(summary_table,
          file.path(result_dir, "chapter04_correlation_inference_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
capture.output(cor_test,
               file = file.path(result_dir, "chapter04_cor_test_R_output.txt"))

preview_table <- df[order(-df$gdp_per_capita_constant_2015_usd),
                    c("country", "country_code", "gdp_per_capita_constant_2015_usd",
                      "log_gdp_per_capita", "life_expectancy")]
preview_table <- head(preview_table, 12)
names(preview_table) <- c("国家或地区", "代码", "人均GDP_2015不变美元",
                          "log人均GDP", "预期寿命")
write.csv(preview_table,
          file.path(table_dir, "chapter04_wdi_preview_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter04_wdi_life_gdp_correlation_scatter.png")
plot(df$log_gdp_per_capita, df$life_expectancy,
     pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "预期寿命",
     main = paste0(analysis_year, "年各国收入水平与预期寿命的相关"))
grid(col = "gray85")
legend("bottomright",
       legend = sprintf("Pearson相关 = %.3f", corrXY),
       bty = "n")
dev.off()

open_png("chapter04_correlation_confidence_interval.png", width = 1600, height = 900)
plot(1, corrXY, xlim = c(0.5, 1.5), ylim = c(max(-1, CI_L - 0.05), min(1, CI_U + 0.05)),
     pch = 16, cex = 1.4, xaxt = "n",
     xlab = "", ylab = "Pearson相关系数",
     main = "相关系数的Fisher Z置信区间")
axis(1, at = 1, labels = paste0(analysis_year, "年WDI样本"))
arrows(1, CI_L, 1, CI_U, angle = 90, code = 3, length = 0.08, lwd = 2)
abline(h = 0, col = "#D95F0E", lty = 2, lwd = 2)
legend("bottomright",
       legend = c("样本相关", "95%置信区间", "零相关"),
       pch = c(16, NA, NA), lty = c(NA, 1, 2), lwd = c(NA, 2, 2),
       col = c("black", "black", "#D95F0E"), bty = "n")
grid(col = "gray88")
dev.off()

set.seed(20260524)
x_demo <- runif(500, -2, 2)
indep_y <- rnorm(500)
nonlinear_y <- x_demo^2 + rnorm(500, sd = 0.35)
positive_y <- 1 + x_demo + rnorm(500, sd = 0.6)
negative_y <- 1 - x_demo + rnorm(500, sd = 0.6)

open_png("chapter04_dependence_vs_correlation_examples.png", width = 2200, height = 1400)
par(mfrow = c(2, 2), family = cn_family, mar = c(4, 4, 3, 1) + 0.1)
plot(x_demo, indep_y, pch = 16, col = adjustcolor("#1B9E77", alpha.f = 0.65),
     xlab = "变量X", ylab = "变量Y",
     main = sprintf("近似独立：相关 %.2f", cor(x_demo, indep_y)))
grid(col = "gray88")
plot(x_demo, nonlinear_y, pch = 16, col = adjustcolor("#7570B3", alpha.f = 0.65),
     xlab = "变量X", ylab = "变量Y",
     main = sprintf("相依但线性相关弱：相关 %.2f", cor(x_demo, nonlinear_y)))
lines(lowess(x_demo, nonlinear_y), col = "#D95F0E", lwd = 2)
grid(col = "gray88")
plot(x_demo, positive_y, pch = 16, col = adjustcolor("#2C7FB8", alpha.f = 0.65),
     xlab = "变量X", ylab = "变量Y",
     main = sprintf("正相关：相关 %.2f", cor(x_demo, positive_y)))
abline(lm(positive_y ~ x_demo), col = "#D95F0E", lwd = 2)
grid(col = "gray88")
plot(x_demo, negative_y, pch = 16, col = adjustcolor("#E7298A", alpha.f = 0.65),
     xlab = "变量X", ylab = "变量Y",
     main = sprintf("负相关：相关 %.2f", cor(x_demo, negative_y)))
abline(lm(negative_y ~ x_demo), col = "#D95F0E", lwd = 2)
grid(col = "gray88")
dev.off()

writeLines(c(
  "第 4 章：关于总体相关的推断",
  "",
  "数据：World Bank WDI 全球国家/地区年度数据。",
  "X：log(人均GDP，2015年不变美元)；Y：预期寿命。",
  sprintf("分析年份：%d；完整样本量：%d", analysis_year, n),
  sprintf("Pearson相关系数：%.4f", corrXY),
  sprintf("95%% Fisher Z置信区间：[%.4f, %.4f]", CI_L, CI_U),
  sprintf("相关为零的t统计量：%.4f；p值：%s", T_obs, p_value_text)
), con = file.path(result_dir, "chapter04_results_readme.txt"))

message("Chapter 04 complete. Outputs written to: ", chapter_dir)
