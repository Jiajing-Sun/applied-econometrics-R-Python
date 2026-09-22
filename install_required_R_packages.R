# 在自己的R环境中安装正文与离线附录使用的包；已安装的包保留。
# 实测版本另见 R-package-versions.csv，在线API扩展按附录另装。
packages <- c("ggplot2", "readr", "dplyr", "tidyr", "tibble", "purrr", "stringr",
              "sandwich", "lmtest", "plm", "nlme", "glmnet", "rpart", "ranger",
              "forecast", "tseries", "vars", "mgcv", "quadprog", "rdrobust",
              "rddensity", "survey", "MASS", "nnet", "httr2", "jsonlite", "writexl")
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
print(packages)

# 安装返回后检查实际可载入性，避免下载失败仍显示成功。
failed <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(failed)) stop("尚不能载入的包：", paste(failed, collapse = ", "))
cat("所有离线教学依赖均可载入。\n")
