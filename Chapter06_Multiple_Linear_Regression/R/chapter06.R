# Chapter 06: 多元线性回归
#
# 本章数据：BEA 美国州级 GDP/个人收入 + BLS 州级失业率。
# 教学对应关系：
#   教材变量 price          -> 人均个人收入（千美元）
#   教材变量 living_area    -> 人均实际GDP（千美元，2017年不变价）
#   教材变量 monthly_fee    -> 州年度平均失业率
#   教材变量 new_production -> 是否人口大州
#   教材变量 build_year     -> log(州人口)
#
# 本脚本保留原章方法：多元 OLS、HC0 稳健标准误、非零假设的 t 检验、
# 长短模型 F 检验、稳健 Wald/F 检验、条件期望置信区间和预测区间。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
bea_path <- file.path(repo_dir, "data", "processed", "bea_us_state_gdp_income_panel_1997_2025.csv")
bls_path <- file.path(repo_dir, "data", "processed", "bls_state_unemployment_cpi_monthly_2015_2025.csv")
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

first_non_na <- function(z) {
  z <- z[!is.na(z)]
  if (length(z) == 0) NA else z[1]
}

hc0_vcov <- function(model) {
  X <- model.matrix(model)
  u <- residuals(model)
  bread <- solve(t(X) %*% X)
  meat <- t(X) %*% (X * as.numeric(u^2))
  bread %*% meat %*% bread
}

