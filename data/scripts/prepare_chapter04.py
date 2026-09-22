"""Rebuild the frozen chapter 4 sample from local files; no live API calls.
Run with Python >=3.10, numpy and pandas. By default verify existing output;
pass --write to regenerate the revision copy's CSV and excluded aggregates.
"""
from pathlib import Path
import json,sys
import numpy as np,pandas as pd
ROOT=Path(__file__).resolve().parents[1]
w=pd.read_csv(ROOT/'processed/wdi_global_selected_indicators_wide.csv')
m=json.loads((ROOT/'metadata/wb_country_metadata_20260922.json').read_text())[1]
m={a['id']:a for a in m}
w=w[(w.year==2024)&(w.gdp_per_capita_constant_2015_usd>0)&w.life_expectancy.notna()].copy()
assert len(w)==236
# FCS (Fragile and conflict affected situations) is an aggregate in the
# historical data but absent from the current country metadata endpoint.
manual_aggregates={'FCS'}
assert set(w.country_code)-set(m)<=manual_aggregates
agg=w.country_code.map(lambda c:c in manual_aggregates or m[c]['region']['id']=='NA')
excluded=w.loc[agg,['country','country_code','year']].copy()
excluded['reason']=excluded.country_code.map(lambda c:'historical FCS aggregate' if c in manual_aggregates else 'metadata region.id=NA')
d=w.loc[~agg,['country','country_code','year','gdp_per_capita_constant_2015_usd','life_expectancy','population']].copy()
d['log_gdp_per_capita']=np.log(d.gdp_per_capita_constant_2015_usd)
d['region']=d.country_code.map(lambda c:m[c]['region']['value'])
d['income_group']=d.country_code.map(lambda c:m[c]['incomeLevel']['value'])
d['log_gdp_pc']=d.log_gdp_per_capita
d=d[['country','country_code','year','gdp_per_capita_constant_2015_usd','life_expectancy','log_gdp_per_capita','population','region','income_group','log_gdp_pc']].reset_index(drop=True)
assert len(d)==192 and len(excluded)==44 and d.country_code.is_unique
out=ROOT/'processed/chapter04_wdi_life_gdp_2024_economies.csv'
if '--write' in sys.argv:
 d.to_csv(out,index=False)
 excluded.to_csv(ROOT/'metadata/chapter04_excluded_aggregates.csv',index=False)
else:
 old=pd.read_csv(out)
 pd.testing.assert_frame_equal(d.sort_values('country_code').reset_index(drop=True),old.sort_values('country_code').reset_index(drop=True),check_exact=False,rtol=1e-12,atol=1e-12)
 excluded.to_csv(ROOT/'metadata/chapter04_excluded_aggregates.csv',index=False)
print('Verified: 236 complete rows = 192 economies + 44 excluded aggregates.')
