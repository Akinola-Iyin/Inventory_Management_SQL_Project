-- ========================================
-- Phase 3 - Strategic & Predictive Analytics
-- ========================================

-- 1. Product Sales Seasonality (top 3 products by sales for each month in each year)
WITH ranking AS (
  SELECT
    o.year_id,
    o.month_id,
    p.product_line,
    od.product_code,
    SUM(od.sales) AS total_sales,
    DENSE_RANK() OVER(PARTITION BY o.year_id, o.month_id ORDER BY SUM(od.sales) DESC) AS rnk
  FROM orders o
  JOIN order_details od ON o.order_number = od.order_number
  JOIN products p ON od.product_code = p.product_code
  GROUP BY o.year_id, o.month_id, od.product_code, p.product_line
)
SELECT
  year_id,
  month_id,
  product_line,
  product_code,
  total_sales,
  rnk
FROM ranking
WHERE rnk <= 3;

-- 2. Quarterly Product Line Growth with Growth % (sales growth in % per product line from q to q in each year)
WITH quarterly_sales AS (
  SELECT
    o.year_id,
    o.qtr_id,
    p.product_line,
    SUM(od.sales) AS total_sales
  FROM orders o
  JOIN order_details od ON o.order_number = od.order_number
  JOIN products p ON od.product_code = p.product_code
  GROUP BY o.year_id, o.qtr_id, p.product_line
),
sales_with_growth AS (
  SELECT
    year_id,
    qtr_id,
    product_line,
    total_sales,
    LEAD(total_sales, 1) OVER (PARTITION BY product_line ORDER BY year_id, qtr_id) AS next_qtr_sales
  FROM quarterly_sales
)
SELECT
  year_id,
  qtr_id,
  product_line,
  total_sales,
  next_qtr_sales,
  ROUND(
    CASE 
      WHEN total_sales = 0 THEN NULL
      ELSE ((next_qtr_sales - total_sales) / total_sales) * 100
    END
  , 2) AS growth_percent
FROM sales_with_growth
ORDER BY product_line, year_id, qtr_id;

-- 3. Detect Underperforming Product Lines (prooduct lines where sales have declined for 2+ consecutive quarters)
WITH quarterly_sales AS (
  SELECT
    o.year_id,
    o.qtr_id,
    p.product_line,
    SUM(od.sales) AS present_qtr_sales
  FROM orders o
  JOIN order_details od ON o.order_number = od.order_number
  JOIN products p ON od.product_code = p.product_code
  GROUP BY o.year_id, o.qtr_id, p.product_line
),
qtr_to_qtr_sales AS (
  SELECT
    year_id,
    qtr_id,
    product_line,
    present_qtr_sales,
    LEAD(present_qtr_sales, 1) OVER (PARTITION BY product_line ORDER BY year_id, qtr_id) AS next_qtr_sales
  FROM quarterly_sales
),
sales_with_decline_flag AS (
  SELECT
    year_id,
    qtr_id,
    product_line,
    present_qtr_sales,
    next_qtr_sales,
    CASE
      WHEN next_qtr_sales IS NULL THEN 0
      WHEN next_qtr_sales < present_qtr_sales THEN 1
      ELSE 0
    END AS is_decline
  FROM qtr_to_qtr_sales
),
consecutive_declines AS (
  SELECT
    year_id,
    qtr_id,
    product_line,
    present_qtr_sales,
    next_qtr_sales,
    is_decline,
    SUM(is_decline) OVER (
      PARTITION BY product_line
      ORDER BY year_id, qtr_id
      ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS consecutive_decline_count
  FROM sales_with_decline_flag
)
SELECT
  product_line,
  year_id,
  qtr_id,
  present_qtr_sales,
  next_qtr_sales,
  is_decline,
  consecutive_decline_count
FROM consecutive_declines
WHERE consecutive_decline_count >= 2
ORDER BY product_line, year_id, qtr_id;

-- 4. Category Contribution to Revenue (% of total revenue each product line contributes per year)
WITH product_line_revenue AS (
  SELECT
    o.year_id,
    p.product_line,
    SUM(od.sales) AS total_revenue
  FROM orders o
  JOIN order_details od ON o.order_number = od.order_number
  JOIN products p ON od.product_code = p.product_code
  GROUP BY o.year_id, p.product_line
),
revenue AS (
  SELECT
    year_id,
    product_line,
    total_revenue,
    SUM(total_revenue) OVER (PARTITION BY year_id) AS yearly_revenue
  FROM product_line_revenue
)
SELECT
  year_id,
  product_line,
  yearly_revenue,
  total_revenue,
  ROUND((total_revenue / yearly_revenue) * 100, 2) AS percentage_of_yearly_revenue
FROM revenue
ORDER BY year_id, percentage_of_yearly_revenue DESC;

-- 5. Restock Prioritization Model (products that sell frequently, bring high revenue and have frequent low-quantity orders)
WITH order_count AS (
  SELECT
    product_code,
    SUM(quantity_ordered) AS total_quantity,
    SUM(CASE WHEN quantity_ordered < 20 THEN 1 ELSE 0 END) AS low_stock_count,
    SUM(sales) AS total_revenue
  FROM order_details
  GROUP BY product_code
)
SELECT
  oc.product_code,
  p.product_line,
  oc.total_quantity,
  oc.low_stock_count,
  oc.total_revenue,
  (oc.total_quantity + oc.total_revenue + oc.low_stock_count * 10) AS restock_score
FROM order_count oc
JOIN products p ON oc.product_code = p.product_code
ORDER BY restock_score DESC;