coef_table <- function(model, vcov_mat, level = 0.95) {
  est <- coef(model)
  se <- sqrt(diag(vcov_mat))
  df_resid <- df.residual(model)
  tval <- est / se
  pval <- 2 * (1 - pt(abs(tval), df = df_resid))
  crit <- qt(1 - (1 - level) / 2, df = df_resid)
  data.frame(
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

bea <- read.csv(bea_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
bea$state <- trimws(gsub("\\s*\\*$", "", bea$state))
bea$state_fips <- floor(as.numeric(bea$geo_fips) / 1000)

bea_agg <- aggregate(
  cbind(real_gdp_millions_2017_usd, current_gdp_millions_usd,
        personal_income_millions_usd, population,
        per_capita_personal_income_usd) ~ state_fips + state + year,
  data = bea,
  FUN = first_non_na,
  na.action = na.pass
)

bls <- read.csv(bls_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
unemp <- aggregate(
  value ~ state_fips + year,
  data = bls[bls$series_type == "state_unemployment_rate", ],
  FUN = mean,
  na.rm = TRUE
)
names(unemp)[names(unemp) == "value"] <- "unemployment_rate"

panel <- merge(bea_agg, unemp, by = c("state_fips", "year"))
panel <- panel[complete.cases(panel), ]
panel <- panel[panel$population > 0 & panel$real_gdp_millions_2017_usd > 0, ]
analysis_year <- max(panel$year)
df <- panel[panel$year == analysis_year, ]

df$income_pc_thousand <- df$per_capita_personal_income_usd / 1000
df$gdp_pc_thousand <- df$real_gdp_millions_2017_usd * 1000 / df$population
df$log_population <- log(df$population)
df$large_state <- as.integer(df$population > median(df$population, na.rm = TRUE))
df <- df[order(df$state), ]
row.names(df) <- NULL

analysis_cols <- c("state", "state_fips", "year", "income_pc_thousand",
                   "gdp_pc_thousand", "unemployment_rate",
                   "large_state", "log_population", "population")
df <- df[, analysis_cols]
write.csv(df,
          file.path(result_dir, "chapter06_bea_bls_state_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 01--05: R 中的多元回归
# ------------------------------------------------------------------------------

ols_model <- lm(income_pc_thousand ~ gdp_pc_thousand + unemployment_rate +
                  large_state, data = df)
vcov_hc0 <- hc0_vcov(ols_model)
rob_inf <- coef_table(ols_model, vcov_hc0, level = 0.95)
write.csv(rob_inf,
          file.path(table_dir, "chapter06_mult_reg_hc0_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

b1 <- rob_inf$估计值[rob_inf$项 == "gdp_pc_thousand"]
se1 <- rob_inf$标准误[rob_inf$项 == "gdp_pc_thousand"]
t_stat <- (b1 - 0.8) / se1
df_model <- df.residual(ols_model)
p_value <- (1 - pt(abs(t_stat), df_model)) * 2

nonzero_test <- data.frame(
  原假设 = "人均实际GDP系数 = 0.8",
  估计值 = b1,
  HC0标准误 = se1,
  t统计量 = t_stat,
  p值 = p_value
)
write.csv(nonzero_test,
          file.path(result_dir, "chapter06_nonzero_slope_test.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 06--17: F 检验
# ------------------------------------------------------------------------------

ols_model_l <- lm(income_pc_thousand ~ gdp_pc_thousand + unemployment_rate +
                    large_state + log_population, data = df)
ols_model_s <- lm(income_pc_thousand ~ gdp_pc_thousand + unemployment_rate, data = df)

n <- nobs(ols_model_l)
residuals_l <- residuals(ols_model_l)
residuals_s <- residuals(ols_model_s)
RSS_l <- sum(residuals_l^2)
RSS_s <- sum(residuals_s^2)
K <- 4
G <- 2
F_obs <- ((RSS_s - RSS_l) / (K - G)) / (RSS_l / (n - (K + 1)))
p <- 1 - pf(F_obs, df1 = K - G, df2 = n - (K + 1))
anova_table <- anova(ols_model_s, ols_model_l)

f_table <- data.frame(
  检验 = "新增 large_state 和 log_population",
  RSS_短模型 = RSS_s,
  RSS_长模型 = RSS_l,
  分子自由度 = K - G,
  分母自由度 = n - (K + 1),
  F统计量 = F_obs,
  p值 = p
)
write.csv(f_table,
          file.path(result_dir, "chapter06_f_test_short_long.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
capture.output(anova_table,
               file = file.path(result_dir, "chapter06_anova_short_long_R_output.txt"))

# ------------------------------------------------------------------------------
# Box 18--19: 稳健 F/Wald 检验
# ------------------------------------------------------------------------------

vcov_l_hc0 <- hc0_vcov(ols_model_l)
beta_l <- coef(ols_model_l)
Rmat <- rbind(
  large_state = c(0, 0, 0, 1, 0),
  log_population = c(0, 0, 0, 0, 1)
)
colnames(Rmat) <- names(beta_l)
q <- nrow(Rmat)
Rb <- as.matrix(Rmat %*% beta_l)
wald_chi2 <- as.numeric(t(Rb) %*% solve(Rmat %*% vcov_l_hc0 %*% t(Rmat)) %*% Rb)
F_rob <- wald_chi2 / q
p_rob <- 1 - pf(F_rob, df1 = q, df2 = df.residual(ols_model_l))
robust_f_table <- data.frame(
  检验 = "HC0稳健Wald检验：large_state = 0 且 log_population = 0",
  F统计量 = F_rob,
  分子自由度 = q,
  分母自由度 = df.residual(ols_model_l),
  p值 = p_rob
)
write.csv(robust_f_table,
          file.path(result_dir, "chapter06_robust_wald_test.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

short_long_table <- data.frame(
  模型 = c("短模型：收入~GDP", "中模型：收入~GDP+失业率+大州",
         "长模型：收入~GDP+失业率+大州+log人口"),
  GDP系数 = c(coef(lm(income_pc_thousand ~ gdp_pc_thousand, data = df))[2],
            coef(ols_model)[2],
            coef(ols_model_l)[2]),
  R2 = c(summary(lm(income_pc_thousand ~ gdp_pc_thousand, data = df))$r.squared,
         summary(ols_model)$r.squared,
         summary(ols_model_l)$r.squared)
)
write.csv(short_long_table,
          file.path(table_dir, "chapter06_short_long_model_comparison.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

aux_gdp <- lm(gdp_pc_thousand ~ unemployment_rate + large_state, data = df)
aux_income <- lm(income_pc_thousand ~ unemployment_rate + large_state, data = df)
fwl_df <- data.frame(
  state = df$state,
  gdp_residual = residuals(aux_gdp),
  income_residual = residuals(aux_income)
)
write.csv(fwl_df,
          file.path(result_dir, "chapter06_fwl_residual_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 20--25: 条件期望的置信区间和预测区间
# ------------------------------------------------------------------------------

simple_model <- lm(income_pc_thousand ~ gdp_pc_thousand, data = df)
x0 <- 75
yhat_x75 <- predict(simple_model, newdata = data.frame(gdp_pc_thousand = x0))

n_simple <- nobs(simple_model)
RSS_simple <- sum(residuals(simple_model)^2)
s2_epsilon <- RSS_simple / (n_simple - 2)
xbar <- mean(df$gdp_pc_thousand)
SSX <- sum((df$gdp_pc_thousand - xbar)^2)
var_eY_x0 <- s2_epsilon * (1 / n_simple + (x0 - xbar)^2 / SSX)

alpha <- 0.05
t_crit <- qt(1 - alpha / 2, df = n_simple - 2)
lb_ci_eY_x0 <- yhat_x75 - t_crit * sqrt(var_eY_x0)
ub_ci_eY_x0 <- yhat_x75 + t_crit * sqrt(var_eY_x0)

var_tildeepsilon_x0 <- var_eY_x0 + s2_epsilon
lb_pi_x0 <- yhat_x75 - t_crit * sqrt(var_tildeepsilon_x0)
ub_pi_x0 <- yhat_x75 + t_crit * sqrt(var_tildeepsilon_x0)

eval_df <- data.frame(
  gdp_pc_thousand = 75,
  unemployment_rate = 4,
  large_state = 1,
  log_population = log(5000000)
)
pred_conf <- predict(ols_model_l, newdata = eval_df,
                     interval = "confidence", level = 0.95)
pred_pi <- predict(ols_model_l, newdata = eval_df,
                   interval = "prediction", level = 0.95)

prediction_table <- data.frame(
  设定 = c("简单模型：GDP=75千美元，条件期望CI",
         "简单模型：GDP=75千美元，单个州预测PI",
         "多元模型：GDP=75、失业率4%、大州、人口500万，条件期望CI",
         "多元模型：GDP=75、失业率4%、大州、人口500万，单个州预测PI"),
  拟合值 = c(as.numeric(yhat_x75), as.numeric(yhat_x75), pred_conf[1, "fit"], pred_pi[1, "fit"]),
  下限 = c(as.numeric(lb_ci_eY_x0), as.numeric(lb_pi_x0), pred_conf[1, "lwr"], pred_pi[1, "lwr"]),
  上限 = c(as.numeric(ub_ci_eY_x0), as.numeric(ub_pi_x0), pred_conf[1, "upr"], pred_pi[1, "upr"])
)
write.csv(prediction_table,
          file.path(result_dir, "chapter06_prediction_intervals.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Figures
# ------------------------------------------------------------------------------

open_png("chapter06_bivariate_relationships.png", width = 2200, height = 1400)
par(mfrow = c(2, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
plot(df$gdp_pc_thousand, df$income_pc_thousand, pch = 16,
     col = adjustcolor("#2C7FB8", alpha.f = 0.7),
     xlab = "人均实际GDP（千美元）", ylab = "人均个人收入（千美元）",
     main = "收入与人均实际GDP")
abline(lm(income_pc_thousand ~ gdp_pc_thousand, data = df), col = "#D95F0E", lwd = 2)
grid(col = "gray85")
plot(df$unemployment_rate, df$income_pc_thousand, pch = 16,
     col = adjustcolor("#7570B3", alpha.f = 0.7),
     xlab = "失业率（%）", ylab = "人均个人收入（千美元）",
     main = "收入与失业率")
abline(lm(income_pc_thousand ~ unemployment_rate, data = df), col = "#D95F0E", lwd = 2)
grid(col = "gray85")
plot(df$gdp_pc_thousand, df$unemployment_rate, pch = 16,
     col = adjustcolor("#1B9E77", alpha.f = 0.7),
     xlab = "人均实际GDP（千美元）", ylab = "失业率（%）",
     main = "失业率与人均实际GDP")
abline(lm(unemployment_rate ~ gdp_pc_thousand, data = df), col = "#D95F0E", lwd = 2)
grid(col = "gray85")
plot(df$log_population, df$income_pc_thousand, pch = 16,
     col = adjustcolor("#E7298A", alpha.f = 0.7),
     xlab = "log(州人口)", ylab = "人均个人收入（千美元）",
     main = "收入与人口规模")
abline(lm(income_pc_thousand ~ log_population, data = df), col = "#D95F0E", lwd = 2)
grid(col = "gray85")
dev.off()

open_png("chapter06_partial_prediction_lines.png")
plot(df$gdp_pc_thousand, df$income_pc_thousand, pch = 16,
     col = ifelse(df$large_state == 1, "#D95F0EAA", "#2C7FB8AA"),
     xlab = "人均实际GDP（千美元）", ylab = "人均个人收入（千美元）",
     main = "多元回归中的条件预测线")
grid(col = "gray85")
gseq <- seq(min(df$gdp_pc_thousand), max(df$gdp_pc_thousand), length.out = 100)
u_med <- median(df$unemployment_rate)
lp_med <- median(df$log_population)
lines(gseq,
      predict(ols_model_l, newdata = data.frame(gdp_pc_thousand = gseq,
                                                unemployment_rate = u_med,
                                                large_state = 0,
                                                log_population = lp_med)),
      col = "#2C7FB8", lwd = 2)
lines(gseq,
      predict(ols_model_l, newdata = data.frame(gdp_pc_thousand = gseq,
                                                unemployment_rate = u_med,
                                                large_state = 1,
                                                log_population = lp_med)),
      col = "#D95F0E", lwd = 2)
legend("topleft", legend = c("其他州", "人口大州"),
       col = c("#2C7FB8", "#D95F0E"), pch = 16, lwd = 2, bty = "n")
dev.off()

open_png("chapter06_fwl_residual_residual.png")
plot(fwl_df$gdp_residual, fwl_df$income_residual, pch = 16,
     col = adjustcolor("#2C7FB8", alpha.f = 0.7),
     xlab = "剔除失业率和大州虚拟变量后的人均GDP残差",
     ylab = "剔除失业率和大州虚拟变量后的人均收入残差",
     main = "回归剖析：残差对残差")
abline(lm(income_residual ~ gdp_residual, data = fwl_df),
       col = "#D95F0E", lwd = 2)
grid(col = "gray85")
legend("topleft", legend = paste0("斜率 = ", round(coef(ols_model)["gdp_pc_thousand"], 3)),
       lwd = 2, col = "#D95F0E", bty = "n")
dev.off()

open_png("chapter06_prediction_interval_plot.png", width = 1600, height = 1000)
x_pos <- c(1, 1.32)
y_rng <- range(prediction_table$下限[1:2], prediction_table$上限[1:2])
y_pad <- diff(y_rng) * 0.06
plot(x_pos, prediction_table$拟合值[1:2], xlim = c(0.78, 1.54),
     ylim = y_rng + c(-y_pad, y_pad), type = "n", xaxt = "n",
     xlab = "", ylab = "人均个人收入（千美元）",
     main = "条件期望置信区间与预测区间")
abline(h = axTicks(2), col = "gray85", lty = "dotted")
axis(1, at = x_pos, labels = c("条件期望", "单个州预测"))
arrows(x_pos, prediction_table$下限[1:2], x_pos, prediction_table$上限[1:2],
       angle = 90, code = 3, length = 0.08, lwd = 2)
points(x_pos, prediction_table$拟合值[1:2], pch = 16)
dev.off()

open_png("chapter06_residual_diagnostics.png", width = 2000, height = 1000)
par(mfrow = c(1, 2), family = cn_family, mar = c(5, 5, 3, 1) + 0.1)
plot(fitted(ols_model), residuals(ols_model), pch = 16,
     col = adjustcolor("#7570B3", alpha.f = 0.7),
     xlab = "拟合值", ylab = "残差",
     main = "残差与拟合值")
abline(h = 0, col = "#D95F0E", lwd = 2, lty = 2)
grid(col = "gray85")
qqnorm(residuals(ols_model), pch = 16,
       col = adjustcolor("#2C7FB8", alpha.f = 0.7),
       xlab = "正态理论分位数", ylab = "样本残差分位数",
       main = "残差正态 Q-Q 图")
qqline(residuals(ols_model), col = "#D95F0E", lwd = 2)
grid(col = "gray85")
dev.off()

writeLines(c(
  "第 6 章：多元线性回归",
  "",
  "数据：BEA 美国州级 GDP/个人收入 + BLS 州级失业率。",
  sprintf("分析年份：%d；样本量：%d", analysis_year, nrow(df)),
  "主模型：人均个人收入（千美元） ~ 人均实际GDP（千美元） + 失业率 + 是否人口大州。",
  sprintf("HC0下人均实际GDP系数：%.4f，标准误：%.4f", b1, se1),
  sprintf("检验 GDP 系数 = 0.8：t=%.4f，p=%.4f", t_stat, p_value),
  sprintf("长短模型F检验：F=%.4f，p=%.4f", F_obs, p),
  sprintf("HC0稳健Wald检验：F=%.4f，p=%.4f", F_rob, p_rob),
  sprintf("简单模型在 GDP=75 千美元处的拟合值：%.4f", as.numeric(yhat_x75))
), con = file.path(result_dir, "chapter06_results_readme.txt"))

message("Chapter 06 complete. Outputs written to: ", chapter_dir)
