-- Q4A: Repeat purchase rate and median days to second order
WITH ranked AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp AS ts,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS rn
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
),
firsts AS (
    SELECT
        customer_unique_id,
        MIN(ts) FILTER (WHERE rn = 1) AS first_order,
        MIN(ts) FILTER (WHERE rn = 2) AS second_order
    FROM ranked
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*)                                             AS total_customers,
    COUNT(second_order)                                  AS repeat_customers,
    ROUND(COUNT(second_order) * 100.0 / COUNT(*), 1)     AS repeat_rate_pct,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY second_order::DATE - first_order::DATE
    )                                                    AS median_days_to_second
FROM firsts;


-- Q4B: Monthly cohort retention for 2017 cohorts
WITH monthly AS (
    SELECT
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1, 2
),
cohorts AS (
    SELECT customer_unique_id, MIN(order_month) AS cohort_month
    FROM monthly
    GROUP BY customer_unique_id
),
activity AS (
    SELECT
        co.cohort_month,
        (EXTRACT(YEAR  FROM AGE(m.order_month, co.cohort_month)) * 12
       + EXTRACT(MONTH FROM AGE(m.order_month, co.cohort_month)))::INT AS month_number,
        COUNT(DISTINCT m.customer_unique_id) AS customers
    FROM monthly m
    JOIN cohorts co ON m.customer_unique_id = co.customer_unique_id
    GROUP BY 1, 2
)
SELECT
    cohort_month,
    month_number,
    customers,
    ROUND(customers * 100.0 /
          FIRST_VALUE(customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 2)
        AS retention_pct
FROM activity
WHERE cohort_month < '2018-01-01'
  AND month_number <= 6
ORDER BY cohort_month, month_number;