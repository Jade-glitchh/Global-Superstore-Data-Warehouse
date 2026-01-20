-- Top 10 Customers by Sales
--- Validates fact–customer joins and sales aggregation.
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM global_superstore_analytics.fact_sales f
JOIN global_superstore_analytics.dim_customer c
  ON f.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.customer_name
ORDER BY total_orders DESC
LIMIT 10;

-- Sales & Profit by Region
--- Validates regional attributes and profitability calculations.
SELECT
c.region,
ROUND(SUM(f.sales), 2) AS total_sales,
ROUND(SUM(f.profit), 2) AS total_profit,
ROUND((SUM(f.profit) / NULLIF(SUM(f.sales), 0)) * 100, 2) AS profit_margin_pct
FROM global_superstore_analytics.fact_sales f
JOIN global_superstore_analytics.dim_customer c
ON f.customer_id = c.customer_id
GROUP BY c.region
ORDER BY total_sales DESC;

-- Discount vs Profit Impact
--- Analyzes how discount levels affect profitability.
SELECT
CASE
WHEN discount = 0 THEN '0%'
WHEN discount > 0 AND discount <= 0.1 THEN '0–10%'
WHEN discount > 0.1 AND discount <= 0.2 THEN '10–20%'
WHEN discount > 0.2 AND discount <= 0.3 THEN '20–30%'
WHEN discount > 0.3 THEN '30%+'
END AS discount_bucket,
COUNT(*) AS order_lines,
ROUND(SUM(sales), 2) AS total_sales,
ROUND(SUM(profit), 2) AS total_profit,
ROUND(AVG(profit), 2) AS avg_profit_per_order
FROM global_superstore_analytics.fact_sales
GROUP BY discount_bucket
ORDER BY discount_bucket;