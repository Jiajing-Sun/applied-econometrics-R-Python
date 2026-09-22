# 仅语法核查；未联网执行。依赖按附录API小节顺序建立的对象。
# 如有需要：
# python -m pip install eurostatapiclient pandas

from eurostatapiclient import EurostatAPIClient

client = EurostatAPIClient("1.0", "json", "en")

# 获取数据集并转换为 DataFrame
dataset = client.get_dataset("tps00001")
df_eurostat = dataset.to_dataframe()
print(df_eurostat.head())

# 筛选请求（示例：仅德国）
params = {"geo": "DE"}
dataset_de = client.get_dataset("tps00001", params=params)
df_de = dataset_de.to_dataframe()
print(df_de.head())
