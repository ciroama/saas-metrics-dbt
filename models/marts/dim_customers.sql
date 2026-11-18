-- Dimension: one row per customer, with descriptive attributes
-- and a few facts about their subscription history.

with customers as (

    select * from {{ ref('stg_customers') }}

),

subscription_summary as (

    select
        customer_id,
        min(start_date)                                   as first_subscription_date,
        max(case when end_date is null then 1 else 0 end) as is_active
    from {{ ref('stg_subscriptions') }}
    group by customer_id

)

select
    customers.customer_id,
    customers.company_name,
    customers.country,
    subscription_summary.first_subscription_date,
    coalesce(subscription_summary.is_active, 0) = 1 as is_active
from customers
left join subscription_summary
    on customers.customer_id = subscription_summary.customer_id
