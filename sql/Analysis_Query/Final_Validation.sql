use Olist_Raw_Data;

SELECT 'All orders - price+freight (all statuses)' AS metric,
       CAST(SUM(order_total_value) AS DECIMAL(14,2)) AS value
FROM fact_orders

UNION ALL
SELECT 'All order items - price only (all statuses)',
       CAST(SUM(price) AS DECIMAL(14,2)) FROM fact_order_items  -- (syntax fix neeche)

UNION ALL
SELECT 'Valid orders (excl canceled/unavailable) - price only',
       CAST((SELECT SUM(foi.price)
             FROM fact_order_items foi
             JOIN fact_orders fo ON fo.order_id = foi.order_id
             WHERE fo.order_status NOT IN ('canceled','unavailable')) AS DECIMAL(14,2))

UNION ALL
SELECT 'Delivered orders - count',
       CAST((SELECT COUNT(*) FROM fact_orders WHERE order_status = 'delivered') AS DECIMAL(14,2))

UNION ALL
SELECT 'Delivered + reviewed + anomaly-free - count',
       CAST((SELECT COUNT(*) FROM fact_orders
             WHERE order_status='delivered' AND review_score IS NOT NULL AND is_date_anomaly=0) AS DECIMAL(14,2))

UNION ALL
SELECT 'Valid orders (excl canceled/unavailable) - count',
       CAST((SELECT COUNT(*) FROM fact_orders WHERE order_status NOT IN ('canceled','unavailable')) AS DECIMAL(14,2))

UNION ALL
SELECT 'Unique customers (RFM base)',
       CAST((SELECT COUNT(*) FROM vw_rfm_base) AS DECIMAL(14,2));


SELECT
  (SELECT COUNT(*) FROM fact_orders WHERE customer_key = -1)      AS fact_orders_unknown_customer,
  (SELECT COUNT(*) FROM fact_order_items WHERE product_key = -1)  AS items_unknown_product,
  (SELECT COUNT(*) FROM fact_order_items WHERE seller_key = -1)   AS items_unknown_seller;



SELECT COUNT(*) AS orphan_purchase_dates
FROM fact_orders fo
LEFT JOIN dim_date dd ON dd.date_key = fo.purchase_date_key
WHERE dd.date_key IS NULL;

SELECT COUNT(*) AS orphan_delivery_dates
FROM fact_orders fo
LEFT JOIN dim_date dd ON dd.date_key = fo.delivery_date_key
WHERE fo.delivery_date_key IS NOT NULL
  AND dd.date_key IS NULL;