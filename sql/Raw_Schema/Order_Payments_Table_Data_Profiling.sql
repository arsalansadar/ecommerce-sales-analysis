use Olist_Raw_Data;

-- 1. Grain check
select COUNT(*) as total_rows,
       COUNT(distinct order_id) as distinct_orders,
       COUNT(distinct CONCAT(order_id, '-', payment_sequential)) as distinct_payment_rows
from olist_order_payments_dataset;

-- 2. Payments per order
select payments_per_order, COUNT(*) as num_orders from
(select order_id, COUNT(*) as payments_per_order 
from olist_order_payments_dataset 
group by order_id
)t 
group by payments_per_order
order by payments_per_order
;

-- 3. Payment type distribution
SELECT payment_type, COUNT(*) AS rows_count,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY rows_count DESC;

-- 4. Value & installments sanity
SELECT
  MIN(payment_value) AS min_val, MAX(payment_value) AS max_val, AVG(payment_value) AS avg_val,
  SUM(CASE WHEN payment_value <= 0 THEN 1 ELSE 0 END) AS zero_or_negative,
  MIN(payment_installments) AS min_installments, MAX(payment_installments) AS max_installments,
  SUM(CASE WHEN payment_installments = 0 THEN 1 ELSE 0 END) AS zero_installments
FROM olist_order_payments_dataset;

-- 5. Orphan check
SELECT COUNT(*) AS payments_without_order
FROM olist_order_payments_dataset p
LEFT JOIN olist_orders_dataset o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;

--  query:1 follow-up
SELECT o.order_id, o.order_status, o.order_purchase_timestamp
FROM olist_orders_dataset o
LEFT JOIN olist_order_payments_dataset p ON p.order_id = o.order_id
WHERE p.order_id IS NULL;


--  query:4 follow-up
SELECT p.*
FROM olist_order_payments_dataset p
WHERE p.payment_value <= 0
ORDER BY p.order_id;


SELECT * FROM olist_order_payments_dataset WHERE payment_installments = 0;


SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value
FROM olist_order_payments_dataset
WHERE order_id IN (
  '00b1cb0320190ca0daa2c88b35206009',
  '45ed6e85398a87c253db47c2d9f48216',
  '4637ca194b6387e2d538dc89b124b0ee',
  '6ccb433e00daae1283ccc956189c82ae',
  '8bcbe01d44d147f901cd3192671144db',
  'b23878b3e8eb4d25a158f57d96331b18',
  'c8c528189310eaa44a745b8d9d26908b',
  'fa65dad1b0e818e3ccc5cb0e39231352'
)
ORDER BY order_id, payment_sequential;