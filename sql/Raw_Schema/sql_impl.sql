create database Olist_Raw_Data;

use Olist_Raw_Data;

-- List of table name in schema
SELECT name FROM sys.tables ORDER BY name;

--  Row counts per table
SELECT t.name AS table_name, SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p
  ON p.object_id = t.object_id AND p.index_id IN (0,1)
GROUP BY t.name
ORDER BY t.name;

--  Column data types
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

select * from dbo.olist_order_items_dataset;

select * from dbo.olist_orders_dataset;

select * from dbo.olist_customers_dataset;

select * from dbo.olist_sellers_dataset;

select * from dbo.olist_products_dataset;

select * from dbo.product_category_name_translation;

select * from dbo.olist_order_payments_dataset;

select * from dbo.olist_order_reviews_dataset;

select * from dbo.olist_geolocation_dataset;

