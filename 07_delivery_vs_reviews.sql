-- Q5.0: Delivered orders in scope, and what's missing
SELECT
    COUNT(*)                                                      AS delivered_orders,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date,
    COUNT(*) FILTER (WHERE order_id NOT IN
                    (SELECT order_id FROM order_reviews))         AS no_review
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01';


  -- Q5A: Review scores for on-time vs. late deliveries
WITH latest_review AS (
    SELECT order_id, review_score
    FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (
                   PARTITION BY order_id
                   ORDER BY review_creation_date DESC, review_answer_timestamp DESC
               ) AS rn
        FROM order_reviews
    ) t
    WHERE rn = 1
),
delivery AS (
    SELECT
        order_id,
        order_delivered_customer_date::DATE
          - order_estimated_delivery_date::DATE AS days_late
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp <  '2018-09-01'
)
SELECT
    CASE WHEN d.days_late <= 0 THEN 'On time' ELSE 'Late' END     AS delivery_status,
    COUNT(*)                                                      AS orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)            AS pct_of_orders,
    ROUND(AVG(r.review_score), 2)                                 AS avg_review_score,
    ROUND(COUNT(*) FILTER (WHERE r.review_score <= 2) * 100.0
          / COUNT(*), 1)                                          AS pct_1_2_stars
FROM delivery d
JOIN latest_review r ON d.order_id = r.order_id
GROUP BY 1
ORDER BY 1 DESC;


-- Q5B: Review score by how late the order was
WITH latest_review AS (
    SELECT order_id, review_score
    FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (
                   PARTITION BY order_id
                   ORDER BY review_creation_date DESC, review_answer_timestamp DESC
               ) AS rn
        FROM order_reviews
    ) t
    WHERE rn = 1
),
delivery AS (
    SELECT
        order_id,
        order_delivered_customer_date::DATE
          - order_estimated_delivery_date::DATE AS days_late
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp >= '2017-01-01'
      AND order_purchase_timestamp <  '2018-09-01'
),
bucketed AS (
    SELECT
        r.review_score,
        CASE
            WHEN d.days_late <= 0 THEN '1. On time or early'
            WHEN d.days_late <= 3 THEN '2. 1-3 days late'
            WHEN d.days_late <= 7 THEN '3. 4-7 days late'
            ELSE                       '4. 8+ days late'
        END AS delay_bucket
    FROM delivery d
    JOIN latest_review r ON d.order_id = r.order_id
)
SELECT
    delay_bucket,
    COUNT(*)                          AS orders,
    ROUND(AVG(review_score), 2)       AS avg_review_score
FROM bucketed
GROUP BY delay_bucket
ORDER BY delay_bucket;


-- Q5C: Late-delivery rate and review score by customer state
WITH latest_review AS (
    SELECT order_id, review_score
    FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (
                   PARTITION BY order_id
                   ORDER BY review_creation_date DESC, review_answer_timestamp DESC
               ) AS rn
        FROM order_reviews
    ) t
    WHERE rn = 1
)
SELECT
    c.customer_state,
    COUNT(*)                                                       AS orders,
    ROUND(COUNT(*) FILTER (
        WHERE o.order_delivered_customer_date::DATE
            > o.order_estimated_delivery_date::DATE) * 100.0
        / COUNT(*), 1)                                             AS late_pct,
    ROUND(AVG(r.review_score), 2)                                  AS avg_review_score
FROM orders o
JOIN customers c     ON o.customer_id = c.customer_id
JOIN latest_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_state
HAVING COUNT(*) >= 300
ORDER BY late_pct DESC;