-- Staging: one clean row per customer.
-- Only renaming and formatting, no business logic.

with source as (

    select * from {{ source('billing', 'raw_customers') }}

)

select
    lower(CustomerID) as customer_id,
    CompanyName       as company_name,
    Country           as country
from source
