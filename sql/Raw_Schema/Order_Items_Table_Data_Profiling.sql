use Olist_Raw_Data;

select * from olist_order_items_dataset;

-- 1. Grain check: kya order_id + order_item_id unique combination hai?
select COUNT(*) as total_rows,
       COUNT(distinct order_id) as distinct_orders,
       COUNT(distinct CONCAT(order_id, '-', order_item_id)) as distinct_order_items
from olist_order_items_dataset;

-- 2. Multi-item orders kitne hain
select items_per_order, COUNT(*) as num_orders
from (
select order_id, COUNT(*) as items_per_order 
from olist_order_items_dataset 
group by order_id
)t
group by items_per_order
order by items_per_order
;

-- 3. Price & freight sanity check
SELECT
  MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price,
  MIN(freight_value) AS min_freight, MAX(freight_value) AS max_freight,AVG(freight_value) AS avg_freight,
  SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END) AS zero_or_negative_price,
  SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS negative_freight
FROM olist_order_items_dataset;

-- 4. Orphan checks (product & seller)
SELECT
  (SELECT COUNT(*) FROM olist_order_items_dataset i
     LEFT JOIN olist_products_dataset p ON p.product_id = i.product_id
     WHERE p.product_id IS NULL) AS items_without_product,
  (SELECT COUNT(*) FROM olist_order_items_dataset i
     LEFT JOIN olist_sellers_dataset s ON s.seller_id = i.seller_id
     WHERE s.seller_id IS NULL) AS items_without_seller; 

-- 5. shipping_limit_date parse check
SELECT
  SUM(CASE WHEN NULLIF(shipping_limit_date,'') IS NOT NULL
            AND TRY_CAST(shipping_limit_date AS datetime2) IS NULL
           THEN 1 ELSE 0 END) AS unparseable_dates
FROM olist_order_items_dataset;