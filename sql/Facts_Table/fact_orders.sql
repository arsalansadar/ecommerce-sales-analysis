use Olist_Raw_Data;


CREATE VIEW fact_orders AS
WITH item_summary AS (
    SELECT order_id, 
           SUM(item_total) AS order_total_value, 
           COUNT(*) AS num_items
    FROM clean.order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT order_id, 
           SUM(payment_value) AS total_payment_value, 
           MAX(payment_installments) AS max_installments
    FROM clean.order_payments
    GROUP BY order_id
),
payment_primary AS (
    SELECT order_id, payment_type AS primary_payment_type
    FROM (
        SELECT order_id, payment_type,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY payment_value DESC) AS rn
        FROM clean.order_payments
    ) ranked
    WHERE rn = 1
)
SELECT
    o.order_id,
    ISNULL(dc.customer_key, -1) AS customer_key,
    CAST(FORMAT(o.order_purchase_ts, 'yyyyMMdd') AS INT)      AS purchase_date_key,
    CAST(FORMAT(o.delivered_customer_ts, 'yyyyMMdd') AS INT)  AS delivery_date_key,
    o.order_status,
    o.delivery_days,
    o.is_late,
    o.is_date_anomaly,
    r.review_score,
    ISNULL(item_summary.order_total_value, 0) AS order_total_value,
    ISNULL(item_summary.num_items, 0)         AS num_items,
    ISNULL(payment_summary.total_payment_value, 0) AS total_payment_value,
    payment_primary.primary_payment_type,
    ISNULL(payment_summary.max_installments, 1) AS max_installments
FROM clean.orders o
LEFT JOIN clean.customers c ON c.customer_id = o.customer_id
LEFT JOIN dim_customer dc ON dc.customer_unique_id = c.customer_unique_id
LEFT JOIN clean.order_reviews r ON r.order_id = o.order_id
LEFT JOIN item_summary ON item_summary.order_id = o.order_id
LEFT JOIN payment_summary ON payment_summary.order_id = o.order_id
LEFT JOIN payment_primary ON payment_primary.order_id = o.order_id;

-- drop view fact_orders;

SELECT SUM(order_total_value) FROM fact_orders;
SELECT SUM(item_total) FROM clean.order_items;

SELECT COUNT(*) FROM fact_orders WHERE customer_key = -1;

-- fact_order_items grain check
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CONCAT(order_id,'-',order_item_id)) AS distinct_combo
FROM fact_order_items;
-- dono barabar hone chahiye (112,650)

-- Orphan check on dimensions
SELECT
  SUM(CASE WHEN product_key = -1 THEN 1 ELSE 0 END) AS unknown_products,
  SUM(CASE WHEN seller_key = -1 THEN 1 ELSE 0 END) AS unknown_sellers
FROM fact_order_items;
-- dono 0 expect karte hain (profiling mein referential integrity clean thi)


-- Alter fact_orders 
ALTER VIEW clean.orders AS
SELECT
    order_id, customer_id, order_status,
    TRY_CAST(order_purchase_timestamp AS DATETIME2)      AS order_purchase_ts,
    TRY_CAST(order_approved_at AS DATETIME2)             AS order_approved_ts,
    TRY_CAST(order_delivered_carrier_date AS DATETIME2)  AS delivered_carrier_ts,
    TRY_CAST(order_delivered_customer_date AS DATETIME2) AS delivered_customer_ts,
    TRY_CAST(order_estimated_delivery_date AS DATETIME2) AS estimated_delivery_ts,
    CASE WHEN TRY_CAST(order_delivered_customer_date AS DATETIME2)
              < TRY_CAST(order_delivered_carrier_date AS DATETIME2)
         THEN 1 ELSE 0 END AS is_date_anomaly,
    CASE WHEN order_status = 'delivered'
              AND NULLIF(order_delivered_customer_date,'') IS NULL
         THEN 1 ELSE 0 END AS is_delivered_missing_date,
    DATEDIFF(DAY, TRY_CAST(order_purchase_timestamp AS DATETIME2),
                  TRY_CAST(order_delivered_customer_date AS DATETIME2)) AS delivery_days,
    DATEDIFF(DAY, TRY_CAST(order_estimated_delivery_date AS DATETIME2),
                  TRY_CAST(order_delivered_customer_date AS DATETIME2)) AS delay_days,
    CASE WHEN DATEDIFF(DAY, TRY_CAST(order_estimated_delivery_date AS DATETIME2),
                            TRY_CAST(order_delivered_customer_date AS DATETIME2)) > 0
         THEN 1 ELSE 0 END AS is_late          -- ✅ ab delay_days > 0 se derive ho raha hai
FROM olist_orders_dataset;

-- Sanity check dobara
SELECT
    SUM(CASE WHEN is_late = 1 AND delay_days <= 0 THEN 1 ELSE 0 END) AS inconsistent_late,
    SUM(CASE WHEN is_late = 0 AND delay_days > 0 THEN 1 ELSE 0 END) AS inconsistent_ontime
FROM fact_orders
WHERE order_status = 'delivered' AND is_date_anomaly = 0;