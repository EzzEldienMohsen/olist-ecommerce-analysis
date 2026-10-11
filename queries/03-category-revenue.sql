-- Question:    Which product categories earn the most revenue, and what share of all revenue is each?
-- Rows:        one per category (top rows shown below)
-- Measures:    category revenue out of all sale revenue (13,433,961.52)
-- Assumptions: sale statuses as in query 01; revenue = item price, freight excluded;
--              products with no category or no English translation are kept in the total
--              (LEFT JOIN) and grouped under a NULL name: 182,206.73, 1.36% of revenue

WITH prod_rev (prod_id, revenue) AS (
    SELECT oi.product_id,
           ROUND(SUM(oi.price)::NUMERIC, 2)
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY oi.product_id
),
cat_rev (english_name, revenue) AS (
    SELECT ct.product_category_name_english,
           ROUND(SUM(pr.revenue)::NUMERIC, 2)
    FROM products p
    LEFT JOIN prod_rev pr ON pr.prod_id = p.product_id
    LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
    GROUP BY ct.product_category_name_english
),
cat_rev_rank (name, revenue, rank) AS (
    SELECT english_name, revenue,
           ROW_NUMBER() OVER (ORDER BY revenue DESC)
    FROM cat_rev
),
running_total (name, rank, running_total) AS (
    SELECT name, rank,
           ROUND(SUM(revenue) OVER (ORDER BY rank)::NUMERIC, 2)
    FROM cat_rev_rank
),
total (total) AS (
    SELECT ROUND(SUM(revenue)::NUMERIC, 2) FROM cat_rev
)
SELECT c.name, c.revenue, c.rank, cr.running_total, t.total,
       ROUND((cr.running_total * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS cumulative_share,
       ROUND((c.revenue * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS share
FROM cat_rev_rank c
LEFT JOIN running_total cr ON c.name IS NOT DISTINCT FROM cr.name
CROSS JOIN total t
ORDER BY c.rank;

/*
         name          |  revenue   | rank | running_total |    total    | cumulative_share | share
-----------------------+------------+------+---------------+-------------+------------------+-------
 health_beauty         | 1253883.64 |    1 |    1253883.64 | 13433961.52 |             9.33 |  9.33
 watches_gifts         | 1192647.13 |    2 |    2446530.77 | 13433961.52 |            18.21 |  8.88
 bed_bath_table        | 1035370.87 |    3 |    3481901.64 | 13433961.52 |            25.92 |  7.71
 sports_leisure        |  975730.95 |    4 |    4457632.59 | 13433961.52 |            33.18 |  7.26
 computers_accessories |  900439.41 |    5 |    5358072.00 | 13433961.52 |            39.88 |  6.70
 furniture_decor       |  721186.57 |    6 |    6079258.57 | 13433961.52 |            45.25 |  5.37
 housewares            |  624967.57 |    7 |    6704226.14 | 13433961.52 |            49.91 |  4.65
 cool_stuff            |  618941.74 |    8 |    7323167.88 | 13433961.52 |            54.51 |  4.61
 auto                  |  584923.46 |    9 |    7908091.34 | 13433961.52 |            58.87 |  4.35
 garden_tools          |  478110.14 |   10 |    8386201.48 | 13433961.52 |            62.43 |  3.56
 toys                  |  475741.28 |   11 |    8861942.76 | 13433961.52 |            65.97 |  3.54
 ... (remaining categories not shown)
*/
