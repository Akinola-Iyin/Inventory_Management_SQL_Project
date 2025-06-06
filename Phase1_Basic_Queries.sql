-- ========================================
-- Phase 1 - Basic Queries
-- ========================================

-- 1. Top 5 Best-Selling Products
SELECT
  product_code,
  SUM(quantity_ordered) AS total_quantity
FROM order_details
GROUP BY product_code
ORDER BY total_quantity DESC
LIMIT 5;

-- 2. Total Sales & Profit by Product
SELECT
  od.product_code,
  p.product_line,
  SUM(od.sales) AS total_sales,
  SUM((od.price_each - (p.msrp * 0.6)) * od.quantity_ordered) AS estimated_profit
FROM order_details od
JOIN products p ON od.product_code = p.product_code
GROUP BY od.product_code, p.product_line
ORDER BY total_sales DESC;

-- 3. Monthly Sales Trend
SELECT
  o.year_id,
  o.month_id,
  SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od ON o.order_number = od.order_number
GROUP BY o.year_id, o.month_id
ORDER BY o.year_id, o.month_id;

-- 4. Order Volume by Status
SELECT
  status,
  COUNT(order_number) AS order_volume
FROM orders
GROUP BY status;

-- 5. Top 5 Customers by Total Spend
SELECT
  o.customer_name,
  SUM(od.sales) AS total_spent
FROM orders o
JOIN order_details od ON o.order_number = od.order_number
GROUP BY o.customer_name
ORDER BY total_spent DESC
LIMIT 5;
