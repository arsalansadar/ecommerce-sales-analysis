use Olist_Raw_Data;

create schema clean;

create view clean.orders as
select 
    order_id,
    customer_id,
    order_status,
    TRY_CAST(order_purchase_timestamp as datetime2) as order_purchase_ts,
    TRY_CAST(order_approved_at as datetime2) as order_approved_ts,
    TRY_CAST(order_delivered_carrier_date as DATETIME2)  as delivered_carrier_ts,
    TRY_CAST(order_delivered_customer_date as DATETIME2) as delivered_customer_ts,
    TRY_CAST(order_estimated_delivery_date as DATETIME2) as estimated_delivery_ts,
    -- Flags (never delete, always flag)
    case when TRY_CAST(order_delivered_customer_date as DATETIME2)
              < TRY_CAST(order_delivered_carrier_date as DATETIME2)
         then 1 else 0 end as is_date_anomaly,
    case when order_status = 'delivered'
              AND NULLIF(order_delivered_customer_date,'') IS NULL
         then 1 else 0 end as is_delivered_missing_date,

    -- Derived fields, useful in almost every later query
    DATEDIFF(DAY,
        TRY_CAST(order_purchase_timestamp as DATETIME2),
        TRY_CAST(order_delivered_customer_date as DATETIME2)) as delivery_days,
    case when TRY_CAST(order_delivered_customer_date as DATETIME2)
              > TRY_CAST(order_estimated_delivery_date as DATETIME2)
         then 1 else 0 end as is_late
from olist_orders_dataset;


create view clean.order_items as
select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    TRY_CAST(shipping_limit_date as DATETIME2) as shipping_limit_ts,
    CAST(price as DECIMAL(12,2))          as price,
    CAST(freight_value as DECIMAL(12,2))  as freight_value,
    CAST(price + freight_value as DECIMAL(12,2)) as item_total
from olist_order_items_dataset;

create view clean.order_payments AS
select
    order_id,
    payment_sequential,
    case when payment_type = 'not_defined' then 'unknown' else payment_type end as payment_type,
    case when payment_installments = 0 then 1 else payment_installments end as payment_installments,
    CAST(payment_value as DECIMAL(12,2)) as payment_value,

    -- Flag, exclude nahi karte yahan
    case when payment_value <= 0 then 1 else 0 end as is_zero_value
from olist_order_payments_dataset;

create view clean.order_reviews AS
select
    order_id,
    review_score,
    TRY_CAST(review_creation_date as DATETIME2)     as review_created_ts,
    TRY_CAST(review_answer_timestamp as DATETIME2)  as review_answered_ts,
    case when NULLIF(review_comment_message,'') IS NOT NULL then 1 else 0 end as has_comment
from (
    select *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY TRY_CAST(review_creation_date as DATETIME2) DESC
        ) as rn
    from olist_order_reviews_dataset
) t
WHERE rn = 1;


create view clean.products as 
select
    product_id,
    COALESCE(NULLIF(product_category_name,''), 'unknown') as category_pt,
    CAST(product_photos_qty as INT)        as photos_qty,
    CAST(product_weight_g as INT)          as weight_g,
    CAST(product_length_cm as INT)         as length_cm,
    CAST(product_height_cm as INT)         as height_cm,
    CAST(product_width_cm as INT)          as width_cm,

    -- Flags
    case when NULLIF(product_category_name,'') IS NULL then 1 else 0 end as is_incomplete_listing,
    case when product_weight_g = 0 OR product_weight_g IS NULL then 1 else 0 end as is_invalid_weight
from olist_products_dataset;


-- Original table ko touch nahi karna, insert seedha usi mein karo
-- (chhoti reference table hai, isliye view ki zaroorat nahi — direct insert theek hai)
insert into product_category_name_translation (product_category_name, product_category_name_english)
values
    ('pc_gamer', 'Gaming PC'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'Portable Kitchen & Food Preparers');

create view clean.products_with_category AS
select
    p.*,
    COALESCE(t.product_category_name_english, 'Unknown') as category_en
from clean.products p
LEFT JOIN product_category_name_translation t
    ON t.product_category_name = p.category_pt;

create view clean.sellers AS
select
    seller_id,
    CAST(seller_zip_code_prefix as VARCHAR(5)) as zip_prefix,
    seller_city,
    seller_state
from olist_sellers_dataset;


create view clean.customers AS
select
    customer_id,
    customer_unique_id,
    CAST(customer_zip_code_prefix as VARCHAR(5)) as zip_prefix,
    customer_city,
    customer_state
from olist_customers_dataset;

create view clean.geolocation AS
select
    CAST(geolocation_zip_code_prefix as VARCHAR(5)) as zip_prefix,
    AVG(geolocation_lat) as avg_lat,
    AVG(geolocation_lng) as avg_lng,
    MAX(geolocation_city)  as city,
    MAX(geolocation_state) as state
from olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;

select customer_unique_id, COUNT(customer_id) 
from clean.customers group by customer_unique_id having COUNT(customer_id) >=2;

-- Row counts match ho rahe hain kya raw se?
select 'orders' as tbl, COUNT(*) from clean.orders
union all select 'order_items', COUNT(*) from clean.order_items
union all select 'order_payments', COUNT(*) from clean.order_payments
union all select 'order_reviews', COUNT(*) from clean.order_reviews  
union all select 'products', COUNT(*) from clean.products
union all select 'sellers', COUNT(*) from clean.sellers
union all select 'customers', COUNT(*) from clean.customers
union all select 'geolocation', COUNT(*) from clean.geolocation;  

-- alter clean.orders > clean.orders view mein add karna

alter view clean.orders as
select
    order_id, customer_id, order_status,
    TRY_CAST(order_purchase_timestamp as DATETIME2)      as order_purchase_ts,
    TRY_CAST(order_approved_at as DATETIME2)             as order_approved_ts,
    TRY_CAST(order_delivered_carrier_date as DATETIME2)  as delivered_carrier_ts,
    TRY_CAST(order_delivered_customer_date as DATETIME2) as delivered_customer_ts,
    TRY_CAST(order_estimated_delivery_date as DATETIME2) as estimated_delivery_ts,
    case when TRY_CAST(order_delivered_customer_date as DATETIME2)
              < TRY_CAST(order_delivered_carrier_date as DATETIME2)
         then 1 else 0 end as is_date_anomaly,
    case when order_status = 'delivered'
              AND NULLIF(order_delivered_customer_date,'') IS NULL
         then 1 else 0 end as is_delivered_missing_date,
    DATEDIFF(DAY, TRY_CAST(order_purchase_timestamp as DATETIME2),
                  TRY_CAST(order_delivered_customer_date as DATETIME2)) as delivery_days,
    DATEDIFF(DAY, TRY_CAST(order_estimated_delivery_date as DATETIME2),
                  TRY_CAST(order_delivered_customer_date as DATETIME2)) as delay_days,  -- NAYA COLUMN
    case when TRY_CAST(order_delivered_customer_date as DATETIME2)
              > TRY_CAST(order_estimated_delivery_date as DATETIME2)
         then 1 else 0 end as is_late
from olist_orders_dataset;

select * from clean.orders