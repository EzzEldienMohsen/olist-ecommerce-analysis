# Query performance notes

Diagnosing slow PostgreSQL queries with `EXPLAIN ANALYZE`: what made each one slow, what I changed, and what the plan looked like before and after. Every rewrite was checked to return the same result as the original.

**Setup.** PostgreSQL 16. Two generated test tables: `big_orders` (2,000,000 rows, customers 1–10,000, dates from 1996-01-01 to 1998-06-19, five countries) and `big_customers` (10,000 rows), both built with `generate_series`. Timings are the `Execution Time` reported by `EXPLAIN ANALYZE`. Parallel query was left on, which is why `Gather` nodes appear. For a clean baseline, all secondary indexes were dropped before the three queries below and only the primary keys were kept.

---

## Query 1: Month filter with `EXTRACT`

```sql
SELECT COUNT(*), SUM(amount)
FROM big_orders
WHERE EXTRACT(YEAR FROM order_date) = 1997
  AND EXTRACT(MONTH FROM order_date) = 3;
```

**Problem.** The filter applies a function to `order_date` for every one of the 2,000,000 rows. An index on `order_date` could not be used for this condition, and the planner could not estimate it well: it expected 21 rows per worker and found 22,963.

**Before.** Parallel Seq Scan on `big_orders` is the slowest node, about 129 ms of the 155 ms total. **155 ms.**

**Fix.** Compare the column directly with a date range:

```sql
WHERE order_date >= '1997-03-01' AND order_date < '1997-04-01'
```

**After.** Same four nodes, still a Parallel Seq Scan, but the filter is a cheap comparison and the estimate is close (29,274 expected, 22,963 actual). **73 ms.** The two queries returned identical results (checked with `EXCEPT`).

**Why it worked.** A plain comparison on the column is cheaper to evaluate per row than two function calls. It also makes the condition usable by an index, which was not measured in this test because the indexes had been dropped. In a separate test with an index on `order_date`, a one-year range ran as an Index Only Scan in 54 ms against 202 ms for the `EXTRACT` version.

---

## Query 2: Per-customer total with a correlated subquery

```sql
SELECT c.customer_id, c.name,
       (SELECT SUM(o.amount) FROM big_orders o WHERE o.customer_id = c.customer_id) AS total
FROM big_customers c
WHERE c.customer_id <= 50;
```

**Problem.** The subquery in the `SELECT` list runs once per customer. The plan shows `loops=50` on a Seq Scan of `big_orders`, each loop reading 2,000,000 rows and discarding 1,999,800 of them.

**Before.** The Seq Scan inside `SubPlan 1` takes about 108 ms per loop, 50 times. **5,435 ms** (middle of three runs; the slowest was 5,907 ms).

**Fix.** Join once and aggregate with `GROUP BY`:

```sql
SELECT c.customer_id, c.name, SUM(o.amount) AS total
FROM big_customers c
JOIN big_orders o ON o.customer_id = c.customer_id
WHERE c.customer_id <= 50
GROUP BY c.customer_id;
```

**After.** Hash Join: the 50 customers are hashed, `big_orders` is read once in parallel, and a hash aggregate sums per customer. **99 ms, about 55 times faster.** Identical results, checked with `EXCEPT`.

**Why it worked.** The original read the 2-million-row table fifty times; the rewrite reads it once. Seeing `loops=N` above a Seq Scan is the signal to look for.

---

## Query 3: Daily spine joined through `DATE_TRUNC`

```sql
SELECT d.day::date, COUNT(o.order_id) AS orders
FROM generate_series(DATE '1997-03-01', DATE '1997-03-31', INTERVAL '1 day') AS d(day)
LEFT JOIN big_orders o ON DATE_TRUNC('day', o.order_date) = d.day
GROUP BY d.day
ORDER BY d.day;
```

**Problem.** The join condition wraps `order_date` in a function. That forces a Merge Join, which has to sort all 2,000,000 rows of `big_orders` first, and the sort does not fit in memory (`Sort Method: external merge  Disk: 50856kB`).

**Before.** Seq Scan plus an on-disk sort of the whole table. **1,185 ms.**

**Fix.** `order_date` is already a `date`, so the function adds nothing. Compare it directly:

```sql
LEFT JOIN big_orders o ON o.order_date = d.day
```

**After.** **664 ms, about 1.8 times faster.** Identical results, checked with `EXCEPT`.

**What is left.** The plan still sorts the whole table on disk (35 MB), because the join is not limited to March and no index exists. The next step would be to restrict `order_date` to the month inside the `ON` clause (keeping the `LEFT JOIN`) and add an index on `order_date`. That was not measured here.

**A related trap.** The spine from `generate_series` is a timestamp with time zone, and `order_date` is a date. Across a daylight-saving change the spine can drift off midnight and match nothing, as it did in an earlier rolling-metrics query. Casting the spine to a date (`d.day::date`) avoids that.

---

## Index and plan experiments

| Experiment | Before | After |
|---|---|---|
| Plain index, `customer_id = 42` (200 of 2M rows) | Parallel Seq Scan, about 70 ms | Bitmap Heap Scan, 2.7 ms |
| Covering index `(customer_id) INCLUDE (order_date)` vs composite `(customer_id, order_date)` | 1.36 ms, 84 rows fetched then removed by a filter | 0.12 ms, both conditions in `Index Cond` |
| Partial index on `country = 'Brazil'`, query that does not repeat the condition vs one that does | Seq Scan, 107 ms | Index Scan, 6.3 ms; index is 2.8 MB against 13 MB for a full index |
| Expression index on `LOWER(name)` | Seq Scan, 7.6 ms | Bitmap Index Scan, 0.09 ms |
| `text_pattern_ops` index for `LIKE 'Customer 12%'` | Seq Scan, 0.63 ms | Index Only Scan, 0.16 ms |
| Materialized view vs plain view over 2M rows | 398 ms (reruns the query) | 0.03 ms (but stale until refreshed) |

Things the plans showed that were not obvious beforehand:

- A partial index is only used when the query repeats its condition.
- A composite index serves its first column; a column in `INCLUDE` is stored but cannot be searched.
- A leading wildcard (`LIKE '%12%'`) cannot use a sorted index.
- Index size follows the share of rows covered: the Brazil index is about 22% of the full index, and Brazil is about 20% of the rows.

---

## Three rules I would follow now

1. **Compare the column, not a function of it.** Anything like `EXTRACT(...)`, `DATE_TRUNC(...)` or `LOWER(...)` on a filtered or joined column hides it from an index. Rewrite as a range, or build an index on the expression.
2. **Look for `loops=N` above a scan.** A subquery that runs once per row turns one scan into N. Replace it with a join and `GROUP BY`, or index the column it searches on.
3. **Compare estimated rows with actual rows, and check the rewrite returns the same result.** A big gap between the two means the planner is guessing, usually because of a function on a column or stale statistics (`ANALYZE`). After any rewrite, run `EXCEPT` against the original before trusting it.

---

## Limits

- The data is generated with uniform random values, so real data with skew would plan differently.
- Most timings are a single `EXPLAIN ANALYZE` run, except where a middle-of-three is stated. First runs are slower because the data is not yet cached.
- Parallel workers were enabled, which affects absolute times but not the comparisons.
