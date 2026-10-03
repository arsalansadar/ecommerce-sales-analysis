use Olist_Raw_Data;


-- Query 1: simple late vs on-time comparison
select case when is_late = 1 then 'Late' else 'On-Time' end as delivery_status,
COUNT(*) as order_count,
AVG(CAST(review_score as float)) as avg_review_score,
STDEV(CAST(review_score as float)) as stdev_review_score
from fact_orders
where order_status = 'delivered'
and review_score is not null
and is_date_anomaly = 0
group by is_late;


-- Query 2: delay bucket wise comparison
with order_with_bucket as (
    select
        review_score,
        delay_days,
        case
            when is_late = 0 then 'On-Time / Early'
            when delay_days between 1 and 3 then 'Late 1-3 days'
            when delay_days between 4 and 7 then 'Late 4-7 days'
            else 'Late 8+ days'
        end as delay_bucket
    from fact_orders
    where order_status = 'delivered'
      and review_score IS NOT NULL
      and is_date_anomaly = 0
)
select
    delay_bucket,
    COUNT(*) as order_count,
    AVG(CAST(review_score as FLOAT)) as avg_review_score,
    CAST(SUM(case when review_score <= 2 then 1 else 0 end) * 100.0 / COUNT(*) as DECIMAL(5,2)) as pct_low_score,
    MIN(delay_days) as min_delay_in_bucket,
    MAX(delay_days) as max_delay_in_bucket
from order_with_bucket
group by delay_bucket
order by MIN(delay_days);

-- followp query for 2 for check delivery delay outliers
select COUNT(*) as extreme_delay_orders
from fact_orders
where delay_days > 30
  and order_status = 'delivered'
  and is_date_anomaly = 0;

select order_id, delay_days, review_score, order_total_value
from fact_orders
where delay_days > 60
  and order_status = 'delivered'
  and is_date_anomaly = 0
order by delay_days DESC;


-- Aggregate confirm karte hain is extreme group ka
select
    COUNT(*) as total_extreme_orders,
    COUNT(review_score) as reviewed_orders,
    AVG(CAST(review_score as FLOAT)) as avg_review_score,
    SUM(case when review_score >= 4 then 1 else 0 end) * 100.0 / COUNT(review_score) as pct_high_score,
    SUM(case when review_score <= 2 then 1 else 0 end) * 100.0 / COUNT(review_score) as pct_low_score
from fact_orders
where delay_days > 30
  and order_status = 'delivered'
  and is_date_anomaly = 0;


-- Query 3 (Python): Mann-Whitney test


-- Query 4: category-wise confounding check
select
    dp.category_english,
    case when fo.is_late = 1 then 'Late' else 'On-Time' end as delivery_status,
    COUNT(*) as order_count,
    AVG(CAST(fo.review_score as FLOAT)) as avg_review_score
from fact_orders fo
JOIN fact_order_items foi ON foi.order_id = fo.order_id
JOIN dim_product dp ON dp.product_key = foi.product_key
where fo.order_status = 'delivered'
  and fo.review_score IS NOT NULL
  and fo.is_date_anomaly = 0
group by dp.category_english, fo.is_late
HAVING COUNT(*) >= 30
order by dp.category_english, delivery_status;


