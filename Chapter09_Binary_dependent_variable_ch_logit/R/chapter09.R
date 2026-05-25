# Chapter 09: 二元因变量
#
# 本章数据：
#   1. ACS PUMS 2023 加州个人样本：用于“高收入概率”的 logit 入门例子。
#   2. UCI Credit Default：用于“违约概率”的赔率比、预测概率、风险比/风险差。
#
# 教学对应关系：
#   high_income                    -> ACS 个人收入是否处于样本最高四分位
#   share_tertiary_school          -> 是否本科及以上学历
#   lnpop                          -> log(年龄)
#   default_next_month             -> 下月是否信用卡违约
#   blood_pressure                 -> 过去还款状态 pay_0
#   male                           -> 男性
#   age                            -> 年龄
#
# 本脚本保留原章方法：logit 估计、赔率比、赔率比置信区间、
# 给定协变量的预测概率、样本平均风险比和风险差，并补充 LPM/logit/probit 对比表。

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
credit_path <- file.path(repo_dir, "data", "processed", "uci_credit_default_clients.csv")
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

glm_table <- function(model, label) {
  sm <- summary(model)$coefficients
  data.frame(
    模型 = label,
    项 = rownames(sm),
    估计值 = as.numeric(sm[, 1]),
    标准误 = as.numeric(sm[, 2]),
    z值 = as.numeric(sm[, 3]),
    p值 = as.numeric(sm[, 4]),
    row.names = NULL
  )
}

lm_table <- function(model, label) {
  sm <- summary(model)$coefficients
  data.frame(
    模型 = label,
    项 = rownames(sm),
    估计值 = as.numeric(sm[, 1]),
    标准误 = as.numeric(sm[, 2]),
    统计量 = as.numeric(sm[, 3]),
    p值 = as.numeric(sm[, 4]),
    row.names = NULL
  )
}

# ------------------------------------------------------------------------------
# Box 01--08: 高收入概率的 logistic 回归
# ------------------------------------------------------------------------------

