import pandas as pd   
from scipy import stats
from sqlalchemy import create_engine
from pathlib import Path 
import pyodbc 

# SQL Server connection
engine = create_engine(
    "mssql://DESKTOP-GVEVCJJ/Olist_Raw_Data"
    "?driver=ODBC+DRIVER+17+FOR+SQL+SERVER"
 "&trusted_connection=yes"
)

query = """
SELECT is_late, review_score
FROM fact_orders
WHERE order_status = 'delivered'
  AND review_score IS NOT NULL
  AND is_date_anomaly = 0
"""
df = pd.read_sql(query, engine)

on_time = df[df['is_late'] == 0]['review_score']
late = df[df['is_late'] == 1]['review_score']

print(f"On-time orders: {len(on_time)}, mean = {on_time.mean():.3f}")
print(f"Late orders: {len(late)}, mean = {late.mean():.3f}")

# One-tailed test: on-time > late
stat, p_value = stats.mannwhitneyu(on_time, late, alternative='greater')
print(f"\nMann-Whitney U statistic: {stat}")
print(f"P-value: {p_value}")

if p_value < 0.05:
    print("Result: Statistically significant. On-time orders have significantly higher review scores.")
else:
    print("Result: Not statistically significant.")