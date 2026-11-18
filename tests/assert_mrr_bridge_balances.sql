-- Reconciliation test (the "MRR bridge"):
-- MRR this month = MRR last month + new + expansion + contraction + churn.
-- The test fails if this query returns any month where the numbers don't add up.

with months as (

    select
        *,
        lag(mrr, 1, 0) over (order by month_start) as previous_month_mrr
    from {{ ref('fct_mrr_monthly') }}

)

select *
from months
where mrr <> previous_month_mrr
           + new_mrr
           + expansion_mrr
           + contraction_mrr
           + churned_mrr
