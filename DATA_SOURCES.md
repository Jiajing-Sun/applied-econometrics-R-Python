# Data Sources

The teaching datasets in `data/processed/` are prepared from public sources.
See `data/data_license_inventory.csv` for source URLs, license or terms pages,
and redistribution notes.

Included datasets cover:

- World Bank WDI macro indicators.
- Our World in Data CO2 series.
- FAOSTAT agricultural panel data.
- BEA regional GDP and personal income.
- BLS unemployment and CPI series.
- EPA AirData annual county AQI data.
- ACS PUMS selected public-use microdata.
- UCI Default of Credit Card Clients.
- NHTSA FARS age 18--24 RD teaching sample.
- NBS 70-city house price statistical releases.

Generated `figures/`, `tables/`, and `results/` folders are not committed. They
are recreated by running the chapter scripts.

The larger raw NHTSA persons extract is not included because the current chapter
scripts use the smaller age 18--24 RD teaching sample.
