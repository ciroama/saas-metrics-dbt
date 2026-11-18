-- Mart: one row per month with total MRR and its movements
-- (new, expansion, contraction, churn).

with customer_months as (

    select
        *,
        -- MRR of the same customer in the previous month (0 if there is none)
        lag(mrr, 1, 0) over (
            partition by customer_id
            order by month_start
        ) as previous_mrr
    from {{ ref('int_mrr_by_customer_month') }}

),

classified as (

    select
        *,
        mrr - previous_mrr as mrr_change,
        case
            when previous_mrr = 0 and mrr > 0 then 'new'
            when previous_mrr > 0 and mrr = 0 then 'churn'
            when mrr > previous_mrr           then 'expansion'
            when mrr < previous_mrr           then 'contraction'
            else 'unchanged'
        end as movement
    from customer_months

)

select
    month_start,
    sum(mrr)                                                           as mrr,
    sum(case when movement = 'new'         then mrr_change else 0 end) as new_mrr,
    sum(case when movement = 'expansion'   then mrr_change else 0 end) as expansion_mrr,
    sum(case when movement = 'contraction' then mrr_change else 0 end) as contraction_mrr,
    sum(case when movement = 'churn'       then mrr_change else 0 end) as churned_mrr,
    count(case when mrr > 0 then 1 end)                                as active_customers
from classified
group by month_start
order by month_start
