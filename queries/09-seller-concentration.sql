-- Question:    How many sellers does it take to reach 80% of revenue, and what share of all sellers is that?
-- Rows:        one per seller up to and including the one that crosses 80% (534); top rows shown
-- Measures:    sellers needed for 80% of revenue out of all 3,095 registered sellers
-- Assumptions: sale statuses as in query 01; revenue = item price, freight excluded;
--              the seller that crosses 80% is included (running total before it is under 80%);
--              denominator = all registered sellers in the sellers table

WITH seller_rev (seller_id, revenue) AS (
    SELECT oi.seller_id,
           ROUND(SUM(oi.price)::NUMERIC, 2)
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY oi.seller_id
),
sellers_stats (seller_id, revenue, running_total, total_rev) AS (
    SELECT seller_id, revenue,
           ROUND(SUM(revenue) OVER (ORDER BY revenue DESC)::NUMERIC, 2),
           ROUND(SUM(revenue) OVER ()::NUMERIC, 2)
    FROM seller_rev
),
total_sellers (total_sellers) AS (
    SELECT COUNT(*) FROM sellers
),
sellers_pareto (seller_id, revenue, running_total, total_rev, percentage) AS (
    SELECT seller_id, revenue, running_total, total_rev,
           ROUND(running_total * 100.0 / NULLIF(total_rev, 0), 2)
    FROM sellers_stats
),
sellers_to_80 AS (
    SELECT *
    FROM sellers_pareto
    WHERE running_total - revenue < total_rev * 0.80
)
SELECT sp.seller_id, sp.revenue, sp.running_total, sp.total_rev, sp.percentage,
       t.total_sellers,
       COUNT(*) OVER () AS sellers_to_reach_80,
       ROUND(COUNT(*) OVER () * 100.0 / NULLIF(t.total_sellers, 0), 2) AS sellers_percentage
FROM sellers_to_80 sp
CROSS JOIN total_sellers t
ORDER BY sp.revenue DESC;

/*
            seller_id             |  revenue  | running_total |  total_rev  | percentage | total_sellers | sellers_to_reach_80 | sellers_percentage
----------------------------------+-----------+---------------+-------------+------------+---------------+---------------------+--------------------
 4869f7a5dfa277a7dca6462dcf3b52b2 | 229237.63 |     229237.63 | 13433961.52 |       1.71 |          3095 |                 534 |              17.25
 53243585a1d6dc2643021fd1853d8905 | 222529.43 |     451767.06 | 13433961.52 |       3.36 |          3095 |                 534 |              17.25
 4a3ca9315b744ce9f8e9374361493884 | 200326.12 |     652093.18 | 13433961.52 |       4.85 |          3095 |                 534 |              17.25
 fa1c13f2614d7b5c4749cbc52fecda94 | 192553.33 |     844646.51 | 13433961.52 |       6.29 |          3095 |                 534 |              17.25
 7c67e1448b00f6e969d365cea6b010ab | 187923.89 |    1032570.40 | 13433961.52 |       7.69 |          3095 |                 534 |              17.25
 7e93a43ef30c4f03f38b393420bc753a | 170305.46 |    1202875.86 | 13433961.52 |       8.95 |          3095 |                 534 |              17.25
 da8622b14eb17ae2831f4ac5b9dab84a | 160236.57 |    1363112.43 | 13433961.52 |      10.15 |          3095 |                 534 |              17.25
 7a67c85e85bb2ce8582c35f2203ad736 | 141715.54 |    1504827.97 | 13433961.52 |      11.20 |          3095 |                 534 |              17.25
 1025f0e2d44d7041d6cf58b6550e0bfa | 138968.55 |    1643796.52 | 13433961.52 |      12.24 |          3095 |                 534 |              17.25
 955fee9216a65b617aa5c0531780ce60 | 135159.70 |    1778956.22 | 13433961.52 |      13.24 |          3095 |                 534 |              17.25
 ... (534 rows in total; the rest not shown)

534 of 3,095 sellers (17.25%) produce 80% of revenue. The largest seller holds 1.71%; the top 10 hold 13.24%.
*/
