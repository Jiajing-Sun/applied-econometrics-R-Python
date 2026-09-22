# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
library(httr2)
url <- paste0("https://sdmx.oecd.org/public/rest/data/",
              "OECD.SDD.STES,DSD_STES@DF_CLI/.M.LI...AA...H")
resp <- request(url) |>
  req_url_query(startPeriod = "2023-02", endPeriod = "2023-04",
                dimensionAtObservation = "AllDimensions",
                format = "csvfilewithlabels") |>
  req_timeout(60) |> req_perform()
cli <- read.csv(text = resp_body_string(resp), check.names = FALSE)
stopifnot(nrow(cli) > 0)
head(cli)
