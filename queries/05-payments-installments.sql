-- Question:    (A) For each payment type: number of orders, total payment value and share of value.
--              (B) For credit-card payments: does the average payment rise with the number of installments?
-- Rows:        (A) one per payment type; (B) 5, one per installment band
-- Measures:    (A) payment value per type out of all payment value; orders counted once per type
--              (B) average payment value per band
-- Assumptions: sale statuses as in query 01. One order can be paid with more than one method
--              (for example a voucher plus a card), so it is counted under each type: the order
--              counts add up to 100,107 against 97,901 sale orders, and shares are based on value.
--              Only credit cards are paid in installments (every other type has exactly 1), so
--              (B) covers credit cards only. The unit in (B) is a payment row, not an order.
--              Payment value includes freight, so its total (15.67M) is higher than item revenue (13.43M).
--              Do not join order_items here: it would repeat each payment once per item.

-- Check: which payment types use installments
SELECT payment_type, COUNT(*) AS payments,
       MIN(payment_installments) AS min_inst, MAX(payment_installments) AS max_inst
FROM payments
GROUP BY payment_type;

/*
 payment_type | payments | min_inst | max_inst
--------------+----------+----------+----------
 not_defined  |        3 |        1 |        1
 boleto       |    19784 |        1 |        1
 debit_card   |     1529 |        1 |        1
 voucher      |     5775 |        1 |        1
 credit_card  |    76795 |        0 |       24
(5 rows)
*/

-- (A) Payment types
WITH type_stats (payment_type, orders, total_value) AS (
    SELECT p.payment_type,
           COUNT(DISTINCT p.order_id),
           ROUND(SUM(p.payment_value)::NUMERIC, 2)
    FROM payments p
    INNER JOIN orders o ON o.order_id = p.order_id
    WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
    GROUP BY p.payment_type
)
SELECT payment_type, orders, total_value,
       ROUND((total_value * 100.0 / SUM(total_value) OVER ())::NUMERIC, 2) AS value_share
FROM type_stats
ORDER BY total_value DESC;

/*
 payment_type | orders | total_value | value_share
--------------+--------+-------------+-------------
 credit_card  |  75393 | 12298625.89 |       78.49
 boleto       |  19467 |  2809491.10 |       17.93
 voucher      |   3734 |   348869.85 |        2.23
 debit_card   |   1513 |   212067.96 |        1.35
(4 rows)
The 3 not_defined payments belong to orders outside the sale statuses.
*/

-- (B) Installment bands, credit cards only (0 installments falls in the '1' band)
SELECT CASE WHEN p.payment_installments <= 1  THEN '1'
            WHEN p.payment_installments <= 3  THEN '2-3'
            WHEN p.payment_installments <= 6  THEN '4-6'
            WHEN p.payment_installments <= 10 THEN '7-10'
            ELSE '11+'
       END AS installment_band,
       COUNT(*) AS payments,
       ROUND(AVG(p.payment_value)::NUMERIC, 2) AS avg_payment_value
FROM payments p
INNER JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status IN ('shipped', 'invoiced', 'approved', 'delivered')
  AND p.payment_type = 'credit_card'
GROUP BY installment_band
ORDER BY MIN(p.payment_installments);

/*
 installment_band | payments | avg_payment_value
------------------+----------+-------------------
 1                |    25086 |             95.61
 2-3              |    22571 |            133.80
 4-6              |    16031 |            180.81
 7-10             |    11655 |            331.25
 11+              |      335 |            360.83
(5 rows)
*/
