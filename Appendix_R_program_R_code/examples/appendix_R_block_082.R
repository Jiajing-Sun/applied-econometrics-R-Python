# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 中国：人均 GDP 与预期寿命
china <- WDI(
  country = "CHN",
  indicator = c(
    gdppc = "NY.GDP.PCAP.KD",
    lifeexp = "SP.DYN.LE00.IN"
  ),
  start = 1990,
  end = 2022
)

china <- china[order(china$year), ]
head(china)

par(mfrow = c(1, 2))
plot(china$year, china$gdppc, type = "l",
     xlab = "Year", ylab = "Constant 2015 USD",
     main = "China: GDP per capita")
plot(china$year, china$lifeexp, type = "l",
     xlab = "Year", ylab = "Years",
     main = "China: life expectancy")
par(mfrow = c(1, 1))
