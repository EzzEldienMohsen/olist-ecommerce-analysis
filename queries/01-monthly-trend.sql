-- Question:    For each complete month, how many sale orders, how much revenue, what average
--              order value, and how did each change from the previous month?
-- Rows:        19, one per complete month (2017-02 to 2018-08)
-- Measures:    orders and revenue per month; average order value = revenue / orders
-- Assumptions: sale = shipped, invoiced, approved, delivered (processing, 0.30% of orders, left out);
--              revenue = sum of item price, freight excluded;
--              a month is complete when every one of its days has at least one order
--              (worked out from the data, not hard-coded; see notes/data-checks.md);
--              order month = purchase month

WITH month_check (month, days_with_orders) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE,
           COUNT(DISTINCT order_purchase_timestamp::DATE)
    FROM orders
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
),
complete_months (month) AS (
    SELECT month
    FROM month_check
    WHERE days_with_orders = (month + INTERVAL '1 month')::DATE - month
),
monthly_data (month, orders, revenue) AS (
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp)::DATE,
           COUNT(DISTINCT o.order_id),
           ROUND(SUM(oi.price)::NUMERIC, 2)
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
),
monthly_report (month, orders, revenue, avg_order_value) AS (
    SELECT cm.month,
           COALESCE(md.orders, 0),
           COALESCE(md.revenue, 0),
           ROUND((md.revenue / NULLIF(md.orders, 0))::NUMERIC, 2)
    FROM complete_months cm
    LEFT JOIN monthly_data md ON cm.month = md.month
)
SELECT month, orders, revenue, avg_order_value,
       LAG(orders) OVER (ORDER BY month) AS prev_orders,
       orders - LAG(orders) OVER (ORDER BY month) AS orders_diff,
       LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))::NUMERIC, 2) AS revenue_diff,
       LAG(avg_order_value) OVER (ORDER BY month) AS prev_aov,
       ROUND((avg_order_value - LAG(avg_order_value) OVER (ORDER BY month))::NUMERIC, 2) AS aov_diff
FROM monthly_report
ORDER BY month;

/*
   month    | orders |  revenue  | avg_order_value | prev_orders | orders_diff | prev_revenue | revenue_diff | prev_aov | aov_diff
------------+--------+-----------+-----------------+-------------+-------------+--------------+--------------+----------+----------
 2017-02-01 |   1686 | 239098.99 |          141.81 |             |             |              |              |          |
 2017-03-01 |   2594 | 363601.87 |          140.17 |        1686 |         908 |    239098.99 |    124502.88 |   141.81 |    -1.64
 2017-04-01 |   2367 | 348049.83 |          147.04 |        2594 |        -227 |    363601.87 |    -15552.04 |   140.17 |     6.87
 2017-05-01 |   3617 | 499417.22 |          138.07 |        2367 |        1250 |    348049.83 |    151367.39 |   147.04 |    -8.97
 2017-06-01 |   3193 | 427600.89 |          133.92 |        3617 |        -424 |    499417.22 |    -71816.33 |   138.07 |    -4.15
 2017-07-01 |   3935 | 490801.42 |          124.73 |        3193 |         742 |    427600.89 |     63200.53 |   133.92 |    -9.19
 2017-08-01 |   4254 | 563911.91 |          132.56 |        3935 |         319 |    490801.42 |     73110.49 |   124.73 |     7.83
 2017-09-01 |   4205 | 617593.91 |          146.87 |        4254 |         -49 |    563911.91 |     53682.00 |   132.56 |    14.31
 2017-10-01 |   4527 | 656134.23 |          144.94 |        4205 |         322 |    617593.91 |     38540.32 |   146.87 |    -1.93
 2017-11-01 |   7396 | 999310.64 |          135.12 |        4527 |        2869 |    656134.23 |    343176.41 |   144.94 |    -9.82
 2017-12-01 |   5583 | 734276.94 |          131.52 |        7396 |       -1813 |    999310.64 |   -265033.70 |   135.12 |    -3.60
 2018-01-01 |   7158 | 941460.24 |          131.53 |        5583 |        1575 |    734276.94 |    207183.30 |   131.52 |     0.01
 2018-02-01 |   6618 | 836995.36 |          126.47 |        7158 |        -540 |    941460.24 |   -104464.88 |   131.53 |    -5.06
 2018-03-01 |   7159 | 979076.52 |          136.76 |        6618 |         541 |    836995.36 |    142081.16 |   126.47 |    10.29
 2018-04-01 |   6911 | 992085.38 |          143.55 |        7159 |        -248 |    979076.52 |     13008.86 |   136.76 |     6.79
 2018-05-01 |   6827 | 992126.40 |          145.32 |        6911 |         -84 |    992085.38 |        41.02 |   143.55 |     1.77
 2018-06-01 |   6145 | 863265.53 |          140.48 |        6827 |        -682 |    992126.40 |   -128860.87 |   145.32 |    -4.84
 2018-07-01 |   6232 | 878003.37 |          140.89 |        6145 |          87 |    863265.53 |     14737.84 |   140.48 |     0.41
 2018-08-01 |   6421 | 848860.10 |          132.20 |        6232 |         189 |    878003.37 |    -29143.27 |   140.89 |    -8.69
(19 rows)
*/
