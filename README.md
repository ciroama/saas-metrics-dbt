# SaaS Metrics with dbt

A small dbt project that turns raw subscription data from a (simulated) billing system into a monthly **MRR** mart, broken down into new, expansion, contraction and churn.

## Why I built it

I work daily with SQL, data quality and KPI definitions in an enterprise BI environment. I built this project to learn dbt hands-on and to practise the core metrics of a B2B SaaS business.

## Lineage

<!-- Screenshot of the lineage graph from `dbt docs serve` coming soon: ![Lineage graph](docs/lineage.png) -->

```text
raw_subscriptions -> stg_subscriptions --+
                                         +--> int_mrr_by_customer_month --> fct_mrr_monthly
raw_plans --------> stg_plans -----------+

raw_customers ----> stg_customers -------> dim_customers
```

## Models

| Layer | Model | What it does |
| --- | --- | --- |
| Staging | `stg_customers`, `stg_plans`, `stg_subscriptions` | Clean the raw data: rename columns, fix casing and types, remove duplicates. One model per source table, no business logic. |
| Intermediate | `int_mrr_by_customer_month` | One row per customer per month with the MRR paid. Includes months with MRR = 0, so churn is visible. |
| Marts | `fct_mrr_monthly` | One row per month: total MRR, new, expansion, contraction and churned MRR, active customers. |
| Marts | `dim_customers` | One row per customer with attributes for filtering. |

Staging and intermediate models are views; marts are tables.

## Result

Output of `dbt show --select fct_mrr_monthly`:

| month_start | mrr | new_mrr | expansion_mrr | contraction_mrr | churned_mrr | active_customers |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-01-01 | 900 | 900 | 0 | 0 | 0 | 2 |
| 2026-02-01 | 1900 | 1000 | 0 | 0 | 0 | 3 |
| 2026-03-01 | 2200 | 0 | 300 | 0 | 0 | 3 |
| 2026-04-01 | 1200 | 0 | 0 | -400 | -600 | 2 |

## Tests

- **Generic tests** on every key: `unique`, `not_null`, `accepted_values` on plans, `relationships` between subscriptions, customers and plans.
- **`assert_mrr_not_negative`**: MRR can never be below zero.
- **`assert_mrr_bridge_balances`**: a reconciliation test. Every month, MRR must equal last month's MRR + new + expansion + contraction + churn.

The raw data intentionally contains a duplicated row and inconsistent casing. The staging layer fixes them, and the `unique` test would catch the duplicate if it slipped through.

## Getting started

**Requirements:** Python 3.10 or later and Git. Tested with dbt-core 1.12 and dbt-duckdb 1.11 on Ubuntu, Python 3.14.

**1. Clone the repository**

```bash
git clone https://github.com/ciroama/saas-metrics-dbt.git
cd saas-metrics-dbt
```

**2. Create a virtual environment and install dbt**

```bash
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install dbt-duckdb
```

**3. Check the setup**

```bash
dbt debug                        # should end with "All checks passed!"
```

The connection is defined in `profiles.yml`. The project uses [DuckDB](https://duckdb.org/), which stores the whole database in one local file, so no cloud account or password is needed.

**4. Load the data and build**

```bash
dbt seed                         # loads the raw CSV files
dbt build                        # runs all models and tests in DAG order
```

**5. Look at the result**

```bash
dbt show --select fct_mrr_monthly
```

You should see the table shown in [Result](#result).

**6. Browse the documentation and lineage**

```bash
dbt docs generate
dbt docs serve
```

## See a test catch a bug

The raw data contains a duplicated subscription row on purpose. To see the tests at work:

1. In `models/staging/stg_subscriptions.sql`, change `select distinct * from renamed` to `select * from renamed`.
2. Run `dbt build`. The `unique` test on `subscription_id` fails and the downstream models are skipped, so the wrong MRR (600 too high in April) never reaches the mart.
3. Restore the file with `git checkout models/staging/stg_subscriptions.sql` and run `dbt build` again.

## Notes

- The raw data comes from seeds but is read through `source()`, to mirror how raw tables loaded by an ingestion tool are used in a real warehouse.
- Generic test arguments are nested under `arguments:`, the syntax required from dbt 1.10 onwards.
- `profiles.yml` is kept in the project only because DuckDB needs no credentials. In a real setup it lives in `~/.dbt/` and is never committed.

## Next steps

- Generate the months from the data instead of project variables.
- Add Net Revenue Retention (NRR) and churn rate to the mart.
- Add MRR by country, using `dim_customers`.
- Build a small dashboard on top of `fct_mrr_monthly`.
