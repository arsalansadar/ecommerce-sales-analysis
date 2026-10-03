use Olist_Raw_Data;

-- Query 1: Each category, total revenue, individual % share,  running cumulative %
-- Category level Pareto
with category_revenue as (
    select 
        dp.category_english,
        SUM(foi.price) as total_revenue,
        COUNT(*) as item_count
    from fact_order_items foi
    join dim_product dp on dp.product_key = foi.product_key
    group by dp.category_english
),
category_pareto as (
   select 
       category_english,
       total_revenue,
       item_count,
       ROW_NUMBER() over(order by total_revenue desc) as category_rank,
       CAST(total_revenue * 100.0 / SUM(total_revenue) over () as DECIMAL(5,2)) as revenue_pct,
       CasT(SUM(total_revenue) over (order by total_revenue desc ROWS UNBOUNDED PRECEDING)
             * 100.0 / SUM(total_revenue) over () as DECIMAL(5,2)) as cumulative_pct
   from category_revenue
)
select * from category_pareto order by category_rank;


-- Query 2: top 20 individual products by revenue, its % share with total revenue.
-- Product level Pareto
select top 20
    dp.product_id,
    dp.category_english,
    SUM(foi.price) as product_revenue,
    COUNT(*) as times_sold,
    cast(SUM(foi.price) * 100.0 / (select SUM(price) from fact_order_items) as DECIMAL(5,3)) as pct_of_total_revenue
from fact_order_items foi
join dim_product dp on dp.product_key = foi.product_key
group by dp.product_id, dp.category_english
order by product_revenue desc;


-- top categories
WITH top_categories as (
    select dp.category_english, SUM(foi.price) as category_total
    from fact_order_items foi
    join dim_product dp on dp.product_key = foi.product_key
    group by dp.category_english
),
product_rank_in_category as (
    select
        dp.category_english,
        dp.product_id,
        SUM(foi.price) as product_revenue,
        ROW_NUMBER() over (partition by dp.category_english order by SUM(foi.price) desc) as rank_in_category
    from fact_order_items foi
    join dim_product dp on dp.product_key = foi.product_key
    group by dp.category_english, dp.product_id
)
select
    tc.category_english,
    tc.category_total,
    SUM(case when pr.rank_in_category <= 5 then pr.product_revenue else 0 end) as top5_product_revenue,
    CAST(SUM(case when pr.rank_in_category <= 5 then pr.product_revenue else 0 end) * 100.0
         / tc.category_total as DECIMAL(5,2)) as top5_concentration_pct
from top_categories tc
join product_rank_in_category pr on pr.category_english = tc.category_english
where tc.category_total > 100000  -- sirf meaningful categories (top ~18 range)
group by tc.category_english, tc.category_total
order by top5_concentration_pct desc;


-- Part C (Order-count vs Revenue) assign rank volume and revenue generate wise
-- konsa category more revenue generate kar raha hai, based on volume
WITH category_metrics as (
    select
        dp.category_english,
        SUM(foi.price) as total_revenue,
        COUNT(*) as item_count,
        CAST(SUM(foi.price) / COUNT(*) as DECIMAL(10,2)) as avg_price_per_item
    from fact_order_items foi
    join dim_product dp on dp.product_key = foi.product_key
    group by dp.category_english
),
ranked as (
    select
        category_english,
        total_revenue,
        item_count,
        avg_price_per_item,
        ROW_NUMBER() over (order by total_revenue desc) as revenue_rank,
        ROW_NUMBER() over (order by item_count desc) as volume_rank
    from category_metrics
)
select
    category_english,
    total_revenue,
    item_count,
    avg_price_per_item,
    revenue_rank,
    volume_rank,
    (volume_rank - revenue_rank) as rank_gap
from ranked
where revenue_rank <= 20 OR volume_rank <= 20   
order by revenue_rank;



