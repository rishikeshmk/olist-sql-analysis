-- Q3A: How many orders does each customer place?
WITH customer_orders AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS frequency
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
)
SELECT frequency,
       COUNT(*) AS customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_customers
FROM customer_orders
GROUP BY frequency
ORDER BY frequency;


-- Q3B: RFM segmentation (delivered orders, Jan 2017 to Aug 2018)
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE AS last_order,
        COUNT(DISTINCT o.order_id)            AS frequency,
        SUM(i.price)                          AS monetary
    FROM orders o
    JOIN customers c   ON o.customer_id = c.customer_id
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY c.customer_unique_id
),
scored AS (
    SELECT
        customer_unique_id,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY last_order)  AS r_score,   -- 5 = most recent
        CASE WHEN frequency = 1 THEN 1
             WHEN frequency = 2 THEN 3
             ELSE 5 END                      AS f_score,
        NTILE(5) OVER (ORDER BY monetary)    AS m_score    -- 5 = biggest spenders
    FROM customer_orders
),
segmented AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal repeat buyers'
            WHEN r_score >= 4                  THEN 'Recent customers'
            WHEN m_score >= 4 AND r_score <= 2 THEN 'At-risk big spenders'
            WHEN r_score <= 2 AND m_score <= 2 THEN 'Lost / low value'
            ELSE 'Others'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                                       AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)             AS pct_customers,
    ROUND(SUM(monetary), 0)                                        AS revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1)   AS pct_revenue,
    ROUND(AVG(monetary), 0)                                        AS avg_spend
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;