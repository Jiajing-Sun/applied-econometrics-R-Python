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
df <- read.csv(file.path(repo_dir,"修订补充示例/第二轮/ch08_调查加权_模拟.csv"),fileEncoding="UTF-8-BOM")

# 代码框 1: {R 中按家庭聚类标准误}
data_path <- file.path("Chapter08_Regression_analysis_with_dependent_error_terms_ch_reg_dep_error",
                       "results", "chapter08_acs_cluster_analysis_data.csv")
acs <- read.csv(data_path, fileEncoding="UTF-8-BOM")
mod <- lm(log_income ~ bachelor, data = acs)
library(sandwich)
library(lmtest)
V <- vcovCL(mod, cluster = acs$household_id, type = "HC0")
coeftest(mod, vcov. = V, df = length(unique(acs$household_id)) - 1)


# 代码框 2: [label=ch08_survey_r]{R 中调查加权回归（示意代码）}
library(survey)
# 模拟数据，仅展示分层与权重接口
df <- read.csv("修订补充示例/第二轮/ch08_调查加权_模拟.csv")

# 设定调查设计对象（df 中：weight 为个体抽样权重，stratum 为分层变量）
# 实际研究中：用调查数据的个体权重和地区列代入，或自构模拟权重
svy_design <- svydesign(ids = ~1,          # 无整群结构时 ~1
                        strata = ~stratum,
                        weights = ~weight,
                        data = df)

# 调查加权回归：标准误已使用分层设计修正
m_svy <- svyglm(income ~ educ + age + urban,
                design = svy_design)
summary(m_svy)   # Estimate 列是 \hat\beta_j；Std. Error 列是分层修正后 SE

# 与不加权 OLS 对比
m_ols <- lm(income ~ educ + age + urban, data = df)
# 比较两列系数与 SE：差异反映权重影响，不能单凭差异判定总体代表性

