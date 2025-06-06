-- ========================================
-- 00 - Data Preparation and Schema
-- Inventory Management SQL Project
-- ========================================

-- ========================================
-- Step 1 - Create Staging Table
-- ========================================

CREATE TABLE sales_data_raw (
    order_number INT,
    quantity_ordered INT,
    price_each DECIMAL(10,2),
    order_line_number INT,
    sales DECIMAL(12,2),
    order_date VARCHAR(50), -- staging import as VARCHAR to allow flexible parsing
    status VARCHAR(20),
    qtr_id INT,
    month_id INT,
    year_id INT,
    product_line VARCHAR(50),
    msrp DECIMAL(10,2),
    product_code VARCHAR(50),
    customer_name VARCHAR(100),
    phone VARCHAR(50),
    address_line1 VARCHAR(100),
    address_line2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    territory VARCHAR(50),
    contact_last_name VARCHAR(50),
    contact_first_name VARCHAR(50),
    deal_size VARCHAR(20)
);

-- ========================================
-- Step 2 - Create Normalized Tables
-- ========================================

-- Products Table
CREATE TABLE products (
    product_code VARCHAR(50) PRIMARY KEY,
    product_line VARCHAR(50),
    msrp DECIMAL(10,2)
);

-- Customers Table
CREATE TABLE customers (
    customer_name VARCHAR(100) PRIMARY KEY,
    phone VARCHAR(50),
    address1 VARCHAR(100),
    address2 VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    country VARCHAR(50),
    territory VARCHAR(50),
    contact_last_name VARCHAR(50),
    contact_first_name VARCHAR(50),
    deal_size VARCHAR(20)
);

-- Orders Table
CREATE TABLE orders (
    order_number INT PRIMARY KEY,
    order_date DATE,
    status VARCHAR(20),
    qtr_id INT,
    month_id INT,
    year_id INT,
    customer_name VARCHAR(100), -- added to allow join to customers
    FOREIGN KEY (customer_name) REFERENCES customers(customer_name)
);

-- Order Details Table
CREATE TABLE order_details (
    order_number INT,
    order_line_number INT,
    product_code VARCHAR(50),
    quantity_ordered INT,
    price_each DECIMAL(10,2),
    sales DECIMAL(12,2),
    PRIMARY KEY (order_number, order_line_number),
    FOREIGN KEY (order_number) REFERENCES orders(order_number),
    FOREIGN KEY (product_code) REFERENCES products(product_code)
);

-- ========================================
-- Step 3 - Populate Normalized Tables
-- ========================================

-- Products
INSERT INTO products (product_code, product_line, msrp)
SELECT DISTINCT
    product_code,
    product_line,
    msrp
FROM sales_data_raw;

-- Customers
INSERT INTO customers (
    customer_name, phone, address1, address2,
    city, state, postal_code, country, territory,
    contact_last_name, contact_first_name, deal_size
)
SELECT DISTINCT
    customer_name, phone, address_line1, address_line2,
    city, state, postal_code, country, territory,
    contact_last_name, contact_first_name, deal_size
FROM sales_data_raw;

-- Orders
INSERT INTO orders (
    order_number, order_date, status, qtr_id, month_id, year_id, customer_name
)
SELECT DISTINCT
    order_number,
    STR_TO_DATE(order_date, '%m/%d/%Y %H:%i'),
    status,
    qtr_id,
    month_id,
    year_id,
    customer_name
FROM sales_data_raw;

-- Order Details
INSERT INTO order_details (
    order_number, order_line_number, product_code,
    quantity_ordered, price_each, sales
)
SELECT
    order_number, order_line_number, product_code,
    quantity_ordered, price_each, sales
FROM sales_data_raw;

-- ========================================
-- End of Data Preparation
-- ========================================
