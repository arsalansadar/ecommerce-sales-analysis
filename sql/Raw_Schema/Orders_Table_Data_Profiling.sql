use Olist_Raw_Data;

-- 1. Grain & key check (expected: teeno 99441)
select COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS distinct_orders,
       COUNT(DISTINCT customer_id) AS distinct_customers
from olist_orders_dataset;

-- 2. Missing values (NULL aur '' dono count karo)
select 
   SUM(case when nullif(order_approved_at, '') is null then 1 else 0 end) as approved_missing,
   SUM(case when nullif(order_delivered_carrier_date, '') is null then 1 else 0 end) as carrier_missing,
   SUM(case when nullif(order_delivered_customer_date, '') is null then 1 else 0 end) as customer_missing
from olist_orders_dataset;

-- 3. Status distribution
select order_status, COUNT(*) as orders,
CAST(100.0 * COUNT(*) / SUM(COUNT(*)) over() as decimal(5,2)) as pct
from olist_orders_dataset
group by order_status order by orders desc;

-- 4. Date range + unparseable dates
select MIN(try_cast(order_purchase_timestamp as datetime2)) as first_order,
       MAX(try_cast(order_purchase_timestamp as datetime2)) as last_order,
       SUM(case when nullif(order_purchase_timestamp,'') is not null
                 and try_cast(order_purchase_timestamp as datetime2) is null
                THEN 1 ELSE 0 END) as unparseable
from olist_orders_dataset;

-- 5. Date logic anomalies
SELECT
  SUM(CASE WHEN TRY_CAST(order_delivered_customer_date AS datetime2)
                < TRY_CAST(order_purchase_timestamp AS datetime2) THEN 1 ELSE 0 END) AS delivered_before_purchase,
  SUM(CASE WHEN TRY_CAST(order_delivered_customer_date AS datetime2)
                < TRY_CAST(order_delivered_carrier_date AS datetime2) THEN 1 ELSE 0 END) AS delivered_before_carrier,
  SUM(CASE WHEN order_status = 'delivered'
                AND NULLIF(order_delivered_customer_date,'') IS NULL THEN 1 ELSE 0 END) AS delivered_without_date
FROM olist_orders_dataset;

-- 6. Orphan checks
SELECT
  (SELECT COUNT(*) FROM olist_orders_dataset o
     LEFT JOIN olist_customers_dataset c ON c.customer_id = o.customer_id
     WHERE c.customer_id IS NULL) AS orders_without_customer,
  (SELECT COUNT(*) FROM olist_orders_dataset o
     LEFT JOIN olist_order_items_dataset i ON i.order_id = o.order_id
     WHERE i.order_id IS NULL) AS orders_without_items;


-- Follow-up query
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM olist_orders_dataset o
LEFT JOIN olist_order_items_dataset i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;