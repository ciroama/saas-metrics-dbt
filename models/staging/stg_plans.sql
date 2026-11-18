-- Staging: one clean row per subscription plan.

with source as (

    select * from {{ source('billing', 'raw_plans') }}

)

select
    lower(PlanID)                 as plan_id,
    PlanName                      as plan_name,
    cast(MonthlyPrice as integer) as monthly_price
from source
