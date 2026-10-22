/*============================================================================
				TrailForge Outdoor Co. Data Cleaning
=============================================================================*/

-- Dim.Promotion
DROP TABLE IF EXISTS clean.dim_promotion
SELECT 
promo_id, promo_name, promo_type, 
CAST(start_date AS date) AS start_date, CAST(end_date AS date) AS end_date,
CAST(discount_pct AS decimal(5,4)) AS discount_pct, channel_scope, category_scope,
CAST(free_shipping_flag AS bit) AS free_shipping_flag, 
CAST(first_order_only_flag AS bit) AS first_order_only_flag
INTO clean.dim_promotion 
FROM dbo.dim_promotion


-- Dim.Channel
DROP TABLE IF EXISTS clean.dim_channel
SELECT 
CAST(channel_id AS int) AS channel_id, channel_name, channel_type, 
CAST(launch_date AS date) AS launch_date,
CAST(fee_rate AS decimal(6,4)) AS fee_rate, 
CAST(fee_fixed_usd AS decimal(6,2)) AS fee_fixed_usd, fee_basis
INTO clean.dim_channel
FROM dbo.dim_channel


-- Dim.Product 
DROP TABLE IF EXISTS clean.dim_product
WITH p AS (
SELECT 
product_id, sku, product_name,
CASE LOWER(REPLACE(LTRIM(RTRIM(category)), ' and ', ' & '))
     WHEN 'apparel' THEN 'Apparel' WHEN 'footwear' THEN 'Footwear' WHEN 'packs & bags' THEN 'Packs & Bags'
     WHEN 'camping & shelter' THEN 'Camping & Shelter' WHEN 'hydration & drinkware' THEN 'Hydration & Drinkware'
     WHEN 'electronics & lighting' THEN 'Electronics & Lighting' 
END AS category, subcategory, brand, launch_date,
CAST(discontinued_date AS DATE) AS discontinued_date,
CAST(list_price_usd AS DECIMAL(10,2)) AS list_price_usd,
CAST(standard_cost_usd AS DECIMAL(10,2)) AS standard_cost_usd,
TRY_CAST(weight_kg AS decimal(6,2)) AS weight_kg
FROM dbo.dim_product)
SELECT
product_id, sku, product_name, category, subcategory, brand, 
launch_date, discontinued_date, list_price_usd, standard_cost_usd,
COALESCE(weight_kg, AVG(weight_kg) OVER (PARTITION BY subcategory)) AS weight_kg
INTO clean.dim_product
FROM p


-- Dim.Customer
DROP TABLE IF EXISTS clean.dim_customer
SELECT 
DISTINCT(customer_id) AS customer_id, 
LTRIM(RTRIM(customer_email)) AS customer_email,
CASE UPPER(LTRIM(RTRIM(customer_type))) WHEN 'CONSUMER' THEN 'Consumer' WHEN 'BUSINESS' THEN 'Business' END AS customer_type,
business_segment, 
COALESCE(
    CASE (LTRIM(RTRIM(country))) 
        WHEN 'UK' THEN 'United Kingdom' WHEN 'U.K.' THEN 'United Kingdom' WHEN 'Great Britain' THEN 'United Kingdom'
        WHEN 'US' THEN 'United States' WHEN 'United States Of America' THEN 'United States' WHEN 'USA' THEN 'United States'
        WHEN 'Aus' THEN 'Australia' WHEN 'UAE' THEN 'United Arab Emirates' WHEN 'RSA' THEN 'South Africa'
        WHEN 'Deustchland' THEN 'Germany' WHEN 'united states' THEN 'United States'
        ELSE country
    END, 'Unknown'
) AS country,
CASE WHEN signup_date < '2023-01-01' THEN 1 ELSE 0 END AS is_pre_period_customer,
CAST(signup_date AS DATE) AS signup_date, acquisition_source, marketing_opt_in
INTO clean.dim_customer
FROM dbo.dim_customer


-- Fact_orders 
DROP TABLE IF EXISTS clean.fact_orders
SELECT 
order_id, customer_id,
CAST(order_date AS DATE) AS order_date,
CAST(order_timestamp_utc AS TIME ) AS oreder_timestamp_utc,
channel_id, ship_geography_id, promo_id, payment_method,
CASE LOWER(LTRIM(RTRIM(order_status)))
    WHEN 'delivered' THEN 'Delivered' WHEN 'completed' THEN 'Delivered'
    WHEN 'cancelled' THEN 'Cancelled' WHEN 'canceled'  THEN 'Cancelled'
    WHEN 'shipped'   THEN 'Shipped'   WHEN 'in transit' THEN 'Shipped' 
    WHEN 'processing' THEN 'Processing' 
END AS order_status,
TRY_CONVERT(date, ship_date, 23) AS ship_date, 
TRY_CONVERT(date, delivery_date, 23) AS delivery_date,
CAST(shipping_charged_usd AS decimal(10,2)) AS shipping_charged_usd,
TRY_CAST(shipping_cost_usd AS decimal(10,2)) AS shipping_cost_usd,
CAST(channel_fee_usd AS decimal(10,2)) AS channel_fee_usd
INTO clean.fact_orders
FROM dbo.fact_orders


-- Order_items
DROP TABLE IF EXISTS clean.fact_order_items
SELECT 
order_item_id, order_id, product_id, 
CAST(quantity AS INT) AS quantity,
CAST(unit_list_price_usd AS DECIMAL(10,2)) AS unit_list_price_usd,
ROUND(CAST(discount_pct AS FLOAT), 2) AS discount_pct,
TRY_CAST(unit_cost_usd AS decimal(10,2)) AS unit_cost_usd,
CAST(line_net_revenue_usd AS DECIMAL(10,2)) AS line_net_revenue_usd
INTO clean.fact_order_items
FROM fact_order_items


-- Fact_returns
DROP TABLE IF EXISTS clean.fact_returns
SELECT 
return_id, order_item_id, return_date, return_quantity,
CASE LOWER(LTRIM(RTRIM(return_reason)))
     WHEN 'size or fit' THEN 'Size or Fit' WHEN 'size/fit' THEN 'Size or Fit'
     WHEN 'defective or damaged' THEN 'Defective or Damaged' WHEN 'defective' THEN 'Defective or Damaged'
     WHEN 'changed mind' THEN 'Changed Mind' WHEN 'not as described' THEN 'Not as Described' WHEN 'arrived late' THEN 'Arrived Late'
     ELSE 'Unknown' 
END  AS return_reason,
CAST(refund_amount_usd AS DECIMAL(10,2)) AS refund_amount_usd, 
CAST(restocked_flag AS BIT) AS restocked_flag,
CAST(return_shipping_cost_usd AS DECIMAL(10,2)) AS return_shipping_cost_usd
INTO clean.fact_returns
FROM fact_returns


-- Fact_marketing_spending
DROP TABLE IF EXISTS clean.fact_marketing_spend
SELECT 
marketing_spend_id, month_start_date, channel_id, region,
TRY_CAST(spend_usd AS DECIMAL(12,2)) AS spend_usd
INTO clean.fact_marketing_spend
FROM fact_marketing_spend