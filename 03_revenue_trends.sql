-- Q1: Monthly revenue, growth %, and running total (delivered orders only)
-- Period: Jan 2017 to Aug 2018 (earlier and later months have incomplete data)

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS month,
        COUNT(DISTINCT o.order_id)                            AS orders,
        SUM(i.price)                                          AS revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT
    month,
    orders,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                        AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100, 1
    )                                                         AS growth_pct,
    SUM(revenue) OVER (ORDER BY month)                        AS running_total
FROM monthly_revenue
ORDER BY month;

-- Total revenue for the period
SELECT SUM(i.price) AS total_revenue
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';