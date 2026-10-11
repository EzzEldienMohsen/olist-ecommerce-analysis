# Olist E-commerce Analysis

SQL analysis of the Olist Brazilian e-commerce dataset (PostgreSQL 16): about 99,000 orders placed between September 2016 and October 2018. It covers sales growth, what sells and where, how customers pay, whether they come back, delivery performance and its effect on reviews, seller concentration, and one query performance fix.

---

## Key findings

- **Revenue grew more than fourfold in nine months, then levelled off.** Monthly revenue rose from 239,099 in February 2017 to a peak of 999,311 in November 2017. Through 2018, sale orders held at 6,145–7,159 a month and revenue at 837k–992k. Average order value stayed within 124.73–147.04 throughout, so the growth came from more orders, not bigger ones.
- **November 2017 was the biggest month in the data.** Orders rose 63.4% over October (7,396 against 4,527), most likely around Black Friday. That month the late-delivery rate also jumped from 5.29% to 14.31%.
- **Late deliveries get 40% lower review scores.** On-time orders average 4.29 out of 5, late orders 2.57. Only 8.0% of reviewed orders were late (7,661 of 95,824), but they pull the average down sharply.
- **Late deliveries peaked in early 2018 without a rise in volume.** Across the 19 complete months, 8.17% of delivered orders arrived late. February 2018 (15.99%) and March 2018 (21.36%, the worst month) had about the same order volume as January (6.56%), so the cause lies outside this data.
- **Only 3.12% of customers ever bought a second time** (2,997 of 96,096). Almost all growth depends on finding new buyers.
- **Three states produce 63.34% of revenue.** São Paulo alone is 38.23%, followed by Rio de Janeiro (13.43%) and Minas Gerais (11.67%). São Paulo also has the lowest average order value (125.30); smaller, more distant states have the highest (Paraíba 216.38).
- **Delivery to the north takes more than three times as long.** São Paulo customers wait 8.70 days on average; Roraima 29.34, Amapá 27.18 and Amazonas 26.36.
- **Bigger purchases go with more installments.** Credit cards carry 78.49% of payment value. A card payment in one installment averages 95.61, while one split into 11 or more averages 360.83, 3.8 times as much. Two-thirds of card payments (66.85%) are split.
- **Revenue relies on a group of sellers, not on any one.** 534 of 3,095 sellers (17.25%) produce 80% of revenue, but the largest single seller holds only 1.71%.
- **No category dominates.** The top 10 categories make 62.43% of revenue; the largest, health & beauty, is 9.33%.

---

## Recommendations

1. **Treat on-time delivery as the main lever on customer satisfaction.** A late order scores 1.72 points lower. Investigate what happened in February and March 2018, and plan carrier capacity ahead of Black Friday, when volume and the late rate both jumped.
2. **Work on the second purchase.** With 3.12% of customers returning, even a small improvement in repeat buying would add revenue without acquisition cost. A follow-up offer after a first on-time delivery is a natural place to start.
3. **Set realistic delivery promises for the north.** Customers in Roraima, Amapá and Amazonas wait more than three times as long as São Paulo. Either improve logistics there or set estimated dates that match reality, since a missed estimate is what turns into a bad review.
4. **Keep installment payments.** Larger purchases are strongly associated with split payments, and cards carry nearly four-fifths of all payment value. Removing or restricting installments would put the higher-value sales at risk.

---

## What this analysis cannot tell you

- **Partial months are excluded from time trends.** A month counts only if every one of its days has an order. That leaves February 2017 to August 2018 (19 months); the thin months at the start and end of the data are left out (see [notes/data-checks.md](notes/data-checks.md)).
- **Revenue means item price**, excluding freight, from orders with status shipped, invoiced, approved or delivered. 301 `processing` orders (0.30%) were paid but are not counted. Payment value includes freight, so payment totals (15.67M) are higher than item revenue (13.43M).
- **A customer means a person** (`customer_unique_id`), not `customer_id`, which Olist creates fresh for every order.
- **"Late" compares timestamps**: an order delivered later than the estimated date and time. Comparing calendar dates instead might change the late rate slightly.
- **Reviews are averaged per order** for the 547 orders with more than one review.
- **The cause of a pattern is not in the data.** Late deliveries and low reviews, and installments and higher values, go together, but this data cannot show which causes which.
- **The dataset is a public, anonymised sample** released by Olist, not the company's full records.

---

## Questions answered

| # | Question | Query |
|---|---|---|
| 1 | How did orders, revenue and average order value change month by month? | [01-monthly-trend.sql](queries/01-monthly-trend.sql) |
| 2 | How are orders spread across statuses, and which count as sales? | [02-order-status.sql](queries/02-order-status.sql) |
| 3 | Which product categories earn the most? | [03-category-revenue.sql](queries/03-category-revenue.sql) |
| 4 | Which states buy the most, and how concentrated is revenue by state? | [04-state-revenue.sql](queries/04-state-revenue.sql) |
| 5 | How do customers pay, and do bigger payments use more installments? | [05-payments-installments.sql](queries/05-payments-installments.sql) |
| 6 | What share of customers buy more than once? | [06-repeat-customers.sql](queries/06-repeat-customers.sql) |
| 7 | What share of deliveries arrive late, month by month? | [07-late-delivery-by-month.sql](queries/07-late-delivery-by-month.sql) |
| 8 | Do late deliveries get lower review scores? | [08-late-delivery-vs-review.sql](queries/08-late-delivery-vs-review.sql) |
| 9 | How many sellers make 80% of revenue? | [09-seller-concentration.sql](queries/09-seller-concentration.sql) |
| 10 | How long does delivery take in each state? | [10-delivery-days-by-state.sql](queries/10-delivery-days-by-state.sql) |
| 11 | Performance: speeding up the repeat-customer query | [11-performance-repeat-customers.md](queries/11-performance-repeat-customers.md) |

Each query file states its question, expected rows, measures and assumptions at the top, with the results pasted at the bottom.

---

## Methods used

- Data checks before any analysis: row counts, key uniqueness, rows per order across tables, and status values ([notes/data-checks.md](notes/data-checks.md))
- Complete months worked out in SQL from the number of days with orders, not hard-coded
- One business rule for "sale" applied in every revenue query, with its cost stated
- Fan-out control: reviews collapsed to one score per order, payments counted by distinct order, no joins between payments and order items
- Window functions for month-over-month change (`LAG`), running totals and Pareto cut-offs
- Conditional aggregation (`CASE`, `FILTER`) for late shares and installment bands
- Revenue totals cross-checked across queries (13,433,961.52 in queries 03, 04 and 09)
- `EXPLAIN ANALYZE` and a covering index to cut a query from 591 ms to 261 ms

---

## Repository layout

```
schema/     schema.sql (tables), load.sql (CSV import), constraints.sql (foreign keys and indexes)
queries/    01-10 analysis queries with results, 11 performance write-up
notes/      data-checks.md (this dataset), analytical-patterns.md and performance.md (SQL pattern notes from earlier Northwind practice)
```

---

## How to run

1. Install PostgreSQL 16.
2. Download the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle. The geolocation file is not needed.
3. Create the database and load it, from the folder holding the CSV files:
   ```
   createdb olist
   psql -d olist -f schema/schema.sql
   psql -d olist -f schema/load.sql
   psql -d olist -f schema/constraints.sql
   ```
4. Run any query:
   ```
   psql -d olist -f queries/01-monthly-trend.sql
   ```

---

*Ezz Eldien Deghedy*
