use Olist_Raw_Data;

-- SELLERS
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT seller_id) AS distinct_sellers,
       SUM(CASE WHEN NULLIF(seller_city,'') IS NULL THEN 1 ELSE 0 END) AS missing_city,
       SUM(CASE WHEN NULLIF(seller_state,'') IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM olist_sellers_dataset;

-- GEOLOCATION
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT geolocation_zip_code_prefix) AS distinct_zips,
       SUM(CASE WHEN geolocation_lat < -90 OR geolocation_lat > 90 THEN 1 ELSE 0 END) AS invalid_lat,
       SUM(CASE WHEN geolocation_lng < -180 OR geolocation_lng > 180 THEN 1 ELSE 0 END) AS invalid_lng
FROM olist_geolocation_dataset;

-- CATEGORY TRANSLATION
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT product_category_name) AS distinct_pt,
       COUNT(DISTINCT product_category_name_english) AS distinct_en
FROM product_category_name_translation;

CREATE VIEW vw_geolocation_clean AS
SELECT geolocation_zip_code_prefix AS zip_prefix,
       AVG(geolocation_lat) AS avg_lat,
       AVG(geolocation_lng) AS avg_lng,
       MAX(geolocation_city) AS city,
       MAX(geolocation_state) AS state
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;