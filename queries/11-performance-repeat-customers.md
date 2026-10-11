# Query 11: speeding up the repeat-customer query

**Query tuned:** the per-customer version of query 06 (one row per customer, ranked by orders). It was chosen because its plan has the clearest bottleneck. Query 04 was slower overall (902 ms), but its time is spread across several joins.

## Before

`EXPLAIN ANALYZE`, execution time **591 ms**.

By node type, Sort took **73.8%** of the time. The largest single sort was the one feeding the `GROUP BY customer_unique_id`:

```
->  Sort  (actual time=319.250..371.113 rows=99441 loops=1)
      Sort Key: customers.customer_unique_id
      Sort Method: external merge  Disk: 7400kB
      ->  Seq Scan on customers  (actual time=0.011..8.104 rows=99441 loops=1)
```

All 99,441 rows had to be sorted, and the sort did not fit in memory, so it spilled to disk. That one node took about 363 ms.

## A change that did not count

Removing `ROW_NUMBER()` and adding `ORDER BY orders DESC LIMIT 10` brought the time to 528 ms (about 11% less) and turned one disk sort into a top-N heapsort. But it returns 10 rows instead of 96,096, so it is a different query, not a faster version of the same one, and it cannot pass an `EXCEPT` check.

## Fix

```sql
CREATE INDEX idx_customer_unique ON customers (customer_unique_id, customer_id);
VACUUM customers;
```

The index stores the rows already ordered by `customer_unique_id` and also carries `customer_id`, the only other column the query reads, so it covers the query.

## After

Same query text, execution time **261 ms**.

```
->  GroupAggregate  (actual time=0.227..49.159 rows=96096 loops=1)
      Group Key: customers.customer_unique_id
      ->  Index Only Scan using idx_customer_unique on customers  (actual time=0.220..27.494 rows=99441 loops=1)
            Heap Fetches: 0
```

| | Before | After |
|---|---|---|
| Execution time | 591 ms | 261 ms (2.3 times faster, 56% less) |
| Grouping input | Seq Scan, then Sort on disk (7,400 kB), about 363 ms | Index Only Scan, 27 ms |
| Sort share of total time | 73.8% | 23.5% |

- The big sort disappeared: the GROUP BY reads the rows in order straight from the index.
- `Heap Fetches: 0` shows the index answered everything without going back to the table. The `VACUUM` made that possible.
- The query text did not change, so the result is identical.
- The remaining sorts come from ordering the 96,096 output rows. The one-row version of query 06 does not need them.
