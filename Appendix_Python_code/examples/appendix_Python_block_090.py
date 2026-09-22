# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 中国：人均 GDP 与预期寿命
china = wb.data.DataFrame(
    ["NY.GDP.PCAP.KD", "SP.DYN.LE00.IN"],
    "CHN",
    time=range(1990, 2023),
    index="time", columns="series", labels=False
).reset_index()

china["year"] = china["time"].str.replace("YR", "", regex=False).astype(int)
china = china.rename(columns={
    "NY.GDP.PCAP.KD": "gdppc",
    "SP.DYN.LE00.IN": "lifeexp"
})

china = china.sort_values("year")
print(china[["year", "gdppc", "lifeexp"]].head())

fig, axes = plt.subplots(1, 2, figsize=(10, 4))
axes[0].plot(china["year"], china["gdppc"])
axes[0].set_title("China: GDP per capita")
axes[0].set_xlabel("Year")
axes[0].set_ylabel("Constant 2015 USD")

axes[1].plot(china["year"], china["lifeexp"])
axes[1].set_title("China: life expectancy")
axes[1].set_xlabel("Year")
axes[1].set_ylabel("Years")

plt.tight_layout()
plt.show()
