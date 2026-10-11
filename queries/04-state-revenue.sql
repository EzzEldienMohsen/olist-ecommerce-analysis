-- Question:    For each customer state: sale orders, real customers, revenue, share of total
--              revenue and average order value. How concentrated is revenue by state?
-- Rows:        27, one per state
-- Measures:    revenue share = state revenue out of all sale revenue;
--              average order value = state revenue / state sale orders
-- Assumptions: sale statuses as in query 01; customer = customer_unique_id (a person),
--              not customer_id (one per order); revenue = item price, freight excluded

WITH state_counts (state, orders, customers) AS (
    SELECT c.customer_state,
           COUNT(DISTINCT o.order_id),
           COUNT(DISTINCT c.customer_unique_id)
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY c.customer_state
),
state_rev (state, revenue) AS (
    SELECT c.customer_state,
           ROUND(SUM(oi.price)::NUMERIC, 2)
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY c.customer_state
),
state_stats (state, orders, customers, revenue, average_order_value, running_total) AS (
    SELECT sc.state, sc.orders, sc.customers, sr.revenue,
           ROUND((sr.revenue / NULLIF(sc.orders, 0))::NUMERIC, 2),
           ROUND(SUM(sr.revenue) OVER (ORDER BY sr.revenue DESC)::NUMERIC, 2)
    FROM state_counts sc
    INNER JOIN state_rev sr ON sc.state = sr.state
),
total (total) AS (
    SELECT ROUND(SUM(revenue)::NUMERIC, 2) FROM state_rev
)
SELECT s.state, s.orders, s.customers, s.revenue, s.average_order_value, s.running_total,
       ROUND((s.running_total * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS cumulative_share,
       ROUND((s.revenue * 100.0 / NULLIF(t.total, 0))::NUMERIC, 2) AS share_of_total
FROM state_stats s
CROSS JOIN total t
ORDER BY s.revenue DESC;

/*
 state | orders | customers |  revenue   | average_order_value | running_total | cumulative_share | share_of_total
-------+--------+-----------+------------+---------------------+---------------+------------------+----------------
 SP    |  40990 |     39619 | 5135956.61 |              125.30 |    5135956.61 |            38.23 |          38.23
 RJ    |  12665 |     12210 | 1804283.24 |              142.46 |    6940239.85 |            51.66 |          13.43
 MG    |  11465 |     11106 | 1568317.94 |              136.79 |    8508557.79 |            63.34 |          11.67
 RS    |   5402 |      5221 |  740534.55 |              137.09 |    9249092.34 |            68.85 |           5.51
 PR    |   4967 |      4810 |  674289.63 |              135.75 |    9923381.97 |            73.87 |           5.02
 SC    |   3586 |      3488 |  514328.32 |              143.43 |   10437710.29 |            77.70 |           3.83
 BA    |   3333 |      3234 |  504829.36 |              151.46 |   10942539.65 |            81.45 |           3.76
 DF    |   2113 |      2050 |  300274.96 |              142.11 |   11242814.61 |            83.69 |           2.24
 GO    |   1993 |      1929 |  286803.80 |              143.91 |   11529618.41 |            85.82 |           2.13
 ES    |   2016 |      1948 |  273448.63 |              135.64 |   11803067.04 |            87.86 |           2.04
 PE    |   1633 |      1590 |  259461.64 |              158.89 |   12062528.68 |            89.79 |           1.93
 CE    |   1318 |      1296 |  224873.28 |              170.62 |   12287401.96 |            91.47 |           1.67
 PA    |    967 |       942 |  178322.23 |              184.41 |   12465724.19 |            92.79 |           1.33
 MT    |    901 |       871 |  155704.53 |              172.81 |   12621428.72 |            93.95 |           1.16
 MA    |    736 |       715 |  119291.62 |              162.08 |   12740720.34 |            94.84 |           0.89
 MS    |    705 |       684 |  116258.85 |              164.91 |   12856979.19 |            95.71 |           0.87
 PB    |    529 |       514 |  114464.30 |              216.38 |   12971443.49 |            96.56 |           0.85
 PI    |    487 |       475 |   86031.19 |              176.66 |   13057474.68 |            97.20 |           0.64
 RN    |    481 |       470 |   82909.08 |              172.37 |   13140383.76 |            97.81 |           0.62
 AL    |    408 |       396 |   80066.12 |              196.24 |   13220449.88 |            98.41 |           0.60
 SE    |    345 |       338 |   58920.85 |              170.79 |   13279370.73 |            98.85 |           0.44
 TO    |    277 |       270 |   49328.99 |              178.08 |   13328699.72 |            99.22 |           0.37
 RO    |    244 |       232 |   45807.76 |              187.74 |   13374507.48 |            99.56 |           0.34
 AM    |    147 |       142 |   22356.84 |              152.09 |   13396864.32 |            99.72 |           0.17
 AC    |     81 |        77 |   15982.95 |              197.32 |   13412847.27 |            99.84 |           0.12
 AP    |     67 |        66 |   13374.81 |              199.62 |   13426222.08 |            99.94 |           0.10
 RR    |     45 |        44 |    7739.44 |              171.99 |   13433961.52 |           100.00 |           0.06
(27 rows)
*/
