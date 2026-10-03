use Olist_Raw_Data;

SELECT AVG(CAST(review_score AS FLOAT)) FROM fact_orders;


WITH valid_orders AS (
    SELECT customer_key, order_id
    FROM fact_orders
    WHERE order_status NOT IN ('canceled','unavailable')
),
customer_order_counts AS (
    SELECT customer_key, COUNT(DISTINCT order_id) AS order_count
    FROM valid_orders
    GROUP BY customer_key
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    CAST(SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS repeat_pct
FROM customer_order_counts;