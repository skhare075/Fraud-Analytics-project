import json
import pandas as pd

with open("train_fraud_labels.json") as f:
    data = json.load(f)

target = data["target"]   # inner mapping

df = pd.DataFrame(
    list(target.items()),
    columns=["transaction_id", "fraud_label"]
)

df["transaction_id"] = df["transaction_id"].astype("int64")

df.to_csv("train_fraud_labels.csv", index=False)

print(df.head())
print(df.shape)