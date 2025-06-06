-- ========================================
-- Phase 2 - Inventory & Sales Insights
-- ========================================

-- 1. Low-Stock Product Detection(i.e orders < 20)
SELECT
  product_code,
  COUNT(*) AS low_quantity_order_count
FROM order_details
WHERE quantity_ordered < 20
GROUP BY product_code
ORDER BY low_quantity_order_count DESC;

-- 2. Monthly Sales Trend by Product Line
SELECT
  o.year_id,
  o.month_id,
  p.product_line,
  SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od ON o.order_number = od.order_number
JOIN products p ON od.product_code = p.product_code
GROUP BY o.year_id, o.month_id, p.product_line
ORDER BY o.year_id, o.month_id, p.product_line;

-- 3. Average Order Size per Product (Average number of units ordered per line for each product)
SELECT
  p.product_line,
  od.product_code,
  AVG(od.quantity_ordered) AS avg_order_per_product
FROM order_details od
JOIN products p ON od.product_code = p.product_code
GROUP BY p.product_line, od.product_code
ORDER BY p.product_line, od.product_code;

-- 4. Bottom 5 Products by Sales
SELECT
  od.product_code,
  p.product_line,
  SUM(od.sales) AS total_sales
FROM order_details od
JOIN products p ON od.product_code = p.product_code
GROUP BY od.product_code, p.product_line
ORDER BY total_sales ASC
LIMIT 5;

-- 5. Region-Based Product Performance
SELECT
  c.country,
  c.territory,
  p.product_line,
  SUM(od.sales) AS total_sales_per_country
FROM products p
JOIN order_details od ON p.product_code = od.product_code
JOIN orders o ON od.order_number = o.order_number
JOIN customers c ON o.customer_name = c.customer_name
GROUP BY c.country, c.territory, p.product_line
ORDER BY c.country, c.territory, p.product_line;
