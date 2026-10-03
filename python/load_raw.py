import pandas as pd 
from sqlalchemy import create_engine
from pathlib import Path 

# Folder containing CSV files
folder = Path(r"E:\Project\E-Commerce_Sales_Analytics\dataSet")

# SQL Server connection
engine = create_engine(
    "mssql://DESKTOP-GVEVCJJ/Olist_Raw_Data"
    "?driver=ODBC+DRIVER+17+FOR+SQL+SERVER"
 "&trusted_connection=yes"
)

# Get all CSV files
csv_files = folder.glob("*.csv")

for file in csv_files: 
    
    table_name = file.stem
    
    print(f"Loading : {file.name} -> dbo.{table_name}")
    
    df = pd.read_csv(file)
    
    df.to_sql(
        table_name,
        con=engine,
        schema="dbo",
        if_exists="replace",
        index=False,
        chunksize=5000
    )
    
    print(f"Completed: {table_name}")
    
print("All CSV files loaded successfully.")