acs <- read.csv(acs_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(acs) <- gsub("^\ufeff", "", names(acs))
acs <- acs[complete.cases(acs[, c("age", "personal_income", "female",
                                  "employed", "has_bachelor_or_higher")]), ]
acs <- acs[acs$age >= 25 & acs$age <= 64 & acs$personal_income >= 0, ]
highest_quartile_limit <- quantile(acs$personal_income, .75)
acs$high_income <- ifelse(acs$personal_income > highest_quartile_limit, 1, 0)
acs$bachelor <- acs$has_bachelor_or_higher
acs$ln_age <- log(acs$age)

logit_model <- glm(high_income ~ bachelor,
                   family = binomial(link = "logit"),
                   data = acs)
logit_model2 <- glm(high_income ~ bachelor + ln_age + female + employed,
                    family = binomial(link = "logit"),
                    data = acs)

beta1hat <- logit_model2$coefficients["bachelor"]
beta2hat <- logit_model2$coefficients["ln_age"]
odds_ratio_bachelor_income <- exp(beta1hat)
odds_ratio_age_10pct <- exp(beta2hat * log(1.10))

acs_table <- rbind(
  glm_table(logit_model, "ACS高收入：单变量logit"),
  glm_table(logit_model2, "ACS高收入：多变量logit")
)
write.csv(acs_table,
          file.path(table_dir, "chapter09_acs_high_income_logit_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

write.csv(acs[, c("age", "female", "employed", "bachelor",
                  "personal_income", "high_income", "ln_age")],
          file.path(result_dir, "chapter09_acs_high_income_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

age_grid <- seq(25, 64, length.out = 100)
pred_no_ba <- predict(logit_model2, newdata = data.frame(
  bachelor = 0,
  ln_age = log(age_grid),
  female = 0,
  employed = 1
), type = "response")
pred_ba <- predict(logit_model2, newdata = data.frame(
  bachelor = 1,
  ln_age = log(age_grid),
  female = 0,
  employed = 1
), type = "response")

open_png("chapter09_acs_high_income_probability.png")
plot(age_grid, pred_no_ba, type = "l", lwd = 2.5, col = "#2166AC",
     ylim = range(c(pred_no_ba, pred_ba)),
     xlab = "年龄",
     ylab = "预测为高收入的概率",
     main = "ACS 加州样本：学历与高收入概率")
lines(age_grid, pred_ba, lwd = 2.5, col = "#D73027")
legend("topleft", legend = c("非本科及以上", "本科及以上"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, bty = "n")
dev.off()

z_grid <- seq(-6, 6, length.out = 400)
link_df <- data.frame(
  z = z_grid,
  logistic = plogis(z_grid),
  probit = pnorm(z_grid),
  linear = pmin(pmax(0.5 + z_grid / 6, 0), 1)
)
write.csv(link_df,
          file.path(result_dir, "chapter09_link_function_grid.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter09_link_functions.png")
plot(z_grid, plogis(z_grid), type = "l", lwd = 2.5, col = "#2166AC",
     ylim = c(0, 1),
     xlab = "线性指数 z = X'beta",
     ylab = "概率",
     main = "logit 与 probit 的 S 形概率变换")
lines(z_grid, pnorm(z_grid), lwd = 2.5, col = "#D73027", lty = 2)
abline(h = c(0, 1), col = "gray70", lty = 3)
legend("topleft", legend = c("logit: Lambda(z)", "probit: Phi(z)"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, lty = c(1, 2), bty = "n")
dev.off()

# ------------------------------------------------------------------------------
# Box 09--20: 信用卡违约概率的例子
# ------------------------------------------------------------------------------

credit <- read.csv(credit_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
names(credit) <- gsub("^\ufeff", "", names(credit))
credit$default <- credit$default_payment_next_month
credit$pay_delay <- credit$pay_0
credit$male <- ifelse(credit$sex == 1, 1, 0)
credit$limit_bal_10k <- credit$limit_bal / 10000
credit$bill_ratio <- ifelse(credit$limit_bal > 0, credit$bill_amt1 / credit$limit_bal, NA)
credit <- credit[complete.cases(credit[, c("default", "pay_delay", "male",
                                           "age", "limit_bal_10k", "bill_ratio")]), ]

logit_default1 <- glm(default ~ pay_delay,
                      family = binomial(link = "logit"),
                      data = credit)
logit_default2 <- glm(default ~ pay_delay + male + age + limit_bal_10k,
                      family = binomial(link = "logit"),
                      data = credit)
probit_default2 <- glm(default ~ pay_delay + male + age + limit_bal_10k,
                       family = binomial(link = "probit"),
                       data = credit)
lpm_default2 <- lm(default ~ pay_delay + male + age + limit_bal_10k,
                   data = credit)
credit$pred_lpm <- predict(lpm_default2)

default_logit_table <- rbind(
  glm_table(logit_default1, "违约：单变量logit"),
  glm_table(logit_default2, "违约：多变量logit"),
  glm_table(probit_default2, "违约：多变量probit")
)
write.csv(default_logit_table,
          file.path(table_dir, "chapter09_credit_logit_probit_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

lpm_table <- lm_table(lpm_default2, "违约：LPM")
write.csv(lpm_table,
          file.path(table_dir, "chapter09_credit_lpm_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

lpm_range <- data.frame(
  指标 = c("LPM最小预测值", "LPM最大预测值", "小于0比例", "大于1比例"),
  数值 = c(min(credit$pred_lpm), max(credit$pred_lpm),
         mean(credit$pred_lpm < 0), mean(credit$pred_lpm > 1))
)
write.csv(lpm_range,
          file.path(result_dir, "chapter09_lpm_prediction_range.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

sum_logit_model <- summary(logit_default1)$coefficients
beta_1_hat <- sum_logit_model["pay_delay", "Estimate"]
se_beta_1_hat <- sum_logit_model["pay_delay", "Std. Error"]
std_dev_pay_delay <- sd(credit$pay_delay)
alpha <- .05
zstat <- qnorm(1 - alpha / 2)
lb_beta_1_hat <- beta_1_hat - zstat * se_beta_1_hat
ub_beta_1_hat <- beta_1_hat + zstat * se_beta_1_hat
lb_odds_ratio <- exp(lb_beta_1_hat * std_dev_pay_delay)
ub_odds_ratio <- exp(ub_beta_1_hat * std_dev_pay_delay)

sum_logit_model2 <- summary(logit_default2)$coefficients
beta_1_hat_b <- sum_logit_model2["pay_delay", "Estimate"]
beta_2_hat_b <- sum_logit_model2["male", "Estimate"]
beta_3_hat_b <- sum_logit_model2["age", "Estimate"]
beta_4_hat_b <- sum_logit_model2["limit_bal_10k", "Estimate"]
std_dev_age <- sd(credit$age)
std_dev_limit <- sd(credit$limit_bal_10k)

beta_hat_b <- sum_logit_model2[, "Estimate"][c("pay_delay", "male",
                                               "age", "limit_bal_10k")]
increases <- c(std_dev_pay_delay, 1, std_dev_age, std_dev_limit)
odds_ratios <- exp(beta_hat_b * increases)

odds_table <- data.frame(
  变量 = c("还款状态增加1个标准差", "男性", "年龄增加1个标准差",
         "额度增加1个标准差", "单变量模型：还款状态OR下限",
         "单变量模型：还款状态OR上限"),
  赔率比 = c(odds_ratios, lb_odds_ratio, ub_odds_ratio)
)
write.csv(odds_table,
          file.path(result_dir, "chapter09_credit_odds_ratios.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

pred_default_manual <- 1 / (1 + exp(-(
  coef(logit_default2)["(Intercept)"] +
    beta_1_hat_b * 2 +
    beta_2_hat_b * 1 +
    beta_3_hat_b * 35 +
    beta_4_hat_b * 5
)))
pred_default <- predict(logit_default2,
                        data.frame(pay_delay = 2, male = 1,
                                   age = 35, limit_bal_10k = 5),
                        type = "response")

credit$pred <- predict(logit_default2, type = "response")

credit_incr_pay <- credit
credit_incr_pay$pay_delay <- credit_incr_pay$pay_delay + std_dev_pay_delay
credit_incr_pay$pred <- predict(logit_default2, newdata = credit_incr_pay,
                                type = "response")
credit$risk_ratio_pay_delay <- credit_incr_pay$pred / credit$pred
credit$risk_diff_pay_delay <- credit_incr_pay$pred - credit$pred
GRR_pay_delay <- mean(credit$risk_ratio_pay_delay)
GRD_pay_delay <- mean(credit$risk_diff_pay_delay)

credit_incr_age <- credit
credit_incr_age$age <- credit_incr_age$age + std_dev_age
credit_incr_age$pred <- predict(logit_default2, newdata = credit_incr_age,
                                type = "response")
credit$risk_ratio_age <- credit_incr_age$pred / credit$pred
credit$risk_diff_age <- credit_incr_age$pred - credit$pred
GRR_age <- mean(credit$risk_ratio_age)
GRD_age <- mean(credit$risk_diff_age)

credit_female <- credit
credit_female$male <- 0
credit_male <- credit
credit_male$male <- 1
credit_female$pred <- predict(logit_default2, newdata = credit_female,
                              type = "response")
credit_male$pred <- predict(logit_default2, newdata = credit_male,
                            type = "response")
credit$risk_ratio_male <- credit_male$pred / credit_female$pred
credit$risk_diff_male <- credit_male$pred - credit_female$pred
GRR_male <- mean(credit$risk_ratio_male)
GRD_male <- mean(credit$risk_diff_male)

risk_effects <- data.frame(
  变量 = c("还款状态增加1个标准差", "年龄增加1个标准差", "男性相对女性"),
  平均风险比 = c(GRR_pay_delay, GRR_age, GRR_male),
  平均风险差 = c(GRD_pay_delay, GRD_age, GRD_male)
)
write.csv(risk_effects,
          file.path(result_dir, "chapter09_credit_risk_effects.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

profile_base <- data.frame(
  pay_delay = c(0, 1, 2),
  male = 1,
  age = 35,
  limit_bal_10k = 5
)
profile_base$预测概率 <- predict(logit_default2, newdata = profile_base,
                              type = "response")
profile_base$赔率 <- profile_base$预测概率 / (1 - profile_base$预测概率)
write.csv(profile_base,
          file.path(result_dir, "chapter09_profile_prediction_table.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

write.csv(credit[, c("default", "pay_delay", "male", "age", "limit_bal_10k",
                     "bill_ratio", "pred", "pred_lpm")],
          file.path(result_dir, "chapter09_credit_default_analysis_data.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

delay_grid <- seq(min(credit$pay_delay), max(credit$pay_delay), length.out = 100)
pred_female <- predict(logit_default2, newdata = data.frame(
  pay_delay = delay_grid,
  male = 0,
  age = median(credit$age),
  limit_bal_10k = median(credit$limit_bal_10k)
), type = "response")
pred_male <- predict(logit_default2, newdata = data.frame(
  pay_delay = delay_grid,
  male = 1,
  age = median(credit$age),
  limit_bal_10k = median(credit$limit_bal_10k)
), type = "response")

open_png("chapter09_credit_default_probability.png")
plot(delay_grid, pred_female, type = "l", lwd = 2.5, col = "#2166AC",
     ylim = range(c(pred_female, pred_male)),
     xlab = "最近一期还款状态",
     ylab = "预测违约概率",
     main = "UCI 信用卡数据：还款状态与违约概率")
lines(delay_grid, pred_male, lwd = 2.5, col = "#D73027")
legend("topleft", legend = c("女性", "男性"),
       col = c("#2166AC", "#D73027"), lwd = 2.5, bty = "n")
dev.off()

open_png("chapter09_credit_predicted_probability_hist.png")
hist(credit$pred, breaks = 40, col = "#9ECAE1", border = "white",
     xlab = "预测违约概率",
     ylab = "频数",
     main = "多变量 logit 的预测概率分布")
dev.off()

open_png("chapter09_lpm_out_of_range.png")
plot(credit$pred_lpm, credit$pred,
     pch = 16, col = rgb(0.2, 0.2, 0.2, 0.25),
     xlab = "LPM 预测值",
     ylab = "logit 预测概率",
     main = "LPM 与 logit 预测概率比较")
abline(v = c(0, 1), col = "#C0392B", lty = 2, lwd = 2)
abline(0, 1, col = "#2166AC", lwd = 2)
legend("topleft", legend = c("45度线", "概率边界"),
       col = c("#2166AC", "#C0392B"), lwd = 2, lty = c(1, 2), bty = "n")
dev.off()

beta_grid <- seq(beta_1_hat - 1.5, beta_1_hat + 1.5, length.out = 250)
intercept_hat <- coef(logit_default1)["(Intercept)"]
ll_grid <- vapply(beta_grid, function(b) {
  p <- plogis(intercept_hat + b * credit$pay_delay)
  sum(credit$default * log(p) + (1 - credit$default) * log(1 - p))
}, numeric(1))
likelihood_profile <- data.frame(beta_pay_delay = beta_grid,
                                 log_likelihood = ll_grid)
write.csv(likelihood_profile,
          file.path(result_dir, "chapter09_likelihood_profile.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

open_png("chapter09_log_likelihood_profile.png")
plot(beta_grid, ll_grid, type = "l", lwd = 2.5, col = "#2166AC",
     xlab = "还款状态系数 beta",
     ylab = "对数似然",
     main = "单变量 logit 的对数似然剖面")
abline(v = beta_1_hat, col = "#C0392B", lwd = 2, lty = 2)
text(beta_1_hat, max(ll_grid), labels = "MLE", pos = 4, col = "#C0392B")
dev.off()

comparison <- data.frame(
  模型 = c("LPM", "logit", "probit"),
  样本量 = c(nobs(lpm_default2), nobs(logit_default2), nobs(probit_default2)),
  pay_delay系数 = c(coef(lpm_default2)["pay_delay"],
                  coef(logit_default2)["pay_delay"],
                  coef(probit_default2)["pay_delay"]),
  AIC = c(AIC(lpm_default2), AIC(logit_default2), AIC(probit_default2))
)
write.csv(comparison,
          file.path(table_dir, "chapter09_binary_model_comparison.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

summary_table <- data.frame(
  指标 = c("ACS样本量", "ACS高收入阈值", "ACS本科高收入赔率比",
         "信用卡样本量", "违约率", "还款状态赔率比",
         "男性赔率比", "给定画像预测违约概率", "手算预测违约概率",
         "还款状态平均风险差"),
  数值 = c(nrow(acs), highest_quartile_limit, odds_ratio_bachelor_income,
         nrow(credit), mean(credit$default), odds_ratios["pay_delay"],
         odds_ratios["male"], pred_default, pred_default_manual, GRD_pay_delay)
)
write.csv(summary_table,
          file.path(result_dir, "chapter09_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

cat("Chapter 09 finished.\n")
cat("ACS sample size:", nrow(acs), "\n")
cat("Credit sample size:", nrow(credit), "\n")
cat("Default rate:", round(mean(credit$default), 4), "\n")
cat("Predicted default probability:", round(pred_default, 4), "\n")
