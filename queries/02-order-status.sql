-- Question:    How many orders are in each status, what share of all orders is that,
--              and which statuses count as a sale?
-- Rows:        8, one per status
-- Measures:    orders per status out of all 99,441 orders
-- Assumptions: the is_sale flag follows the data: a status counts as paid when its orders
--              have order_approved_at filled in. processing (301 orders, all approved) is
--              flagged as a sale here, but queries 01, 03, 04, 05, 07 and 09 use the narrower
--              list (shipped, invoiced, approved, delivered); the 0.30% gap is noted there.
--              canceled and unavailable orders were often paid but not fulfilled, so they are not sales.

WITH status_stats (status, orders) AS (
    SELECT order_status, COUNT(order_id)
    FROM orders
    GROUP BY order_status
),
flag (status, is_sale) AS (
    SELECT DISTINCT order_status,
           CASE WHEN order_status IN ('shipped', 'invoiced', 'approved', 'delivered', 'processing')
                    THEN 'sale'
                WHEN order_status IN ('unavailable', 'canceled', 'created')
                    THEN 'not_sale'
           END
    FROM orders
),
total (total) AS (
    SELECT COUNT(*) FROM orders
)
SELECT s.status, s.orders, f.is_sale, t.total,
       ROUND((s.orders * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS percentage
FROM status_stats s
INNER JOIN flag f ON s.status = f.status
CROSS JOIN total t
ORDER BY s.orders DESC;

/*
   status    | orders | is_sale  | total | percentage
-------------+--------+----------+-------+------------
 delivered   |  96478 | sale     | 99441 |      97.02
 shipped     |   1107 | sale     | 99441 |       1.11
 canceled    |    625 | not_sale | 99441 |       0.63
 unavailable |    609 | not_sale | 99441 |       0.61
 invoiced    |    314 | sale     | 99441 |       0.32
 processing  |    301 | sale     | 99441 |       0.30
 created     |      5 | not_sale | 99441 |       0.01
 approved    |      2 | sale     | 99441 |       0.00
(8 rows)

Supporting check (orders with a payment approval time, by status):
 order_status | orders | approved
--------------+--------+----------
 shipped      |   1107 |     1107
 unavailable  |    609 |      609
 invoiced     |    314 |      314
 created      |      5 |        0
 approved     |      2 |        2
 processing   |    301 |      301
 delivered    |  96478 |    96464
 canceled     |    625 |      484
Note: 14 delivered orders have no approval time; they are kept as sales.
*/
