-- MRR can never be negative.
-- The test fails if this query returns any row.

select *
from {{ ref('fct_mrr_monthly') }}
where mrr < 0
