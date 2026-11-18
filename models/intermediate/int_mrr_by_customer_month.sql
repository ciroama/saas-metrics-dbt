-- Intermediate: one row per customer per month, with the MRR the customer paid.
-- Every customer gets a row for every month, also months with MRR = 0:
-- this is what makes churn visible in the next model.

with months as (

    -- one row per month, between the two dates set in dbt_project.yml
    select cast(month_start as date) as month_start
    from range(
        date '{{ var("start_month") }}',
        date '{{ var("end_month") }}',
        interval 1 month
    ) as t(month_start)

),

customers as (

    select customer_id from {{ ref('stg_customers') }}

),

grid as (

    -- every customer x every month
    select
        months.month_start,
        customers.customer_id
    from months
    cross join customers

),

subscriptions as (

    select
        s.customer_id,
        s.start_date,
        s.end_date,
        p.monthly_price
    from {{ ref('stg_subscriptions') }} as s
    join {{ ref('stg_plans') }}         as p
        on s.plan_id = p.plan_id

)

select
    grid.month_start,
    grid.customer_id,
    coalesce(sum(subscriptions.monthly_price), 0) as mrr
from grid
left join subscriptions
    on  subscriptions.customer_id = grid.customer_id
    and subscriptions.start_date <= grid.month_start
    and (subscriptions.end_date is null or subscriptions.end_date >= grid.month_start)
group by 1, 2
