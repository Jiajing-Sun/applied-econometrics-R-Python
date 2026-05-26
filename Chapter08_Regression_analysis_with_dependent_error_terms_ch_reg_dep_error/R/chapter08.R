# Chapter 08: 带有相关误差项的回归分析
#
# 本章数据：
#   1. ACS PUMS 2023 加州个人样本，用于聚类稳健标准误和多层/随机截距例子。
#   2. BEA 州级 GDP/收入 + BLS 州级失业率，用于州面板固定效应例子。
#
# 教学对应关系：
#   outcome_income           -> log(个人收入+1)
#   bachelor_or_above        -> 是否本科及以上学历
#   age                      -> 年龄
#   household_id             -> 家庭编号 serialno
#   state_income_pc_k         -> 人均个人收入（千美元）
#   state_unemployment_rate   -> 州失业率
#
# 本脚本保留原章方法：普通 OLS、HC0 稳健标准误、按组聚类稳健标准误、
# 随机截距多层模型、个体固定效应和双向固定效应。

args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) == 0) {
  script_dir <- getwd()
} else {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
}

chapter_dir <- normalizePath(file.path(script_dir, ".."))
repo_dir <- normalizePath(file.path(chapter_dir, ".."))
acs_path <- file.path(repo_dir, "data", "processed", "acs_pums_california_persons_2023_selected.csv")
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

coef_table_from_vcov <- function(model, vcov_mat, label, df_override = NULL) {
  est <- coef(model)
  se <- sqrt(diag(vcov_mat))
  df_resid <- if (is.null(df_override)) df.residual(model) else df_override
  tval <- est / se
  pval <- 2 * (1 - pt(abs(tval), df = df_resid))
  data.frame(
    模型 = label,
    项 = names(est),
    估计值 = as.numeric(est),
    标准误 = as.numeric(se),
    t统计量 = as.numeric(tval),
    p值 = as.numeric(pval),
    自由度 = df_resid,
    row.names = NULL
  )
}

coef_table_matrix <- function(mat, label) {
  data.frame(
    模型 = label,
    项 = rownames(mat),
    估计值 = as.numeric(mat[, 1]),
    标准误 = as.numeric(mat[, 2]),
    t统计量 = as.numeric(mat[, 3]),
    p值 = as.numeric(mat[, 4]),
    自由度 = NA_real_,
    row.names = NULL
  )
}

first_non_na <- function(z) {
  z <- z[!is.na(z)]
  if (length(z) == 0) NA else z[1]
}

library(lmtest)
library(sandwich)
library(plm)
library(nlme)

# ------------------------------------------------------------------------------
# Box 01: 聚类数据下的 OLS
# ------------------------------------------------------------------------------

