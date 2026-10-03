-- 1. Grain check
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT review_id) AS distinct_review_ids,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM olist_order_reviews_dataset;

-- 2. Reviews per order distribution
SELECT reviews_per_order, COUNT(*) AS num_orders
FROM (
  SELECT order_id, COUNT(*) AS reviews_per_order
  FROM olist_order_reviews_dataset
  GROUP BY order_id
) t
GROUP BY reviews_per_order
ORDER BY reviews_per_order;

-- 3. Review score distribution
SELECT review_score, COUNT(*) AS num_reviews,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- 4. Comment fill rate
SELECT
  SUM(CASE WHEN NULLIF(review_comment_title,'') IS NOT NULL THEN 1 ELSE 0 END) AS has_title,
  SUM(CASE WHEN NULLIF(review_comment_message,'') IS NOT NULL THEN 1 ELSE 0 END) AS has_message,
  COUNT(*) AS total
FROM olist_order_reviews_dataset;

-- 5. Orphan check + date parse check
SELECT
  (SELECT COUNT(*) FROM olist_order_reviews_dataset r
     LEFT JOIN olist_orders_dataset o ON o.order_id = r.order_id
     WHERE o.order_id IS NULL) AS reviews_without_order,
  SUM(CASE WHEN NULLIF(review_creation_date,'') IS NOT NULL
            AND TRY_CAST(review_creation_date AS datetime2) IS NULL THEN 1 ELSE 0 END) AS unparseable_creation,
  SUM(CASE WHEN NULLIF(review_answer_timestamp,'') IS NOT NULL
            AND TRY_CAST(review_answer_timestamp AS datetime2) IS NULL THEN 1 ELSE 0 END) AS unparseable_answer
FROM olist_order_reviews_dataset;