# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)

# 示例：世界银行 API 端点（返回 JSON）
url <- paste0("https://api.worldbank.org/v2/country/CHN/indicator/",
              "NY.GDP.PCAP.KD")
resp <- request(url) |>
  req_url_query(format = "json", date = "1990:2024", per_page = 1000) |>
  req_timeout(30) |> req_perform()
txt  <- resp_body_string(resp)

obj <- fromJSON(txt)

# 数据通常位于第二个元素中
head(obj[[2]])
