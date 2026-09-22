# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
from io import StringIO
import requests
import pandas as pd

url = ("https://sdmx.oecd.org/public/rest/data/"
       "OECD.SDD.STES,DSD_STES@DF_CLI/.M.LI...AA...H")
params = {"startPeriod": "2023-02", "endPeriod": "2023-04",
          "dimensionAtObservation": "AllDimensions",
          "format": "csvfilewithlabels"}
resp = requests.get(url, params=params, timeout=60)
resp.raise_for_status()
df_oecd = pd.read_csv(StringIO(resp.text))
assert not df_oecd.empty
print(df_oecd.head())
