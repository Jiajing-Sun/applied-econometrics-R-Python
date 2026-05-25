# Chapter 07: 非线性函数形式
#
# 本章数据：World Bank WDI 全球宏观指标 + Our World in Data 全球年度 CO2。
# 教学对应关系：
#   教材变量 wind_direction -> log(人均GDP，2015年不变美元)
#   教材变量 pm25           -> 人均CO2排放（吨/人）
#   教材变量 wind_cat       -> log(人均GDP)十分位分箱
#   教材变量 land_wind      -> 高收入国家虚拟变量
#   教材变量 strong_wind    -> 高贸易开放度虚拟变量
#   教材变量 wind_speed     -> 贸易占GDP比重
#
# 本脚本保留原章方法：分箱均值、虚拟变量、多项式函数、poly() 正交多项式、
# 对数模型、交互项以及 HC0 稳健标准误。

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

hc0_vcov <- function(model) {
  X <- model.matrix(model)
  u <- residuals(model)
  bread <- solve(t(X) %*% X)
  meat <- t(X) %*% (X * as.numeric(u^2))
  bread %*% meat %*% bread
}

coef_table <- function(model, vcov_mat, label = "模型", level = 0.95) {
  est <- coef(model)
  se <- sqrt(diag(vcov_mat))
  df_resid <- df.residual(model)
  tval <- est / se
  pval <- 2 * (1 - pt(abs(tval), df = df_resid))
  crit <- qt(1 - (1 - level) / 2, df = df_resid)
  data.frame(
    模型 = label,
    项 = names(est),
    估计值 = as.numeric(est),
    标准误 = as.numeric(se),
    t统计量 = as.numeric(tval),
    p值 = as.numeric(pval),
    CI下限 = as.numeric(est - crit * se),
    CI上限 = as.numeric(est + crit * se),
    row.names = NULL
  )
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
df_all$log_co2_pc <- log(df_all$co2_pc_tonnes)

usable <- df_all[
  complete.cases(df_all[, c("gdp_per_capita_constant_2015_usd", "population",
                            "trade_pct_gdp", "annual_co2_emissions",
                            "co2_pc_tonnes", "log_gdp_pc", "log_co2_pc")]) &
    df_all$gdp_per_capita_constant_2015_usd > 0 &
    df_all$population > 0 &
    df_all$annual_co2_emissions > 0 &
    df_all$co2_pc_tonnes > 0,
]

year_counts <- aggregate(country_code ~ year, data = usable, FUN = length)
analysis_year <- max(year_counts$year[year_counts$country_code >= 150])
df <- usable[usable$year == analysis_year, ]
df <- df[order(df$country), ]
row.names(df) <- NULL

df$income_decile <- cut(
  df$log_gdp_pc,
  breaks = unique(quantile(df$log_gdp_pc, probs = seq(0, 1, by = 0.1),
                           na.rm = TRUE)),
  include.lowest = TRUE
)
df$income_group <- cut(
  df$log_gdp_pc,
  breaks = unique(quantile(df$log_gdp_pc, probs = seq(0, 1, by = 0.25),
                           na.rm = TRUE)),
  include.lowest = TRUE,
  labels = c("低收入组", "中低收入组", "中高收入组", "高收入组")
)
df$high_income <- ifelse(df$log_gdp_pc > median(df$log_gdp_pc), 1, 0)
df$high_trade <- ifelse(df$trade_pct_gdp > median(df$trade_pct_gdp), 1, 0)

analysis_cols <- c("country", "country_code", "year",
                   "gdp_per_capita_constant_2015_usd", "log_gdp_pc",
                   "trade_pct_gdp", "population", "co2_pc_tonnes",
                   "log_co2_pc", "income_decile", "income_group",
                   "high_income", "high_trade")
write.csv(df[, analysis_cols],
          file.path(result_dir, "chapter07_wdi_owid_income_co2_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 01--05: 分箱均值图
# ------------------------------------------------------------------------------

df_agg <- aggregate(
  cbind(co2_pc_tonnes, log_gdp_pc) ~ income_decile,
  data = df,
  FUN = mean
)
names(df_agg) <- c("收入分箱", "人均CO2均值", "log人均GDP均值")
write.csv(df_agg,
          file.path(table_dir, "chapter07_income_decile_co2_means.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter07_income_co2_binned_means.png")
plot(df$log_gdp_pc, df$co2_pc_tonnes,
     pch = 16, col = rgb(0.35, 0.35, 0.35, 0.35),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     main = paste0(analysis_year, "年收入水平与人均CO2排放"))
points(df_agg$log人均GDP均值, df_agg$人均CO2均值,
       pch = 19, col = "#C0392B", cex = 1.25)
lines(df_agg$log人均GDP均值, df_agg$人均CO2均值,
      col = "#C0392B", lwd = 2)
legend("topleft", legend = c("国家/地区", "十分位分箱均值"),
       pch = c(16, 19), lty = c(NA, 1),
       col = c(rgb(0.35, 0.35, 0.35, 0.6), "#C0392B"),
       bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 06--13: 多项式函数形式
# ------------------------------------------------------------------------------

df$log_gdp2 <- df$log_gdp_pc^2
df$log_gdp3 <- df$log_gdp_pc^3
df$log_gdp4 <- df$log_gdp_pc^4

ols_model_poly <- lm(co2_pc_tonnes ~ log_gdp_pc + log_gdp2 +
                       log_gdp3 + log_gdp4, data = df)
ols_model_poly_alt <- lm(co2_pc_tonnes ~ poly(log_gdp_pc, 4), data = df)

newdata <- data.frame(
  log_gdp_pc = seq(min(df$log_gdp_pc), max(df$log_gdp_pc), length.out = 300)
)
newdata$log_gdp2 <- newdata$log_gdp_pc^2
newdata$log_gdp3 <- newdata$log_gdp_pc^3
newdata$log_gdp4 <- newdata$log_gdp_pc^4
newdata$pred <- predict(ols_model_poly_alt, newdata)
newdata$pred_alt <- coef(ols_model_poly)[1] +
  coef(ols_model_poly)[2] * newdata$log_gdp_pc +
  coef(ols_model_poly)[3] * newdata$log_gdp2 +
  coef(ols_model_poly)[4] * newdata$log_gdp3 +
  coef(ols_model_poly)[5] * newdata$log_gdp4

poly_table <- coef_table(ols_model_poly, hc0_vcov(ols_model_poly),
                         label = "四阶原始多项式")
write.csv(poly_table,
          file.path(table_dir, "chapter07_polynomial_hc0_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

quad_model <- lm(co2_pc_tonnes ~ log_gdp_pc + log_gdp2, data = df)
quad_points <- as.numeric(quantile(df$log_gdp_pc, probs = c(0.25, 0.5, 0.75)))
quad_marginal <- data.frame(
  位置 = c("第25百分位", "中位数", "第75百分位"),
  log人均GDP = quad_points,
  边际效应 = coef(quad_model)[2] + 2 * coef(quad_model)[3] * quad_points
)
write.csv(quad_marginal,
          file.path(table_dir, "chapter07_quadratic_marginal_effects.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

shape_x <- seq(-2.2, 2.2, length.out = 250)
open_png("chapter07_polynomial_shapes.png")
plot(shape_x, shape_x, type = "l", lwd = 2.3, col = "#2166AC",
     ylim = c(-3.2, 4.2),
     xlab = "解释变量 X",
     ylab = "条件均值的形状",
     main = "多项式函数形式的典型形状")
lines(shape_x, 0.45 * shape_x^2 - 1.2, lwd = 2.3, col = "#C0392B")
lines(shape_x, -0.55 * shape_x^2 + 2.0, lwd = 2.3, col = "#238B45")
lines(shape_x, 0.2 * shape_x^3 - 0.7 * shape_x, lwd = 2.3, col = "#756BB1")
abline(h = 0, col = "grey80", lty = 3)
legend("topleft",
       legend = c("线性", "U形二次", "倒U形二次", "三次非单调"),
       lty = 1, lwd = 2.3,
       col = c("#2166AC", "#C0392B", "#238B45", "#756BB1"),
       bty = "n")
dev.off()

open_png("chapter07_income_co2_binned_polynomial.png")
plot(df$log_gdp_pc, df$co2_pc_tonnes,
     pch = 16, col = rgb(0.35, 0.35, 0.35, 0.28),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "人均CO2排放（吨/人）",
     main = "分箱均值与四阶多项式拟合")
points(df_agg$log人均GDP均值, df_agg$人均CO2均值,
       pch = 19, col = "#C0392B", cex = 1.25)
lines(newdata$log_gdp_pc, newdata$pred, col = "#2166AC", lwd = 2.5)
legend("topleft", legend = c("国家/地区", "十分位分箱均值", "四阶多项式拟合"),
       pch = c(16, 19, NA), lty = c(NA, NA, 1),
       col = c(rgb(0.35, 0.35, 0.35, 0.6), "#C0392B", "#2166AC"),
       bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# 对数模型
# ------------------------------------------------------------------------------

log_log_model <- lm(log_co2_pc ~ log_gdp_pc, data = df)
lin_log_model <- lm(co2_pc_tonnes ~ log_gdp_pc, data = df)
log_model_table <- rbind(
  coef_table(log_log_model, hc0_vcov(log_log_model), label = "log-log模型"),
  coef_table(lin_log_model, hc0_vcov(lin_log_model), label = "lin-log模型")
)
write.csv(log_model_table,
          file.path(table_dir, "chapter07_log_models_hc0_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

log_interpretation <- data.frame(
  模型 = c("log-log", "lin-log", "log-level"),
  设定 = c("log(Y) ~ log(X)", "Y ~ log(X)", "log(Y) ~ X"),
  系数含义 = c("X 增加1%，Y 平均约变化 beta%",
            "X 增加1%，Y 平均约变化 beta/100 个单位",
            "X 增加1个单位，Y 平均约变化 100*(exp(beta)-1)%"),
  本章读法 = c(
    sprintf("收入弹性约 %.3f", coef(log_log_model)[2]),
    sprintf("人均GDP增加1%%，人均CO2约变化 %.3f 吨", coef(lin_log_model)[2] / 100),
    "本章未作为主模型；常用于二元或比例型因变量的稳健性比较"
  )
)
write.csv(log_interpretation,
          file.path(table_dir, "chapter07_log_model_interpretation.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter07_log_log_income_co2.png")
plot(df$log_gdp_pc, df$log_co2_pc,
     pch = 16, col = rgb(0.35, 0.35, 0.35, 0.35),
     xlab = "log(人均GDP，2015年不变美元)",
     ylab = "log(人均CO2排放)",
     main = "对数模型：收入与人均CO2排放")
abline(log_log_model, col = "#2166AC", lwd = 2)
china <- df[df$country_code == "CHN", ]
if (nrow(china) == 1) {
  points(china$log_gdp_pc, china$log_co2_pc, pch = 19,
         col = "#D73027", cex = 1.4)
  text(china$log_gdp_pc, china$log_co2_pc, labels = "中国",
       pos = 4, col = "#D73027", cex = 0.9)
}
legend("topleft", legend = c("国家/地区", "OLS拟合线", "中国"),
       pch = c(16, NA, 19), lty = c(NA, 1, NA),
       col = c(rgb(0.35, 0.35, 0.35, 0.6), "#2166AC", "#D73027"),
       bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 14--15: 虚拟变量和交互项
# ------------------------------------------------------------------------------

df$high_income_high_trade <- df$high_income * df$high_trade
df$high_income_trade <- df$high_income * df$trade_pct_gdp

ols_model1 <- lm(co2_pc_tonnes ~ high_income, data = df)
ols_model2 <- lm(co2_pc_tonnes ~ high_income + high_trade +
                   high_income_high_trade, data = df)
ols_model3 <- lm(co2_pc_tonnes ~ high_income + trade_pct_gdp +
                   high_income_trade, data = df)

interaction_table <- rbind(
  coef_table(ols_model1, hc0_vcov(ols_model1), label = "模型1：高收入虚拟变量"),
  coef_table(ols_model2, hc0_vcov(ols_model2), label = "模型2：两个虚拟变量交互"),
  coef_table(ols_model3, hc0_vcov(ols_model3), label = "模型3：虚拟变量与连续变量交互")
)
write.csv(interaction_table,
          file.path(table_dir, "chapter07_interaction_models_hc0_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

dummy_prediction <- expand.grid(
  high_income = c(0, 1),
  high_trade = c(0, 1)
)
dummy_prediction$high_income_high_trade <- dummy_prediction$high_income * dummy_prediction$high_trade
dummy_prediction$收入组 <- ifelse(dummy_prediction$high_income == 1, "高收入", "非高收入")
dummy_prediction$贸易组 <- ifelse(dummy_prediction$high_trade == 1, "高贸易开放度", "低贸易开放度")
dummy_prediction$预测人均CO2 <- predict(ols_model2, newdata = dummy_prediction)
write.csv(dummy_prediction[, c("收入组", "贸易组", "预测人均CO2")],
          file.path(table_dir, "chapter07_dummy_interaction_predictions.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

group_means <- aggregate(co2_pc_tonnes ~ income_group, data = df, FUN = mean)
names(group_means) <- c("收入组", "人均CO2均值")
write.csv(group_means,
          file.path(table_dir, "chapter07_income_group_means.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter07_income_group_means.png")
barplot(group_means$人均CO2均值, names.arg = group_means$收入组,
        col = "#74A9CF", border = NA,
        xlab = "按log(人均GDP)划分的四分位收入组",
        ylab = "人均CO2排放均值（吨/人）",
        main = "收入组虚拟变量对应的人均CO2差异")
dev.off()

trade_grid <- seq(quantile(df$trade_pct_gdp, 0.05),
                  quantile(df$trade_pct_gdp, 0.95), length.out = 100)
pred_low <- predict(ols_model3, newdata = data.frame(
  high_income = 0,
  trade_pct_gdp = trade_grid,
  high_income_trade = 0
))
pred_high <- predict(ols_model3, newdata = data.frame(
  high_income = 1,
  trade_pct_gdp = trade_grid,
  high_income_trade = trade_grid
))

trade_points <- as.numeric(quantile(df$trade_pct_gdp, probs = c(0.25, 0.5, 0.75)))
trade_prediction <- rbind(
  data.frame(收入组 = "非高收入", 贸易开放度 = trade_points,
             预测人均CO2 = predict(ols_model3, newdata = data.frame(
               high_income = 0, trade_pct_gdp = trade_points, high_income_trade = 0))),
  data.frame(收入组 = "高收入", 贸易开放度 = trade_points,
             预测人均CO2 = predict(ols_model3, newdata = data.frame(
               high_income = 1, trade_pct_gdp = trade_points, high_income_trade = trade_points)))
)
write.csv(trade_prediction,
          file.path(table_dir, "chapter07_trade_interaction_predictions.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter07_trade_interaction.png")
plot(df$trade_pct_gdp, df$co2_pc_tonnes,
     pch = ifelse(df$high_income == 1, 17, 16),
     col = ifelse(df$high_income == 1, rgb(0.84, 0.19, 0.15, 0.55),
                  rgb(0.13, 0.40, 0.67, 0.45)),
     xlab = "贸易占GDP比重（%）",
     ylab = "人均CO2排放（吨/人）",
     main = "交互项：收入组与贸易开放度")
lines(trade_grid, pred_low, col = "#2166AC", lwd = 2.5)
lines(trade_grid, pred_high, col = "#D73027", lwd = 2.5)
legend("topright",
       legend = c("低/中收入国家", "高收入国家", "低/中收入拟合线", "高收入拟合线"),
       pch = c(16, 17, NA, NA), lty = c(NA, NA, 1, 1),
       col = c("#2166AC", "#D73027", "#2166AC", "#D73027"),
       bty = "n")
dev.off()

summary_table <- data.frame(
  指标 = c("分析年份", "样本量", "人均CO2均值", "人均CO2中位数",
         "log-log模型收入弹性", "四阶多项式R2", "交互模型R2"),
  数值 = c(analysis_year, nrow(df), mean(df$co2_pc_tonnes),
         median(df$co2_pc_tonnes), coef(log_log_model)[2],
         summary(ols_model_poly)$r.squared, summary(ols_model3)$r.squared)
)
write.csv(summary_table,
          file.path(result_dir, "chapter07_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 07 finished.\n")
cat("Analysis year:", analysis_year, "\n")
cat("Sample size:", nrow(df), "\n")
cat("Log-log elasticity:", round(coef(log_log_model)[2], 4), "\n")
