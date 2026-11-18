-- Staging: one clean row per contract period.
-- Fixes column names, casing and types, and removes exact duplicates.

with source as (

    select * from {{ source('billing', 'raw_subscriptions') }}

),

renamed as (

    select
        lower(SubID)            as subscription_id,
        lower(CustomerID)       as customer_id,
        lower(Plan)             as plan_id,
        cast(StartDate as date) as start_date,
        cast(EndDate as date)   as end_date      -- NULL = still active
    from source

),

deduplicated as (

    select distinct * from renamed

)

select * from deduplicated
