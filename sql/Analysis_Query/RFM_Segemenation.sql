use Olist_Raw_Data;

create view vw_rfm_base as
with order_revenue as (
select order_id, SUM(price) as order_revenue 
from fact_order_items
group by order_id
),
valid_orders as (
select fo.order_id, 
fo.customer_key, dd.full_date as purchase_date, orv.order_revenue
from fact_orders fo 
join dim_date dd on dd.date_key = fo.purchase_date_key
join order_revenue orv on orv.order_id = fo.order_id
where fo.order_status not in ('canceled', 'unavailable')
),
snapshot as (
    select DATEADD(DAY, 1, MAX(purchase_date)) as snapshot_date
    from valid_orders
)
select
    customer_key,
    DATEDIFF(DAY, MAX(purchase_date), (select snapshot_date from snapshot)) as recency_days,
    COUNT(DISTINCT order_id)  as frequency,
    SUM(order_revenue)        as monetary
from valid_orders
group by customer_key;



-- 1. Total monetary source se match karna chahiye
select
  (select SUM(monetary) from vw_rfm_base) as rfm_total,
  (select SUM(foi.price)
   from fact_order_items foi
   join fact_orders fo on fo.order_id = foi.order_id
   where fo.order_status not in ('canceled','unavailable')) as source_total;

-- 2. Customers ki count aur recency ki range
select COUNT(*) as customers,
       MIN(recency_days) as min_recency,
       MAX(recency_days) as max_recency,
       MIN(monetary) as min_monetary,
       MAX(monetary) as max_monetary
from vw_rfm_base;

-- 3. Frequency ka distribution
select frequency, COUNT(*) as customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) over () as DECIMAL(5,2)) as pct
from vw_rfm_base
group by frequency
order by frequency;

-- create view vw_rfm_scored 
create view vw_rfm_scored as
select
    customer_key, recency_days, frequency, monetary,
    NTILE(5) over (order by recency_days desc, customer_key) as r_score,
    case when frequency = 1 then 1
         when frequency = 2 then 2
         else 3 end                                          as f_score,
    NTILE(5) over (order by monetary asc, customer_key)      as m_score
from vw_rfm_base;

create view vw_rfm_segments as
select *,
  case
    when f_score >= 2 AND r_score >= 4      then 'Champions'
    when f_score >= 2 AND r_score IN (2,3)  then 'Loyal Repeat'
    when f_score >= 2 AND r_score = 1       then 'At-Risk Repeat'
    when r_score >= 4 AND m_score >= 4      then 'New High-Value'
    when r_score >= 4                       then 'New Customers'
    when r_score = 3                        then 'Needs Attention'
    when m_score >= 4                       then 'Win-Back Priority'
    else 'Lost / Hibernating'
  end as segment
from vw_rfm_scored;

-- 1. Score buckets ~19k-19k ke aas-paas hone chahiye, total 94,983
select 'r' as score_type, r_score as score, COUNT(*) as customers from vw_rfm_scored group by r_score
union all
select 'm', m_score, COUNT(*) from vw_rfm_scored group by m_score
union all
select 'f', f_score, COUNT(*) from vw_rfm_scored group by f_score
ORDER BY score_type, score;

-- 2. Segment summary
select segment,
       COUNT(*) as customers,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) over () as DECIMAL(5,2)) as pct_customers,
       CAST(SUM(monetary) as DECIMAL(14,2)) as revenue,
       CAST(100.0 * SUM(monetary) / SUM(SUM(monetary)) over () as DECIMAL(5,2)) as pct_revenue,
       CAST(AVG(recency_days * 1.0) as DECIMAL(7,1)) as avg_recency,
       CAST(AVG(frequency * 1.0) as DECIMAL(5,2))    as avg_frequency,
       CAST(AVG(monetary) as DECIMAL(10,2))          as avg_monetary
from vw_rfm_segments
group by segment
order by revenue desc;
