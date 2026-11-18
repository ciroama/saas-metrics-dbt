# SaaS Metrics with dbt

A small dbt project that turns raw subscription data from a (simulated) billing system into a monthly **MRR** mart, broken down into new, expansion, contraction and churn.

## Why I built it

I work daily with SQL, data quality and KPI definitions in an enterprise BI environment. I built this project to learn dbt hands-on and to practise the core metrics of a B2B SaaS business.

## Lineage

<!-- Add a screenshot of the lineage graph from `dbt docs serve` here -->
![Lineage graph](docs/lineage.png)

## Models

| Layer | Model | What it does |
| --- | --- | --- |
| Staging | `stg_customers`, `stg_plans`, `stg_subscriptions` | Clean the raw data: rename columns, fix casing and types, remove duplicates. One model per source table, no business logic. |
| Intermediate | `int_mrr_by_customer_month` | One row per customer per month with the MRR paid. Includes months with MRR = 0, so churn is visible. |
| Marts | `fct_mrr_monthly` | One row per month: total MRR, new, expansion, contraction and churned MRR, active customers. |
| Marts | `dim_customers` | One row per customer with attributes for filtering. |

Staging and intermediate models are views; marts are tables.

## Result

| Month | MRR | New | Expansion | Contraction | Churn |
| --- | --- | --- | --- | --- | --- |
| 2026-01 | 900 | +900 | 0 | 0 | 0 |
| 2026-02 | 1,900 | +1,000 | 0 | 0 | 0 |
| 2026-03 | 2,200 | 0 | +300 | 0 | 0 |
| 2026-04 | 1,200 | 0 | 0 | −400 | −600 |

## Tests

- **Generic tests** on every key: `unique`, `not_null`, `accepted_values` on plans, `relationships` between subscriptions, customers and plans.
- **`assert_mrr_not_negative`**: MRR can never be below zero.
- **`assert_mrr_bridge_balances`**: a reconciliation test. Every month, MRR must equal last month's MRR + new + expansion + contraction + churn.

The raw data intentionally contains a duplicated row and inconsistent casing. The staging layer fixes them, and the `unique` test would catch the duplicate if it slipped through.

## How to run

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install dbt-duckdb

dbt debug                          # check the connection
dbt seed                           # load the raw CSV files
dbt build                          # run all models and tests
dbt docs generate && dbt docs serve
```

The project uses [DuckDB](https://duckdb.org/), a local database in a single file, so it runs on any laptop with no cloud account. The raw data comes from seeds but is read through `source()`, to mirror how raw tables loaded by an ingestion tool are used in a real warehouse.

## Next steps

- Generate the months from the data instead of project variables.
- Add Net Revenue Retention (NRR) and churn rate to the mart.
- Add MRR by country, using `dim_customers`.
- Build a small dashboard on top of `fct_mrr_monthly`.
