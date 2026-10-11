-- Question:    Do late deliveries get lower review scores?
-- Rows:        3 (Late, On_time, No_date)
-- Measures:    average review score per order, compared between late and on-time delivered orders
-- Assumptions: 547 orders have more than one review; each order's score is the average of its
--              reviews, so every order counts once. late = delivered timestamp later than the
--              estimated timestamp (as in query 07). All months are included.
--              The 8 No_date orders are too few to read and are left out of the finding.
--              This shows an association, not proof that lateness causes the lower score.

WITH order_review (order_id, review) AS (
    SELECT order_id,
           ROUND(AVG(review_score)::NUMERIC, 2)
    FROM reviews
    GROUP BY order_id
),
flag (order_id, flag) AS (
    SELECT order_id,
           CASE WHEN order_estimated_delivery_date >= order_delivered_customer_date THEN 'On_time'
                WHEN order_estimated_delivery_date <  order_delivered_customer_date THEN 'Late'
                WHEN order_delivered_customer_date IS NULL THEN 'No_date'
           END
    FROM orders
    WHERE order_status = 'delivered'
)
SELECT f.flag,
       ROUND(AVG(orr.review)::NUMERIC, 2) AS avg_review,
       COUNT(*) AS orders
FROM order_review orr
INNER JOIN flag f ON f.order_id = orr.order_id
GROUP BY f.flag;

/*
  flag   | avg_review | orders
---------+------------+--------
 Late    |       2.57 |   7661
 No_date |       4.50 |      8
 On_time |       4.29 |  88163
(3 rows)

Late orders score 1.72 points (40%) lower. Late = 7,661 of 95,824 reviewed delivered orders (8.0%).
*/
