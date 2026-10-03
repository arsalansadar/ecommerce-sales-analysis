-- 1. Grain check
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_id) AS distinct_products
FROM olist_products_dataset;

-- 2. Missing category & other nulls
SELECT
  SUM(CASE WHEN NULLIF(product_category_name,'') IS NULL THEN 1 ELSE 0 END) AS missing_category,
  SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS missing_weight,
  SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS missing_length,
  SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS missing_photos
FROM olist_products_dataset;

-- 3. Category translation coverage
SELECT COUNT(DISTINCT p.product_category_name) AS categories_in_products,
       COUNT(DISTINCT t.product_category_name) AS categories_in_translation,
       SUM(CASE WHEN t.product_category_name IS NULL
                 AND NULLIF(p.product_category_name,'') IS NOT NULL
                THEN 1 ELSE 0 END) AS products_missing_translation
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
  ON t.product_category_name = p.product_category_name;

-- 4. Sanity check on physical attributes
SELECT MIN(product_weight_g) AS min_weight, MAX(product_weight_g) AS max_weight,
       MIN(product_photos_qty) AS min_photos, MAX(product_photos_qty) AS max_photos
FROM olist_products_dataset;

-- 1. Confirm: same 610 rows missing both category & photos?
SELECT COUNT(*) AS overlap_count
FROM olist_products_dataset
WHERE NULLIF(product_category_name,'') IS NULL
  AND product_photos_qty IS NULL;

-- 2. Which 2 categories have no translation, and how many products each
SELECT p.product_category_name, COUNT(*) AS product_count
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
  ON t.product_category_name = p.product_category_name
WHERE t.product_category_name IS NULL
  AND NULLIF(p.product_category_name,'') IS NOT NULL
GROUP BY p.product_category_name;

-- 3. How many products have zero weight, and any other zero physical attributes
SELECT
  SUM(CASE WHEN product_weight_g = 0 THEN 1 ELSE 0 END) AS zero_weight,
  SUM(CASE WHEN product_length_cm = 0 THEN 1 ELSE 0 END) AS zero_length,
  SUM(CASE WHEN product_height_cm = 0 THEN 1 ELSE 0 END) AS zero_height,
  SUM(CASE WHEN product_width_cm = 0 THEN 1 ELSE 0 END) AS zero_width
FROM olist_products_dataset;

-- 4. The 2 rows with missing weight/length — check them fully
SELECT * FROM olist_products_dataset
WHERE product_weight_g IS NULL OR product_length_cm IS NULL;


SELECT COUNT(*) AS times_ordered
FROM olist_order_items_dataset
WHERE product_id = '5eb564652db742ff8f28759cd8d2652a';