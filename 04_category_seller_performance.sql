-- Q2A: Top 15 categories by revenue, with share and cumulative share
WITH category_revenue AS (
    SELECT
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(i.price)               AS revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    JOIN products p    ON i.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
           ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1
)
SELECT
    category,
    orders,
    revenue,
    RANK() OVER (ORDER BY revenue DESC)                              AS revenue_rank,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 1)                 AS pct_of_total,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0
          / SUM(revenue) OVER (), 1)                                 AS cumulative_pct
FROM category_revenue
ORDER BY revenue_rank
LIMIT 15;


-- Q2B: How concentrated is revenue across sellers? (10 equal-sized groups)
WITH seller_revenue AS (
    SELECT
        i.seller_id,
        SUM(i.price) AS revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY i.seller_id
),
ranked AS (
    SELECT
        seller_id,
        revenue,
        NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM seller_revenue
)
SELECT
    decile,
    COUNT(*)                                                          AS sellers,
    ROUND(SUM(revenue), 0)                                            AS revenue,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 1)        AS pct_of_revenue
FROM ranked
GROUP BY decile
ORDER BY decile;


-- Q2C: Top 3 categories per customer state
WITH state_category AS (
    SELECT
        c.customer_state,
        COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
        SUM(i.price) AS revenue
    FROM orders o
    JOIN customers c   ON o.customer_id = c.customer_id
    JOIN order_items i ON o.order_id = i.order_id
    JOIN products p    ON i.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
           ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
    GROUP BY 1, 2
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY customer_state ORDER BY revenue DESC) AS rnk
    FROM state_category
)
SELECT customer_state, rnk, category, ROUND(revenue, 0) AS revenue
FROM ranked
WHERE rnk <= 3
ORDER BY customer_state, rnk;