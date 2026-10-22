/*============================================================
	TrailForge Outdoor CO. Exploratgory Data Analysis (EDA)
==============================================================*/
USE TrailForgeAnalytics
GO
/*============================================================
  Q1. WHERE DID THE MARGIN GO?
==============================================================*/
-- 1a. Revenue and profit by year, with growth versus the previous year.
WITH annual AS (
    SELECT order_year,
           COUNT(*) AS orders,
           SUM(net_revenue) AS net_revenue,
           SUM(contribution_profit) AS contribution_profit
    FROM rpt.vw_order_pnl
    GROUP BY order_year
)
SELECT a.order_year, a.orders,
ROUND(a.net_revenue, 0) AS net_revenue,
ROUND(a.contribution_profit, 0) AS contribution_profit,
ROUND(100.0 * a.contribution_profit / NULLIF(a.net_revenue, 0), 1) AS contribution_margin_pct,
ROUND(100.0 * (a.net_revenue - p.net_revenue) / NULLIF(p.net_revenue, 0), 1) AS revenue_growth_pct,
ROUND(100.0 * (a.contribution_profit - p.contribution_profit) / NULLIF(p.contribution_profit, 0), 1) AS profit_growth_pct
FROM annual a
LEFT JOIN annual p
ON p.order_year = a.order_year - 1
ORDER BY a.order_year
/* Profit after marketing in 2025 was about $261.5K (22.6% of net revenue), up about 24% on 2024, against revenue growth of 44%.
Findings:
   2024 was healthy: profit grew almost as fast as revenue and margin held at about 30%. The problem is 2025. Revenue grew 44% but profit only
   29% (24% after marketing), so margin dropped about 3 points. Selling more but keeping less of money.
Caution: 2023 -> 2024 growth looks huge partly because 2023 was the first year (App launched mid-year, new markets opening).*/

-- 1b. Where did the margin go?
SELECT order_year,
ROUND(100.0 * SUM(net_cogs) / SUM(net_revenue), 1) AS product_cost_pct,
ROUND(100.0 * SUM(shipping_cost) / SUM(net_revenue), 1) AS shipping_cost_pct,
ROUND(100.0 * SUM(return_shipping_cost) / SUM(net_revenue), 2) AS return_shipping_pct,
ROUND(100.0 * SUM(channel_fees) / SUM(net_revenue), 1) AS channel_fees_pct,
ROUND(100.0 * SUM(contribution_profit) / SUM(net_revenue), 1) AS contribution_margin_pct
FROM rpt.vw_order_pnl
GROUP BY order_year
ORDER BY order_year
/* Findings:
   About three-quarters of the margin loss is product cost. More had been paid for the goods relative to what they were sold for.
   Shipping and channel fees explain most of the rest. Return shipping is tiny. So the first place to look is product cost versus prices. */ 

   -- 1c. Did it happen suddenly or gradually? Margin by quarter
SELECT order_year,
DATEPART(quarter, order_date) AS quarter_no,
ROUND(100.0 * SUM(contribution_profit) / SUM(net_revenue), 1) AS contribution_margin_pct
FROM rpt.vw_order_pnl
GROUP BY order_year, DATEPART(quarter, order_date)
ORDER BY order_year, quarter_no
/* Findings:
   Margin drifted down from mid-2024 and fell fastest through 2025, reaching its lowest point in Q3 2025 (23.7%). It was a gradual slide,
   not a one-off event, which points to cost and pricing pressure building up over time.
   Caution: Q4 2025 looks like a recovery, but the last ~35 days of orders have not yet had time to generate returns (is_mature_order = 0).
   Treat Q4 2025 margin as flattering and do not claim the problem is fixed. */


/*==============================================
  Q2. IS DISCOUNTING STILL PAYING FOR ITSELF?
==============================================*/

-- 2a. How much do we discount? Consumer vs. everyone
SELECT order_year,
COUNT(*) AS consumer_orders,
ROUND(100.0 * SUM(is_promo_order) / COUNT(*), 1) AS promo_order_pct,
ROUND(100.0 * (1 - SUM(net_merch_revenue) / SUM(gross_merch_revenue)), 1) AS consumer_discount_depth_pct
FROM rpt.vw_order_pnl
WHERE channel_name <> 'Wholesale'
GROUP BY order_year
ORDER BY order_year

SELECT order_year,
ROUND(100.0 * (1 - SUM(net_merch_revenue) / SUM(gross_merch_revenue)), 1) AS all_channels_discount_pct
FROM rpt.vw_order_pnl
GROUP BY order_year
ORDER BY order_year
/* Findings:
   Consumer discounting went up sharply in 2025: more orders used a promotion and the average discount per dollar doubled. */

