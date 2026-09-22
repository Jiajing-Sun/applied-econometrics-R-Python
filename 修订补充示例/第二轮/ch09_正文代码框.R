# 正文代码框顺序运行；扩展数据凡带“模拟”均非真实调查记录。
args <- commandArgs(trailingOnly=FALSE)
file_arg <- args[grepl("^--file=",args)]
script_dir <- if(length(file_arg)) dirname(normalizePath(gsub("~+~"," ",sub("^--file=","",file_arg[1]),fixed=TRUE))) else getwd()
repo_dir <- normalizePath(file.path(script_dir,"..",".."))
local_lib <- file.path(repo_dir,"..",".R-library")
if(dir.exists(local_lib)) .libPaths(c(local_lib,.libPaths()))
setwd(repo_dir)
library(sandwich)
library(lmtest)
set.seed(922)
acs <- read.csv(file.path(repo_dir,"Chapter09_Binary_dependent_variable_ch_logit/results/chapter09_acs_high_income_analysis_data.csv"),fileEncoding="UTF-8-BOM")
credit <- read.csv(file.path(repo_dir,"Chapter09_Binary_dependent_variable_ch_logit/results/chapter09_credit_default_analysis_data.csv"),fileEncoding="UTF-8-BOM")
choice_df <- read.csv(file.path(repo_dir,"修订补充示例/第二轮/ch09_有序多项选择_模拟.csv"),fileEncoding="UTF-8-BOM")

# 代码框 1: {R 中估计线性概率模型}
data_path <- file.path("Chapter09_Binary_dependent_variable_ch_logit",
                       "results", "chapter09_credit_default_analysis_data.csv")
credit <- read.csv(data_path, fileEncoding="UTF-8-BOM")
lpm <- lm(default ~ pay_delay + male + age + limit_bal_10k,
          data = credit)
lmtest::coeftest(lpm, vcov. = sandwich::vcovHC(lpm, type="HC1"),
                 df = Inf)
range(predict(lpm))


# 代码框 2: {R 中 logit 模型}
acs <- read.csv("Chapter09_Binary_dependent_variable_ch_logit/results/chapter09_acs_high_income_analysis_data.csv", fileEncoding="UTF-8-BOM")
mod <- glm(high_income ~ bachelor + log(age) + female + employed,
           data = acs, family = binomial(link = "logit"))
exp(coef(mod))


# 代码框 3: {R 中计算平均边际效应}
mod_credit <- glm(default ~ pay_delay + male + age + limit_bal_10k,
                  data = credit, family = binomial(link = "logit"))
p0 <- predict(mod_credit, type = "response")
credit_hi <- credit
credit_hi$pay_delay <- credit_hi$pay_delay + sd(credit$pay_delay)
p1 <- predict(mod_credit, newdata = credit_hi, type = "response")
mean(p1 - p0)


# 代码框 4: {R 中从概率到分类}
phat <- predict(mod_credit, type = "response")
class_05 <- as.integer(phat >= 0.5)
table(predicted = class_05, observed = credit$default)
class_03 <- as.integer(phat >= 0.3)
table(predicted = class_03, observed = credit$default)


# 代码框 5: {R 中有序 logit 与多项 logit}
library(MASS)
choice_df <- read.csv("修订补充示例/第二轮/ch09_有序多项选择_模拟.csv")
# 有序 logit（比例赔率模型）
choice_df$edu_level <- ordered(choice_df$edu_level,
                               levels = c("低", "中", "高"))
fit_ord <- polr(edu_level ~ log_income + age, data = choice_df,
               method = "logistic", Hess = TRUE)
# 多项 logit
library(nnet)
fit_mnl <- multinom(transport ~ income + distance, data = choice_df)

