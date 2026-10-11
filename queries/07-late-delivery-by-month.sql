-- Question:    For each complete month, what share of delivered orders arrived after the estimated date?
-- Rows:        19, one per complete month (2017-02 to 2018-08)
-- Measures:    late orders out of delivered orders that have a delivery date (late_share_of_delivered)
-- Assumptions: month = purchase month; complete months as in query 01;
--              late = delivered timestamp later than the estimated delivery timestamp;
--              8 delivered orders have no delivery date and are left out of both counts
--              (shown in the no_date column)

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
delivered_orders (month, delivered_orders) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE, COUNT(order_id)
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
),
late_orders (month, late_orders) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE, COUNT(order_id)
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date > order_estimated_delivery_date
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
),
non_delivered_orders (month, non_orders) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE, COUNT(order_id)
    FROM orders
    WHERE order_status <> 'delivered'
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
),
total (month, total) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE, COUNT(*)
    FROM orders
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
),
no_delivery_date (month, no_date) AS (
    SELECT DATE_TRUNC('month', order_purchase_timestamp)::DATE, COUNT(order_id)
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NULL
    GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE
)
SELECT m.month, d.delivered_orders, l.late_orders, n.non_orders, t.total, nd.no_date,
       ROUND(l.late_orders * 100.0 / NULLIF(t.total, 0), 2) AS late_share_of_total,
       ROUND(d.delivered_orders * 100.0 / NULLIF(t.total, 0), 2) AS delivered_share_of_total,
       ROUND(l.late_orders * 100.0 / NULLIF(d.delivered_orders, 0), 2) AS late_share_of_delivered
FROM complete_months m
LEFT JOIN delivered_orders d ON m.month = d.month
LEFT JOIN late_orders l ON m.month = l.month
LEFT JOIN no_delivery_date nd ON m.month = nd.month
LEFT JOIN non_delivered_orders n ON m.month = n.month
LEFT JOIN total t ON m.month = t.month
ORDER BY m.month;

/*
   month    | delivered_orders | late_orders | non_orders | total | no_date | late_share_of_total | delivered_share_of_total | late_share_of_delivered
------------+------------------+-------------+------------+-------+---------+---------------------+--------------------------+-------------------------
 2017-02-01 |             1653 |          53 |        127 |  1780 |         |                2.98 |                    92.87 |                    3.21
 2017-03-01 |             2546 |         142 |        136 |  2682 |         |                5.29 |                    94.93 |                    5.58
 2017-04-01 |             2303 |         181 |        101 |  2404 |         |                7.53 |                    95.80 |                    7.86
 2017-05-01 |             3545 |         128 |        154 |  3700 |       1 |                3.46 |                    95.81 |                    3.61
 2017-06-01 |             3135 |         121 |        110 |  3245 |         |                3.73 |                    96.61 |                    3.86
 2017-07-01 |             3872 |         133 |        154 |  4026 |         |                3.30 |                    96.17 |                    3.43
 2017-08-01 |             4193 |         139 |        138 |  4331 |         |                3.21 |                    96.81 |                    3.32
 2017-09-01 |             4150 |         216 |        135 |  4285 |         |                5.04 |                    96.85 |                    5.20
 2017-10-01 |             4478 |         237 |        153 |  4631 |         |                5.12 |                    96.70 |                    5.29
 2017-11-01 |             7288 |        1043 |        255 |  7544 |       1 |               13.83 |                    96.61 |                   14.31
 2017-12-01 |             5513 |         462 |        160 |  5673 |         |                8.14 |                    97.18 |                    8.38
 2018-01-01 |             7069 |         464 |        200 |  7269 |         |                6.38 |                    97.25 |                    6.56
 2018-02-01 |             6555 |        1048 |        173 |  6728 |         |               15.58 |                    97.43 |                   15.99
 2018-03-01 |             7003 |        1496 |        208 |  7211 |         |               20.75 |                    97.12 |                   21.36
 2018-04-01 |             6798 |         361 |        141 |  6939 |         |                5.20 |                    97.97 |                    5.31
 2018-05-01 |             6749 |         556 |        124 |  6873 |         |                8.09 |                    98.20 |                    8.24
 2018-06-01 |             6096 |          83 |         68 |  6167 |       3 |                1.35 |                    98.85 |                    1.36
 2018-07-01 |             6156 |         276 |        133 |  6292 |       3 |                4.39 |                    97.84 |                    4.48
 2018-08-01 |             6351 |         660 |        161 |  6512 |         |               10.14 |                    97.53 |                   10.39
(19 rows)

Across the 19 months: 7,799 late of 95,453 delivered = 8.17%.
*/