-- 2b. Does a deeper discount still earn a profit? (consumer lines; margin = line contribution / net merchandise revenue)
WITH lines AS (
    SELECT order_year, net_merch_revenue, line_contribution,
           CASE WHEN discount_pct = 0   THEN '0% (full price)'
                WHEN discount_pct <= .10 THEN '1-10%'
                WHEN discount_pct <= .20 THEN '11-20%'
                WHEN discount_pct <= .30 THEN '21-30%'
                ELSE 'over 30%' END AS discount_band
    FROM rpt.vw_line_pnl
    WHERE channel_name <> 'Wholesale'
)
SELECT discount_band, order_year,
ROUND(SUM(net_merch_revenue), 0) AS net_revenue,
ROUND(100.0 * SUM(line_contribution) / NULLIF(SUM(net_merch_revenue), 0), 1) AS margin_pct
FROM lines
GROUP BY discount_band, order_year
ORDER BY discount_band, order_year
/* Findings:
   Light discounts (up to 10%) cost little margin. Discounts of 21-30% leave only 4-11% margin once shipping, fees and returns are paid, and the
   deepest 2025 discounts (over 30%) lose money. Those deep discounts only started appearing in 2025. */


/*======================================================================
  Q3. WHICH CHANNELS, CATEGORIES AND PRODUCTS EARN THEIR KEEP?
=======================================================================*/

-- 3a. Channel: share of revenue and margin
WITH ch AS (
    SELECT channel_name, order_year, SUM(net_merch_revenue) AS rev, SUM(line_contribution) AS profit
    FROM rpt.vw_line_pnl
    GROUP BY channel_name, order_year
), 
    yr AS (
    SELECT order_year, SUM(rev) AS total_rev 
    FROM ch 
    GROUP BY order_year
)
SELECT c.channel_name, c.order_year,
       ROUND(c.rev, 0) AS net_revenue,
       ROUND(100.0 * c.rev / y.total_rev, 1) AS revenue_share_pct,
       ROUND(100.0 * c.profit / NULLIF(c.rev, 0), 1) AS margin_pct
FROM ch c 
JOIN yr y ON y.order_year = c.order_year
ORDER BY c.channel_name, c.order_year
/* Findings:
   The channel MIX barely changed: wholesale is still about two-thirds of revenue. Margins fell inside every channel. 
   The Marketplace is clearly the weakest. */

-- 3b. Category margin by year
SELECT category, order_year,
ROUND(SUM(net_merch_revenue), 0) AS net_revenue,
ROUND(100.0 * SUM(line_contribution) / NULLIF(SUM(net_merch_revenue), 0), 1) AS margin_pct
FROM rpt.vw_line_pnl
WHERE category <> 'Unknown'
GROUP BY category, order_year
ORDER BY category, order_year
/* Findings:
   Three categories carry the decline. Apparel, Packs and Hydration were broadly stable.
   Electronics & lighting is the weakest channel.
   It may be a category-specific problem, not a company-wide one. */

-- 3c. The weakest category in detail: Electronics by channel
SELECT channel_name, order_year,
ROUND(SUM(net_merch_revenue), 0) AS net_revenue,
ROUND(100.0 * SUM(line_contribution) / NULLIF(SUM(net_merch_revenue), 0), 1) AS margin_pct
FROM rpt.vw_line_pnl
WHERE category = 'Electronics & Lighting'
GROUP BY channel_name, order_year
ORDER BY channel_name, order_year
/* Findings:
   Electronics on the Marketplace lost money in 2025 (the 15% commission plus deal discounts exceed the product margin). Wholesale electronics, which
   has a fixed 20% discount, fell from a 20% to a 10% margin. */

-- 3d. The key test: product cost as a % of list price, by category. If cost rises but list prices do not, margin must fall.
SELECT category, order_year,
ROUND(100.0 * SUM(cogs) / NULLIF(SUM(gross_revenue), 0), 1) AS cost_as_pct_of_list_price
FROM rpt.vw_line_pnl
WHERE category <> 'Unknown'
GROUP BY category, order_year
ORDER BY category, order_year
/* Findings:
   This is the root cause the data supports. In Electronics, cost went from 63% to 70% of the list price; in Footwear from 52% to 54%.
   Products cost us more but list prices did not rise enough to cover it, so every sale earns less. Stable categories (Apparel, Packs) show no such change. */

/*=============================================
  Q4. IS SHIPPING ERODING MARGIN, AND WHERE? 
==============================================*/

