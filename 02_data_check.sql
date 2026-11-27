-- 1. Row counts (should be roughly 99k, 3k, 33k, 99k, 112k, 103k, 99k)
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews;

-- 2. Order status breakdown
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 3. Date range of the data
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 4. Missing delivery dates by status
SELECT order_status,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS no_delivery_date
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- 5. Orders with no items (should be very few)
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items i ON o.order_id = i.order_id
WHERE i.order_id IS NULL;

-- 6. Orders with more than one review
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
    SELECT order_id
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;

-- 7. Products with a missing category
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;