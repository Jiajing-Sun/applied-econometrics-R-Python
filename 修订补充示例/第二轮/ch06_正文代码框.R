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
df <- read.csv(file.path(repo_dir,"Chapter06_Multiple_Linear_Regression/results/chapter06_bea_bls_state_analysis_data.csv"),fileEncoding="UTF-8-BOM")

# 代码框 1: {R 中多元回归}
data_path <- file.path("Chapter06_Multiple_Linear_Regression",
                       "results", "chapter06_bea_bls_state_analysis_data.csv")
df <- read.csv(data_path, fileEncoding="UTF-8-BOM")
mod_mid <- lm(income_pc_thousand ~ gdp_pc_thousand +
                unemployment_rate + large_state, data = df)
library(sandwich)
library(lmtest)
coeftest(mod_mid, vcov = vcovHC(mod_mid, type = "HC0"))