-- 4a. Shipping cost not recovered from customers, by destination country (all years)
SELECT ship_country,
COUNT(*) AS orders,
ROUND(SUM(shipping_revenue), 0) AS shipping_charged,
ROUND(SUM(shipping_cost), 0) AS shipping_cost,
ROUND(100.0 * (SUM(shipping_cost) - SUM(shipping_revenue)) / SUM(net_merch_revenue), 1) AS unrecovered_shipping_pct_of_sales
FROM rpt.vw_order_pnl
WHERE channel_name <> 'Wholesale'
GROUP BY ship_country
ORDER BY unrecovered_shipping_pct_of_sales
/* Finding:
   Every extra dollar of sales to the UAE, South Africa or Ghana costs about 15-18 cents in unrecovered shipping, versus about 4 cents in the US.
   The far markets are where free-shipping thresholds ($150) are too low for the carrier cost. */

-- 4b. Is it getting worse? And how much shipping do customers actually pay for?
SELECT order_year,
COUNT(*) AS orders,
ROUND(100.0 * SUM(shipping_revenue) / SUM(shipping_cost), 0) AS pct_of_shipping_cost_recovered,
ROUND(100.0 * SUM(CASE WHEN shipping_revenue = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS free_shipping_orders_pct,
ROUND(100.0 * SUM(CASE WHEN ship_region = 'Middle East & Africa' THEN 1 ELSE 0 END) / COUNT(*), 1) AS orders_to_middle_east_africa_pct,
ROUND(100.0 * (SUM(shipping_cost) - SUM(shipping_revenue)) / SUM(net_merch_revenue), 1) AS unrecovered_shipping_pct_of_sales
FROM rpt.vw_order_pnl
WHERE channel_name <> 'Wholesale'
GROUP BY order_year
ORDER BY order_year
/* Findings:
   About three out of four consumer orders ship free, and customers now cover only 19% of the shipping bill, down from 26%. Two things worked
   together: carrier rates rose each year, and a growing share of orders (0.7% to 10%) goes to the expensive far markets we opened in 2023-24. */


/*===================================================
 Q5. HOW COSTLY ARE RETURNS AND WHAT DRIVES THEM?
===================================================*/

-- 5a. Unit return rate by category
SELECT category,
SUM(quantity) AS units_sold,
SUM(units_returned) AS units_returned,
ROUND(100.0 * SUM(units_returned) / SUM(quantity), 1) AS return_rate_pct
FROM rpt.vw_line_pnl
WHERE channel_name <> 'Wholesale' AND order_date <= '2025-11-30' AND category <> 'Unknown'
GROUP BY category
ORDER BY return_rate_pct DESC
/* Findings:
   Footwear and Apparel are returned at 15-19%, two to four times the rate of Camping or Hydration. Footwear is also a category whose margin fell."  */

-- 5b. Why are they returned? Share of 'Size or Fit' and 'Defective' returns by category
SELECT p.category,
COUNT(*) AS returns,
ROUND(100.0 * SUM(CASE WHEN r.return_reason = 'Size or Fit' THEN 1 ELSE 0 END) / COUNT(*), 0) AS size_fit_pct,
ROUND(100.0 * SUM(CASE WHEN r.return_reason = 'Defective or Damaged' THEN 1 ELSE 0 END) / COUNT(*), 0) AS defective_pct
FROM clean.fact_returns r
JOIN clean.fact_order_items i ON i.order_item_id = r.order_item_id
JOIN clean.fact_orders o ON o.order_id = i.order_id
JOIN clean.dim_product p ON p.product_id = i.product_id
WHERE o.channel_id <> 4
GROUP BY p.category
ORDER BY returns DESC
/* Findings:
   About 53% of Apparel returns and 51% of Footwear returns are Size or Fit.
   Defects account for 56% of Electronics returns and 49% of Hydration returns, but
   only 8-12% of Apparel and Footwear returns.
   Half of clothing and shoe returns are about fit. That is a product information problem (size guides, fit descriptions, reviews), which is cheaper to
   fix than a quality problem. Electronics returns are dominated by faulty products, which is a supplier quality conversation. */

-- 5c. Return rate by channel, and by discount level
SELECT channel_name, 
ROUND(100.0 * SUM(units_returned) / SUM(quantity), 1) AS return_rate_pct
FROM rpt.vw_line_pnl
WHERE channel_name <> 'Wholesale' AND order_date <= '2025-11-30'
GROUP BY channel_name
ORDER BY return_rate_pct DESC

SELECT 
CASE 
    WHEN discount_pct >= .20 THEN 'Deep discount (20%+)' ELSE 'Under 20% or full price'
END AS price_group,
ROUND(100.0 * SUM(units_returned) / SUM(quantity), 1) AS return_rate_pct
FROM rpt.vw_line_pnl
WHERE channel_name <> 'Wholesale' AND order_date <= '2025-11-30'
GROUP BY 
    CASE
        WHEN discount_pct >= .20 THEN 'Deep discount (20%+)' ELSE 'Under 20% or full price' END
/* Findings:
   Marketplace customers return about 1.5 times as often as App customers, and heavily discounted items come back almost twice as often. */

GO
/*=================================================================
  Q6. WHICH CUSTOMERS ARE WORTH ACQUIRING AND DO THEY COME BACK?
==================================================================*/
WITH cust AS (
    SELECT customer_id, COUNT(*) AS orders, SUM(contribution_profit) AS contribution, MIN(order_date) AS first_order
    FROM rpt.vw_order_pnl
    GROUP BY customer_id
)
SELECT c.acquisition_source,
COUNT(*) AS customers,
ROUND(AVG(1.0 * x.orders), 2) AS avg_orders,
ROUND(100.0 * SUM(CASE WHEN x.orders >= 2 THEN 1 ELSE 0 END) / COUNT(*), 0) AS repeat_buyers_pct,
ROUND(AVG(x.contribution), 0) AS avg_profit_per_customer
FROM cust x
JOIN clean.dim_customer c ON c.customer_id = x.customer_id
WHERE c.customer_type = 'Consumer' AND c.is_pre_period_customer = 0 AND YEAR(x.first_order) = 2023
GROUP BY c.acquisition_source
ORDER BY avg_profit_per_customer
/* Findings:
   A Marketplace customer is worth about $56 of profit versus $185-$260 for customers who came through our own channels, roughly a quarter. 
   They order less often, buy smaller baskets, and every order pays a 15% commission. */


/*===================================================
  Q7. IS MARKETING SPEND BECOMING LESS EFFICIENT?
===================================================*/
WITH rev AS (
    SELECT channel_id, order_year, SUM(net_revenue) AS net_revenue
    FROM rpt.vw_order_pnl
    GROUP BY channel_id, order_year
), 
    spend AS (
    SELECT channel_id, YEAR(month_start_date) AS yr, SUM(spend_usd) AS spend
    FROM clean.fact_marketing_spend
    GROUP BY channel_id, YEAR(month_start_date)
)
SELECT ch.channel_name, s.yr, 
ROUND(s.spend, 0) AS marketing_spend,
ROUND(100.0 * s.spend / NULLIF(r.net_revenue, 0), 1) AS spend_pct_of_channel_revenue
FROM spend s
JOIN rev r ON r.channel_id = s.channel_id AND r.order_year = s.yr
JOIN clean.dim_channel ch ON ch.channel_id = s.channel_id
ORDER BY ch.channel_name, s.yr

SELECT YEAR(month_start_date) AS yr,
ROUND(SUM(spend_usd), 0) AS total_marketing_spend
FROM clean.fact_marketing_spend 
GROUP BY YEAR(month_start_date) 
ORDER BY yr
/* Findings:
   Marketing grew much faster than revenue, so more is paid for each dollar of Website and Marketplace sales.
   The App became cheaper to run as it scaled. */


/*==========================================
  Q8. WHAT IS THE SIZE OF THE OPPORTUNITY? 
  =========================================*/
--Question: how much extra 2025 profit if product cost had stayed at the same % of list price as in 2024?

WITH y24 AS (
    SELECT category, SUM(cogs) / SUM(gross_revenue) AS cost_ratio_2024
    FROM rpt.vw_line_pnl WHERE order_year = 2024 AND category <> 'Unknown' GROUP BY category
), 
    y25 AS (
    SELECT category, SUM(cogs) AS cogs_2025, SUM(gross_revenue) AS list_value_2025
    FROM rpt.vw_line_pnl WHERE order_year = 2025 AND category <> 'Unknown' GROUP BY category
)
SELECT b.category,
ROUND(100.0 * a.cost_ratio_2024, 1) AS cost_pct_of_list_2024,
ROUND(100.0 * b.cogs_2025 / b.list_value_2025, 1) AS cost_pct_of_list_2025,
ROUND((b.cogs_2025 / b.list_value_2025 - a.cost_ratio_2024) * b.list_value_2025, 0) AS profit_lost_vs_2024_cost_ratio
FROM y25 b 
JOIN y24 a ON a.category = b.category
ORDER BY profit_lost_vs_2024_cost_ratio DESC
/* Findings:
   If we had kept cost at 2024 levels relative to price, 2025 profit would have been about $23K higher; half of that is Electronics alone.
   This is the size of the cost vs price gap that pricing and supplier action would need to close. */