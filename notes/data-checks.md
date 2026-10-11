# Data checks before analysis

What the data looked like before any question was answered, and the decisions that followed.

## Row counts

| Table | Rows |
|---|---|
| customers | 99,441 |
| orders | 99,441 |
| order_items | 112,650 |
| payments | 103,886 |
| reviews | 99,224 |
| products | 32,951 |
| sellers | 3,095 |
| category_translation | 71 |

## Keys and grain

- **customer_id is one per order, not one per person.** `customers` has 99,441 distinct `customer_id` values but only 96,096 distinct `customer_unique_id` values. Every order creates a new `customer_id`. All customer-level questions use `customer_unique_id`.
- **review_id is not unique.** Some review ids appear two or three times, so `reviews` has no primary key.
- **Reviews per order.** 547 orders have more than one review and 768 have none. Joining reviews to orders would repeat rows for the 547 and drop the 768 with an inner join. Query 08 averages the reviews of each order first.
- **Payments per order.** Some orders are paid with more than one method, so `payments` has more rows than orders. Query 05 counts distinct orders and never joins `order_items`.

## Categories

- 610 products have no category.
- 13 products have a category with no English translation.
- Both groups are kept in revenue totals (query 03 uses a LEFT JOIN) and make up 182,206.73 of revenue (1.36%).

## Order status

| Status | Orders | Payment approved |
|---|---|---|
| delivered | 96,478 | 96,464 |
| shipped | 1,107 | 1,107 |
| canceled | 625 | 484 |
| unavailable | 609 | 609 |
| invoiced | 314 | 314 |
| processing | 301 | 301 |
| created | 5 | 0 |
| approved | 2 | 2 |

- The status is spelled `canceled` (one l). A filter using `cancelled` silently matches nothing.
- **Sale rule used in revenue queries:** shipped, invoiced, approved, delivered (97,901 orders). `processing` orders were all paid but are left out (301 orders, 0.30%). `canceled` and `unavailable` orders were often paid but not fulfilled, so they are not sales.
- 14 delivered orders have no approval time and 8 delivered orders have no delivery date.

## Complete months

Orders per month were checked by the number of days that had at least one order:

| Month | Days with orders | First order | Last order |
|---|---|---|---|
| 2016-09 | 4 | 2016-09-04 | 2016-09-15 |
| 2016-10 | 10 | 2016-10-02 | 2016-10-22 |
| 2016-11 | 0 (no orders) | | |
| 2016-12 | 1 | 2016-12-23 | 2016-12-23 |
| 2017-01 | 27 of 31 | 2017-01-05 | 2017-01-31 |
| 2017-02 to 2018-08 | every day | 1st | last day |
| 2018-09 | 11 | 2018-09-03 | 2018-09-29 |
| 2018-10 | 4 | 2018-10-01 | 2018-10-17 |

A month counts as complete when every one of its days has at least one order. That keeps 19 months, 2017-02 to 2018-08. The rule is computed in SQL (`complete_months` CTE in queries 01 and 07), not hard-coded. 2017-01 is the only borderline month: its first order was on the 5th.