acs <- read.csv(acs_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(acs) <- gsub("^\ufeff", "", names(acs))
acs <- acs[complete.cases(acs[, c("serialno", "age", "personal_income",
                                  "female", "employed",
                                  "has_bachelor_or_higher")]), ]
acs <- acs[acs$age >= 25 & acs$age <= 64 & acs$personal_income >= 0, ]
acs$household_id <- acs$serialno
acs$log_income <- log1p(acs$personal_income)
acs$income_thousand <- acs$personal_income / 1000
acs$bachelor <- acs$has_bachelor_or_higher
acs$age_centered <- acs$age - mean(acs$age)
acs <- acs[order(acs$household_id, acs$person_order), ]
row.names(acs) <- NULL

write.csv(acs[, c("household_id", "person_order", "age", "female", "employed",
                  "bachelor", "personal_income", "log_income")],
          file.path(result_dir, "chapter08_acs_cluster_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

ols_model <- lm(log_income ~ bachelor, data = acs)
sd_y <- sd(acs$log_income, na.rm = TRUE)
beta_bachelor <- coef(ols_model)["bachelor"]
beta_bachelor_std <- beta_bachelor / sd_y

V_hc0 <- vcovHC(ols_model, type = "HC0")
V_cl <- vcovCL(ols_model, cluster = acs$household_id, type = "HC0")
cluster_df <- length(unique(acs$household_id)) - 1

cluster_table1 <- rbind(
  coef_table_from_vcov(ols_model, vcov(ols_model), "普通OLS", df.residual(ols_model)),
  coef_table_from_vcov(ols_model, V_hc0, "HC0稳健", df.residual(ols_model)),
  coef_table_from_vcov(ols_model, V_cl, "按家庭聚类", cluster_df)
)

ols_model2 <- lm(log_income ~ age_centered, data = acs)
V_hc0_2 <- vcovHC(ols_model2, type = "HC0")
V_cl2 <- vcovCL(ols_model2, cluster = acs$household_id, type = "HC0")

cluster_table2 <- rbind(
  coef_table_from_vcov(ols_model2, vcov(ols_model2), "年龄：普通OLS", df.residual(ols_model2)),
  coef_table_from_vcov(ols_model2, V_hc0_2, "年龄：HC0稳健", df.residual(ols_model2)),
  coef_table_from_vcov(ols_model2, V_cl2, "年龄：按家庭聚类", cluster_df)
)

ols_model3 <- lm(log_income ~ bachelor + age_centered + female + employed, data = acs)
V_cl3 <- vcovCL(ols_model3, cluster = acs$household_id, type = "HC0")
cluster_table3 <- coef_table_from_vcov(ols_model3, V_cl3,
                                       "本科+年龄+性别+就业：按家庭聚类",
                                       cluster_df)

cluster_tables <- rbind(cluster_table1, cluster_table2, cluster_table3)
write.csv(cluster_tables,
          file.path(table_dir, "chapter08_acs_cluster_robust_tables.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter08_acs_income_by_education.png")
boxplot(log_income ~ bachelor, data = acs,
        names = c("非本科及以上", "本科及以上"),
        col = c("#9ECAE1", "#FDD0A2"),
        xlab = "教育组",
        ylab = "log(个人收入+1)",
        main = "ACS 加州样本：学历与个人收入")
dev.off()

se_compare <- cluster_tables[
  cluster_tables$项 == "bachelor" &
    cluster_tables$模型 %in% c("普通OLS", "HC0稳健", "按家庭聚类"),
  c("模型", "标准误")
]
se_compare$相对HC0 <- se_compare$标准误 /
  se_compare$标准误[se_compare$模型 == "HC0稳健"]
write.csv(se_compare,
          file.path(table_dir, "chapter08_bachelor_se_comparison.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

household_size <- as.data.frame(table(acs$household_id), stringsAsFactors = FALSE)
names(household_size) <- c("household_id", "household_size")
household_size_summary <- data.frame(
  指标 = c("家庭数", "平均家庭样本人数", "中位数家庭样本人数", "最大家庭样本人数",
         "单人家庭占比"),
  数值 = c(nrow(household_size), mean(household_size$household_size),
         median(household_size$household_size), max(household_size$household_size),
         mean(household_size$household_size == 1))
)
write.csv(household_size_summary,
          file.path(result_dir, "chapter08_household_size_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter08_cluster_se_comparison.png")
barplot(se_compare$标准误, names.arg = se_compare$模型,
        col = c("#9ECAE1", "#74C476", "#FD8D3C"),
        xlab = "标准误类型",
        ylab = "本科及以上系数的标准误",
        main = "普通、稳健与聚类标准误比较")
dev.off()

open_png("chapter08_cluster_structure_schematic.png")
plot(NA, xlim = c(0.5, 4.5), ylim = c(0.4, 5.1),
     xlab = "家庭（聚类）",
     ylab = "",
     axes = FALSE,
     main = "聚类数据结构：同一家庭内误差可能相关")
axis(1, at = 1:4, labels = paste0("家庭", 1:4))
axis(2, at = 1:4, labels = paste0("个人", 1:4), las = 1)
box()
for (g in 1:4) {
  n_members <- c(3, 2, 4, 2)[g]
  y_pos <- seq(1, n_members, length.out = n_members) + 0.25
  points(rep(g, n_members), y_pos, pch = 19, cex = 1.4, col = "#2166AC")
  segments(g - 0.18, y_pos, g + 0.18, y_pos, col = "#2166AC", lwd = 2)
  rect(g - 0.35, min(y_pos) - 0.35, g + 0.35, max(y_pos) + 0.35,
       border = "#C0392B", lwd = 2)
}
text(2.5, 4.9,
     expression("共同家庭冲击 " * c[g] * " 使同组误差相关"),
     col = "#C0392B", cex = 0.95)
dev.off()

# ------------------------------------------------------------------------------
# Box 02--03: 多层模型（随机截距）
# ------------------------------------------------------------------------------

set.seed(20260524)
lme_sample_size <- min(12000, nrow(acs))
lme_df <- acs[sample(seq_len(nrow(acs)), lme_sample_size), ]
lme_df$household_id <- factor(lme_df$household_id)

multi_model1 <- tryCatch(
  lme(log_income ~ bachelor + age_centered + female + employed,
      random = ~ 1 | household_id,
      data = lme_df,
      method = "REML",
      control = lmeControl(msMaxIter = 80, opt = "optim")),
  error = function(e) e
)

if (inherits(multi_model1, "error")) {
  writeLines(conditionMessage(multi_model1),
             con = file.path(result_dir, "chapter08_lme_error.txt"))
  lme_fixed <- data.frame()
  lme_var <- data.frame(层级 = "模型未收敛", 方差 = NA, 占比 = NA)
} else {
  lme_fixed <- data.frame(
    项 = rownames(summary(multi_model1)$tTable),
    summary(multi_model1)$tTable,
    row.names = NULL,
    check.names = FALSE
  )
  names(lme_fixed) <- c("项", "估计值", "标准误", "自由度", "t统计量", "p值")
  vc <- VarCorr(multi_model1)
  household_var <- as.numeric(vc[1, "Variance"])
  residual_var <- as.numeric(vc[2, "Variance"])
  lme_var <- data.frame(
    层级 = c("家庭随机截距", "个体残差"),
    方差 = c(household_var, residual_var),
    占比 = c(household_var, residual_var) / (household_var + residual_var)
  )
}

write.csv(lme_fixed,
          file.path(table_dir, "chapter08_multilevel_fixed_effects.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
write.csv(lme_var,
          file.path(result_dir, "chapter08_multilevel_variance_components.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# ------------------------------------------------------------------------------
# Box 04: 面板数据与固定效应
# ------------------------------------------------------------------------------

bea <- read.csv(bea_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(bea) <- gsub("^\ufeff", "", names(bea))
bea$state <- trimws(gsub("\\s*\\*$", "", bea$state))
bea$state_fips <- floor(as.numeric(bea$geo_fips) / 1000)
bea_agg <- aggregate(
  cbind(real_gdp_millions_2017_usd, personal_income_millions_usd,
        population, per_capita_personal_income_usd) ~ state_fips + state + year,
  data = bea,
  FUN = first_non_na,
  na.action = na.pass
)

bls <- read.csv(bls_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(bls) <- gsub("^\ufeff", "", names(bls))
unemp <- aggregate(
  value ~ state_fips + year,
  data = bls[bls$series_type == "state_unemployment_rate", ],
  FUN = mean,
  na.rm = TRUE
)
names(unemp)[names(unemp) == "value"] <- "unemployment_rate"
unemp$state_fips <- as.integer(unemp$state_fips)

panel <- merge(bea_agg, unemp, by = c("state_fips", "year"))
panel <- panel[complete.cases(panel), ]
panel <- panel[panel$population > 0 & panel$real_gdp_millions_2017_usd > 0, ]
panel$income_pc_thousand <- panel$per_capita_personal_income_usd / 1000
panel$gdp_pc_thousand <- panel$real_gdp_millions_2017_usd * 1000 / panel$population
panel <- panel[panel$year >= 2015 & panel$year <= 2024, ]
panel <- panel[order(panel$state, panel$year), ]
row.names(panel) <- NULL

write.csv(panel[, c("state", "state_fips", "year", "income_pc_thousand",
                    "gdp_pc_thousand", "unemployment_rate", "population")],
          file.path(result_dir, "chapter08_bea_bls_state_panel_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

pooled_model <- lm(income_pc_thousand ~ unemployment_rate, data = panel)
pooled_table <- coef_table_from_vcov(
  pooled_model,
  vcovCL(pooled_model, cluster = panel$state, type = "HC0"),
  "合并OLS（按州聚类）",
  length(unique(panel$state)) - 1
)

within_model <- plm(
  income_pc_thousand ~ unemployment_rate,
  effect = "individual",
  index = c("state", "year"),
  data = panel
)
within_table <- coef_table_matrix(
  coeftest(within_model,
           vcov = vcovHC(within_model, type = "HC0", cluster = "group")),
  "州固定效应"
)

twoway_model <- plm(
  income_pc_thousand ~ unemployment_rate,
  effect = "twoways",
  index = c("state", "year"),
  data = panel
)
twoway_table <- coef_table_matrix(
  coeftest(twoway_model,
           vcov = vcovHC(twoway_model, type = "HC0", cluster = "group")),
  "州与年份双向固定效应"
)

panel_tables <- rbind(pooled_table, within_table, twoway_table)
write.csv(panel_tables,
          file.path(table_dir, "chapter08_state_panel_fe_tables.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

panel_model_summary <- panel_tables[panel_tables$项 == "unemployment_rate",
                                    c("模型", "估计值", "标准误", "t统计量", "p值")]
write.csv(panel_model_summary,
          file.path(table_dir, "chapter08_panel_model_comparison.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

selected_states <- c("California", "Texas", "New York", "Florida", "Illinois")
panel_sel <- panel[panel$state %in% selected_states, ]
open_png("chapter08_state_income_panel_lines.png")
plot(range(panel_sel$year), range(panel_sel$income_pc_thousand),
     type = "n",
     xlab = "年份",
     ylab = "人均个人收入（千美元）",
     main = "美国州面板：人均收入随时间变化")
cols <- c("#2166AC", "#D73027", "#1B7837", "#762A83", "#E08214")
for (i in seq_along(selected_states)) {
  tmp <- panel_sel[panel_sel$state == selected_states[i], ]
  lines(tmp$year, tmp$income_pc_thousand, col = cols[i], lwd = 2)
}
legend("topleft", legend = c("加利福尼亚", "得克萨斯", "纽约", "佛罗里达", "伊利诺伊"),
       col = cols, lwd = 2, bty = "n")
dev.off()

coef_compare <- panel_tables[panel_tables$项 == "unemployment_rate",
                             c("模型", "估计值", "标准误")]
open_png("chapter08_fixed_effect_estimates.png")
bar_mid <- barplot(coef_compare$估计值, names.arg = coef_compare$模型,
                   col = c("#9ECAE1", "#74C476", "#FD8D3C"),
                   xlab = "模型",
                   ylab = "失业率系数",
                   main = "合并OLS、州固定效应与双向固定效应")
arrows(bar_mid, coef_compare$估计值 - 1.96 * coef_compare$标准误,
       bar_mid, coef_compare$估计值 + 1.96 * coef_compare$标准误,
       angle = 90, code = 3, length = 0.06)
abline(h = 0, lty = 2, col = "gray40")
dev.off()

within_demo_state <- "California"
within_demo <- panel[panel$state == within_demo_state, ]
within_demo$income_dm <- within_demo$income_pc_thousand - mean(within_demo$income_pc_thousand)
within_demo$unemp_dm <- within_demo$unemployment_rate - mean(within_demo$unemployment_rate)
write.csv(within_demo[, c("state", "year", "income_pc_thousand",
                          "unemployment_rate", "income_dm", "unemp_dm")],
          file.path(result_dir, "chapter08_within_transformation_demo.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter08_within_transformation_schematic.png")
x_lim <- range(within_demo$unemployment_rate)
x_pad <- diff(x_lim) * 0.16
plot(within_demo$unemployment_rate, within_demo$income_pc_thousand,
     pch = 19, col = "#2166AC",
     xlim = c(x_lim[1], x_lim[2] + x_pad),
     xlab = "失业率",
     ylab = "人均个人收入（千美元）",
     main = "固定效应的组内变化：以加利福尼亚为例")
text(within_demo$unemployment_rate, within_demo$income_pc_thousand,
     labels = within_demo$year, pos = 4, cex = 0.75, col = "#2166AC")
points(mean(within_demo$unemployment_rate), mean(within_demo$income_pc_thousand),
       pch = 4, cex = 1.8, lwd = 2.2, col = "#C0392B")
arrows(mean(within_demo$unemployment_rate), mean(within_demo$income_pc_thousand),
       within_demo$unemployment_rate, within_demo$income_pc_thousand,
       length = 0.06, col = rgb(0.2, 0.2, 0.2, 0.45))
legend("topright", legend = c("年度观测", "州内均值", "去均值方向"),
       pch = c(19, 4, NA), lty = c(NA, NA, 1),
       col = c("#2166AC", "#C0392B", "gray40"), bty = "n")
dev.off()

summary_table <- data.frame(
  指标 = c("ACS样本量", "ACS家庭数", "本科及以上普通OLS系数",
         "本科及以上标准化系数", "LME样本量", "面板州数",
         "面板年份起点", "面板年份终点", "双向FE失业率系数"),
  数值 = c(nrow(acs), length(unique(acs$household_id)), beta_bachelor,
         beta_bachelor_std, lme_sample_size, length(unique(panel$state)),
         min(panel$year), max(panel$year),
         coef(twoway_model)["unemployment_rate"])
)
write.csv(summary_table,
          file.path(result_dir, "chapter08_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 08 finished.\n")
cat("ACS sample size:", nrow(acs), "\n")
cat("ACS households:", length(unique(acs$household_id)), "\n")
cat("Panel observations:", nrow(panel), "\n")
cat("Two-way FE unemployment coefficient:",
    round(coef(twoway_model)["unemployment_rate"], 4), "\n")
