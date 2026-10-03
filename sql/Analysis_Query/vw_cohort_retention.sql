use Olist_Raw_Data;

create view vw_cohort_retention as
with customer_first_order as (
    select
        dc.customer_unique_id,
        MIN(o.order_purchase_ts) as first_order_date
    from clean.orders o
    join clean.customers c on c.customer_id = o.customer_id
    join dim_customer dc on dc.customer_unique_id = c.customer_unique_id
    group by dc.customer_unique_id
),
cohort_base as (
    select
        customer_unique_id,
        DATEFROMPARTS(YEAR(first_order_date), MONTH(first_order_date), 1) as cohort_month
    from customer_first_order
),
customer_orders as (
    select
        dc.customer_unique_id,
        DATEFROMPARTS(YEAR(o.order_purchase_ts), MONTH(o.order_purchase_ts), 1) as order_month
    from clean.orders o
    join clean.customers c on c.customer_id = o.customer_id
    join dim_customer dc on dc.customer_unique_id = c.customer_unique_id
),
cohort_activity as (
    select
        cb.cohort_month,
        DATEDIFF(MONTH, cb.cohort_month, co.order_month) as month_offset,
        COUNT(distinct co.customer_unique_id) as active_customers
    from cohort_base cb
    join customer_orders co on co.customer_unique_id = cb.customer_unique_id
    group by cb.cohort_month, DATEDIFF(MONTH, cb.cohort_month, co.order_month)
),
cohort_size as (
    select cohort_month, active_customers as cohort_total
    from cohort_activity
    where month_offset = 0
)
select
    ca.cohort_month,
    ca.month_offset,
    ca.active_customers,
    cs.cohort_total,
    CAST(ca.active_customers * 100.0 / cs.cohort_total as DECIMAL(5,2)) as retention_pct
from cohort_activity ca
join cohort_size cs on cs.cohort_month = ca.cohort_month;

select * from vw_cohort_retention;