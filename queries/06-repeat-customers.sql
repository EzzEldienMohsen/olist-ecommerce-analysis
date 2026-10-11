-- Question:    What share of real customers ordered more than once, and how many orders did
--              the heaviest buyer place?
-- Rows:        1
-- Measures:    customers with more than 1 order out of all unique customers
-- Assumptions: customer = customer_unique_id (a person); each customer_id is one order, so
--              counting customer_id per person counts their orders; every order status counts
--              as an order here (this is about buying behaviour, not revenue).
--              The 17-order customer has not been checked for same-day orders.

WITH cust_orders (cust_id, orders) AS (
    SELECT customer_unique_id, COUNT(customer_id)
    FROM customers
    GROUP BY customer_unique_id
),
flag (cust_id, orders, rep_cust) AS (
    SELECT cust_id, orders,
           CASE WHEN orders > 1 THEN 'repeat' ELSE 'single' END
    FROM cust_orders
),
total (total) AS (
    SELECT COUNT(*) FROM flag
),
flag_stat (rep_cust, count) AS (
    SELECT rep_cust, COUNT(cust_id)
    FROM flag
    GROUP BY rep_cust
)
SELECT fs.count AS repeat_customers,
       t.total AS all_customers,
       ROUND((fs.count * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS repeat_share,
       (SELECT MAX(orders) FROM cust_orders) AS max_orders
FROM flag_stat fs
CROSS JOIN total t
WHERE fs.rep_cust = 'repeat';

/*
 repeat_customers | all_customers | repeat_share | max_orders
------------------+---------------+--------------+------------
             2997 |         96096 |         3.12 |         17
(1 row)

Heaviest buyers (from the per-customer version of this query): 17, 9, 7, 7, 7, 6, 6, 6, 6 orders.
*/
