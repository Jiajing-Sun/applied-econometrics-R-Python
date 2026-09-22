# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# install.packages("fredr")
library(fredr)

api_key <- Sys.getenv("FRED_API_KEY")
stopifnot(nzchar(api_key))  # 请先配置自己的密钥，不在书稿中填写
fredr_set_key(api_key)

# 示例序列：美国失业率（UNRATE）
unrate <- fredr(
  series_id = "UNRATE",
  observation_start = as.Date("2000-01-01")
)

head(unrate)
