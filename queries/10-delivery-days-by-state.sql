-- Question:    How many days does delivery take on average in each customer state, slowest first?
-- Rows:        27, one per state
-- Measures:    average of (delivery date - purchase date) in days, per state
-- Assumptions: delivered orders with a delivery date only; days counted between calendar dates;
--              cut-off for trusting an average: at least 30 orders per state.
--              The smallest state, RR, has 45 sale orders (query 04), so all 27 states are kept.

WITH order_delivery (order_id, customer_id, delivery_days) AS (
    SELECT order_id, customer_id,
           order_delivered_customer_date::DATE - order_purchase_timestamp::DATE
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
),
state_days_avg (state, delivery_days_avg) AS (
    SELECT c.customer_state,
           ROUND(AVG(od.delivery_days)::NUMERIC, 2)
    FROM customers c
    INNER JOIN order_delivery od ON c.customer_id = od.customer_id
    GROUP BY c.customer_state
)
SELECT state, delivery_days_avg
FROM state_days_avg
ORDER BY delivery_days_avg DESC;

/*
 state | delivery_days_avg
-------+-------------------
 RR    |             29.34
 AP    |             27.18
 AM    |             26.36
 AL    |             24.50
 PA    |             23.73
 MA    |             21.51
 SE    |             21.46
 CE    |             21.20
 AC    |             21.00
 PB    |             20.39
 PI    |             19.39
 BA    |             19.28
 RO    |             19.28
 RN    |             19.22
 PE    |             18.40
 MT    |             18.00
 TO    |             17.60
 ES    |             15.72
 GO    |             15.54
 MS    |             15.54
 RS    |             15.25
 RJ    |             15.24
 SC    |             14.90
 DF    |             12.90
 MG    |             11.94
 PR    |             11.94
 SP    |              8.70
(27 rows)
*/