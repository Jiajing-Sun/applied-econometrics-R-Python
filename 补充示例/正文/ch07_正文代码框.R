# 正文代码框顺序运行；扩展数据凡带“模拟”均非真实调查记录。
args <- commandArgs(trailingOnly=FALSE)
file_arg <- args[grepl("^--file=",args)]
script_dir <- if(length(file_arg)) dirname(normalizePath(gsub("~+~"," ",sub("^--file=","",file_arg[1]),fixed=TRUE))) else getwd()
repo_dir <- normalizePath(file.path(script_dir,"..",".."))
setwd(repo_dir)
library(sandwich)
library(lmtest)
set.seed(922)


# 代码框 1: book_chapters/ch07_nonlinear.tex:128 / ch07_nonlinear_0
data_path <- file.path("Chapter07_Nonlinear_functional_form",
                       "results", "chapter07_wdi_owid_income_co2_analysis_data.csv")
df <- read.csv(data_path, fileEncoding="UTF-8-BOM")
quad_model <- lm(co2_pc_tonnes ~ log_gdp_pc + I(log_gdp_pc^2), data = df)
grid <- quantile(df$log_gdp_pc, c(.25, .50, .75))
coef(quad_model)[2] + 2 * coef(quad_model)[3] * grid


# 代码框 2: book_chapters/ch07_nonlinear.tex:331 / ch07_nonlinear_2
library(sandwich)
library(lmtest)
mod_log <- lm(log(co2_pc_tonnes) ~ log_gdp_pc, data = df)
coeftest(mod_log, vcov = vcovHC(mod_log, type = "HC0"))


# 代码框 3: book_chapters/ch07_nonlinear.tex:484 / ch07_cont_interact_r
# 中心化
df$lgdp_c <- df$log_gdp_pc - mean(df$log_gdp_pc)
df$trade_c <- df$trade_pct_gdp - mean(df$trade_pct_gdp)

# 估计含交互项模型
mod_int <- lm(co2_pc_tonnes ~ lgdp_c * trade_c, data = df)
library(sandwich); library(lmtest)
coeftest(mod_int, vcov = vcovHC(mod_int, type = "HC0"))

# 在贸易开放度三个百分位处计算收入边际效应
q_trade <- quantile(df$trade_c, c(0.1, 0.5, 0.9))
b1 <- coef(mod_int)["lgdp_c"]
b3 <- coef(mod_int)["lgdp_c:trade_c"]
me_at_q <- b1 + b3 * q_trade
print(me_at_q)

# 边际效应置信区间（delta 法）
V <- vcovHC(mod_int, type = "HC0")
for (q in q_trade) {
  grad <- c(0, 1, 0, q)  # 对 (截距, lgdp_c, trade_c, 交互项) 的梯度
  se_me <- sqrt(t(grad) %*% V %*% grad)
  me <- b1 + b3*q
  crit <- qt(.975, df.residual(mod_int))
  print(c(ME=me, SE=se_me, lower=me-crit*se_me, upper=me+crit*se_me))
}


# 代码框 4: book_chapters/ch07_nonlinear.tex:576 / ch07_kink_r
# 单折点线性样条，折点 c = 8.5
c1 <- 8.5
df$kink1 <- pmax(df$log_gdp_pc - c1, 0)

mod_kink <- lm(co2_pc_tonnes ~ log_gdp_pc + kink1, data = df)
coeftest(mod_kink, vcov = vcovHC(mod_kink, type = "HC0"))
# log_gdp_pc 系数 = 折点前斜率
# kink1 系数    = 折点后的斜率增量

# 两折点样条
c2 <- 10.0
df$kink2 <- pmax(df$log_gdp_pc - c2, 0)
mod_kink2 <- lm(co2_pc_tonnes ~ log_gdp_pc + kink1 + kink2, data = df)

# 画出分段拟合曲线
grid <- data.frame(log_gdp_pc = seq(6.0, 11.5, by=0.05))
grid$kink1 <- pmax(grid$log_gdp_pc - c1, 0)
grid$pred  <- predict(mod_kink, newdata=grid)


# 代码框 5: book_chapters/ch07_nonlinear.tex:690 / ch07_me_r
mod_quad <- lm(co2_pc_tonnes ~ log_gdp_pc + I(log_gdp_pc^2), data=df)
V <- sandwich::vcovHC(mod_quad, type="HC0")
points <- c(AME=mean(df$log_gdp_pc),
            quantile(df$log_gdp_pc, c(.25, .50, .75)))
crit <- qt(.975, df.residual(mod_quad))
for (q in points) {
  grad <- c(0, 1, 2*q)
  me <- sum(grad * coef(mod_quad))
  se <- sqrt(drop(t(grad) %*% V %*% grad))
  print(c(x=q, ME=me, SE=se, lower=me-crit*se, upper=me+crit*se))
}


# 代码框 6: book_chapters/ch07_nonlinear.tex:769 / ch07_nonlinear_10
grid <- data.frame(log_gdp_pc = seq(min(df$log_gdp_pc),
                                    max(df$log_gdp_pc),
                                    length.out = 100))
grid$pred_quad <- predict(quad_model, newdata = grid)
grid$pred_log  <- exp(predict(mod_log, newdata = grid))
