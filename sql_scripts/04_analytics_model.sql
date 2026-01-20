-- Building Dimensions & Fact Tables
-- Create schema
CREATE SCHEMA IF NOT EXISTS global_superstore_analytics;

------------------------------------------------------------
-- DIMENSIONS

-- Customer Dimension
CREATE TABLE IF NOT EXISTS global_superstore_analytics.dim_customer (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT,
    segment TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    region TEXT,
    market TEXT
);

INSERT INTO global_superstore_analytics.dim_customer
SELECT DISTINCT
    customer_id, customer_name, segment,
    city, state, country, region, market
FROM clean_zone.global_superstore_clean
ON CONFLICT (customer_id) DO NOTHING;

-- Product Dimension
CREATE TABLE IF NOT EXISTS global_superstore_analytics.dim_product (
    product_id TEXT PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    sub_category TEXT
);

INSERT INTO global_superstore_analytics.dim_product
SELECT DISTINCT
    product_id, product_name, category, sub_category
FROM clean_zone.global_superstore_clean
ON CONFLICT (product_id) DO NOTHING;

-- Shipping Dimension
CREATE TABLE IF NOT EXISTS global_superstore_analytics.dim_shipping (
    ship_mode TEXT,
    order_priority TEXT,
    PRIMARY KEY (ship_mode, order_priority)
);

INSERT INTO global_superstore_analytics.dim_shipping
SELECT DISTINCT
    ship_mode, order_priority
FROM clean_zone.global_superstore_clean
ON CONFLICT (ship_mode, order_priority) DO NOTHING;

-- Date Dimension
CREATE TABLE IF NOT EXISTS global_superstore_analytics.dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE UNIQUE,
    day INT,
    month INT,
    year INT,
    quarter INT,
    week_of_year INT
);

INSERT INTO global_superstore_analytics.dim_date (full_date)
SELECT DISTINCT order_date
FROM clean_zone.global_superstore_clean
ON CONFLICT (full_date) DO NOTHING;

INSERT INTO global_superstore_analytics.dim_date (full_date)
SELECT DISTINCT ship_date
FROM clean_zone.global_superstore_clean
ON CONFLICT (full_date) DO NOTHING;

-- Populate date attributes
UPDATE global_superstore_analytics.dim_date
SET
    day = EXTRACT(DAY FROM full_date),
    month = EXTRACT(MONTH FROM full_date),
    year = EXTRACT(YEAR FROM full_date),
    quarter = EXTRACT(QUARTER FROM full_date),
    week_of_year = EXTRACT(WEEK FROM full_date)
WHERE day IS NULL;

------------------------------------------------------------
-- FACT TABLE
------------------------------------------------------------

-- Grain: One row per order line item
CREATE TABLE IF NOT EXISTS global_superstore_analytics.fact_sales (
    row_id INT PRIMARY KEY,
    order_id TEXT,
    customer_id TEXT REFERENCES global_superstore_analytics.dim_customer(customer_id),
    product_id TEXT REFERENCES global_superstore_analytics.dim_product(product_id),
    order_date_id INT REFERENCES global_superstore_analytics.dim_date(date_id),
    ship_date_id INT REFERENCES global_superstore_analytics.dim_date(date_id),
    ship_mode TEXT,
    order_priority TEXT,
    sales NUMERIC,
    quantity INT,
    discount NUMERIC,
    profit NUMERIC,
    shipping_cost NUMERIC
);

INSERT INTO global_superstore_analytics.fact_sales (
    row_id, order_id, customer_id, product_id,
    order_date_id, ship_date_id, ship_mode, order_priority,
    sales, quantity, discount, profit, shipping_cost
)
SELECT
    c.row_id,
    c.order_id,
    c.customer_id,
    c.product_id,
    d1.date_id,
    d2.date_id,
    c.ship_mode,
    c.order_priority,
    c.sales,
    c.quantity,
    c.discount,
    c.profit,
    c.shipping_cost
FROM clean_zone.global_superstore_clean c
JOIN global_superstore_analytics.dim_date d1
  ON c.order_date = d1.full_date
JOIN global_superstore_analytics.dim_date d2
  ON c.ship_date = d2.full_date
ON CONFLICT (row_id) DO UPDATE
SET sales = EXCLUDED.sales,
    quantity = EXCLUDED.quantity,
    profit = EXCLUDED.profit;