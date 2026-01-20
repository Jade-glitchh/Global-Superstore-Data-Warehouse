-- Insert data into the clean zone

CREATE SCHEMA IF NOT EXISTS clean_zone;

CREATE TABLE IF NOT EXISTS clean_zone.global_superstore_clean (
    row_id INT PRIMARY KEY,
    order_id TEXT,
    order_date DATE,
    ship_date DATE,
    ship_mode TEXT,
    customer_id TEXT,
    customer_name TEXT,
    segment TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    postal_code TEXT,
    market TEXT,
    region TEXT,
    product_id TEXT,
    category TEXT,
    sub_category TEXT,
    product_name TEXT,
    sales NUMERIC,
    quantity INT,
    discount NUMERIC,
    profit NUMERIC,
    shipping_cost NUMERIC,
    order_priority TEXT
);

INSERT INTO clean_zone.global_superstore_clean (
    row_id, order_id, order_date, ship_date, ship_mode,
    customer_id, customer_name, segment, city, state,
    country, postal_code, market, region, product_id,
    category, sub_category, product_name, sales, quantity,
    discount, profit, shipping_cost, order_priority
)
SELECT DISTINCT
    row_id,
    order_id,
    order_date::DATE,
    ship_date::DATE,
    ship_mode,
    customer_id,
    customer_name,
    segment,
    city,
    state,
    country,
    NULLIF(postal_code, ''),
    market,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales,
    quantity,
    discount,
    profit,
    shipping_cost,
    order_priority
FROM raw_zone.global_superstore_raw
ON CONFLICT (row_id) DO UPDATE
SET
    sales = EXCLUDED.sales,
    quantity = EXCLUDED.quantity,
    discount = EXCLUDED.discount,
    profit = EXCLUDED.profit,
    shipping_cost = EXCLUDED.shipping_cost;
