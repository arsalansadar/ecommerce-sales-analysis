use Olist_Raw_Data;

CREATE VIEW fact_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    ISNULL(dp.product_key, -1) AS product_key,
    ISNULL(ds.seller_key, -1)  AS seller_key,
    CAST(FORMAT(oi.shipping_limit_ts, 'yyyyMMdd') AS INT) AS shipping_date_key,
    oi.price,
    oi.freight_value,
    oi.item_total
FROM clean.order_items oi
LEFT JOIN dim_product dp ON dp.product_id = oi.product_id
LEFT JOIN dim_seller  ds ON ds.seller_id  = oi.seller_id;